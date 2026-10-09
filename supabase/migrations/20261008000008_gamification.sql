-- Entrega 3: recompensas (capas, selos, títulos), conquistas diárias,
-- semanais e gerais, convites, currículo de ações, participantes com
-- check-in, fotos de participantes, atualizações de campanha, doação de
-- itens e marcar pessoas.

create type public.reward_kind as enum ('cover', 'badge', 'title');
create type public.achievement_period as enum ('daily', 'weekly', 'general');
create type public.item_request_status as enum ('requested', 'accepted', 'rejected', 'delivered', 'cancelled');
alter type public.notification_kind add value if not exists 'post_update';
alter type public.notification_kind add value if not exists 'item_request';
alter type public.notification_kind add value if not exists 'mention';
alter type public.notification_kind add value if not exists 'invite';

-- Fuso de Cuiabá para "hoje" e "esta semana".
create function private.period_start(p public.achievement_period) returns timestamptz
language sql stable set search_path = '' as $$
  select case p
    when 'daily' then date_trunc('day', now() at time zone 'America/Cuiaba') at time zone 'America/Cuiaba'
    when 'weekly' then date_trunc('week', now() at time zone 'America/Cuiaba') at time zone 'America/Cuiaba'
    else '-infinity'::timestamptz end;
$$;

-- Recompensas ----------------------------------------------------------------

