-- Entrega 4: pagamentos (modo sandbox, pronto para gateway real), doação em
-- R$ e com moedas, fundo de doações, pacotes de moedas, inscrições em
-- comunidades, loja (produtos, pedidos, avaliações) e painel financeiro.
--
-- Fluxo de pagamento: o app cria o pagamento (create_payment) e o banco
-- calcula o valor. Em sandbox o próprio app confirma (confirm_sandbox_payment).
-- Em produção só o webhook do gateway (Edge Function com service_role) chama
-- private.fulfill_payment. Tudo é idempotente.

create type public.payment_status as enum ('pending', 'paid', 'failed', 'refunded', 'expired');
create type public.payment_kind as enum ('donation', 'coin_package', 'subscription', 'order', 'ad_campaign');
create type public.payment_method as enum ('pix', 'card');
create type public.order_status as enum ('pending_payment', 'paid', 'shipped', 'delivered', 'cancelled');
create type public.subscription_status as enum ('active', 'cancelled', 'expired');
create type public.payout_status as enum ('requested', 'paid', 'rejected');
alter type public.notification_kind add value if not exists 'donation';
alter type public.notification_kind add value if not exists 'order';
alter type public.notification_kind add value if not exists 'subscription';

-- Configuração da plataforma (só funções leem).
create table private.settings (
  key text primary key,
  value jsonb not null
);
insert into private.settings (key, value) values
  ('payments_mode', '"sandbox"'),
  ('coins_per_real', '100'),
  ('platform_fee_percent', '0'),
  ('min_reward_donation', '5');

create function private.setting(p_key text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select value from private.settings where key = p_key;
$$;

-- Pacotes de moedas ------------------------------------------------------------

create table public.coin_packages (
  id text primary key,
  coins integer not null check (coins > 0),
  price numeric(10, 2) not null check (price > 0),
  active boolean not null default true,
  sort integer not null default 0
);
alter table public.coin_packages enable row level security;
create policy "pacotes visíveis" on public.coin_packages for select to authenticated using (active);
insert into public.coin_packages (id, coins, price, sort) values
  ('coins_1000', 1000, 4.99, 1), ('coins_2500', 2500, 11.99, 2), ('coins_5000', 5000, 24.90, 3);

-- Pagamentos -------------------------------------------------------------------

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  payer_id uuid not null references public.profiles (id) on delete cascade,
  kind public.payment_kind not null,
  amount numeric(12, 2) not null check (amount > 0),
  method public.payment_method not null default 'pix',
  status public.payment_status not null default 'pending',
  provider text not null default 'sandbox',
  provider_ref text,
  pix_code text,
  description text not null default '',
  -- O que será entregue quando pagar (post, pacote, plano, pedido...).
  details jsonb not null default '{}',
  created_at timestamptz not null default now(),
  paid_at timestamptz,
  expires_at timestamptz not null default now() + interval '30 minutes'
);
create index payments_payer_idx on public.payments (payer_id, created_at desc);
create unique index payments_provider_ref_idx on public.payments (provider, provider_ref) where provider_ref is not null;
alter table public.payments enable row level security;
create policy "cada um vê os próprios pagamentos" on public.payments
  for select to authenticated using (payer_id = (select auth.uid()));
alter publication supabase_realtime add table public.payments;

-- Doações ----------------------------------------------------------------------

create table public.donations (
  id bigint generated always as identity primary key,
  post_id bigint not null references public.posts (id) on delete cascade,
  donor_id uuid references public.profiles (id) on delete set null,
  amount numeric(12, 2) not null check (amount > 0),
  coins integer not null default 0,
  via_coins boolean not null default false,
  payment_id uuid references public.payments (id) on delete set null,
  created_at timestamptz not null default now()
);
create index donations_post_idx on public.donations (post_id, created_at desc);
create index donations_donor_idx on public.donations (donor_id, created_at desc);
create index donations_payment_idx on public.donations (payment_id) where payment_id is not null;
alter table public.donations enable row level security;
create policy "doador e autor veem a doação" on public.donations
  for select to authenticated using (
    donor_id = (select auth.uid())
    or exists (select 1 from public.posts p where p.id = post_id and p.author_id = (select auth.uid())));

