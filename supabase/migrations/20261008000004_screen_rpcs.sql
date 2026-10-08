-- Funções orientadas às telas. Leituras devolvem JSON no formato dos modelos
-- do app (Post, AppUser, Comment), com as chaves em camelCase, para o Flutter
-- usar o fromJson direto. Escritas com regra de negócio são security definer
-- e validam auth.uid() no corpo.

-- Serializadores -------------------------------------------------------------

create function public.pronouns_label(p public.pronouns) returns text
language sql immutable set search_path = '' as $$
  select case p
    when 'ele_dele' then 'Ele/dele'
    when 'ela_dela' then 'Ela/dela'
    when 'elu_delu' then 'Elu/delu'
    else '' end;
$$;

create function public.pronouns_from_label(p text) returns public.pronouns
language sql immutable set search_path = '' as $$
  select case lower(coalesce(p, ''))
    when 'ele/dele' then 'ele_dele'::public.pronouns
    when 'ela/dela' then 'ela_dela'::public.pronouns
    when 'elu/delu' then 'elu_delu'::public.pronouns
    else null end;
$$;

-- Perfil público (sem dados privados).
create function public.profile_json(p public.profiles) returns jsonb
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
    'badgeIds', '[]'::jsonb
  );
$$;

-- Perfil do usuário logado, com dados privados e quem ele segue.
create function public.my_profile() returns jsonb
language sql stable set search_path = '' as $$
  select public.profile_json(p)
    || jsonb_build_object(
      'email', coalesce((select auth.jwt()) ->> 'email', ''),
      'birthDate', pp.birth_date,
      'emailNews', coalesce(pp.email_news, false),
      'address', case when pp.cep is not null and pp.street is not null and p.state is not null and p.city is not null
        then jsonb_build_object('cep', pp.cep, 'street', pp.street, 'complement', coalesce(pp.complement, ''),
                                'state', p.state, 'city', p.city)
        end,
      'followingIds', coalesce(
        (select jsonb_agg(f.followed_id) from public.follows f where f.follower_id = p.id), '[]'::jsonb)
    )
  from public.profiles p
  left join public.profile_private pp on pp.profile_id = p.id
  where p.id = (select auth.uid());
$$;

create function public.post_json(p public.posts, a public.profiles) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'id', p.id::text,
    'type', p.type,
    'subtype', p.subtype,
    'status', p.status,
    'title', p.title,
    'description', p.description,
    'imageUrl', p.cover_url,
    'categories', to_jsonb(p.categories),
    'tags', to_jsonb(p.tags),
    'authorId', a.id,
    'authorName', a.name,
    'authorType', a.account_type,
    'authorAvatarUrl', a.avatar_url,
    'createdAt', p.created_at,
    'likes', p.likes_count,
    'shares', p.shares_count,
    'commentsCount', p.comments_count,
    'interests', p.interests_count,
    'rewardCoins', p.reward_coins,
    'rewardXp', p.reward_xp,
    'targetAmount', p.target_amount,
    'raisedAmount', p.raised_amount,
    'recurring', p.recurring,
    'startsAt', p.starts_at,
    'endsAt', p.ends_at,
    'location', p.location_text,
    'city', p.city,
    'state', p.state,
    'link', p.link_url,
    'attending', p.participants_count,
    'capacity', p.capacity,
    'durationMinutes', p.duration_minutes,
    'steps', to_jsonb(p.steps),
    'adPlan', p.ad_plan,
    'activityKind', p.activity_kind,
    'liked', exists (select 1 from public.post_likes l
                      where l.post_id = p.id and l.profile_id = (select auth.uid())),
    'saved', exists (select 1 from public.post_interests i
                      where i.post_id = p.id and i.profile_id = (select auth.uid())),
    'confirmed', exists (select 1 from public.participations x
                          where x.post_id = p.id and x.profile_id = (select auth.uid())
                            and x.status in ('going', 'attended'))
  );
$$;

create function public.comment_json(c public.comments, a public.profiles) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'id', c.id::text,
    'postId', c.post_id::text,
    'parentId', c.parent_id::text,
    'authorId', a.id,
    'authorName', a.name,
    'authorAvatarUrl', a.avatar_url,
    'text', c.body,
    'createdAt', c.created_at,
    'likes', c.likes_count,
    'replies', c.replies_count,
    'liked', exists (select 1 from public.comment_likes l
                      where l.comment_id = c.id and l.profile_id = (select auth.uid())),
    'lastReplyAuthor', (
      select ra.name from public.comments r join public.profiles ra on ra.id = r.author_id
       where r.parent_id = c.id and r.deleted_at is null
       order by r.created_at desc limit 1)
  );
