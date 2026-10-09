-- Entrega 6: denúncias, bloqueios, suspensão, verificação de contas, painel
-- de administração/moderação e página pública de transparência.

create type public.report_target as enum ('post', 'comment', 'profile', 'message', 'story', 'product', 'ad');
create type public.report_reason as enum ('spam', 'scam', 'hate', 'violence', 'nudity', 'false_info', 'other');
create type public.report_status as enum ('open', 'actioned', 'dismissed');
create type public.verification_request_status as enum ('pending', 'approved', 'rejected');
alter type public.notification_kind add value if not exists 'moderation';

alter table public.profiles add column suspended_until timestamptz;

-- O app também não altera a suspensão.
create or replace function private.guard_profile_columns() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('authenticated', 'anon') and (
       new.id is distinct from old.id
    or new.xp is distinct from old.xp
    or new.coins is distinct from old.coins
    or new.role is distinct from old.role
    or new.verification_status is distinct from old.verification_status
    or new.followers_count is distinct from old.followers_count
    or new.following_count is distinct from old.following_count
    or new.posts_count is distinct from old.posts_count
    or new.rating_avg is distinct from old.rating_avg
    or new.rating_count is distinct from old.rating_count
    or new.invite_code is distinct from old.invite_code
    or new.is_demo is distinct from old.is_demo
    or new.suspended_until is distinct from old.suspended_until
    or (old.onboarding_completed and new.account_type is distinct from old.account_type)
  ) then
    raise exception 'Campo protegido do perfil' using errcode = '42501';
  end if;
  return new;
end $$;

-- Quem é da equipe (admin/moderador). Usada nas policies e nas RPCs.
create function public.am_i_staff() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles where id = (select auth.uid()) and role in ('admin', 'moderator'));
$$;

create function private.require_staff() returns uuid
language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.am_i_staff() then
    raise exception 'Acesso restrito à equipe do Save Easy.' using errcode = '42501';
  end if;
  return (select auth.uid());
end $$;

-- Bloqueios ---------------------------------------------------------------------

create table public.blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index blocks_blocked_idx on public.blocks (blocked_id);
alter table public.blocks enable row level security;
create policy "cada um vê quem bloqueou" on public.blocks
  for select to authenticated using (blocker_id = (select auth.uid()));

-- Ids bloqueados nos dois sentidos (eu bloqueei ou me bloquearam).
create function public.blocked_ids() returns setof uuid
language sql stable security definer set search_path = '' as $$
  select blocked_id from public.blocks where blocker_id = (select auth.uid())
  union
  select blocker_id from public.blocks where blocked_id = (select auth.uid());
$$;

create function private.is_blocked_pair(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.blocks
                  where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a));
$$;

create function public.toggle_block(p_target uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_blocked boolean;
begin
  if me is null or p_target = me then raise exception 'Operação inválida.' using errcode = 'P0001'; end if;
  delete from public.blocks where blocker_id = me and blocked_id = p_target;
  if found then
    v_blocked := false;
  else
    insert into public.blocks (blocker_id, blocked_id) values (me, p_target);
    delete from public.follows where (follower_id = me and followed_id = p_target)
                                  or (follower_id = p_target and followed_id = me);
    v_blocked := true;
  end if;
  return jsonb_build_object('blocked', v_blocked, 'me', public.my_profile());
end $$;

create function public.my_blocks() returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.profile_json(p) order by b.created_at desc), '[]'::jsonb)
    from public.blocks b join public.profiles p on p.id = b.blocked_id
   where b.blocker_id = (select auth.uid());
$$;

-- Bloqueio e suspensão valem em qualquer caminho de escrita (triggers).
create function private.guard_interaction() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_actor uuid;
  v_target uuid;
begin
  case tg_table_name
  when 'comments' then
    v_actor := new.author_id;
    v_target := (select author_id from public.posts where id = new.post_id);
  when 'follows' then
    v_actor := new.follower_id;
    v_target := new.followed_id;
  when 'messages' then
    v_actor := new.author_id;
    v_target := (select cm.profile_id from public.conversation_members cm
                   join public.conversations c on c.id = cm.conversation_id and not c.is_group
                  where cm.conversation_id = new.conversation_id and cm.profile_id <> new.author_id limit 1);
  when 'posts', 'stories' then
    v_actor := new.author_id;
  else
    return new;
  end case;

  if (select suspended_until from public.profiles where id = v_actor) > now() then
    raise exception 'Sua conta está suspensa temporariamente.' using errcode = '42501';
  end if;
  if v_target is not null and private.is_blocked_pair(v_actor, v_target) then
    raise exception 'Não é possível interagir com esse perfil.' using errcode = '42501';
  end if;
  return new;