-- Fundo de doações: alimentado pela plataforma e por 30% dos anúncios; paga
-- as doações feitas com moedas (coins_per_real moedas = R$ 1).
create table public.fund_ledger (
  id bigint generated always as identity primary key,
  amount numeric(12, 2) not null,
  kind text not null check (kind in ('platform_contribution', 'ad_share', 'coin_donation', 'adjustment')),
  ref_table text,
  ref_id text,
  note text,
  created_at timestamptz not null default now()
);
alter table public.fund_ledger enable row level security;
insert into public.fund_ledger (amount, kind, note) values (500, 'platform_contribution', 'Aporte inicial do lançamento em Cuiabá');

-- Inscrições em comunidades ------------------------------------------------------

create table public.subscription_plans (
  id bigint generated always as identity primary key,
  community_id uuid not null references public.profiles (id) on delete cascade,
  name text not null check (char_length(name) between 2 and 40),
  price numeric(10, 2) not null check (price > 0),
  months integer not null default 1 check (months in (1, 3, 6, 12)),
  benefits text not null default '',
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create index subscription_plans_community_idx on public.subscription_plans (community_id) where active;

create table public.community_subscriptions (
  subscriber_id uuid not null references public.profiles (id) on delete cascade,
  community_id uuid not null references public.profiles (id) on delete cascade,
  plan_id bigint references public.subscription_plans (id) on delete set null,
  status public.subscription_status not null default 'active',
  started_at timestamptz not null default now(),
  current_period_end timestamptz not null,
  reward_granted_at timestamptz,
  primary key (subscriber_id, community_id)
);
create index community_subscriptions_community_idx on public.community_subscriptions (community_id, status);
create index community_subscriptions_plan_idx on public.community_subscriptions (plan_id);

alter table public.subscription_plans enable row level security;
alter table public.community_subscriptions enable row level security;
create policy "planos visíveis" on public.subscription_plans for select to authenticated using (active);
create policy "assinante e comunidade veem" on public.community_subscriptions
  for select to authenticated using ((select auth.uid()) in (subscriber_id, community_id));

-- Comunidade ganha planos padrão ao existir.
create function private.default_plans(p_community uuid) returns void
language sql security definer set search_path = '' as $$
  insert into public.subscription_plans (community_id, name, price, months, benefits)
  select p_community, x.name, x.price, x.months, x.benefits
    from (values ('Mensal', 9.90, 1, 'Apoie todo mês e receba novidades exclusivas.'),
                 ('Anual', 99.00, 12, '2 meses grátis em relação ao mensal.')) as x(name, price, months, benefits)
   where not exists (select 1 from public.subscription_plans where community_id = p_community);
$$;

create function private.on_community_plans() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.account_type = 'community' then perform private.default_plans(new.id); end if;
  return null;
end $$;
create trigger profiles_community_plans after insert or update of account_type on public.profiles
  for each row execute function private.on_community_plans();
select private.default_plans(id) from public.profiles where account_type = 'community';

-- Loja --------------------------------------------------------------------------

create table public.products (
  id bigint generated always as identity primary key,
  seller_id uuid not null references public.profiles (id) on delete cascade,
  name text not null check (char_length(name) between 2 and 80),
  description text not null default '' check (char_length(description) <= 1000),
  price numeric(10, 2) not null check (price > 0),
  image_url text,
  icon text not null default 'shopping_bag',
  stock integer check (stock is null or stock >= 0),
  active boolean not null default true,
  rating_avg numeric(2, 1) not null default 0,
  rating_count integer not null default 0,
  sales_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index products_seller_idx on public.products (seller_id) where active;
create trigger products_updated_at before update on public.products
  for each row execute function private.set_updated_at();

create table public.orders (
  id bigint generated always as identity primary key,
  buyer_id uuid references public.profiles (id) on delete set null,
  seller_id uuid not null references public.profiles (id) on delete cascade,
  product_id bigint references public.products (id) on delete set null,
  product_name text not null,
  quantity integer not null default 1 check (quantity between 1 and 20),
  unit_price numeric(10, 2) not null,
  total numeric(12, 2) not null,
  status public.order_status not null default 'pending_payment',
  shipping_address text not null default '',
  payment_id uuid references public.payments (id) on delete set null,
  reward_granted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index orders_buyer_idx on public.orders (buyer_id, created_at desc);
create index orders_seller_idx on public.orders (seller_id, created_at desc);
create index orders_product_idx on public.orders (product_id);
create index orders_payment_idx on public.orders (payment_id) where payment_id is not null;
create trigger orders_updated_at before update on public.orders
  for each row execute function private.set_updated_at();

create table public.product_reviews (
  product_id bigint not null references public.products (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  comment text not null default '' check (char_length(comment) <= 500),
  created_at timestamptz not null default now(),
  primary key (product_id, author_id)
);
create index product_reviews_author_idx on public.product_reviews (author_id);

alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.product_reviews enable row level security;
create policy "produtos ativos visíveis" on public.products for select to authenticated
  using (active or seller_id = (select auth.uid()));
create policy "comprador e vendedor veem o pedido" on public.orders for select to authenticated
  using ((select auth.uid()) in (buyer_id, seller_id));
create policy "avaliações visíveis" on public.product_reviews for select to authenticated using (true);

create function private.on_review_change() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_product bigint := coalesce(new.product_id, old.product_id);
begin
  update public.products p
     set rating_avg = coalesce((select round(avg(rating), 1) from public.product_reviews where product_id = v_product), 0),
         rating_count = (select count(*) from public.product_reviews where product_id = v_product)
   where p.id = v_product;
  return null;
end $$;
create trigger product_reviews_stats after insert or update or delete on public.product_reviews
  for each row execute function private.on_review_change();

-- Repasses (saques) -----------------------------------------------------------

create table public.payouts (
  id bigint generated always as identity primary key,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  amount numeric(12, 2) not null check (amount > 0),
  status public.payout_status not null default 'requested',
  pix_key text not null default '',
  note text,
  created_at timestamptz not null default now(),
  processed_at timestamptz
);
create index payouts_profile_idx on public.payouts (profile_id, created_at desc);
alter table public.payouts enable row level security;
create policy "cada um vê os próprios repasses" on public.payouts
  for select to authenticated using (profile_id = (select auth.uid()));

-- JSON -------------------------------------------------------------------------

create function public.payment_json(p public.payments) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'id', p.id, 'kind', p.kind, 'amount', p.amount, 'method', p.method, 'status', p.status,
    'provider', p.provider, 'pixCode', p.pix_code, 'description', p.description,
    'createdAt', p.created_at, 'paidAt', p.paid_at, 'expiresAt', p.expires_at,
    'sandbox', private.setting('payments_mode') = '"sandbox"'::jsonb);
$$;

create function public.product_json(pr public.products, s public.profiles) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'id', pr.id::text, 'name', pr.name, 'description', pr.description, 'price', pr.price,
    'communityId', s.id, 'communityName', s.name, 'sellerAvatarUrl', s.avatar_url,
    'section', case
      when pr.rating_count > 0 and pr.rating_avg >= 4.5 then 'top_rated'
      when exists (select 1 from public.profiles me where me.id = (select auth.uid())
                    and me.state = s.state and lower(me.city) = lower(s.city)) then 'nearby'
      else 'popular' end,
    'icon', pr.icon, 'rating', pr.rating_avg, 'ratingCount', pr.rating_count,
    'imageUrl', pr.image_url, 'stock', pr.stock, 'active', pr.active, 'salesCount', pr.sales_count);
$$;

create function public.order_json(o public.orders) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'id', o.id::text, 'productId', o.product_id::text, 'productName', o.product_name,
    'quantity', o.quantity, 'unitPrice', o.unit_price, 'total', o.total, 'status', o.status,
    'shippingAddress', o.shipping_address, 'createdAt', o.created_at, 'updatedAt', o.updated_at,
    'buyer', (select public.profile_json(b) from public.profiles b where b.id = o.buyer_id),
    'seller', (select public.profile_json(s) from public.profiles s where s.id = o.seller_id),
    'reviewed', exists (select 1 from public.product_reviews r
                         where r.product_id = o.product_id and r.author_id = o.buyer_id));
$$;

-- Pagamentos: criar, confirmar (sandbox) e entregar --------------------------

-- Valor e descrição saem do banco, nunca do app.
create function public.create_payment(p_kind public.payment_kind, p jsonb, p_method public.payment_method default 'pix')
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_amount numeric(12, 2);
  v_desc text;
  v_details jsonb := coalesce(p, '{}');
  v_post public.posts;
  v_pkg public.coin_packages;
  v_plan public.subscription_plans;
  v_product public.products;
  v_qty integer;
  v_order bigint;
  v_payment public.payments;
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;

  case p_kind
  when 'donation' then
    select * into v_post from public.posts
     where id = (p ->> 'postId')::bigint and deleted_at is null and status = 'published';
    if v_post.id is null or v_post.type <> 'donation' then
      raise exception 'Essa publicação não recebe doações.' using errcode = 'P0001';
    end if;
    v_amount := round((p ->> 'amount')::numeric, 2);
    if v_amount is null or v_amount < 1 or v_amount > 50000 then
      raise exception 'Escolha um valor entre R$ 1 e R$ 50.000.' using errcode = 'P0001';
    end if;
    v_desc := 'Doação: ' || v_post.title;
  when 'coin_package' then
    select * into v_pkg from public.coin_packages where id = p ->> 'packageId' and active;
    if v_pkg.id is null then raise exception 'Pacote não encontrado.' using errcode = 'P0002'; end if;
    v_amount := v_pkg.price;
    v_desc := v_pkg.coins || ' moedas';
  when 'subscription' then
    select * into v_plan from public.subscription_plans where id = (p ->> 'planId')::bigint and active;
    if v_plan.id is null then raise exception 'Plano não encontrado.' using errcode = 'P0002'; end if;
    if v_plan.community_id = me then raise exception 'Você não pode assinar a própria comunidade.' using errcode = 'P0001'; end if;
    v_amount := v_plan.price;
    v_desc := 'Inscrição ' || v_plan.name || ' - ' || (select name from public.profiles where id = v_plan.community_id);
    v_details := v_details || jsonb_build_object('communityId', v_plan.community_id);
  when 'order' then
    select * into v_product from public.products where id = (p ->> 'productId')::bigint and active;
    if v_product.id is null then raise exception 'Produto indisponível.' using errcode = 'P0002'; end if;
    if v_product.seller_id = me then raise exception 'Você não pode comprar o próprio produto.' using errcode = 'P0001'; end if;
    v_qty := greatest(coalesce((p ->> 'quantity')::integer, 1), 1);
    if v_product.stock is not null and v_product.stock < v_qty then
      raise exception 'Estoque insuficiente.' using errcode = 'P0001';
    end if;
    v_amount := v_product.price * v_qty;
    v_desc := v_product.name || case when v_qty > 1 then ' (' || v_qty || 'x)' else '' end;
    insert into public.orders (buyer_id, seller_id, product_id, product_name, quantity, unit_price, total, shipping_address)
    values (me, v_product.seller_id, v_product.id, v_product.name, v_qty, v_product.price, v_amount,
            left(coalesce(p ->> 'shippingAddress', ''), 300))
    returning id into v_order;
    v_details := v_details || jsonb_build_object('orderId', v_order);
  else
    raise exception 'Tipo de pagamento não suportado aqui.' using errcode = 'P0001';
  end case;

  insert into public.payments (payer_id, kind, amount, method, description, details, pix_code)
  values (me, p_kind, v_amount, p_method, v_desc, v_details,
          case when p_method = 'pix' then '00020126SAVEEASY-SANDBOX-' || replace(gen_random_uuid()::text, '-', '') end)
  returning * into v_payment;
  if v_order is not null then
    update public.orders set payment_id = v_payment.id where id = v_order;
  end if;
  return public.payment_json(v_payment);
end $$;

-- Entrega o que foi pago. Idempotente (só age em pagamento pendente).
create function private.fulfill_payment(p_payment_id uuid) returns void
language plpgsql security definer set search_path = '' as $$
declare
  v public.payments;
  v_post public.posts;
  v_plan public.subscription_plans;
  v_order public.orders;
  v_min numeric := (private.setting('min_reward_donation'))::numeric;
begin
  update public.payments set status = 'paid', paid_at = now()
   where id = p_payment_id and status = 'pending'
  returning * into v;
  if v.id is null then return; end if;

  case v.kind
  when 'donation' then
    select * into v_post from public.posts where id = (v.details ->> 'postId')::bigint;
    insert into public.donations (post_id, donor_id, amount, payment_id) values (v_post.id, v.payer_id, v.amount, v.id);
    update public.posts set raised_amount = raised_amount + v.amount where id = v_post.id;
    -- Recompensa: doação mínima e uma vez por dia por campanha.
    if v.amount >= v_min and not exists (
         select 1 from public.coin_ledger where profile_id = v.payer_id and reason = 'donation_reward'
            and ref_table = 'posts' and ref_id = v_post.id::text and created_at > now() - interval '24 hours') then
      perform private.grant_reward(v.payer_id, v_post.reward_coins, v_post.reward_xp, 'donation_reward',
                                   'posts', v_post.id::text, null, v_post.title);
    end if;
    perform private.notify(v_post.author_id, v.payer_id, 'donation',
      private.actor_name(v.payer_id) || ' doou R$ ' || replace(to_char(v.amount, 'FM999999990.00'), '.', ',') || ' para "' || v_post.title || '"',
      '', v_post.id);
  when 'coin_package' then
    perform private.grant_reward(v.payer_id, (select coins from public.coin_packages where id = v.details ->> 'packageId'),
                                 0, 'coin_purchase', 'payments', v.id::text, null, v.description);
  when 'subscription' then
    select * into v_plan from public.subscription_plans where id = (v.details ->> 'planId')::bigint;
    insert into public.community_subscriptions (subscriber_id, community_id, plan_id, status, current_period_end)
    values (v.payer_id, v_plan.community_id, v_plan.id, 'active', now() + make_interval(months => v_plan.months))
    on conflict (subscriber_id, community_id) do update
       set plan_id = excluded.plan_id, status = 'active',
           current_period_end = greatest(public.community_subscriptions.current_period_end, now())
                                + make_interval(months => v_plan.months);
    if (select reward_granted_at from public.community_subscriptions
         where subscriber_id = v.payer_id and community_id = v_plan.community_id) is null then
      perform private.grant_reward(v.payer_id, 50, 80, 'subscription_reward', 'profiles', v_plan.community_id::text);
      update public.community_subscriptions set reward_granted_at = now()
       where subscriber_id = v.payer_id and community_id = v_plan.community_id;
    end if;
    perform private.notify(v_plan.community_id, v.payer_id, 'subscription',
      private.actor_name(v.payer_id) || ' se inscreveu (' || v_plan.name || ')', '');
  when 'order' then
    update public.orders set status = 'paid' where id = (v.details ->> 'orderId')::bigint returning * into v_order;
    update public.products
       set stock = case when stock is null then null else greatest(stock - v_order.quantity, 0) end,
           sales_count = sales_count + v_order.quantity
     where id = v_order.product_id;
    if v_order.reward_granted_at is null then
      perform private.grant_reward(v.payer_id, 20, 30, 'store_purchase_reward', 'orders', v_order.id::text);
      update public.orders set reward_granted_at = now() where id = v_order.id;
    end if;
    perform private.notify(v_order.seller_id, v.payer_id, 'order',
      'Novo pedido: ' || v_order.product_name, 'R$ ' || replace(to_char(v_order.total, 'FM999999990.00'), '.', ','));
  when 'ad_campaign' then
    -- Implementado na migration de anúncios (private.on_ad_paid).
    null;
  end case;
end $$;

-- Sandbox: o próprio pagador simula a confirmação do Pix. Desligado quando
-- payments_mode = 'live'.
create function public.confirm_sandbox_payment(p_payment_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v public.payments;
begin
  if private.setting('payments_mode') <> '"sandbox"'::jsonb then
    raise exception 'Confirmação manual desativada.' using errcode = '42501';
  end if;
  select * into v from public.payments where id = p_payment_id and payer_id = me;
  if v.id is null then raise exception 'Pagamento não encontrado.' using errcode = 'P0002'; end if;
  if v.status = 'pending' and v.expires_at < now() then
    update public.payments set status = 'expired' where id = v.id;
    raise exception 'O código Pix expirou. Gere outro.' using errcode = 'P0001';
  end if;
  perform private.fulfill_payment(v.id);
  return jsonb_build_object('payment', (select public.payment_json(x) from public.payments x where x.id = v.id),
                            'me', public.my_profile());
end $$;

create function public.payment_status(p_payment_id uuid) returns jsonb
language sql stable set search_path = '' as $$
  select public.payment_json(p) from public.payments p
   where p.id = p_payment_id and p.payer_id = (select auth.uid());
$$;

create function public.my_payments(p_limit integer default 50) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.payment_json(p) order by p.created_at desc), '[]'::jsonb)
    from (select * from public.payments where payer_id = (select auth.uid()) and status in ('paid', 'refunded')
           order by created_at desc limit least(greatest(p_limit, 1), 200)) p;