$$;

create function public.post_json_by_id(p_post_id bigint) returns jsonb
language sql stable set search_path = '' as $$
  select public.post_json(p, a)
    from public.posts p join public.profiles a on a.id = p.author_id
   where p.id = p_post_id;
$$;

-- Leituras de tela -----------------------------------------------------------

-- Feed: abas popular | nearby | following, filtro de categoria e busca.
create function public.feed(
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

-- Detalhe: post + autor + comentários (raiz) numa chamada.
create function public.post_detail(p_post_id bigint) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'post', public.post_json(p, a),
    'author', public.profile_json(a),
    'comments', coalesce((
      select jsonb_agg(public.comment_json(c, ca) order by c.created_at desc)
        from (select * from public.comments
               where post_id = p.id and parent_id is null and deleted_at is null
               order by created_at desc limit 50) c
        join public.profiles ca on ca.id = c.author_id
    ), '[]'::jsonb)
  )
  from public.posts p join public.profiles a on a.id = p.author_id
  where p.id = p_post_id;
$$;

create function public.comment_replies(p_comment_id bigint) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.comment_json(c, a) order by c.created_at), '[]'::jsonb)
    from public.comments c join public.profiles a on a.id = c.author_id
   where c.parent_id = p_comment_id and c.deleted_at is null;
$$;

create function public.profile_page(p_profile_id uuid) returns jsonb
language sql stable set search_path = '' as $$
  select case when p.id = (select auth.uid()) then public.my_profile() else public.profile_json(p) end
    from public.profiles p where p.id = p_profile_id;
$$;

create function public.author_posts(p_profile_id uuid, p_limit integer default 30, p_offset integer default 0)
returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.post_json(x.p, x.a)), '[]'::jsonb)
    from (
      select p, a from public.posts p join public.profiles a on a.id = p.author_id
       where p.author_id = p_profile_id and p.deleted_at is null
       order by p.created_at desc, p.id desc
       limit least(greatest(p_limit, 1), 100) offset greatest(p_offset, 0)
    ) x;
$$;

create function public.search_profiles(p_query text default '', p_limit integer default 30) returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.profile_json(x)), '[]'::jsonb)
    from (
      select p.* from public.profiles p
       where p.id <> coalesce((select auth.uid()), '00000000-0000-0000-0000-000000000000'::uuid)
         and p.onboarding_completed
         and (coalesce(p_query, '') = '' or p.name ilike '%' || p_query || '%'
              or p.username ilike '%' || p_query || '%')
       order by p.followers_count desc
       limit least(greatest(p_limit, 1), 100)
    ) x;
$$;

-- Lista de seguidores ou seguidos. p_kind: followers | following
create function public.follow_list(p_profile_id uuid, p_kind text default 'followers') returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.profile_json(p) order by f.created_at desc), '[]'::jsonb)
    from public.follows f
    join public.profiles p
      on p.id = case when p_kind = 'following' then f.followed_id else f.follower_id end
   where case when p_kind = 'following' then f.follower_id else f.followed_id end = p_profile_id;
$$;

create function public.my_interests() returns jsonb
language sql stable set search_path = '' as $$
  select coalesce(jsonb_agg(public.post_json(p, a) order by i.created_at desc), '[]'::jsonb)
    from public.post_interests i
    join public.posts p on p.id = i.post_id and p.deleted_at is null
    join public.profiles a on a.id = p.author_id
   where i.profile_id = (select auth.uid());
$$;

create function public.is_username_available(p_username text) returns boolean
language sql stable security definer set search_path = '' as $$
  select lower(p_username) ~ '^[a-z0-9._]{3,30}$'
     and not exists (select 1 from public.profiles
                      where username = lower(p_username)
                        and id <> coalesce((select auth.uid()), '00000000-0000-0000-0000-000000000000'::uuid));
$$;

-- Escritas de perfil ---------------------------------------------------------

