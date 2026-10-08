-- Perfis, dados privados, seguidores e livro-razão de moedas/XP.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique
    check (username = lower(username) and username ~ '^[a-z0-9._]{3,30}$'),
  name text not null default '' check (char_length(name) <= 80),
  account_type public.account_type not null default 'personal',
  role public.app_role not null default 'user',
  verification_status public.verification_status not null default 'unverified',
  pronouns public.pronouns,
  bio text not null default '' check (char_length(bio) <= 300),
  avatar_url text,
  cover_url text,
  city text,
  state text check (state is null or state ~ '^[A-Z]{2}$'),
  xp integer not null default 0 check (xp >= 0),
  level integer generated always as (xp / 300 + 1) stored,
  coins integer not null default 0 check (coins >= 0),
  followers_count integer not null default 0,
  following_count integer not null default 0,
  posts_count integer not null default 0,
  rating_avg numeric(2, 1) not null default 0,
  rating_count integer not null default 0,
  invite_code text not null unique default substr(md5(random()::text), 1, 8),
  onboarding_completed boolean not null default false,
  is_demo boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index profiles_city_state_idx on public.profiles (state, city);
create index profiles_name_trgm_idx on public.profiles using gin (name extensions.gin_trgm_ops);

create trigger profiles_updated_at before update on public.profiles
  for each row execute function private.set_updated_at();

-- Dados que só o dono vê.
create table public.profile_private (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  birth_date date,
  email_news boolean not null default false,
  cep text,
  street text,
  complement text,
  updated_at timestamptz not null default now()
);

create trigger profile_private_updated_at before update on public.profile_private
  for each row execute function private.set_updated_at();

create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  followed_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followed_id),
  check (follower_id <> followed_id)
);

create index follows_followed_idx on public.follows (followed_id);

-- Livro-razão: toda moeda/XP que entra ou sai. Imutável.
create table public.coin_ledger (
  id bigint generated always as identity primary key,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  amount integer not null check (amount <> 0),
  reason public.ledger_reason not null,
  ref_table text,
  ref_id text,
  counterpart_id uuid references public.profiles (id) on delete set null,
  note text,
  created_at timestamptz not null default now()
);

create index coin_ledger_profile_idx on public.coin_ledger (profile_id, created_at desc);
create index coin_ledger_counterpart_idx on public.coin_ledger (counterpart_id);

create table public.xp_ledger (
  id bigint generated always as identity primary key,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  amount integer not null check (amount > 0),
  reason public.ledger_reason not null,
  ref_table text,
  ref_id text,
  created_at timestamptz not null default now()
);

create index xp_ledger_profile_idx on public.xp_ledger (profile_id, created_at desc);

-- Credita/debita moedas e XP de forma atômica. Só chamado por outras funções.
create function private.grant_reward(
  p_profile uuid,
  p_coins integer,
  p_xp integer,
  p_reason public.ledger_reason,
  p_ref_table text default null,
  p_ref_id text default null,
  p_counterpart uuid default null,
  p_note text default null
) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if p_coins <> 0 then
    insert into public.coin_ledger (profile_id, amount, reason, ref_table, ref_id, counterpart_id, note)
    values (p_profile, p_coins, p_reason, p_ref_table, p_ref_id, p_counterpart, p_note);
  end if;
  if p_xp > 0 then
    insert into public.xp_ledger (profile_id, amount, reason, ref_table, ref_id)
    values (p_profile, p_xp, p_reason, p_ref_table, p_ref_id);
  end if;
  update public.profiles
     set coins = coins + p_coins,
         xp = xp + greatest(p_xp, 0)
   where id = p_profile;
end $$;

-- O app não altera colunas de sistema (moedas, XP, papel, contadores...).
-- current_user é 'authenticated' quando o update vem do app; dentro de funções
-- security definer é o dono, então as RPCs podem alterar.
create function private.guard_profile_columns() returns trigger
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
    or (old.onboarding_completed and new.account_type is distinct from old.account_type)
  ) then
    raise exception 'Campo protegido do perfil' using errcode = '42501';
  end if;
  return new;
end $$;

create trigger profiles_guard before update on public.profiles
  for each row execute function private.guard_profile_columns();

-- Contadores de seguidores.
create function private.on_follow_change() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    update public.profiles set following_count = following_count + 1 where id = new.follower_id;
    update public.profiles set followers_count = followers_count + 1 where id = new.followed_id;
  else
    update public.profiles set following_count = greatest(following_count - 1, 0) where id = old.follower_id;
    update public.profiles set followers_count = greatest(followers_count - 1, 0) where id = old.followed_id;
  end if;
  return null;
end $$;

create trigger follows_counters after insert or delete on public.follows
  for each row execute function private.on_follow_change();

-- Cadastro: cria o perfil a partir do auth.users. O @ provisório é trocado ao
-- completar o perfil.
create function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, username, name)
  values (
    new.id,
    'user_' || substr(replace(new.id::text, '-', ''), 1, 12),
    coalesce(left(new.raw_user_meta_data ->> 'name', 80), '')
  );
  insert into public.profile_private (profile_id) values (new.id);
  perform private.grant_reward(new.id, 100, 0, 'signup_bonus');
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function private.handle_new_user();

-- RLS ------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.profile_private enable row level security;
alter table public.follows enable row level security;
alter table public.coin_ledger enable row level security;
alter table public.xp_ledger enable row level security;

create policy "Perfis são públicos" on public.profiles
  for select to anon, authenticated using (true);
create policy "Dono edita o perfil" on public.profiles
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy "Dono vê dados privados" on public.profile_private
  for select to authenticated using (profile_id = (select auth.uid()));
create policy "Dono edita dados privados" on public.profile_private
  for update to authenticated
  using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));

create policy "Seguidores são públicos" on public.follows
  for select to anon, authenticated using (true);
create policy "Seguir em nome próprio" on public.follows
  for insert to authenticated with check (follower_id = (select auth.uid()));
create policy "Deixar de seguir em nome próprio" on public.follows
  for delete to authenticated using (follower_id = (select auth.uid()));

create policy "Dono vê o extrato de moedas" on public.coin_ledger
  for select to authenticated using (profile_id = (select auth.uid()));
create policy "Dono vê o extrato de XP" on public.xp_ledger
  for select to authenticated using (profile_id = (select auth.uid()));