$$;

create function public.coin_packages_list() returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'coins', coins, 'price', price) order by sort), '[]'::jsonb)
    from public.coin_packages where active;
$$;

-- Doar com moedas: o fundo paga a campanha em R$ (coins_per_real moedas = R$1).
create function public.donate_coins(p_post_id bigint, p_coins integer) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_post public.posts;
  v_rate integer := (private.setting('coins_per_real'))::integer;
  v_value numeric(12, 2);
  v_fund numeric;
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  select * into v_post from public.posts where id = p_post_id and deleted_at is null and status = 'published';
  if v_post.id is null or v_post.type <> 'donation' then
    raise exception 'Essa publicação não recebe doações.' using errcode = 'P0001';
  end if;
  if p_coins is null or p_coins < v_rate then
    raise exception 'Doe pelo menos % moedas.', v_rate using errcode = 'P0001';
  end if;
  if (select coins from public.profiles where id = me) < p_coins then
    raise exception 'Você não tem moedas suficientes.' using errcode = 'P0001';
  end if;
  v_value := round(p_coins::numeric / v_rate, 2);
  select coalesce(sum(amount), 0) into v_fund from public.fund_ledger;
  if v_fund < v_value then
    raise exception 'O fundo de doações está sem saldo agora. Tente um valor menor.' using errcode = 'P0001';
  end if;

  perform private.grant_reward(me, -p_coins, p_coins / 20, 'coins_donated', 'posts', p_post_id::text, null, v_post.title);
  insert into public.fund_ledger (amount, kind, ref_table, ref_id, note)
  values (-v_value, 'coin_donation', 'posts', p_post_id::text, p_coins || ' moedas');
  insert into public.donations (post_id, donor_id, amount, coins, via_coins) values (p_post_id, me, v_value, p_coins, true);
  update public.posts set raised_amount = raised_amount + v_value where id = p_post_id;
  perform private.notify(v_post.author_id, me, 'donation',
    private.actor_name(me) || ' doou ' || p_coins || ' moedas (R$ ' || replace(to_char(v_value, 'FM999999990.00'), '.', ',') || ') para "'
    || v_post.title || '"', '', p_post_id);
  return jsonb_build_object('post', public.post_json_by_id(p_post_id), 'me', public.my_profile());
