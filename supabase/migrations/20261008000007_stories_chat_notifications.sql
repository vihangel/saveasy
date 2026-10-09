-- Entrega 2: stories (24h), notificações geradas pelo banco e mensagens em
-- tempo real. Tudo é escrito por RPC (security definer); o app só lê direto
-- as tabelas que o Realtime precisa (messages e notifications), com RLS.

create extension if not exists pg_cron with schema pg_catalog;

create type public.notification_kind as enum (
  'follow', 'comment', 'reply', 'participation', 'coins_received',
  'event_reminder', 'system'
);

-- Stories --------------------------------------------------------------------

create table public.stories (
  id bigint generated always as identity primary key,
  author_id uuid not null references public.profiles (id) on delete cascade,
  type public.post_type not null default 'social_action',
  body text not null default '' check (char_length(body) <= 280),
  image_url text,
  post_id bigint references public.posts (id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '24 hours',
  check (body <> '' or image_url is not null)
);
create index stories_active_idx on public.stories (expires_at desc, author_id);
create index stories_author_idx on public.stories (author_id, created_at desc);
create index stories_post_idx on public.stories (post_id) where post_id is not null;

create table public.story_views (
  story_id bigint not null references public.stories (id) on delete cascade,
  viewer_id uuid not null references public.profiles (id) on delete cascade,
  viewed_at timestamptz not null default now(),
  rewarded boolean not null default false,
  primary key (story_id, viewer_id)
);
create index story_views_viewer_idx on public.story_views (viewer_id, viewed_at desc);

alter table public.stories enable row level security;
alter table public.story_views enable row level security;

create policy "stories ativos são públicos para quem está logado" on public.stories
  for select to authenticated using (expires_at > now());
create policy "cada um vê as próprias visualizações" on public.story_views
  for select to authenticated using (viewer_id = (select auth.uid()));

-- Mensagens ------------------------------------------------------------------

-- Conversa direta (2 membros) ou grupo de uma comunidade (owner_id = perfil
-- da comunidade). A prévia da última mensagem fica na conversa para a lista.
create table public.conversations (
  id bigint generated always as identity primary key,
  is_group boolean not null default false,
  owner_id uuid references public.profiles (id) on delete cascade,
  direct_key text unique,
  last_message_at timestamptz not null default now(),
  last_message_preview text not null default '',
  created_at timestamptz not null default now(),
  check (is_group = (owner_id is not null)),
  check (is_group or direct_key is not null)
);
create unique index conversations_group_owner_idx on public.conversations (owner_id) where is_group;

create table public.conversation_members (
  conversation_id bigint not null references public.conversations (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  last_read_at timestamptz not null default now(),
  primary key (conversation_id, profile_id)
);
create index conversation_members_profile_idx on public.conversation_members (profile_id);

create table public.messages (
  id bigint generated always as identity primary key,
  conversation_id bigint not null references public.conversations (id) on delete cascade,
  author_id uuid references public.profiles (id) on delete set null,
  body text not null default '' check (char_length(body) <= 2000),
  shared_post_id bigint references public.posts (id) on delete set null,
  created_at timestamptz not null default now(),
  check (body <> '' or shared_post_id is not null)
);
create index messages_conversation_idx on public.messages (conversation_id, created_at desc, id desc);
create index messages_author_idx on public.messages (author_id);
create index messages_shared_post_idx on public.messages (shared_post_id) where shared_post_id is not null;

alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;

create policy "membro vê a própria participação" on public.conversation_members
  for select to authenticated using (profile_id = (select auth.uid()));
create policy "membro vê a conversa" on public.conversations
  for select to authenticated using (exists (
    select 1 from public.conversation_members m
     where m.conversation_id = conversations.id and m.profile_id = (select auth.uid())));
-- Usada também pelo Realtime para decidir quem recebe cada mensagem.
create policy "membro vê as mensagens" on public.messages
  for select to authenticated using (exists (
    select 1 from public.conversation_members m
     where m.conversation_id = messages.conversation_id and m.profile_id = (select auth.uid())));

-- Notificações ---------------------------------------------------------------

create table public.notifications (
  id bigint generated always as identity primary key,
  recipient_id uuid not null references public.profiles (id) on delete cascade,
  actor_id uuid references public.profiles (id) on delete cascade,
  kind public.notification_kind not null,
  title text not null,
  body text not null default '',
  post_id bigint references public.posts (id) on delete cascade,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_recipient_idx on public.notifications (recipient_id, created_at desc);
create index notifications_unread_idx on public.notifications (recipient_id) where read_at is null;
create index notifications_actor_idx on public.notifications (actor_id) where actor_id is not null;
create index notifications_post_idx on public.notifications (post_id) where post_id is not null;
-- Um lembrete por evento e pessoa.
create unique index notifications_reminder_once_idx on public.notifications (recipient_id, post_id)
  where kind = 'event_reminder';

alter table public.notifications enable row level security;
create policy "cada um vê as próprias notificações" on public.notifications
  for select to authenticated using (recipient_id = (select auth.uid()));

alter publication supabase_realtime add table public.messages, public.notifications;

-- Geração de notificações (triggers) ----------------------------------------

create function private.notify(
  p_recipient uuid, p_actor uuid, p_kind public.notification_kind,
  p_title text, p_body text default '', p_post bigint default null
) returns void
language sql security definer set search_path = '' as $$
  insert into public.notifications (recipient_id, actor_id, kind, title, body, post_id)
  select p_recipient, p_actor, p_kind, p_title, coalesce(p_body, ''), p_post
   where p_recipient is not null and p_recipient is distinct from p_actor;
$$;

create function private.actor_name(p uuid) returns text
language sql stable security definer set search_path = '' as $$
  select coalesce(nullif(name, ''), '@' || username) from public.profiles where id = p;
$$;

create function private.on_follow_notify() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  perform private.notify(new.followed_id, new.follower_id, 'follow',
    private.actor_name(new.follower_id) || ' começou a seguir você', '');
  return null;
end $$;
create trigger follows_notify after insert on public.follows
  for each row execute function private.on_follow_notify();

create function private.on_comment_notify() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_post public.posts;
  v_parent_author uuid;
begin
  select * into v_post from public.posts where id = new.post_id;
  if new.parent_id is not null then
    select author_id into v_parent_author from public.comments where id = new.parent_id;
    perform private.notify(v_parent_author, new.author_id, 'reply',
      private.actor_name(new.author_id) || ' respondeu seu comentário', left(new.body, 140), new.post_id);
  end if;
  if v_parent_author is distinct from v_post.author_id then
    perform private.notify(v_post.author_id, new.author_id, 'comment',
      private.actor_name(new.author_id) || ' comentou em "' || v_post.title || '"', left(new.body, 140), new.post_id);
  end if;
  return null;
end $$;
create trigger comments_notify after insert on public.comments
  for each row execute function private.on_comment_notify();

create function private.on_participation_notify() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_post public.posts;
begin
  if new.status <> 'going' or (tg_op = 'UPDATE' and old.status = 'going') then return null; end if;
  select * into v_post from public.posts where id = new.post_id;
  perform private.notify(v_post.author_id, new.profile_id, 'participation',
    private.actor_name(new.profile_id) || ' vai participar de "' || v_post.title || '"', '', new.post_id);
  return null;
end $$;
create trigger participations_notify after insert or update of status on public.participations
  for each row execute function private.on_participation_notify();

create function private.on_coins_notify() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.reason = 'coins_received' then
    perform private.notify(new.profile_id, new.counterpart_id, 'coins_received',
      private.actor_name(new.counterpart_id) || ' enviou ' || new.amount || ' moedas para você',
      coalesce(new.note, ''));
  end if;
  return null;
end $$;
create trigger coin_ledger_notify after insert on public.coin_ledger
  for each row execute function private.on_coins_notify();

-- Lembrete 24h antes de eventos e ações sociais (pg_cron a cada 15 min).
create function private.send_event_reminders() returns integer
language plpgsql security definer set search_path = '' as $$
declare
  v_count integer;
begin
  insert into public.notifications (recipient_id, kind, title, body, post_id)
  select pa.profile_id, 'event_reminder', 'Lembrete: "' || p.title || '" é amanhã',
         coalesce(p.location_text, 'Confira os detalhes na publicação.'), p.id
    from public.posts p
    join public.participations pa on pa.post_id = p.id and pa.status = 'going'
   where p.deleted_at is null and p.status = 'published'
     and p.starts_at between now() and now() + interval '24 hours'
  on conflict do nothing;
  get diagnostics v_count = row_count;
  return v_count;
end $$;

-- Limpeza: stories expirados há mais de 7 dias.
create function private.purge_old_stories() returns void
language sql security definer set search_path = '' as $$
  delete from public.stories where expires_at < now() - interval '7 days';
$$;

select cron.schedule('event-reminders', '*/15 * * * *', 'select private.send_event_reminders()');
select cron.schedule('purge-old-stories', '30 3 * * *', 'select private.purge_old_stories()');

-- Stories: RPCs ----------------------------------------------------------------

create function public.story_json(s public.stories, a public.profiles, p_seen boolean) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'id', s.id::text,
    'authorId', s.author_id,
    'authorName', a.name,
    'authorAvatarUrl', a.avatar_url,
    'type', s.type,
    'text', s.body,
    'imageUrl', s.image_url,
    'postId', s.post_id::text,
    'createdAt', s.created_at,
    'seen', p_seen
  );
$$;

-- Bandeja do feed: meus stories, de quem eu sigo e da minha cidade (24h).
create function public.stories_tray(p_limit integer default 60) returns jsonb
language sql stable set search_path = '' as $$
  with me as (
    select id, coalesce(state, 'MT') as state, coalesce(city, 'Cuiabá') as city
      from public.profiles where id = (select auth.uid())
  ),
  tray as (
    select s, a, s.author_id = me.id
                 or exists (select 1 from public.story_views v
                             where v.story_id = s.id and v.viewer_id = me.id) as seen
      from public.stories s
      join public.profiles a on a.id = s.author_id
      cross join me
     where s.expires_at > now()
       and (s.author_id = me.id
            or exists (select 1 from public.follows f where f.follower_id = me.id and f.followed_id = s.author_id)
            or (a.state = me.state and lower(a.city) = lower(me.city)))
     order by s.created_at desc
     limit least(greatest(p_limit, 1), 100)
  )
  select coalesce(jsonb_agg(public.story_json(tray.s, tray.a, tray.seen)
                            order by (tray.s).created_at desc), '[]'::jsonb)
    from tray;
$$;

-- Marca como visto. Story de propaganda dá 20 moedas uma vez (máx. 5 por dia).
-- Devolve o perfil atualizado quando houve recompensa, senão null.
create function public.view_story(p_story_id bigint) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_story public.stories;
  v_inserted integer;
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  select * into v_story from public.stories where id = p_story_id and expires_at > now();
  if v_story.id is null then return null; end if;

  insert into public.story_views (story_id, viewer_id) values (p_story_id, me) on conflict do nothing;
  get diagnostics v_inserted = row_count;

  if v_inserted = 1 and v_story.type = 'ad' and v_story.author_id <> me
     and (select count(*) from public.story_views
           where viewer_id = me and rewarded and viewed_at > now() - interval '24 hours') < 5 then
    update public.story_views set rewarded = true where story_id = p_story_id and viewer_id = me;
    perform private.grant_reward(me, 20, 0, 'ad_viewed', 'stories', p_story_id::text);
    return public.my_profile();
  end if;
  return null;
end $$;

-- Publica um story. O primeiro do dia dá +20 moedas e +20 XP.
create function public.create_story(p jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_account public.account_type;
  v_type public.post_type := coalesce(nullif(p ->> 'type', ''), 'social_action')::public.post_type;
  v_story public.stories;
  v_first boolean;
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  select account_type into v_account from public.profiles where id = me;
  if not private.can_create_post(v_account, v_type) then
    raise exception 'Seu tipo de conta não pode publicar esse tipo de story.' using errcode = 'P0001';
  end if;
  v_first := not exists (select 1 from public.stories
                          where author_id = me and created_at > now() - interval '24 hours');

  insert into public.stories (author_id, type, body, image_url, post_id)
  values (me, v_type, left(trim(coalesce(p ->> 'text', '')), 280), nullif(p ->> 'imageUrl', ''),
          (select id from public.posts where id = nullif(p ->> 'postId', '')::bigint and deleted_at is null))
  returning * into v_story;

  if v_first then
    perform private.grant_reward(me, 20, 20, 'story_created', 'stories', v_story.id::text);
  end if;
  return jsonb_build_object(
    'story', public.story_json(v_story, (select a from public.profiles a where a.id = me), true),
    'me', public.my_profile());
exception when check_violation then
  raise exception 'Escreva algo ou adicione uma imagem.' using errcode = 'P0001';
end $$;

create function public.delete_story(p_story_id bigint) returns void
language sql security definer set search_path = '' as $$
  delete from public.stories where id = p_story_id and author_id = (select auth.uid());
$$;

-- Notificações: RPCs ---------------------------------------------------------

create function public.notification_json(n public.notifications, a public.profiles) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'id', n.id::text,
    'kind', n.kind,
    'title', n.title,
    'body', n.body,
    'date', n.created_at,
    'read', n.read_at is not null,
    'postId', n.post_id::text,
    'actorId', a.id,
    'actorName', a.name,
    'actorAvatarUrl', a.avatar_url
  );
$$;

create function public.my_notifications(p_limit integer default 50, p_before bigint default null) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.notification_json(x.n, x.a)
                            order by (x.n).created_at desc, (x.n).id desc), '[]'::jsonb)
    from (
      select n, a
        from public.notifications n
        left join public.profiles a on a.id = n.actor_id
       where n.recipient_id = (select auth.uid())
         and (p_before is null or n.id < p_before)
       order by n.created_at desc, n.id desc
       limit least(greatest(p_limit, 1), 100)
    ) x;