create table public.rewards (
  id text primary key,
  kind public.reward_kind not null,
  name text not null,
  description text not null default '',
  price integer not null check (price >= 0),
  sponsor text not null default 'Save Easy',
  icon text not null default 'star',
  active boolean not null default true,
  sort integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.user_rewards (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  reward_id text not null references public.rewards (id) on delete cascade,
  equipped boolean not null default false,
  acquired_at timestamptz not null default now(),
  primary key (profile_id, reward_id)
);
create index user_rewards_reward_idx on public.user_rewards (reward_id);
create index user_rewards_equipped_idx on public.user_rewards (profile_id) where equipped;

alter table public.rewards enable row level security;
alter table public.user_rewards enable row level security;
create policy "catálogo visível" on public.rewards for select to authenticated using (active);
create policy "itens equipados são públicos" on public.user_rewards
  for select to authenticated using (equipped or profile_id = (select auth.uid()));

-- Conquistas -----------------------------------------------------------------

-- metric: o que é contado (ver private.metric_value).
create table public.achievements (
  id text primary key,
  title text not null,
  description text not null default '',
  period public.achievement_period not null,
  metric text not null,
  goal integer not null check (goal > 0),
  reward_coins integer not null default 0,
  reward_xp integer not null default 0,
  active boolean not null default true,
  sort integer not null default 0
);

create table public.achievement_claims (
  profile_id uuid not null references public.profiles (id) on delete cascade,
  achievement_id text not null references public.achievements (id) on delete cascade,
  period_start timestamptz not null,
  claimed_at timestamptz not null default now(),
  primary key (profile_id, achievement_id, period_start)
);
create index achievement_claims_achievement_idx on public.achievement_claims (achievement_id);

alter table public.achievements enable row level security;
alter table public.achievement_claims enable row level security;
create policy "conquistas visíveis" on public.achievements for select to authenticated using (active);
create policy "cada um vê os próprios resgates" on public.achievement_claims
  for select to authenticated using (profile_id = (select auth.uid()));

-- Convites -------------------------------------------------------------------

create table public.invites (
  invitee_id uuid primary key references public.profiles (id) on delete cascade,
  inviter_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  level_reward_at timestamptz
);
create index invites_inviter_idx on public.invites (inviter_id);
alter table public.invites enable row level security;
create policy "envolvidos veem o convite" on public.invites
  for select to authenticated using ((select auth.uid()) in (inviter_id, invitee_id));

-- Extras das publicações -----------------------------------------------------

create table public.post_photos (
  id bigint generated always as identity primary key,
  post_id bigint not null references public.posts (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  image_url text not null,
  caption text not null default '' check (char_length(caption) <= 200),
  created_at timestamptz not null default now()
);
create index post_photos_post_idx on public.post_photos (post_id, created_at desc);
create index post_photos_author_idx on public.post_photos (author_id, created_at desc);

create table public.post_updates (
  id bigint generated always as identity primary key,
  post_id bigint not null references public.posts (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  image_url text,
  created_at timestamptz not null default now()
);
create index post_updates_post_idx on public.post_updates (post_id, created_at desc);

create table public.item_requests (
  id bigint generated always as identity primary key,
  post_id bigint not null references public.posts (id) on delete cascade,
  requester_id uuid not null references public.profiles (id) on delete cascade,
  message text not null default '' check (char_length(message) <= 500),
  status public.item_request_status not null default 'requested',
  reward_granted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (post_id, requester_id)
);
create index item_requests_requester_idx on public.item_requests (requester_id);
create trigger item_requests_updated_at before update on public.item_requests
  for each row execute function private.set_updated_at();

create table public.post_mentions (
  post_id bigint not null references public.posts (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, profile_id)
);
create index post_mentions_profile_idx on public.post_mentions (profile_id);

alter table public.post_photos enable row level security;
alter table public.post_updates enable row level security;
alter table public.item_requests enable row level security;
alter table public.post_mentions enable row level security;
create policy "fotos visíveis" on public.post_photos for select to authenticated using (true);
create policy "atualizações visíveis" on public.post_updates for select to authenticated using (true);
create policy "menções visíveis" on public.post_mentions for select to authenticated using (true);
create policy "pedido visível ao autor do post e a quem pediu" on public.item_requests
  for select to authenticated using (
    requester_id = (select auth.uid())
    or exists (select 1 from public.posts p where p.id = post_id and p.author_id = (select auth.uid())));

-- Perfil com selos e título equipados ----------------------------------------

create or replace function public.profile_json(p public.profiles) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'id', p.id,
    'name', p.name,
    'username', p.username,
    'email', '',
    'accountType', p.account_type,
    'pronouns', public.pronouns_label(p.pronouns),
    'avatarUrl', p.avatar_url,
    'coverUrl', p.cover_url,
    'bio', p.bio,
    'city', p.city,
    'state', p.state,
    'level', p.level,
    'xp', p.xp,
    'coins', p.coins,
    'balance', 0,
    'followers', p.followers_count,
    'following', p.following_count,
    'postsCount', p.posts_count,
    'rating', p.rating_avg,
    'verificationStatus', p.verification_status,
    'onboardingCompleted', p.onboarding_completed,
    'role', p.role,
    'badgeIds', coalesce((select jsonb_agg(ur.reward_id order by ur.acquired_at)
                            from public.user_rewards ur join public.rewards r on r.id = ur.reward_id
                           where ur.profile_id = p.id and ur.equipped and r.kind = 'badge'), '[]'::jsonb),
    'titleId', (select ur.reward_id from public.user_rewards ur join public.rewards r on r.id = ur.reward_id
                 where ur.profile_id = p.id and ur.equipped and r.kind = 'title' limit 1),
    'coverRewardId', (select ur.reward_id from public.user_rewards ur join public.rewards r on r.id = ur.reward_id
                       where ur.profile_id = p.id and ur.equipped and r.kind = 'cover' limit 1)
  );
$$;

-- Recompensas: RPCs ----------------------------------------------------------

create function public.reward_json(r public.rewards, p_owned boolean, p_equipped boolean) returns jsonb
language sql immutable set search_path = '' as $$
  select jsonb_build_object('id', r.id, 'kind', r.kind, 'name', r.name, 'description', r.description,
                            'price', r.price, 'sponsor', r.sponsor, 'icon', r.icon,
                            'owned', p_owned, 'equipped', p_equipped);
$$;

create function public.rewards_catalog(p_kind public.reward_kind default null) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.reward_json(r, ur.reward_id is not null, coalesce(ur.equipped, false))
                            order by r.kind, r.sort, r.price), '[]'::jsonb)
    from public.rewards r
    left join public.user_rewards ur on ur.reward_id = r.id and ur.profile_id = (select auth.uid())
   where r.active and (p_kind is null or r.kind = p_kind);
$$;

-- Catálogo por ids (selos e título de outro perfil).
create function public.rewards_by_ids(p_ids text[]) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.reward_json(r, false, true)), '[]'::jsonb)
    from public.rewards r where r.id = any (p_ids);
$$;