end $$;

-- Resumo público do fundo (também usado na página de transparência).
create function public.donation_fund() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'balance', coalesce(sum(amount), 0),
    'received', coalesce(sum(amount) filter (where amount > 0), 0),
    'paidOut', coalesce(-sum(amount) filter (where amount < 0), 0),
    'coinsPerReal', (private.setting('coins_per_real'))::integer)
  from public.fund_ledger;
$$;

-- Inscrições -------------------------------------------------------------------

create function public.community_plans(p_community_id uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'plans', coalesce((select jsonb_agg(jsonb_build_object('id', id::text, 'name', name, 'price', price,
                                                            'months', months, 'benefits', benefits) order by months)
                         from public.subscription_plans where community_id = p_community_id and active), '[]'::jsonb),
    'subscribers', (select count(*) from public.community_subscriptions
                     where community_id = p_community_id and status = 'active' and current_period_end > now()),
    'mine', (select jsonb_build_object('status', s.status, 'planId', s.plan_id::text,
                                       'currentPeriodEnd', s.current_period_end)
               from public.community_subscriptions s
              where s.community_id = p_community_id and s.subscriber_id = (select auth.uid())));
$$;

create function public.cancel_subscription(p_community_id uuid) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  -- Continua ativa até o fim do período pago; só não renova.
  update public.community_subscriptions set status = 'cancelled'
   where community_id = p_community_id and subscriber_id = (select auth.uid()) and status = 'active';
  return public.community_plans(p_community_id);
