-- Entrega 5: anúncios de empresas, influenciadores e comunidades.
-- Formatos: barra inferior, post impulsionado no feed e story patrocinado
-- (quem assiste ganha moedas). Preço calculado no banco; pagamento pelo
-- mesmo fluxo da Entrega 4; 30% vai para o fundo de doações.

create type public.ad_format as enum ('bar', 'boosted_post', 'story');
create type public.ad_status as enum ('pending_payment', 'in_review', 'active', 'paused', 'rejected', 'ended');
create type public.ad_event_kind as enum ('impression', 'click');

insert into private.settings (key, value) values
  ('ad_daily_price', '{"bar": 9.90, "boosted_post": 14.90, "story": 7.90}'),
  ('ad_plan_days', '{"daily": 1, "weekly": 7, "monthly": 30}'),
  ('ad_plan_discount', '{"daily": 0, "weekly": 0.15, "monthly": 0.30}'),
  ('ad_extra_city_percent', '30'),
  ('ad_fund_share', '0.30');

create table public.ad_campaigns (
  id bigint generated always as identity primary key,
  owner_id uuid not null references public.profiles (id) on delete cascade,
  format public.ad_format not null,
  plan public.ad_plan not null,
  title text not null check (char_length(title) between 3 and 60),
  body text not null default '' check (char_length(body) <= 140),
  image_url text,
  cta_label text not null default 'Saiba mais' check (char_length(cta_label) <= 20),
  link_url text,
  post_id bigint references public.posts (id) on delete set null,
  state text not null default 'MT',
  cities text[] not null default '{}',
  status public.ad_status not null default 'pending_payment',
  price numeric(10, 2) not null check (price > 0),
  payment_id uuid references public.payments (id) on delete set null,
  story_id bigint references public.stories (id) on delete set null,
  review_note text,
  impressions integer not null default 0,
  clicks integer not null default 0,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  check (format <> 'boosted_post' or post_id is not null)
);
create index ad_campaigns_owner_idx on public.ad_campaigns (owner_id, created_at desc);
create index ad_campaigns_serving_idx on public.ad_campaigns (format, ends_at) where status = 'active';
create index ad_campaigns_post_idx on public.ad_campaigns (post_id) where post_id is not null;
create index ad_campaigns_payment_idx on public.ad_campaigns (payment_id) where payment_id is not null;
create index ad_campaigns_story_idx on public.ad_campaigns (story_id) where story_id is not null;

create table public.ad_events (
  id bigint generated always as identity primary key,
  campaign_id bigint not null references public.ad_campaigns (id) on delete cascade,
  viewer_id uuid references public.profiles (id) on delete set null,
  kind public.ad_event_kind not null,
  created_at timestamptz not null default now()
);
create index ad_events_campaign_idx on public.ad_events (campaign_id, kind, created_at desc);
create index ad_events_viewer_idx on public.ad_events (viewer_id, campaign_id, created_at desc);

alter table public.ad_campaigns enable row level security;
alter table public.ad_events enable row level security;
create policy "dono vê as próprias campanhas" on public.ad_campaigns
  for select to authenticated using (owner_id = (select auth.uid()));

-- Preço -------------------------------------------------------------------------

create function public.ad_quote(p_format public.ad_format, p_plan public.ad_plan, p_cities text[] default '{}')
returns jsonb
language sql stable security definer set search_path = '' as $$
  with cfg as (
    select (private.setting('ad_daily_price') ->> p_format::text)::numeric as daily,
           (private.setting('ad_plan_days') ->> p_plan::text)::integer as days,
           (private.setting('ad_plan_discount') ->> p_plan::text)::numeric as discount,
           (private.setting('ad_extra_city_percent'))::numeric / 100 as extra
  )
  select jsonb_build_object(
    'days', cfg.days,
    'dailyPrice', cfg.daily,
    'discount', cfg.discount,
    'price', round(cfg.daily * cfg.days * (1 - cfg.discount)
                   * (1 + cfg.extra * greatest(coalesce(array_length(p_cities, 1), 1) - 1, 0)), 2),
    'fundShare', (private.setting('ad_fund_share'))::numeric)
  from cfg;
$$;

-- JSON ---------------------------------------------------------------------------

create function public.ad_campaign_json(c public.ad_campaigns) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'id', c.id::text, 'format', c.format, 'plan', c.plan, 'title', c.title, 'body', c.body,
    'imageUrl', c.image_url, 'ctaLabel', c.cta_label, 'linkUrl', c.link_url, 'postId', c.post_id::text,
    'state', c.state, 'cities', to_jsonb(c.cities), 'status', c.status, 'price', c.price,
    'reviewNote', c.review_note, 'impressions', c.impressions, 'clicks', c.clicks,
    'startsAt', c.starts_at, 'endsAt', c.ends_at, 'createdAt', c.created_at,
    'ownerId', c.owner_id,
    'ownerName', (select name from public.profiles where id = c.owner_id),
    'ownerAvatarUrl', (select avatar_url from public.profiles where id = c.owner_id));