end $$;
create trigger comments_interaction_guard before insert on public.comments for each row execute function private.guard_interaction();
create trigger follows_interaction_guard before insert on public.follows for each row execute function private.guard_interaction();
create trigger messages_interaction_guard before insert on public.messages for each row execute function private.guard_interaction();
create trigger posts_interaction_guard before insert on public.posts for each row execute function private.guard_interaction();
create trigger stories_interaction_guard before insert on public.stories for each row execute function private.guard_interaction();

-- Feed sem quem está bloqueado (mesma função da migration 4 + filtro).
create or replace function public.feed(
  p_tab text default 'popular',
  p_category public.post_category default null,
  p_query text default '',
  p_limit integer default 30,
  p_offset integer default 0
) returns jsonb
language sql stable set search_path = '' as $$
  with me as (
    select coalesce(state, 'MT') as state, coalesce(city, 'Cuiabá') as city
      from public.profiles where id = (select auth.uid())
    union all
    select 'MT', 'Cuiabá' where (select auth.uid()) is null
  ),
  page as (
    select p, a,
           row_number() over (
             order by case when p_tab = 'popular' then (p.likes_count + 2 * p.comments_count
                        + 3 * p.participants_count + p.interests_count) end desc nulls last,
                      p.created_at desc, p.id desc) as rn
      from public.posts p
      join public.profiles a on a.id = p.author_id
     where p.deleted_at is null
       and p.status in ('published', 'finished')
       and p.author_id not in (select public.blocked_ids())
       and (a.suspended_until is null or a.suspended_until < now())
       and (p_category is null or p_category = any (p.categories))
       and (coalesce(p_query, '') = ''
            or p.search @@ websearch_to_tsquery('portuguese', p_query)
            or p.title ilike '%' || p_query || '%'
            or a.name ilike '%' || p_query || '%')
       and case p_tab
         when 'following' then
           p.author_id = (select auth.uid())
           or exists (select 1 from public.follows f
                       where f.follower_id = (select auth.uid()) and f.followed_id = p.author_id)
         when 'nearby' then
           exists (select 1 from me where me.state = p.state and lower(me.city) = lower(p.city))
           or p.type = 'tutorial' or p.link_url is not null
         else true
       end
  )
  select coalesce(jsonb_agg(public.post_json(page.p, page.a) order by page.rn), '[]'::jsonb)
    from page
   where page.rn > greatest(p_offset, 0)
     and page.rn <= greatest(p_offset, 0) + least(greatest(p_limit, 1), 100);
$$;

-- Denúncias ---------------------------------------------------------------------

create table public.reports (
  id bigint generated always as identity primary key,
  reporter_id uuid references public.profiles (id) on delete set null,
  target_type public.report_target not null,
  target_id text not null,
  reason public.report_reason not null,
  details text not null default '' check (char_length(details) <= 1000),
  status public.report_status not null default 'open',
  resolved_by uuid references public.profiles (id) on delete set null,
  resolved_at timestamptz,
  resolution_note text,
  created_at timestamptz not null default now()
);
create index reports_open_idx on public.reports (created_at) where status = 'open';
create index reports_target_idx on public.reports (target_type, target_id);
create index reports_reporter_idx on public.reports (reporter_id);
create index reports_resolved_by_idx on public.reports (resolved_by);
create unique index reports_once_idx on public.reports (reporter_id, target_type, target_id) where status = 'open';
alter table public.reports enable row level security;
create policy "quem denunciou vê a própria denúncia; equipe vê todas" on public.reports
  for select to authenticated using (reporter_id = (select auth.uid()) or (select public.am_i_staff()));

create function public.report_content(p_target public.report_target, p_target_id text, p_reason public.report_reason,
                                      p_details text default '')
returns void
language plpgsql security definer set search_path = '' as $$
begin
  if (select auth.uid()) is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  insert into public.reports (reporter_id, target_type, target_id, reason, details)
  values ((select auth.uid()), p_target, p_target_id, p_reason, left(trim(coalesce(p_details, '')), 1000))
  on conflict do nothing;
end $$;