end $$;

-- Comunidade edita os próprios planos.
create function public.save_subscription_plan(p jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
begin
  if (select account_type from public.profiles where id = me) <> 'community' then
    raise exception 'Só comunidades têm planos de inscrição.' using errcode = '42501';
  end if;
  if p ? 'id' and nullif(p ->> 'id', '') is not null then
    update public.subscription_plans
       set name = trim(p ->> 'name'), price = (p ->> 'price')::numeric, months = coalesce((p ->> 'months')::integer, months),
           benefits = coalesce(p ->> 'benefits', ''), active = coalesce((p ->> 'active')::boolean, true)
     where id = (p ->> 'id')::bigint and community_id = me;
  else
    insert into public.subscription_plans (community_id, name, price, months, benefits)
    values (me, trim(p ->> 'name'), (p ->> 'price')::numeric, coalesce((p ->> 'months')::integer, 1),
            coalesce(p ->> 'benefits', ''));
  end if;
  return public.community_plans(me);
end $$;

-- Loja -------------------------------------------------------------------------

create function public.store_products(p_query text default '', p_seller_id uuid default null) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.product_json(pr, s) order by pr.sales_count desc, pr.created_at desc), '[]'::jsonb)
    from public.products pr join public.profiles s on s.id = pr.seller_id
   where (pr.active or (p_seller_id is not null and pr.seller_id = (select auth.uid())))
     and (p_seller_id is null or pr.seller_id = p_seller_id)
     and (coalesce(p_query, '') = '' or pr.name ilike '%' || p_query || '%' or s.name ilike '%' || p_query || '%');