$$;

-- Criar e pagar --------------------------------------------------------------------

create function public.create_ad_campaign(p jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_me public.profiles;
  v_format public.ad_format := (p ->> 'format')::public.ad_format;
  v_plan public.ad_plan := coalesce(nullif(p ->> 'plan', ''), 'weekly')::public.ad_plan;
  v_cities text[] := coalesce((select array_agg(trim(x)) from jsonb_array_elements_text(coalesce(p -> 'cities', '[]')) x
                                where trim(x) <> ''), '{}');
  v_post bigint := nullif(p ->> 'postId', '')::bigint;
  v public.ad_campaigns;
begin
  select * into v_me from public.profiles where id = me;
  if v_me.id is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  if not private.can_create_post(v_me.account_type, 'ad') then
    raise exception 'Anúncios são para empresas, influenciadores e comunidades.' using errcode = '42501';
  end if;
  if v_post is not null and not exists (select 1 from public.posts where id = v_post and author_id = me and deleted_at is null) then
    raise exception 'Escolha uma publicação sua para impulsionar.' using errcode = 'P0001';
  end if;
  if array_length(v_cities, 1) is null then v_cities := array[coalesce(v_me.city, 'Cuiabá')]; end if;

  insert into public.ad_campaigns (owner_id, format, plan, title, body, image_url, cta_label, link_url, post_id,
                                   state, cities, price)
  values (me, v_format, v_plan, trim(p ->> 'title'), left(trim(coalesce(p ->> 'body', '')), 140),
          nullif(p ->> 'imageUrl', ''), coalesce(nullif(trim(p ->> 'ctaLabel'), ''), 'Saiba mais'),
          nullif(trim(p ->> 'linkUrl'), ''), v_post, coalesce(v_me.state, 'MT'), v_cities,
          (public.ad_quote(v_format, v_plan, v_cities) ->> 'price')::numeric)
  returning * into v;
  return public.ad_campaign_json(v);
exception when check_violation then
  raise exception 'Confira o título (3 a 60 letras) e, para impulsionar, a publicação.' using errcode = 'P0001';
end $$;

-- Cobrança da campanha (reaproveita a pendente se existir).
create function public.ad_campaign_payment(p_campaign_id bigint) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v public.ad_campaigns;
  v_payment public.payments;
begin
  select * into v from public.ad_campaigns where id = p_campaign_id and owner_id = me;
  if v.id is null or v.status <> 'pending_payment' then
    raise exception 'Campanha não está aguardando pagamento.' using errcode = 'P0001';
  end if;
  select * into v_payment from public.payments
   where id = v.payment_id and status = 'pending' and expires_at > now();
  if v_payment.id is null then
    insert into public.payments (payer_id, kind, amount, description, details, pix_code)
    values (me, 'ad_campaign', v.price, 'Anúncio: ' || v.title, jsonb_build_object('campaignId', v.id),
            '00020126SAVEEASY-SANDBOX-' || replace(gen_random_uuid()::text, '-', ''))
    returning * into v_payment;
    update public.ad_campaigns set payment_id = v_payment.id where id = v.id;
  end if;
  return public.payment_json(v_payment);
end $$;

-- Ativa a campanha (dono verificado) ou manda para análise.
create function private.activate_campaign(p_campaign_id bigint) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v public.ad_campaigns;
  v_days integer;
  v_story bigint;
begin
  select * into v from public.ad_campaigns where id = p_campaign_id;
  v_days := (private.setting('ad_plan_days') ->> v.plan::text)::integer;
  if v.format = 'story' then
    insert into public.stories (author_id, type, body, image_url, post_id, expires_at)
    values (v.owner_id, 'ad', left(v.title || case when v.body <> '' then ' · ' || v.body else '' end, 280),
            v.image_url, v.post_id, now() + make_interval(days => v_days))
    returning id into v_story;
  end if;
  update public.ad_campaigns
     set status = 'active', starts_at = now(), ends_at = now() + make_interval(days => v_days), story_id = v_story
   where id = p_campaign_id;
end $$;

create function private.on_ad_paid() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v public.ad_campaigns;
begin
  if new.kind <> 'ad_campaign' or new.status <> 'paid' or old.status = 'paid' then return null; end if;
  select * into v from public.ad_campaigns where id = (new.details ->> 'campaignId')::bigint;
  if v.id is null or v.status <> 'pending_payment' then return null; end if;
  insert into public.fund_ledger (amount, kind, ref_table, ref_id, note)
  values (round(new.amount * (private.setting('ad_fund_share'))::numeric, 2), 'ad_share', 'ad_campaigns', v.id::text,
          'Anúncio: ' || v.title);
  if (select verification_status from public.profiles where id = v.owner_id) = 'verified' then
    perform private.activate_campaign(v.id);
  else
    update public.ad_campaigns set status = 'in_review' where id = v.id;
  end if;
  return null;
end $$;
create trigger payments_ad_paid after update of status on public.payments
  for each row execute function private.on_ad_paid();

-- Webhook do gateway (Edge Function com service_role). Confere valor.
create function public.fulfill_payment_from_gateway(p_payment_id uuid, p_provider text, p_provider_ref text,
                                                    p_amount numeric)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not exists (select 1 from public.payments where id = p_payment_id and amount = p_amount) then
    raise exception 'Pagamento não confere.' using errcode = 'P0001';
  end if;
  update public.payments set provider = p_provider, provider_ref = p_provider_ref
   where id = p_payment_id and status = 'pending';
  perform private.fulfill_payment(p_payment_id);
end $$;

-- Dono: lista, pausa e retoma ------------------------------------------------------

create function public.my_ad_campaigns() returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.ad_campaign_json(c) order by c.created_at desc), '[]'::jsonb)
    from public.ad_campaigns c where c.owner_id = (select auth.uid());