create function public.redeem_reward(p_reward_id text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v public.rewards;
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  select * into v from public.rewards where id = p_reward_id and active;
  if v.id is null then raise exception 'Recompensa não encontrada.' using errcode = 'P0002'; end if;
  if exists (select 1 from public.user_rewards where profile_id = me and reward_id = v.id) then
    raise exception 'Você já possui esse item.' using errcode = 'P0001';
  end if;
  if (select coins from public.profiles where id = me) < v.price then
    raise exception 'Moedas insuficientes.' using errcode = 'P0001';
  end if;
  insert into public.user_rewards (profile_id, reward_id) values (me, v.id);
  perform private.grant_reward(me, -v.price, 0, 'reward_redeemed', 'rewards', v.id, null, v.name);
  return jsonb_build_object('reward', public.reward_json(v, true, false), 'me', public.my_profile());
end $$;

-- Equipa: até 1 capa, 1 título e 3 selos. Ids não possuídos são ignorados.
create function public.equip_rewards(p_title_id text, p_badge_ids text[], p_cover_id text default null)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  if coalesce(array_length(p_badge_ids, 1), 0) > 3 then
    raise exception 'Você pode exibir até 3 selos.' using errcode = 'P0001';
  end if;
  update public.user_rewards ur
     set equipped = (ur.reward_id = p_title_id and r.kind = 'title')
                 or (ur.reward_id = any (coalesce(p_badge_ids, '{}')) and r.kind = 'badge')
                 or (ur.reward_id = p_cover_id and r.kind = 'cover')
    from public.rewards r
   where r.id = ur.reward_id and ur.profile_id = me;
  return public.my_profile();
end $$;

-- Conquistas: RPCs -----------------------------------------------------------

create function private.metric_value(p_profile uuid, p_metric text, p_since timestamptz) returns integer
language sql stable security definer set search_path = '' as $$
  select (case p_metric
    when 'likes' then (select count(*) from public.post_likes where profile_id = p_profile and created_at >= p_since)
    when 'comments' then (select count(*) from public.comments
                           where author_id = p_profile and deleted_at is null and created_at >= p_since)
    when 'stories' then (select count(*) from public.stories where author_id = p_profile and created_at >= p_since)
    when 'posts' then (select count(*) from public.posts
                        where author_id = p_profile and deleted_at is null and created_at >= p_since)
    when 'participations' then (select count(*) from public.participations
                                 where profile_id = p_profile and status in ('going', 'attended')
                                   and created_at >= p_since)
    when 'environment' then (select count(*) from public.participations x join public.posts p on p.id = x.post_id
                              where x.profile_id = p_profile and x.status in ('going', 'attended')
                                and 'environment' = any (p.categories) and x.created_at >= p_since)
    when 'donations' then (select count(*) from public.coin_ledger
                            where profile_id = p_profile and reason in ('donation_reward', 'coins_donated')
                              and created_at >= p_since)
    when 'invites' then (select count(*) from public.invites where inviter_id = p_profile and created_at >= p_since)
    when 'follows' then (select count(*) from public.follows where follower_id = p_profile and created_at >= p_since)
    else 0 end)::integer;
$$;

create function public.my_achievements() returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'id', a.id, 'title', a.title, 'description', a.description,
      'goal', a.goal,
      'current', least(private.metric_value((select auth.uid()), a.metric, private.period_start(a.period)), a.goal),
      'rewardCoins', a.reward_coins, 'rewardXp', a.reward_xp,
      'daily', a.period = 'daily', 'period', a.period,
      'claimed', exists (select 1 from public.achievement_claims c
                          where c.profile_id = (select auth.uid()) and c.achievement_id = a.id
                            and c.period_start = private.period_start(a.period)))
    order by a.period, a.sort), '[]'::jsonb)
    from public.achievements a
   where a.active and (select auth.uid()) is not null;
$$;

create function public.claim_achievement(p_achievement_id text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v public.achievements;
  v_start timestamptz;
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  select * into v from public.achievements where id = p_achievement_id and active;
  if v.id is null then raise exception 'Conquista não encontrada.' using errcode = 'P0002'; end if;
  v_start := private.period_start(v.period);
  if private.metric_value(me, v.metric, v_start) < v.goal then
    raise exception 'Essa conquista ainda não pode ser resgatada.' using errcode = 'P0001';
  end if;
  insert into public.achievement_claims (profile_id, achievement_id, period_start)
  values (me, v.id, v_start) on conflict do nothing;
  if not found then raise exception 'Você já resgatou essa conquista.' using errcode = 'P0001'; end if;
  perform private.grant_reward(me, v.reward_coins, v.reward_xp, 'achievement_claimed', 'achievements', v.id);
  return public.my_profile();
end $$;

-- Convites: RPCs e recompensa no nível 20 ------------------------------------

create function public.my_invite() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'code', p.invite_code,
    'invited', (select count(*) from public.invites where inviter_id = p.id),
    'reachedLevel20', (select count(*) from public.invites where inviter_id = p.id and level_reward_at is not null),
    'invitedBy', (select public.profile_json(x) from public.invites i join public.profiles x on x.id = i.inviter_id
                   where i.invitee_id = p.id),
    'canRedeem', not exists (select 1 from public.invites where invitee_id = p.id)
                 and p.created_at > now() - interval '30 days'
  )
  from public.profiles p where p.id = (select auth.uid());