$$;

create function public.product_detail(p_product_id bigint) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'product', public.product_json(pr, s),
    'reviews', coalesce((select jsonb_agg(jsonb_build_object('rating', r.rating, 'comment', r.comment,
                                                              'createdAt', r.created_at, 'authorName', a.name,
                                                              'authorAvatarUrl', a.avatar_url)
                                          order by r.created_at desc)
                           from public.product_reviews r join public.profiles a on a.id = r.author_id
                          where r.product_id = pr.id), '[]'::jsonb))
    from public.products pr join public.profiles s on s.id = pr.seller_id
   where pr.id = p_product_id;
$$;

create function public.save_product(p jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v public.products;
begin
  if (select account_type from public.profiles where id = me) not in ('community', 'business') then
    raise exception 'Só comunidades e empresas vendem na loja.' using errcode = '42501';
  end if;
  if nullif(p ->> 'id', '') is not null then
    update public.products
       set name = trim(p ->> 'name'), description = coalesce(p ->> 'description', ''),
           price = (p ->> 'price')::numeric, image_url = nullif(p ->> 'imageUrl', ''),
           icon = coalesce(nullif(p ->> 'icon', ''), icon),
           stock = (p ->> 'stock')::integer, active = coalesce((p ->> 'active')::boolean, true)
     where id = (p ->> 'id')::bigint and seller_id = me
    returning * into v;
    if v.id is null then raise exception 'Produto não encontrado.' using errcode = 'P0002'; end if;
  else
    insert into public.products (seller_id, name, description, price, image_url, icon, stock)
    values (me, trim(p ->> 'name'), coalesce(p ->> 'description', ''), (p ->> 'price')::numeric,
            nullif(p ->> 'imageUrl', ''), coalesce(nullif(p ->> 'icon', ''), 'shopping_bag'), (p ->> 'stock')::integer)
    returning * into v;
  end if;
  return public.product_json(v, (select s from public.profiles s where s.id = me));
exception when check_violation then
  raise exception 'Confira nome (2 a 80 letras) e preço maior que zero.' using errcode = 'P0001';
end $$;

-- Desativa (pedidos antigos continuam apontando para ele).
create function public.delete_product(p_product_id bigint) returns void
language sql security definer set search_path = '' as $$
  update public.products set active = false where id = p_product_id and seller_id = (select auth.uid());
$$;

create function public.my_orders() returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.order_json(o) order by o.created_at desc), '[]'::jsonb)
    from public.orders o where o.buyer_id = (select auth.uid()) and o.status <> 'pending_payment';