-- Verificação de contas -----------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('verification-docs', 'verification-docs', false, 10485760,
        array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do nothing;

create policy "Envio documento na minha pasta" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'verification-docs' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Vejo meus documentos; equipe vê todos" on storage.objects
  for select to authenticated
  using (bucket_id = 'verification-docs'
         and ((storage.foldername(name))[1] = (select auth.uid())::text or (select public.am_i_staff())));

create table public.verification_requests (
  id bigint generated always as identity primary key,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  legal_name text not null check (char_length(legal_name) between 3 and 120),
  document_number text not null check (char_length(document_number) between 11 and 18),
  document_path text not null,
  notes text not null default '' check (char_length(notes) <= 500),
  status public.verification_request_status not null default 'pending',
  reviewed_by uuid references public.profiles (id) on delete set null,
  reviewed_at timestamptz,
  review_note text,
  created_at timestamptz not null default now()
);
create index verification_requests_profile_idx on public.verification_requests (profile_id, created_at desc);
create index verification_requests_pending_idx on public.verification_requests (created_at) where status = 'pending';
create index verification_requests_reviewed_by_idx on public.verification_requests (reviewed_by);
alter table public.verification_requests enable row level security;
create policy "dono e equipe veem o pedido" on public.verification_requests
  for select to authenticated using (profile_id = (select auth.uid()) or (select public.am_i_staff()));

create function public.request_verification(p_legal_name text, p_document_number text, p_document_path text,
                                            p_notes text default '')
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_profile public.profiles;
begin
  select * into v_profile from public.profiles where id = me;
  if v_profile.account_type = 'personal' then
    raise exception 'A verificação é para comunidades, empresas e influenciadores.' using errcode = 'P0001';
  end if;
  if v_profile.verification_status in ('pending', 'verified') then
    raise exception 'Sua conta já está verificada ou em análise.' using errcode = 'P0001';
  end if;
  if split_part(p_document_path, '/', 1) <> me::text then
    raise exception 'Documento inválido.' using errcode = 'P0001';
  end if;
  insert into public.verification_requests (profile_id, legal_name, document_number, document_path, notes)
  values (me, trim(p_legal_name), regexp_replace(p_document_number, '[^0-9./-]', '', 'g'), p_document_path,
          left(trim(coalesce(p_notes, '')), 500));
  update public.profiles set verification_status = 'pending' where id = me;
  return public.my_profile();
exception when check_violation then
  raise exception 'Confira o nome (3 a 120 letras) e o CPF/CNPJ.' using errcode = 'P0001';
end $$;

create function public.my_verification() returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object('status', p.verification_status,
    'lastRequest', (select jsonb_build_object('status', r.status, 'reviewNote', r.review_note, 'createdAt', r.created_at)
                      from public.verification_requests r where r.profile_id = p.id
                     order by r.created_at desc limit 1))
    from public.profiles p where p.id = (select auth.uid());
$$;

-- Painel admin --------------------------------------------------------------------

create function public.admin_dashboard() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_staff();
  return jsonb_build_object(
    'openReports', (select count(*) from public.reports where status = 'open'),
    'pendingVerifications', (select count(*) from public.verification_requests where status = 'pending'),
    'adsInReview', (select count(*) from public.ad_campaigns where status = 'in_review'),
    'payoutsRequested', (select count(*) from public.payouts where status = 'requested'),
    'users', (select count(*) from public.profiles where not is_demo),
    'posts', (select count(*) from public.posts where deleted_at is null),
    'donations', (select coalesce(sum(amount), 0) from public.donations),
    'fund', public.donation_fund());
end $$;

create function public.admin_reports(p_status public.report_status default 'open') returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_staff();
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', r.id::text, 'targetType', r.target_type, 'targetId', r.target_id, 'reason', r.reason,
      'details', r.details, 'status', r.status, 'createdAt', r.created_at, 'resolutionNote', r.resolution_note,
      'reporterName', (select name from public.profiles where id = r.reporter_id),
      'reportsOnTarget', (select count(*) from public.reports x
                           where x.target_type = r.target_type and x.target_id = r.target_id),
      'preview', case r.target_type
        when 'post' then (select jsonb_build_object('title', p.title, 'text', left(p.description, 200),
                                                    'authorId', p.author_id, 'authorName', a.name)
                            from public.posts p join public.profiles a on a.id = p.author_id where p.id::text = r.target_id)
        when 'comment' then (select jsonb_build_object('title', 'Comentário', 'text', left(c.body, 200),
                                                       'authorId', c.author_id, 'authorName', a.name, 'postId', c.post_id::text)
                               from public.comments c join public.profiles a on a.id = c.author_id where c.id::text = r.target_id)
        when 'profile' then (select jsonb_build_object('title', p.name, 'text', p.bio, 'authorId', p.id, 'authorName', p.name)
                               from public.profiles p where p.id::text = r.target_id)
        when 'message' then (select jsonb_build_object('title', 'Mensagem', 'text', left(m.body, 200),
                                                       'authorId', m.author_id, 'authorName', a.name)
                               from public.messages m left join public.profiles a on a.id = m.author_id where m.id::text = r.target_id)
        when 'story' then (select jsonb_build_object('title', 'Story', 'text', s.body, 'authorId', s.author_id, 'authorName', a.name)
                             from public.stories s join public.profiles a on a.id = s.author_id where s.id::text = r.target_id)
        when 'product' then (select jsonb_build_object('title', pr.name, 'text', pr.description, 'authorId', pr.seller_id,
                                                       'authorName', a.name)
                               from public.products pr join public.profiles a on a.id = pr.seller_id where pr.id::text = r.target_id)
        when 'ad' then (select jsonb_build_object('title', c.title, 'text', c.body, 'authorId', c.owner_id, 'authorName', a.name)
                          from public.ad_campaigns c join public.profiles a on a.id = c.owner_id where c.id::text = r.target_id)
      end) order by r.created_at)
    from public.reports r where r.status = p_status), '[]'::jsonb);