$$;

-- Quem foi convidado ganha 100 moedas; quem convidou ganha 50 agora e 1000
-- quando o convidado chegar ao nível 20.
create function public.redeem_invite(p_code text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_inviter uuid;
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  select id into v_inviter from public.profiles where invite_code = lower(trim(p_code));
  if v_inviter is null then raise exception 'Código de convite inválido.' using errcode = 'P0001'; end if;
  if v_inviter = me then raise exception 'Você não pode usar o próprio código.' using errcode = 'P0001'; end if;
  if (select created_at from public.profiles where id = me) < now() - interval '30 days' then
    raise exception 'O código só pode ser usado nos primeiros 30 dias de conta.' using errcode = 'P0001';
  end if;
  insert into public.invites (invitee_id, inviter_id) values (me, v_inviter) on conflict do nothing;
  if not found then raise exception 'Você já usou um código de convite.' using errcode = 'P0001'; end if;
  perform private.grant_reward(me, 100, 0, 'invite_reward', 'invites', me::text, v_inviter, 'Código de convite');
  perform private.grant_reward(v_inviter, 50, 20, 'invite_reward', 'invites', me::text, me, 'Amigo entrou');
  perform private.notify(v_inviter, me, 'invite', private.actor_name(me) || ' entrou com seu convite', '+50 moedas');
  return public.my_profile();
end $$;

create function private.on_level_invite_reward() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_inviter uuid;
begin
  if new.level >= 20 and old.level < 20 then
    update public.invites set level_reward_at = now()
     where invitee_id = new.id and level_reward_at is null
    returning inviter_id into v_inviter;
    if v_inviter is not null then
      perform private.grant_reward(v_inviter, 1000, 0, 'invite_reward', 'invites', new.id::text, new.id,
                                   'Convidado chegou ao nível 20');
      perform private.notify(v_inviter, new.id, 'invite',
        private.actor_name(new.id) || ' chegou ao nível 20!', '+1000 moedas pelo convite');
    end if;
  end if;
  return null;
end $$;
create trigger profiles_invite_level after update of xp on public.profiles
  for each row execute function private.on_level_invite_reward();

-- Currículo de ações ---------------------------------------------------------

create function public.action_resume(p_profile_id uuid, p_from timestamptz default null, p_to timestamptz default null)
returns jsonb
language sql stable security definer set search_path = '' as $$
  with items as (
    select x.created_at as at, case when x.status = 'attended' then 'attended' else 'participation' end as kind,
           p.id as post_id, p.title, p.type, p.reward_coins as coins, p.reward_xp as xp
      from public.participations x join public.posts p on p.id = x.post_id
     where x.profile_id = p_profile_id and x.status in ('going', 'attended') and p.deleted_at is null
    union all
    select p.created_at, 'post', p.id, p.title, p.type, 0, 30
      from public.posts p where p.author_id = p_profile_id and p.deleted_at is null
    union all
    select l.created_at, 'donation', p.id, coalesce(p.title, l.note, 'Doação'), coalesce(p.type, 'donation'), l.amount, 0
      from public.coin_ledger l
      left join public.posts p on l.ref_table = 'posts' and p.id::text = l.ref_id
     where l.profile_id = p_profile_id and l.reason = 'donation_reward'
    union all
    select r.updated_at, 'item_received', p.id, p.title, p.type, 0, 0
      from public.item_requests r join public.posts p on p.id = r.post_id
     where r.requester_id = p_profile_id and r.status = 'delivered'
  )
  select jsonb_build_object(
    'items', coalesce((select jsonb_agg(jsonb_build_object('date', at, 'kind', kind, 'postId', post_id::text,
                                                            'title', title, 'type', type, 'coins', coins, 'xp', xp)
                                        order by at desc)
                         from items
                        where (p_from is null or at >= p_from) and (p_to is null or at < p_to)), '[]'::jsonb),
    'totals', (select jsonb_build_object(
                 'participations', count(*) filter (where kind in ('participation', 'attended')),
                 'posts', count(*) filter (where kind = 'post'),
                 'donations', count(*) filter (where kind = 'donation'),
                 'items', count(*) filter (where kind = 'item_received'))
                 from items
                where (p_from is null or at >= p_from) and (p_to is null or at < p_to))
  );
$$;

-- Participantes e check-in ---------------------------------------------------

-- Código de check-in que o participante mostra ao organizador (QR/texto).
create function private.checkin_code(p_post bigint, p_profile uuid) returns text
language sql immutable set search_path = '' as $$
  select upper(substr(md5(p_post::text || ':' || p_profile::text || ':saveeasy-checkin'), 1, 6));
$$;

create function public.post_participants(p_post_id bigint) returns jsonb
language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(public.profile_json(pr) || jsonb_build_object(
           'participationStatus', x.status, 'checkedInAt', x.checked_in_at)
         order by x.status desc, x.created_at), '[]'::jsonb)
    from public.participations x join public.profiles pr on pr.id = x.profile_id
   where x.post_id = p_post_id and x.status in ('going', 'attended', 'no_show');