$$;

create function public.seller_orders() returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.order_json(o) order by o.created_at desc), '[]'::jsonb)
    from public.orders o where o.seller_id = (select auth.uid()) and o.status <> 'pending_payment';
$$;

-- Vendedor: shipped / delivered / cancelled (cancelar pago = reembolso).
create function public.update_order_status(p_order_id bigint, p_status public.order_status) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v public.orders;
begin
  select * into v from public.orders where id = p_order_id and seller_id = me;
  if v.id is null then raise exception 'Pedido não encontrado.' using errcode = 'P0002'; end if;
  if p_status not in ('shipped', 'delivered', 'cancelled') or v.status in ('delivered', 'cancelled')
     or v.status = 'pending_payment' then
    raise exception 'Não dá para mudar esse pedido para esse status.' using errcode = 'P0001';
  end if;
  update public.orders set status = p_status where id = p_order_id returning * into v;
  if p_status = 'cancelled' then
    update public.payments set status = 'refunded' where id = v.payment_id and status = 'paid';
    update public.products set stock = case when stock is null then null else stock + v.quantity end,
                               sales_count = greatest(sales_count - v.quantity, 0)
     where id = v.product_id;
  end if;
  perform private.notify(v.buyer_id, me, 'order',
    case p_status when 'shipped' then 'Seu pedido foi enviado: '
                  when 'delivered' then 'Pedido entregue: '
                  else 'Pedido cancelado e reembolsado: ' end || v.product_name, '');
  return public.order_json(v);
end $$;