end $$;

-- Ações: dismiss (arquiva), remove (esconde o conteúdo), suspend (suspende o
-- autor por p_days dias e esconde o conteúdo). Todas as denúncias do mesmo
-- alvo são resolvidas juntas.
create function public.resolve_report(p_report_id bigint, p_action text, p_note text default '', p_days integer default 7)
returns void
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := private.require_staff();
  r public.reports;
  v_author uuid;
begin
  select * into r from public.reports where id = p_report_id;
  if r.id is null then raise exception 'Denúncia não encontrada.' using errcode = 'P0002'; end if;
  if p_action not in ('dismiss', 'remove', 'suspend') then
    raise exception 'Ação inválida.' using errcode = 'P0001';
  end if;

  if p_action in ('remove', 'suspend') then
    case r.target_type
    when 'post' then
      update public.posts set status = 'hidden' where id::text = r.target_id returning author_id into v_author;
    when 'comment' then
      update public.comments set deleted_at = now() where id::text = r.target_id returning author_id into v_author;
    when 'message' then
      delete from public.messages where id::text = r.target_id returning author_id into v_author;
    when 'story' then
      delete from public.stories where id::text = r.target_id returning author_id into v_author;
    when 'product' then
      update public.products set active = false where id::text = r.target_id returning seller_id into v_author;
    when 'ad' then
      update public.ad_campaigns set status = 'rejected', review_note = p_note
       where id::text = r.target_id returning owner_id into v_author;
    when 'profile' then
      v_author := r.target_id::uuid;
    end case;
  end if;

  if p_action = 'suspend' and v_author is not null then
    update public.profiles set suspended_until = now() + make_interval(days => greatest(p_days, 1)) where id = v_author;
  end if;
  if p_action <> 'dismiss' and v_author is not null then
    perform private.notify(v_author, null, 'moderation',
      case p_action when 'suspend' then 'Sua conta foi suspensa por ' || greatest(p_days, 1) || ' dia(s)'
                    else 'Um conteúdo seu foi removido' end,
      coalesce(nullif(p_note, ''), 'Ele viola as regras da comunidade Save Easy.'));
  end if;

  update public.reports
     set status = case when p_action = 'dismiss' then 'dismissed' else 'actioned' end::public.report_status,
         resolved_by = me, resolved_at = now(), resolution_note = nullif(p_note, '')
   where target_type = r.target_type and target_id = r.target_id and status = 'open';
end $$;

create function public.admin_verifications() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_staff();
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', v.id::text, 'legalName', v.legal_name, 'documentNumber', v.document_number,
      'documentPath', v.document_path, 'notes', v.notes, 'createdAt', v.created_at,
      'profile', public.profile_json(p)) order by v.created_at)
    from public.verification_requests v join public.profiles p on p.id = v.profile_id
    where v.status = 'pending'), '[]'::jsonb);
end $$;

create function public.review_verification(p_request_id bigint, p_approve boolean, p_note text default '')
returns void
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := private.require_staff();
  v public.verification_requests;
begin
  update public.verification_requests
     set status = case when p_approve then 'approved' else 'rejected' end::public.verification_request_status,
         reviewed_by = me, reviewed_at = now(), review_note = nullif(p_note, '')
   where id = p_request_id and status = 'pending'
  returning * into v;
  if v.id is null then raise exception 'Pedido não encontrado.' using errcode = 'P0002'; end if;
  update public.profiles set verification_status = case when p_approve then 'verified' else 'rejected' end::public.verification_status
   where id = v.profile_id;
  perform private.notify(v.profile_id, null, 'moderation',
    case when p_approve then 'Sua conta foi verificada! ✔' else 'Verificação não aprovada' end,
    coalesce(nullif(p_note, ''), case when p_approve then 'Agora seus anúncios entram no ar na hora e você pode pedir repasses.'
                                      else 'Revise os dados e envie de novo.' end));