$$;

create function public.my_checkin_code(p_post_id bigint) returns text
language sql stable security definer set search_path = '' as $$
  select private.checkin_code(p_post_id, x.profile_id)
    from public.participations x
   where x.post_id = p_post_id and x.profile_id = (select auth.uid()) and x.status in ('going', 'attended');
$$;

-- Organizador marca presença (por pessoa ou pelo código). Presença dá +10 XP.
create function public.check_in(p_post_id bigint, p_profile_id uuid default null, p_code text default null,
                                p_attended boolean default true)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_target uuid := p_profile_id;
  v_prev public.participation_status;
begin
  if not exists (select 1 from public.posts where id = p_post_id and author_id = me) then
    raise exception 'Só o organizador pode marcar presença.' using errcode = '42501';
  end if;
  if v_target is null and p_code is not null then
    select profile_id into v_target from public.participations
     where post_id = p_post_id and private.checkin_code(post_id, profile_id) = upper(trim(p_code));
    if v_target is null then raise exception 'Código não encontrado neste evento.' using errcode = 'P0001'; end if;
  end if;
  select status into v_prev from public.participations where post_id = p_post_id and profile_id = v_target;
  if v_prev is null then raise exception 'Essa pessoa não confirmou presença.' using errcode = 'P0001'; end if;

  update public.participations
     set status = case when p_attended then 'attended' else 'no_show' end::public.participation_status,
         checked_in_at = case when p_attended then coalesce(checked_in_at, now()) end
   where post_id = p_post_id and profile_id = v_target;
  if p_attended and v_prev <> 'attended' and not exists (
       select 1 from public.xp_ledger where profile_id = v_target and ref_table = 'checkin'
                                        and ref_id = p_post_id::text) then
    perform private.grant_reward(v_target, 0, 10, 'participation_reward', 'checkin', p_post_id::text);
  end if;
  return public.post_participants(p_post_id);
end $$;

-- Fotos dos participantes ----------------------------------------------------

create function public.post_photos_list(p_post_id bigint) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', f.id::text, 'postId', f.post_id::text, 'imageUrl', f.image_url,
                                               'caption', f.caption, 'createdAt', f.created_at,
                                               'authorId', a.id, 'authorName', a.name,
                                               'authorAvatarUrl', a.avatar_url)
                            order by f.created_at desc), '[]'::jsonb)
    from public.post_photos f join public.profiles a on a.id = f.author_id
   where f.post_id = p_post_id;
$$;

create function public.add_post_photo(p_post_id bigint, p_image_url text, p_caption text default '')
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
begin
  if not exists (select 1 from public.posts p where p.id = p_post_id and p.deleted_at is null
                   and (p.author_id = me or exists (select 1 from public.participations x
                         where x.post_id = p.id and x.profile_id = me and x.status in ('going', 'attended')))) then
    raise exception 'Só quem participou pode enviar fotos.' using errcode = '42501';
  end if;
  insert into public.post_photos (post_id, author_id, image_url, caption)
  values (p_post_id, me, p_image_url, left(trim(coalesce(p_caption, '')), 200));
  return public.post_photos_list(p_post_id);