create function public.review_product(p_product_id bigint, p_rating integer, p_comment text default '') returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
begin
  if not exists (select 1 from public.orders where product_id = p_product_id and buyer_id = me
                   and status in ('paid', 'shipped', 'delivered')) then
    raise exception 'Só quem comprou pode avaliar.' using errcode = '42501';
  end if;
  insert into public.product_reviews (product_id, author_id, rating, comment)
  values (p_product_id, me, p_rating, left(trim(coalesce(p_comment, '')), 500))
  on conflict (product_id, author_id) do update set rating = excluded.rating, comment = excluded.comment;
  return public.product_detail(p_product_id);
exception when check_violation then
  raise exception 'Dê uma nota de 1 a 5.' using errcode = 'P0001';
end $$;

-- Painel financeiro ------------------------------------------------------------

create function public.my_finance() returns jsonb
language sql stable security definer set search_path = '' as $$
  with me as (select (select auth.uid()) as id),
  donations as (
    select coalesce(sum(d.amount) filter (where not d.via_coins), 0) as money,
           coalesce(sum(d.amount) filter (where d.via_coins), 0) as from_coins,
           count(*) as n
      from public.donations d join public.posts p on p.id = d.post_id, me where p.author_id = me.id),
  subs as (
    select coalesce(sum(pay.amount), 0) as total
      from public.payments pay, me
     where pay.kind = 'subscription' and pay.status = 'paid'
       and (pay.details ->> 'communityId')::uuid = me.id),
  sales as (
    select coalesce(sum(o.total) filter (where o.status in ('paid', 'shipped', 'delivered')), 0) as total,
           count(*) filter (where o.status in ('paid', 'shipped', 'delivered')) as n,
           count(*) filter (where o.status = 'paid') as to_ship
      from public.orders o, me where o.seller_id = me.id),
  paid_out as (
    select coalesce(sum(po.amount) filter (where po.status in ('requested', 'paid')), 0) as total
      from public.payouts po, me where po.profile_id = me.id)
  select jsonb_build_object(
    'donations', donations.money, 'donationsFromCoins', donations.from_coins, 'donationsCount', donations.n,
    'subscriptions', subs.total,
    'activeSubscribers', (select count(*) from public.community_subscriptions s, me
                           where s.community_id = me.id and s.status = 'active' and s.current_period_end > now()),
    'sales', sales.total, 'salesCount', sales.n, 'ordersToShip', sales.to_ship,
    'feePercent', (private.setting('platform_fee_percent'))::numeric,
    'payouts', paid_out.total,
    'available', round((donations.money + donations.from_coins + subs.total + sales.total)
                       * (1 - (private.setting('platform_fee_percent'))::numeric / 100) - paid_out.total, 2),
    'payoutHistory', coalesce((select jsonb_agg(jsonb_build_object('id', po.id::text, 'amount', po.amount,
                                                                    'status', po.status, 'createdAt', po.created_at)
                                                 order by po.created_at desc)
                                 from public.payouts po, me where po.profile_id = me.id), '[]'::jsonb))
  from donations, subs, sales, paid_out;
$$;

create function public.request_payout(p_amount numeric, p_pix_key text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
begin
  if (select account_type from public.profiles where id = me) = 'personal' then
    raise exception 'Repasses são para comunidades, empresas e influenciadores.' using errcode = '42501';
  end if;
  if (select verification_status from public.profiles where id = me) <> 'verified' then
    raise exception 'Verifique a conta antes de pedir repasses.' using errcode = 'P0001';
  end if;
  if p_amount is null or p_amount < 10 or p_amount > (public.my_finance() ->> 'available')::numeric then
    raise exception 'Valor indisponível (mínimo R$ 10).' using errcode = 'P0001';
  end if;
  if char_length(trim(coalesce(p_pix_key, ''))) < 5 then
    raise exception 'Informe a chave Pix.' using errcode = 'P0001';
  end if;
  insert into public.payouts (profile_id, amount, pix_key) values (me, round(p_amount, 2), trim(p_pix_key));
  return public.my_finance();
end $$;

-- Expira Pix pendentes.
create function private.expire_payments() returns void
language sql security definer set search_path = '' as $$
  update public.payments set status = 'expired' where status = 'pending' and expires_at < now() - interval '1 hour';
  update public.orders o set status = 'cancelled'
    from public.payments p where p.id = o.payment_id and p.status = 'expired' and o.status = 'pending_payment';
$$;
select cron.schedule('expire-payments', '7 * * * *', 'select private.expire_payments()');

-- Permissões das funções -----------------------------------------------------
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;
revoke execute on all functions in schema private from public, anon, authenticated;
