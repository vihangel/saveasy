-- Publicações (uma tabela com colunas por tipo), interações e participação.

create table public.posts (
  id bigint generated always as identity primary key,
  author_id uuid not null references public.profiles (id) on delete cascade,
  type public.post_type not null,
  subtype text not null default '',
  activity_kind public.activity_kind,
  status public.post_status not null default 'published',
  title text not null check (char_length(title) between 3 and 120),
  description text not null default '' check (char_length(description) <= 5000),
  cover_url text,
  categories public.post_category[] not null default '{}',
  tags text[] not null default '{}' check (cardinality(tags) <= 10),
  reward_coins integer not null default 0 check (reward_coins >= 0),
  reward_xp integer not null default 0 check (reward_xp >= 0),
  likes_count integer not null default 0,
  comments_count integer not null default 0,
  shares_count integer not null default 0,
  interests_count integer not null default 0,
  participants_count integer not null default 0,
  -- doação
  target_amount numeric(12, 2) check (target_amount is null or target_amount > 0),
  raised_amount numeric(12, 2) not null default 0,
  recurring boolean not null default false,
  -- agenda e local (evento, ação social, atividade)
  starts_at timestamptz,
  ends_at timestamptz,
  location_text text,
  city text,
  state text check (state is null or state ~ '^[A-Z]{2}$'),
  link_url text,
  capacity integer check (capacity is null or capacity > 0),
  -- tutorial
  duration_minutes integer check (duration_minutes is null or duration_minutes > 0),
  steps text[] not null default '{}',
  -- propaganda
  ad_plan public.ad_plan,
  search tsvector generated always as (
    to_tsvector('portuguese'::regconfig, title || ' ' || description)
  ) stored,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint donation_needs_target check (type <> 'donation' or target_amount is not null),
  constraint event_needs_schedule check (
    type <> 'event' or (starts_at is not null and (location_text is not null or link_url is not null))
  ),
  constraint ends_after_start check (ends_at is null or starts_at is null or ends_at > starts_at)
);

create index posts_author_idx on public.posts (author_id, created_at desc);
create index posts_recent_idx on public.posts (created_at desc, id desc) where deleted_at is null;
create index posts_region_idx on public.posts (state, city) where deleted_at is null;
create index posts_categories_idx on public.posts using gin (categories);
create index posts_tags_idx on public.posts using gin (tags);
create index posts_search_idx on public.posts using gin (search);

create trigger posts_updated_at before update on public.posts
  for each row execute function private.set_updated_at();

-- Recompensa por tipo (o autor não define quanto o post paga).
create table public.post_reward_rules (
  post_type public.post_type primary key,
  reward_coins integer not null check (reward_coins >= 0),
  reward_xp integer not null check (reward_xp >= 0)
);

insert into public.post_reward_rules (post_type, reward_coins, reward_xp) values
  ('donation', 50, 100),
  ('event', 25, 60),
  ('social_action', 40, 80),
  ('activity', 20, 50),
  ('tutorial', 15, 40),
  ('discussion', 5, 20),
  ('ad', 20, 10);

create table public.post_likes (
  post_id bigint not null references public.posts (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, profile_id)
);
create index post_likes_profile_idx on public.post_likes (profile_id);