$$;

-- Sem ids: marca todas.
create function public.mark_notifications_read(p_ids bigint[] default null) returns void
language sql security definer set search_path = '' as $$
  update public.notifications set read_at = now()
   where recipient_id = (select auth.uid()) and read_at is null
     and (p_ids is null or id = any (p_ids));
$$;

-- Contadores da barra inferior.
create function public.unread_counts() returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'notifications', (select count(*) from public.notifications
                       where recipient_id = (select auth.uid()) and read_at is null),
    'messages', (select count(*) from public.conversation_members cm
                   join public.messages m on m.conversation_id = cm.conversation_id
                  where cm.profile_id = (select auth.uid())
                    and m.created_at > cm.last_read_at
                    and m.author_id is distinct from cm.profile_id)
  );
$$;

-- Mensagens: RPCs ------------------------------------------------------------

-- Formato do ChatThread do app. kind: grupo de comunidade = community;
-- conversa direta segue o tipo da outra conta (empresa = company).
create function public.thread_json(p_conversation_id bigint) returns jsonb
language sql stable security definer set search_path = '' as $$
  with c as (select * from public.conversations where id = p_conversation_id),
  me as (select * from public.conversation_members
          where conversation_id = p_conversation_id and profile_id = (select auth.uid())),
  peer as (
    select pr.* from public.profiles pr, c
     where pr.id = case when c.is_group then c.owner_id else (
             select profile_id from public.conversation_members
              where conversation_id = c.id and profile_id <> (select auth.uid()) limit 1) end
  )
  select jsonb_build_object(
    'id', c.id::text,
    'name', coalesce(peer.name, 'Conversa'),
    'kind', case when c.is_group or peer.account_type = 'community' then 'community'
                 when peer.account_type = 'business' then 'company'
                 else 'person' end,
    'lastMessage', c.last_message_preview,
    'updatedAt', c.last_message_at,
    'unread', (select count(*) from public.messages m
                where m.conversation_id = c.id and m.created_at > me.last_read_at
                  and m.author_id is distinct from me.profile_id),
    'online', false,
    'members', (select count(*) from public.conversation_members where conversation_id = c.id),
    'avatarUrl', peer.avatar_url,
    'peerId', peer.id,
    'peerUsername', peer.username,
    'isGroup', c.is_group
  )
  from c join me on true left join peer on true;