end $$;

create function public.admin_ads_in_review() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_staff();
  return coalesce((select jsonb_agg(public.ad_campaign_json(c) order by c.created_at)
                     from public.ad_campaigns c where c.status = 'in_review'), '[]'::jsonb);
end $$;

-- Aprovar ativa; recusar reembolsa e devolve a parte do fundo.
create function public.review_ad(p_campaign_id bigint, p_approve boolean, p_note text default '') returns void
language plpgsql security definer set search_path = '' as $$
declare
  v public.ad_campaigns;
begin
  perform private.require_staff();
  select * into v from public.ad_campaigns where id = p_campaign_id and status = 'in_review';
  if v.id is null then raise exception 'Campanha não está em análise.' using errcode = 'P0002'; end if;
  if p_approve then
    perform private.activate_campaign(v.id);
  else
    update public.ad_campaigns set status = 'rejected', review_note = nullif(p_note, '') where id = v.id;
    update public.payments set status = 'refunded' where id = v.payment_id and status = 'paid';
    insert into public.fund_ledger (amount, kind, ref_table, ref_id, note)
    select -amount, 'adjustment', 'ad_campaigns', v.id::text, 'Estorno de anúncio recusado'
      from public.fund_ledger where kind = 'ad_share' and ref_table = 'ad_campaigns' and ref_id = v.id::text;
  end if;
  perform private.notify(v.owner_id, null, 'moderation',
    case when p_approve then 'Seu anúncio "' || v.title || '" está no ar' else 'Anúncio "' || v.title || '" recusado' end,
    coalesce(nullif(p_note, ''), case when p_approve then '' else 'O valor foi reembolsado.' end));
end $$;

create function public.admin_payouts() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
begin
  perform private.require_staff();
  return coalesce((select jsonb_agg(jsonb_build_object('id', po.id::text, 'amount', po.amount, 'status', po.status,
                                                        'pixKey', po.pix_key, 'createdAt', po.created_at,
                                                        'profile', public.profile_json(p)) order by po.created_at)
                     from public.payouts po join public.profiles p on p.id = po.profile_id
                    where po.status = 'requested'), '[]'::jsonb);
end $$;

create function public.set_payout_status(p_payout_id bigint, p_paid boolean, p_note text default '') returns void
language plpgsql security definer set search_path = '' as $$
declare
  v public.payouts;
begin
  perform private.require_staff();
  update public.payouts
     set status = case when p_paid then 'paid' else 'rejected' end::public.payout_status,
         processed_at = now(), note = nullif(p_note, '')
   where id = p_payout_id and status = 'requested'
  returning * into v;
  if v.id is null then raise exception 'Repasse não encontrado.' using errcode = 'P0002'; end if;
  perform private.notify(v.profile_id, null, 'moderation',
    case when p_paid then 'Repasse de R$ ' || replace(to_char(v.amount, 'FM999999990.00'), '.', ',') || ' enviado'
         else 'Repasse não aprovado' end, coalesce(nullif(p_note, ''), ''));
end $$;

-- Transparência (pública, sem dados pessoais) ---------------------------------

create function public.transparency() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'fund', public.donation_fund(),
    'donationsTotal', (select coalesce(sum(amount), 0) from public.donations),
    'donationsCount', (select count(*) from public.donations),
    'campaigns', (select count(*) from public.posts where type = 'donation' and deleted_at is null),
    'actions', (select count(*) from public.posts where type in ('event', 'social_action', 'activity') and deleted_at is null),
    'volunteers', (select count(distinct profile_id) from public.participations where status in ('going', 'attended')),
    'adShare', (select coalesce(sum(amount), 0) from public.fund_ledger where kind = 'ad_share'),
    'movements', coalesce((select jsonb_agg(jsonb_build_object('amount', f.amount, 'kind', f.kind, 'note', f.note,
                                                               'createdAt', f.created_at) order by f.created_at desc)
                             from (select * from public.fund_ledger order by created_at desc limit 30) f), '[]'::jsonb));
$$;

-- Permissões das funções -----------------------------------------------------
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;
revoke execute on function public.fulfill_payment_from_gateway(uuid, text, text, numeric) from authenticated;
grant execute on function public.fulfill_payment_from_gateway(uuid, text, text, numeric) to service_role;
-- Página de transparência abre sem login.
grant execute on function public.transparency() to anon;
revoke execute on all functions in schema private from public, anon, authenticated;