$$;

create function public.set_ad_campaign_paused(p_campaign_id bigint, p_paused boolean) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v public.ad_campaigns;
begin
  update public.ad_campaigns
     set status = case when p_paused then 'paused' else 'active' end::public.ad_status
   where id = p_campaign_id and owner_id = (select auth.uid())
     and status = case when p_paused then 'active' else 'paused' end::public.ad_status
     and coalesce(ends_at, now()) >= now()
  returning * into v;
  if v.id is null then raise exception 'Não dá para mudar essa campanha agora.' using errcode = 'P0001'; end if;
  return public.ad_campaign_json(v);
end $$;

create function public.delete_ad_campaign(p_campaign_id bigint) returns void
language sql security definer set search_path = '' as $$
  delete from public.ad_campaigns
   where id = p_campaign_id and owner_id = (select auth.uid()) and status = 'pending_payment';
$$;

-- Veiculação ----------------------------------------------------------------------

-- Anúncios ativos para a região de quem vê (aleatório, sem os próprios).
create function public.next_ads(p_format public.ad_format, p_limit integer default 1) returns jsonb
language sql volatile security definer set search_path = '' as $$
  with me as (
    select id, coalesce(state, 'MT') as state, coalesce(city, 'Cuiabá') as city
      from public.profiles where id = (select auth.uid())
  )
  select coalesce(jsonb_agg(
           public.ad_campaign_json(c)
           || case when c.format = 'boosted_post' then
                jsonb_build_object('post', (select public.post_json(p, a) from public.posts p
                                              join public.profiles a on a.id = p.author_id
                                             where p.id = c.post_id and p.deleted_at is null))
              else '{}'::jsonb end), '[]'::jsonb)
    from (
      select c.* from public.ad_campaigns c, me
       where c.format = p_format and c.status = 'active' and c.ends_at > now() and c.owner_id <> me.id
         and c.state = me.state
         and (cardinality(c.cities) = 0 or exists (select 1 from unnest(c.cities) x where lower(x) = lower(me.city)))
       order by random()
       limit least(greatest(p_limit, 1), 5)
    ) c;
$$;

-- Impressão conta 1× por pessoa e campanha a cada hora; clique sempre.
create function public.track_ad(p_campaign_id bigint, p_kind public.ad_event_kind) returns void
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
begin
  if p_kind = 'impression' and exists (
       select 1 from public.ad_events where campaign_id = p_campaign_id and viewer_id = me and kind = 'impression'
          and created_at > now() - interval '1 hour') then
    return;
  end if;
  insert into public.ad_events (campaign_id, viewer_id, kind) values (p_campaign_id, me, p_kind);
  update public.ad_campaigns
     set impressions = impressions + (p_kind = 'impression')::integer,
         clicks = clicks + (p_kind = 'click')::integer
   where id = p_campaign_id;
end $$;

-- Encerra campanhas vencidas (cron).
create function private.end_ad_campaigns() returns void
language sql security definer set search_path = '' as $$
  update public.ad_campaigns set status = 'ended' where status in ('active', 'paused') and ends_at < now();
$$;
select cron.schedule('end-ad-campaigns', '*/30 * * * *', 'select private.end_ad_campaigns()');

-- Permissões das funções -----------------------------------------------------
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;
-- Só o webhook (service_role) entrega pagamento confirmado pelo gateway.
revoke execute on function public.fulfill_payment_from_gateway(uuid, text, text, numeric) from authenticated;
grant execute on function public.fulfill_payment_from_gateway(uuid, text, text, numeric) to service_role;
revoke execute on all functions in schema private from public, anon, authenticated;