$$;

create function public.my_conversations(p_kind text default null) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(t order by t ->> 'updatedAt' desc), '[]'::jsonb)
    from (
      select public.thread_json(cm.conversation_id) as t
        from public.conversation_members cm
       where cm.profile_id = (select auth.uid())
    ) x
   where p_kind is null or t ->> 'kind' = p_kind;
$$;

create function public.conversation(p_conversation_id bigint) returns jsonb
language plpgsql stable set search_path = '' as $$
declare
  v jsonb := public.thread_json(p_conversation_id);
begin
  if v is null then raise exception 'Conversa não encontrada.' using errcode = 'P0002'; end if;
  return v;
end $$;

create function public.message_json(m public.messages, a public.profiles) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'id', m.id::text,
    'threadId', m.conversation_id::text,
    'authorId', m.author_id,
    'authorName', coalesce(a.name, 'Conta excluída'),
    'text', m.body,
    'sentAt', m.created_at,
    'fromMe', m.author_id = (select auth.uid()),
    'sharedPostId', m.shared_post_id::text
  );
$$;

-- Últimas mensagens (ordem cronológica) e marca a conversa como lida.
create function public.conversation_messages(
  p_conversation_id bigint, p_limit integer default 50, p_before bigint default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v jsonb;
begin
  update public.conversation_members set last_read_at = now()
   where conversation_id = p_conversation_id and profile_id = me;
  if not found then raise exception 'Conversa não encontrada.' using errcode = 'P0002'; end if;

  select coalesce(jsonb_agg(public.message_json(x.m, x.a) order by (x.m).id), '[]'::jsonb) into v
    from (
      select m, a from public.messages m
        left join public.profiles a on a.id = m.author_id
       where m.conversation_id = p_conversation_id and (p_before is null or m.id < p_before)
       order by m.id desc
       limit least(greatest(p_limit, 1), 200)
    ) x;
  return v;
end $$;

-- Uma mensagem (usado quando o Realtime avisa de uma nova).
create function public.message_by_id(p_message_id bigint) returns jsonb
language sql stable set search_path = '' as $$
  select public.message_json(m, a)
    from public.messages m
    left join public.profiles a on a.id = m.author_id
   where m.id = p_message_id;
$$;

create function public.mark_conversation_read(p_conversation_id bigint) returns void
language sql security definer set search_path = '' as $$
  update public.conversation_members set last_read_at = now()
   where conversation_id = p_conversation_id and profile_id = (select auth.uid());
$$;

create function public.send_message(
  p_conversation_id bigint, p_body text default '', p_shared_post_id bigint default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_msg public.messages;
  v_body text := left(trim(coalesce(p_body, '')), 2000);
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  if not exists (select 1 from public.conversation_members
                  where conversation_id = p_conversation_id and profile_id = me) then
    raise exception 'Conversa não encontrada.' using errcode = 'P0002';
  end if;
  if v_body = '' and p_shared_post_id is null then
    raise exception 'Escreva uma mensagem.' using errcode = 'P0001';
  end if;

  insert into public.messages (conversation_id, author_id, body, shared_post_id)
  values (p_conversation_id, me, v_body, p_shared_post_id)
  returning * into v_msg;

  update public.conversations
     set last_message_at = v_msg.created_at,
         last_message_preview = case when v_body = '' then 'Compartilhou uma publicação' else left(v_body, 120) end
   where id = p_conversation_id;
  update public.conversation_members set last_read_at = v_msg.created_at
   where conversation_id = p_conversation_id and profile_id = me;

  return public.message_json(v_msg, (select a from public.profiles a where a.id = me));
end $$;

-- Abre (ou cria) a conversa com um perfil. Comunidade abre o grupo dela.
create function public.open_conversation(p_profile_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_target public.profiles;
  v_id bigint;
  v_key text;
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  select * into v_target from public.profiles where id = p_profile_id;
  if v_target.id is null then raise exception 'Perfil não encontrado.' using errcode = 'P0002'; end if;

  if v_target.account_type = 'community' then
    insert into public.conversations (is_group, owner_id) values (true, v_target.id)
    on conflict (owner_id) where is_group do update set owner_id = excluded.owner_id
    returning id into v_id;
    insert into public.conversation_members (conversation_id, profile_id)
    values (v_id, v_target.id), (v_id, me)
    on conflict do nothing;
  else
    if v_target.id = me then raise exception 'Você não pode conversar consigo.' using errcode = 'P0001'; end if;
    v_key := least(me::text, v_target.id::text) || ':' || greatest(me::text, v_target.id::text);
    insert into public.conversations (direct_key) values (v_key)
    on conflict (direct_key) do update set direct_key = excluded.direct_key
    returning id into v_id;
    insert into public.conversation_members (conversation_id, profile_id)
    values (v_id, me), (v_id, v_target.id)
    on conflict do nothing;
  end if;
  return public.thread_json(v_id);
end $$;

-- Sair de um grupo de comunidade (conversa direta não sai, só some se vazia).
create function public.leave_conversation(p_conversation_id bigint) returns void
language sql security definer set search_path = '' as $$
  delete from public.conversation_members cm
   using public.conversations c
   where c.id = cm.conversation_id and c.is_group and c.owner_id <> cm.profile_id
     and cm.conversation_id = p_conversation_id and cm.profile_id = (select auth.uid());
$$;

-- Permissões das funções -----------------------------------------------------
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;
revoke execute on all functions in schema private from public, anon, authenticated;