-- Último passo do cadastro: tipo de conta, @, dados pessoais e endereço.
create function public.complete_profile(
  p_account_type public.account_type,
  p_name text,
  p_username text,
  p_pronouns text default null,
  p_birth_date date default null,
  p_cep text default null,
  p_street text default null,
  p_complement text default null,
  p_city text default null,
  p_state text default null,
  p_email_news boolean default false,
  p_avatar_url text default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  if not public.is_username_available(p_username) then
    raise exception 'Esse nome de usuário já está em uso.' using errcode = 'P0001';
  end if;
  if char_length(trim(coalesce(p_name, ''))) < 2 then
    raise exception 'Informe o nome.' using errcode = 'P0001';
  end if;

  update public.profiles
     set account_type = p_account_type,
         name = trim(p_name),
         username = lower(p_username),
         pronouns = public.pronouns_from_label(p_pronouns),
         city = nullif(trim(coalesce(p_city, '')), ''),
         state = nullif(upper(trim(coalesce(p_state, ''))), ''),
         avatar_url = coalesce(p_avatar_url, avatar_url),
         onboarding_completed = true
   where id = me;

  update public.profile_private
     set birth_date = p_birth_date,
         email_news = coalesce(p_email_news, false),
         cep = nullif(regexp_replace(coalesce(p_cep, ''), '\D', '', 'g'), ''),
         street = nullif(trim(coalesce(p_street, '')), ''),
         complement = nullif(trim(coalesce(p_complement, '')), '')
   where profile_id = me;

  return public.my_profile();
end $$;

-- Editar perfil (campos livres). Roda como o usuário: a RLS e o guard valem.
create function public.update_my_profile(
  p_name text,
  p_username text,
  p_bio text default '',
  p_pronouns text default null,
  p_avatar_url text default null,
  p_cover_url text default null
) returns jsonb
language plpgsql set search_path = '' as $$
begin
  if not public.is_username_available(p_username) then
    raise exception 'Esse nome de usuário já está em uso.' using errcode = 'P0001';
  end if;
  update public.profiles
     set name = trim(p_name),
         username = lower(p_username),
         bio = coalesce(p_bio, ''),
         pronouns = public.pronouns_from_label(p_pronouns),
         avatar_url = p_avatar_url,
         cover_url = p_cover_url
   where id = (select auth.uid());
  return public.my_profile();
end $$;

create function public.toggle_follow(p_target uuid) returns jsonb
language plpgsql set search_path = '' as $$
begin
  if exists (select 1 from public.follows where follower_id = (select auth.uid()) and followed_id = p_target) then
    delete from public.follows where follower_id = (select auth.uid()) and followed_id = p_target;
  else
    insert into public.follows (follower_id, followed_id) values ((select auth.uid()), p_target);
  end if;
  return public.my_profile();
end $$;

-- Exclui a conta (LGPD). Apaga o usuário do Auth e tudo em cascata.
create function public.delete_my_account() returns void
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  delete from auth.users where id = me;
end $$;

-- Escritas de publicação -----------------------------------------------------

-- Quem pode criar cada tipo (PRODUTO §3.4 / BACKEND §3.4, sujeito a decisão).
create function private.can_create_post(p_account public.account_type, p_type public.post_type)
returns boolean
language sql immutable set search_path = '' as $$
  select case
    when p_type = 'ad' then p_account in ('business', 'influencer', 'community')
    else true
  end;
$$;

create function private.normalize_tags(p jsonb) returns text[]
language sql immutable set search_path = '' as $$
  select coalesce(array(
    select distinct lower(trim(t)) from jsonb_array_elements_text(coalesce(p, '[]'::jsonb)) t
     where trim(t) <> '' limit 10), '{}');
$$;

create function public.create_post(p jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me public.profiles;
  v_type public.post_type := (p ->> 'type')::public.post_type;
  v_rule public.post_reward_rules;
  v_post public.posts;
begin
  select * into me from public.profiles where id = (select auth.uid());
  if me.id is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  if not me.onboarding_completed then
    raise exception 'Complete seu perfil antes de publicar.' using errcode = 'P0001';
  end if;
  if not private.can_create_post(me.account_type, v_type) then
    raise exception 'Seu tipo de conta não pode criar esse tipo de publicação.' using errcode = 'P0001';
  end if;
  select * into v_rule from public.post_reward_rules where post_type = v_type;

  insert into public.posts (
    author_id, type, subtype, activity_kind, title, description, cover_url, categories, tags,
    reward_coins, reward_xp, target_amount, recurring, starts_at, ends_at,
    location_text, city, state, link_url, capacity, duration_minutes, steps, ad_plan
  ) values (
    me.id, v_type, coalesce(p ->> 'subtype', ''),
    (p ->> 'activityKind')::public.activity_kind,
    trim(p ->> 'title'), coalesce(trim(p ->> 'description'), ''), p ->> 'imageUrl',
    coalesce(array(select jsonb_array_elements_text(p -> 'categories')::public.post_category), '{}'),
    private.normalize_tags(p -> 'tags'),
    coalesce(v_rule.reward_coins, 0), coalesce(v_rule.reward_xp, 0),
    (p ->> 'targetAmount')::numeric, coalesce((p ->> 'recurring')::boolean, false),
    (p ->> 'startsAt')::timestamptz, (p ->> 'endsAt')::timestamptz,
    nullif(trim(coalesce(p ->> 'location', '')), ''),
    coalesce(nullif(trim(coalesce(p ->> 'city', '')), ''), case when p ? 'location' then me.city end),
    coalesce(nullif(upper(trim(coalesce(p ->> 'state', ''))), ''), case when p ? 'location' then me.state end),
    nullif(trim(coalesce(p ->> 'link', '')), ''),
    (p ->> 'capacity')::integer, (p ->> 'durationMinutes')::integer,
    coalesce(array(select jsonb_array_elements_text(p -> 'steps')), '{}'),
    (p ->> 'adPlan')::public.ad_plan
  ) returning * into v_post;

  perform private.grant_reward(me.id, 0, 30, 'post_created', 'posts', v_post.id::text);

  return jsonb_build_object('post', public.post_json_by_id(v_post.id), 'author', public.my_profile());
end $$;

-- Editar: autor apenas; tipo não muda; meta não muda depois de receber doações.
create function public.update_post(p_post_id bigint, p jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_post public.posts;
begin
  select * into v_post from public.posts where id = p_post_id and deleted_at is null;
  if v_post.id is null or v_post.author_id <> (select auth.uid()) then
    raise exception 'Publicação não encontrada.' using errcode = 'P0002';
  end if;

  update public.posts set
    subtype = coalesce(p ->> 'subtype', subtype),
    title = coalesce(trim(p ->> 'title'), title),
    description = coalesce(trim(p ->> 'description'), description),
    cover_url = case when p ? 'imageUrl' then p ->> 'imageUrl' else cover_url end,
    categories = case when p ? 'categories'
      then array(select jsonb_array_elements_text(p -> 'categories')::public.post_category) else categories end,
    tags = case when p ? 'tags' then private.normalize_tags(p -> 'tags') else tags end,
    target_amount = case when raised_amount > 0 then target_amount
                         else coalesce((p ->> 'targetAmount')::numeric, target_amount) end,
    recurring = coalesce((p ->> 'recurring')::boolean, recurring),
    starts_at = case when p ? 'startsAt' then (p ->> 'startsAt')::timestamptz else starts_at end,
    ends_at = case when p ? 'endsAt' then (p ->> 'endsAt')::timestamptz else ends_at end,
    location_text = case when p ? 'location' then nullif(trim(p ->> 'location'), '') else location_text end,
    link_url = case when p ? 'link' then nullif(trim(p ->> 'link'), '') else link_url end,
    capacity = case when p ? 'capacity' then (p ->> 'capacity')::integer else capacity end,
    duration_minutes = case when p ? 'durationMinutes' then (p ->> 'durationMinutes')::integer else duration_minutes end,
    steps = case when p ? 'steps' then array(select jsonb_array_elements_text(p -> 'steps')) else steps end
  where id = p_post_id;

  return public.post_json_by_id(p_post_id);
end $$;

create function public.delete_post(p_post_id bigint) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.posts set deleted_at = now(), status = 'archived'
   where id = p_post_id and author_id = (select auth.uid()) and deleted_at is null;
  if not found then raise exception 'Publicação não encontrada.' using errcode = 'P0002'; end if;
end $$;

-- Interações (rodam como o usuário; contadores pelos triggers) ---------------

create function public.toggle_post_like(p_post_id bigint) returns jsonb
language plpgsql set search_path = '' as $$
begin
  if exists (select 1 from public.post_likes where post_id = p_post_id and profile_id = (select auth.uid())) then
    delete from public.post_likes where post_id = p_post_id and profile_id = (select auth.uid());
  else
    insert into public.post_likes (post_id, profile_id) values (p_post_id, (select auth.uid()));
  end if;
  return public.post_json_by_id(p_post_id);
end $$;

create function public.toggle_post_interest(p_post_id bigint, p_kind public.interest_kind default 'saved')
returns jsonb
language plpgsql set search_path = '' as $$
begin
  if exists (select 1 from public.post_interests where post_id = p_post_id and profile_id = (select auth.uid())) then
    delete from public.post_interests where post_id = p_post_id and profile_id = (select auth.uid());
  else
    insert into public.post_interests (post_id, profile_id, kind) values (p_post_id, (select auth.uid()), p_kind);
  end if;
  return public.post_json_by_id(p_post_id);
end $$;

create function public.share_post(p_post_id bigint) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  if (select auth.uid()) is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  update public.posts set shares_count = shares_count + 1 where id = p_post_id and deleted_at is null;
  return public.post_json_by_id(p_post_id);
end $$;

create function public.add_comment(p_post_id bigint, p_body text, p_parent_id bigint default null)
returns jsonb
language plpgsql set search_path = '' as $$
declare
  v_comment public.comments;
begin
  insert into public.comments (post_id, author_id, parent_id, body)
  values (p_post_id, (select auth.uid()), p_parent_id, trim(p_body))
  returning * into v_comment;
  return (select public.comment_json(v_comment, a) from public.profiles a where a.id = v_comment.author_id);
end $$;

create function public.toggle_comment_like(p_comment_id bigint) returns jsonb
language plpgsql set search_path = '' as $$
begin
  if exists (select 1 from public.comment_likes where comment_id = p_comment_id and profile_id = (select auth.uid())) then
    delete from public.comment_likes where comment_id = p_comment_id and profile_id = (select auth.uid());
  else
    insert into public.comment_likes (comment_id, profile_id) values (p_comment_id, (select auth.uid()));
  end if;
  return (select public.comment_json(c, a)
            from public.comments c join public.profiles a on a.id = c.author_id
           where c.id = p_comment_id);
end $$;

-- security definer: a policy de leitura esconde comentários apagados, o que
-- bloquearia o soft delete feito como o usuário.
create function public.delete_comment(p_comment_id bigint) returns void
language plpgsql security definer set search_path = '' as $$
begin
  update public.comments set deleted_at = now()
   where id = p_comment_id and author_id = (select auth.uid()) and deleted_at is null;
  if not found then raise exception 'Comentário não encontrado.' using errcode = 'P0002'; end if;
end $$;

-- Participação: recompensa uma única vez por pessoa e post ------------------

create function public.participate(p_post_id bigint) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
  v_post public.posts;
  v_part public.participations;
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  select * into v_post from public.posts where id = p_post_id and deleted_at is null;
  if v_post.id is null or v_post.type not in ('event', 'social_action', 'activity') then
    raise exception 'Essa publicação não aceita participação.' using errcode = 'P0001';
  end if;
  if v_post.status <> 'published' or coalesce(v_post.ends_at, v_post.starts_at) < now() then
    raise exception 'Essa ação já foi encerrada.' using errcode = 'P0001';
  end if;
  if v_post.capacity is not null and v_post.participants_count >= v_post.capacity then
    raise exception 'Não há mais vagas.' using errcode = 'P0001';
  end if;

  insert into public.participations (post_id, profile_id, status)
  values (p_post_id, me, 'going')
  on conflict (post_id, profile_id) do update set status = 'going'
  returning * into v_part;

  if v_part.reward_granted_at is null then
    perform private.grant_reward(me, v_post.reward_coins, v_post.reward_xp,
                                 'participation_reward', 'posts', p_post_id::text);
    update public.participations set reward_granted_at = now()
     where post_id = p_post_id and profile_id = me;
  end if;

  return jsonb_build_object('post', public.post_json_by_id(p_post_id), 'me', public.my_profile());
end $$;

create function public.cancel_participation(p_post_id bigint) returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  update public.participations set status = 'cancelled'
   where post_id = p_post_id and profile_id = (select auth.uid()) and status = 'going';
  return jsonb_build_object('post', public.post_json_by_id(p_post_id), 'me', public.my_profile());
end $$;

-- Enviar moedas --------------------------------------------------------------

create function public.send_coins(p_to uuid, p_amount integer, p_message text default '') returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  me uuid := (select auth.uid());
begin
  if me is null then raise exception 'Não autenticado' using errcode = '42501'; end if;
  if p_to = me then raise exception 'Você não pode enviar moedas para si.' using errcode = 'P0001'; end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Escolha quantas moedas enviar.' using errcode = 'P0001';
  end if;
  if (select coins from public.profiles where id = me) < p_amount then
    raise exception 'Você não tem moedas suficientes.' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.profiles where id = p_to) then
    raise exception 'Perfil não encontrado.' using errcode = 'P0002';
  end if;

  perform private.grant_reward(me, -p_amount, p_amount / 2, 'coins_sent', null, null, p_to,
                               left(nullif(trim(p_message), ''), 140));
  perform private.grant_reward(p_to, p_amount, 0, 'coins_received', null, null, me,
                               left(nullif(trim(p_message), ''), 140));
  return public.my_profile();
end $$;

-- Permissões das funções -----------------------------------------------------
-- Tudo exige login, exceto checar @ disponível (usado no cadastro).
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;
grant execute on function public.is_username_available(text) to anon;
revoke execute on all functions in schema private from public, anon, authenticated;