-- "Tenho interesse" / salvo = seguir a publicação.
create table public.post_interests (
  post_id bigint not null references public.posts (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  kind public.interest_kind not null default 'saved',
  created_at timestamptz not null default now(),
  primary key (post_id, profile_id)
);
create index post_interests_profile_idx on public.post_interests (profile_id, created_at desc);

create table public.comments (
  id bigint generated always as identity primary key,
  post_id bigint not null references public.posts (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  parent_id bigint references public.comments (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  likes_count integer not null default 0,
  replies_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index comments_post_idx on public.comments (post_id, created_at desc);
create index comments_author_idx on public.comments (author_id);
create index comments_parent_idx on public.comments (parent_id);

create trigger comments_updated_at before update on public.comments
  for each row execute function private.set_updated_at();

create table public.comment_likes (
  comment_id bigint not null references public.comments (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, profile_id)
);
create index comment_likes_profile_idx on public.comment_likes (profile_id);

create table public.participations (
  post_id bigint not null references public.posts (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  status public.participation_status not null default 'going',
  checked_in_at timestamptz,
  reward_granted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (post_id, profile_id)
);
create index participations_profile_idx on public.participations (profile_id, created_at desc);

create trigger participations_updated_at before update on public.participations
  for each row execute function private.set_updated_at();

-- Contadores ----------------------------------------------------------------
create function private.on_post_like_change() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.posts
     set likes_count = greatest(likes_count + case when tg_op = 'INSERT' then 1 else -1 end, 0)
   where id = coalesce(new.post_id, old.post_id);
  return null;
end $$;
create trigger post_likes_counter after insert or delete on public.post_likes
  for each row execute function private.on_post_like_change();

create function private.on_post_interest_change() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.posts
     set interests_count = greatest(interests_count + case when tg_op = 'INSERT' then 1 else -1 end, 0)
   where id = coalesce(new.post_id, old.post_id);
  return null;
end $$;
create trigger post_interests_counter after insert or delete on public.post_interests
  for each row execute function private.on_post_interest_change();

create function private.on_comment_change() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  delta integer := 0;
begin
  if tg_op = 'INSERT' then
    delta := 1;
  elsif tg_op = 'UPDATE' and old.deleted_at is null and new.deleted_at is not null then
    delta := -1;
  end if;
  if delta <> 0 then
    update public.posts set comments_count = greatest(comments_count + delta, 0) where id = new.post_id;
    if new.parent_id is not null then
      update public.comments set replies_count = greatest(replies_count + delta, 0) where id = new.parent_id;
    end if;
  end if;
  return null;
end $$;
create trigger comments_counter after insert or update of deleted_at on public.comments
  for each row execute function private.on_comment_change();

create function private.on_comment_like_change() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.comments
     set likes_count = greatest(likes_count + case when tg_op = 'INSERT' then 1 else -1 end, 0)
   where id = coalesce(new.comment_id, old.comment_id);
  return null;
end $$;
create trigger comment_likes_counter after insert or delete on public.comment_likes
  for each row execute function private.on_comment_like_change();

create function private.on_participation_change() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.posts p
     set participants_count = (
       select count(*) from public.participations x
        where x.post_id = p.id and x.status in ('going', 'attended')
     )
   where p.id = coalesce(new.post_id, old.post_id);
  return null;
end $$;
create trigger participations_counter after insert or update or delete on public.participations
  for each row execute function private.on_participation_change();

create function private.on_post_change() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    update public.profiles set posts_count = posts_count + 1 where id = new.author_id;
  elsif old.deleted_at is null and new.deleted_at is not null then
    update public.profiles set posts_count = greatest(posts_count - 1, 0) where id = new.author_id;
  end if;
  return null;
end $$;
create trigger posts_author_counter after insert or update of deleted_at on public.posts
  for each row execute function private.on_post_change();

-- Comentário: o app só altera o texto ou apaga (soft delete).
create function private.guard_comment_columns() returns trigger
language plpgsql set search_path = '' as $$
begin
  if current_user in ('authenticated', 'anon') and (
       new.post_id is distinct from old.post_id
    or new.author_id is distinct from old.author_id
    or new.parent_id is distinct from old.parent_id
    or new.likes_count is distinct from old.likes_count
    or new.replies_count is distinct from old.replies_count
  ) then
    raise exception 'Campo protegido do comentário' using errcode = '42501';
  end if;
  return new;
end $$;
create trigger comments_guard before update on public.comments
  for each row execute function private.guard_comment_columns();

-- RLS ------------------------------------------------------------------------
-- posts: leitura pública dos publicados; escrita só pelas RPCs create/update/delete_post.
alter table public.posts enable row level security;
alter table public.post_reward_rules enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_interests enable row level security;
alter table public.comments enable row level security;
alter table public.comment_likes enable row level security;
alter table public.participations enable row level security;

create policy "Publicações visíveis" on public.posts
  for select to anon, authenticated
  using (
    (deleted_at is null and status in ('published', 'finished', 'cancelled'))
    or author_id = (select auth.uid())
  );

create policy "Regras de recompensa são públicas" on public.post_reward_rules
  for select to anon, authenticated using (true);

create policy "Vejo minhas curtidas" on public.post_likes
  for select to authenticated using (profile_id = (select auth.uid()));
create policy "Curto em nome próprio" on public.post_likes
  for insert to authenticated with check (profile_id = (select auth.uid()));
create policy "Descurto em nome próprio" on public.post_likes
  for delete to authenticated using (profile_id = (select auth.uid()));

create policy "Vejo meus interesses" on public.post_interests
  for select to authenticated using (profile_id = (select auth.uid()));
create policy "Salvo em nome próprio" on public.post_interests
  for insert to authenticated with check (profile_id = (select auth.uid()));
create policy "Removo meus salvos" on public.post_interests
  for delete to authenticated using (profile_id = (select auth.uid()));

create policy "Comentários visíveis" on public.comments
  for select to anon, authenticated using (deleted_at is null);
create policy "Comento em nome próprio" on public.comments
  for insert to authenticated with check (author_id = (select auth.uid()));
create policy "Edito meus comentários" on public.comments
  for update to authenticated
  using (author_id = (select auth.uid())) with check (author_id = (select auth.uid()));

create policy "Vejo minhas curtidas em comentários" on public.comment_likes
  for select to authenticated using (profile_id = (select auth.uid()));
create policy "Curto comentário em nome próprio" on public.comment_likes
  for insert to authenticated with check (profile_id = (select auth.uid()));
create policy "Descurto comentário em nome próprio" on public.comment_likes
  for delete to authenticated using (profile_id = (select auth.uid()));

create policy "Participante ou organizador vê a participação" on public.participations
  for select to authenticated
  using (
    profile_id = (select auth.uid())
    or exists (select 1 from public.posts p where p.id = post_id and p.author_id = (select auth.uid()))
  );