end $$;

create function public.delete_post_photo(p_photo_id bigint) returns void
language sql security definer set search_path = '' as $$
  delete from public.post_photos f
   where f.id = p_photo_id
     and (f.author_id = (select auth.uid())
          or exists (select 1 from public.posts p where p.id = f.post_id and p.author_id = (select auth.uid())));
$$;

-- Álbum do perfil: fotos enviadas pela pessoa.
create function public.profile_album(p_profile_id uuid) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', f.id::text, 'postId', f.post_id::text, 'imageUrl', f.image_url,
                                               'caption', f.caption, 'createdAt', f.created_at,
                                               'authorId', f.author_id, 'postTitle', p.title)
                            order by f.created_at desc), '[]'::jsonb)
    from public.post_photos f join public.posts p on p.id = f.post_id
   where f.author_id = p_profile_id and p.deleted_at is null;
$$;

-- Atualizações de campanha ---------------------------------------------------

create function public.post_updates_list(p_post_id bigint) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', u.id::text, 'body', u.body, 'imageUrl', u.image_url,
                                               'createdAt', u.created_at) order by u.created_at desc), '[]'::jsonb)
    from public.post_updates u where u.post_id = p_post_id;
$$;

-- Avisa quem participa ou demonstrou interesse.
create function public.add_post_update(p_post_id bigint, p_body text, p_image_url text default null)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_post public.posts;
begin
  select * into v_post from public.posts where id = p_post_id and author_id = me and deleted_at is null;
  if v_post.id is null then raise exception 'Só o autor pode publicar atualizações.' using errcode = '42501'; end if;
  if char_length(trim(coalesce(p_body, ''))) = 0 then
    raise exception 'Escreva a atualização.' using errcode = 'P0001';
  end if;
  insert into public.post_updates (post_id, body, image_url) values (p_post_id, trim(p_body), p_image_url);
  insert into public.notifications (recipient_id, actor_id, kind, title, body, post_id)
  select distinct q.profile_id, me, 'post_update'::public.notification_kind, 'Novidade em "' || v_post.title || '"', left(trim(p_body), 140), p_post_id
    from (select profile_id from public.participations where post_id = p_post_id and status in ('going', 'attended')
          union select profile_id from public.post_interests where post_id = p_post_id) q
   where q.profile_id <> me;
  return public.post_updates_list(p_post_id);
end $$;

-- Doação de itens ------------------------------------------------------------

create function public.item_request_json(r public.item_requests, a public.profiles) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object('id', r.id::text, 'postId', r.post_id::text, 'status', r.status,
                            'message', r.message, 'createdAt', r.created_at, 'updatedAt', r.updated_at,
                            'requester', public.profile_json(a));
$$;

-- Autor vê todos os pedidos; os demais veem só o próprio.
create function public.item_requests_for_post(p_post_id bigint) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.item_request_json(r, a) order by r.created_at), '[]'::jsonb)
    from public.item_requests r join public.profiles a on a.id = r.requester_id
   where r.post_id = p_post_id;
$$;

create function public.request_item(p_post_id bigint, p_message text default '') returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_post public.posts;
  v public.item_requests;
begin
  select * into v_post from public.posts where id = p_post_id and deleted_at is null;
  if v_post.id is null or v_post.type <> 'activity' or v_post.activity_kind is distinct from 'item_giveaway' then
    raise exception 'Essa publicação não é uma doação de itens.' using errcode = 'P0001';
  end if;
  if v_post.author_id = me then raise exception 'Você é quem está doando.' using errcode = 'P0001'; end if;
  if v_post.status <> 'published' then raise exception 'Essa doação já foi encerrada.' using errcode = 'P0001'; end if;
  insert into public.item_requests (post_id, requester_id, message)
  values (p_post_id, me, left(trim(coalesce(p_message, '')), 500))
  on conflict (post_id, requester_id) do update
     set status = 'requested', message = excluded.message
   where public.item_requests.status in ('cancelled', 'rejected')
  returning * into v;
  if v.id is null then raise exception 'Você já pediu esse item.' using errcode = 'P0001'; end if;
  perform private.notify(v_post.author_id, me, 'item_request',
    private.actor_name(me) || ' quer receber "' || v_post.title || '"', left(v.message, 140), p_post_id);
  return public.item_request_json(v, (select a from public.profiles a where a.id = me));
end $$;

-- Autor: accepted / rejected / delivered. Quem pediu: cancelled.
-- Entregue: o doador ganha a recompensa do post (uma vez por pedido).
create function public.update_item_request(p_request_id bigint, p_status public.item_request_status) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v public.item_requests;
  v_post public.posts;
begin
  select * into v from public.item_requests where id = p_request_id;
  select * into v_post from public.posts where id = v.post_id;
  if v.id is null then raise exception 'Pedido não encontrado.' using errcode = 'P0002'; end if;
  if p_status = 'cancelled' then
    if v.requester_id <> me then raise exception 'Sem permissão.' using errcode = '42501'; end if;
  elsif v_post.author_id <> me then
    raise exception 'Só quem doa pode responder.' using errcode = '42501';
  elsif p_status = 'requested' then
    raise exception 'Status inválido.' using errcode = 'P0001';
  end if;

  update public.item_requests set status = p_status where id = p_request_id returning * into v;
  if p_status = 'delivered' and v.reward_granted_at is null then
    perform private.grant_reward(v_post.author_id, v_post.reward_coins, v_post.reward_xp,
                                 'participation_reward', 'item_requests', v.id::text);
    update public.item_requests set reward_granted_at = now() where id = v.id returning * into v;
  end if;
  if p_status in ('accepted', 'rejected', 'delivered') then
    perform private.notify(v.requester_id, me, 'item_request',
      case p_status when 'accepted' then 'Seu pedido foi aceito: "'
                    when 'rejected' then 'Seu pedido não foi aceito: "'
                    else 'Item entregue: "' end || v_post.title || '"', '', v.post_id);
  end if;
  return public.item_request_json(v, (select a from public.profiles a where a.id = v.requester_id));
end $$;

-- Marcar pessoas -------------------------------------------------------------

create function public.set_post_mentions(p_post_id bigint, p_profile_ids uuid[]) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_post public.posts;
begin
  select * into v_post from public.posts where id = p_post_id and author_id = me;
  if v_post.id is null then raise exception 'Só o autor pode marcar pessoas.' using errcode = '42501'; end if;
  if coalesce(array_length(p_profile_ids, 1), 0) > 20 then
    raise exception 'Marque até 20 pessoas.' using errcode = 'P0001';
  end if;
  delete from public.post_mentions where post_id = p_post_id and not (profile_id = any (coalesce(p_profile_ids, '{}')));
  with added as (
    insert into public.post_mentions (post_id, profile_id)
    select p_post_id, id from public.profiles where id = any (coalesce(p_profile_ids, '{}')) and id <> me
    on conflict do nothing
    returning profile_id
  )
  insert into public.notifications (recipient_id, actor_id, kind, title, post_id)
  select profile_id, me, 'mention'::public.notification_kind, private.actor_name(me) || ' marcou você em "' || v_post.title || '"', p_post_id
    from added;
  return public.post_mentions_list(p_post_id);
end $$;

create function public.post_mentions_list(p_post_id bigint) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.profile_json(pr) order by m.created_at), '[]'::jsonb)
    from public.post_mentions m join public.profiles pr on pr.id = m.profile_id
   where m.post_id = p_post_id;
$$;

-- Extras do detalhe numa chamada: fotos, atualizações, marcados, meus pedidos
-- de item e meu código de check-in.
create function public.post_extras(p_post_id bigint) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'photos', public.post_photos_list(p_post_id),
    'updates', public.post_updates_list(p_post_id),
    'mentions', public.post_mentions_list(p_post_id),
    'itemRequests', coalesce((select jsonb_agg(public.item_request_json(r, a) order by r.created_at)
                                from public.item_requests r join public.profiles a on a.id = r.requester_id
                               where r.post_id = p_post_id
                                 and (r.requester_id = (select auth.uid())
                                      or exists (select 1 from public.posts p
                                                  where p.id = r.post_id and p.author_id = (select auth.uid())))),
                             '[]'::jsonb),
    'checkinCode', public.my_checkin_code(p_post_id),
    'participantsPreview', coalesce((select jsonb_agg(jsonb_build_object('id', pr.id, 'name', pr.name,
                                                                         'avatarUrl', pr.avatar_url))
                                       from (select pr.* from public.participations x
                                               join public.profiles pr on pr.id = x.profile_id
                                              where x.post_id = p_post_id and x.status in ('going', 'attended')
                                              order by x.created_at limit 8) pr), '[]'::jsonb)
  );
$$;

-- Catálogos iniciais ---------------------------------------------------------

insert into public.rewards (id, kind, name, description, price, sponsor, icon, sort) values
  ('r_cover_pantanal', 'cover', 'Pantanal ao Entardecer', 'Capa com o pôr do sol do Pantanal.', 1000, 'Save Easy', 'forest', 1),
  ('r_cover_chapada', 'cover', 'Chapada dos Guimarães', 'Capa com o Véu de Noiva.', 2500, 'Save Easy', 'forest', 2),
  ('r_cover_recycle', 'cover', 'Reciclagem', 'Capa exclusiva para quem ama reciclar.', 3200, 'EcoCuiabá Reciclagem', 'recycle', 3),
  ('r_badge_coffee', 'badge', 'Café Solidário', 'Selo para quem apoia pequenos produtores.', 400, 'Save Easy', 'coffee', 1),
  ('r_badge_planet', 'badge', 'Planeta Terra', 'Selo de quem cuida do meio ambiente.', 500, 'Save Easy', 'planet', 2),
  ('r_badge_vegan', 'badge', 'Vegano', 'Selo para quem apoia a causa animal na alimentação.', 710, 'Save Easy', 'vegan', 3),
  ('r_badge_voluntary', 'badge', 'Voluntário', 'Selo de quem já participou de ações voluntárias.', 400, 'Mãos do Porto', 'volunteer', 4),
  ('r_badge_shiba', 'badge', 'Amigo dos Pets', 'Selo de quem ajuda animais resgatados.', 500, 'Patas do Coxipó', 'pets', 5),
  ('r_badge_blood', 'badge', 'Doador de Sangue', 'Selo para quem doa vida.', 300, 'Banco de Sangue Vida MT', 'love', 6),
  ('r_title_education', 'title', 'Apoiador da educação', 'Título exibido abaixo do seu nome.', 200, 'Save Easy', 'school', 1),
  ('r_title_animals', 'title', 'Protetor dos animais', 'Título exibido abaixo do seu nome.', 350, 'Patas do Coxipó', 'pets', 2),
  ('r_title_green', 'title', 'Guardião verde', 'Título exibido abaixo do seu nome.', 250, 'EcoCuiabá Reciclagem', 'eco', 3),
  ('r_title_pantanal', 'title', 'Guardião do Pantanal', 'Título exibido abaixo do seu nome.', 600, 'Instituto Pantanal Vivo', 'eco', 4);

insert into public.achievements (id, title, description, period, metric, goal, reward_coins, reward_xp, sort) values
  ('a_daily_like', 'Curta 5 publicações', 'Mostre apoio a quem está fazendo o bem.', 'daily', 'likes', 5, 10, 5, 1),
  ('a_daily_comment', 'Comente em 1 publicação', 'Uma palavra de incentivo faz diferença.', 'daily', 'comments', 1, 10, 5, 2),
  ('a_daily_share', 'Compartilhe 1 boa ação', 'Publique um story hoje.', 'daily', 'stories', 1, 15, 10, 3),
  ('a_weekly_participate', 'Participe de 2 ações', 'Confirme presença em 2 ações nesta semana.', 'weekly', 'participations', 2, 60, 30, 1),
  ('a_weekly_post', 'Publique 1 boa ação', 'Crie uma publicação nesta semana.', 'weekly', 'posts', 1, 40, 20, 2),
  ('a_donations', 'Faça 100 doações', 'Doações em dinheiro ou moedas.', 'general', 'donations', 100, 500, 200, 1),
  ('a_recycle', 'Recicle 10 vezes', 'Participe de 10 ações de meio ambiente.', 'general', 'environment', 10, 200, 100, 2),
  ('a_events', 'Participe de 50 eventos', 'Eventos, ações sociais e atividades.', 'general', 'participations', 50, 300, 150, 3),
  ('a_friends', 'Convide 5 amigos', 'Use seu código de convite.', 'general', 'invites', 5, 250, 100, 4),
  ('a_follow', 'Siga 10 perfis', 'Acompanhe quem faz o bem em Cuiabá.', 'general', 'follows', 10, 50, 20, 5);

-- Permissões das funções -----------------------------------------------------
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;
revoke execute on all functions in schema private from public, anon, authenticated;
