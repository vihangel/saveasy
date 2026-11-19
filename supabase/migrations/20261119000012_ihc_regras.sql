-- Regras da avaliação de IHC (19/11/2026) aplicadas também no banco.
--
-- O app já impede estas ações; aqui o banco passa a recusar chamadas diretas.
-- Não remove nem altera publicações existentes.
--
--   1. Campanha encerrada não recebe doação (Pix ou moedas).
--   2. Autor não doa nem participa da própria publicação (e, por isso, não
--      ganha moedas/XP com ela).
--   3. Check-in só a partir do dia da publicação.
--   4. A publicação informa se o autor é verificado (selo "não verificada").
--   5. Objetivo diário "Compartilhe 1 boa ação" passa a dizer o que conta
--      de verdade: publicar um story.
--
-- Datas comparadas no fuso de Cuiabá: a campanha aceita doações até o fim do
-- dia de encerramento, como no app.

-- Utilitário: o dia (em Cuiabá) de um instante.
create function private.local_day(p timestamptz) returns date
language sql stable set search_path = '' as $$
  select (p at time zone 'America/Cuiaba')::date;
$$;

-- 1 e 2: doação -------------------------------------------------------------

-- Valida uma doação para a campanha p_post_id feita por p_donor.
create function private.assert_can_donate(p_post_id bigint, p_donor uuid) returns void
language plpgsql stable security definer set search_path = '' as $$
declare
  v_post public.posts;
begin
  select * into v_post from public.posts where id = p_post_id;
  if v_post.id is null then return; end if; -- as funções de origem já tratam "não encontrada"
  if v_post.author_id = p_donor then
    raise exception 'Você organiza esta campanha, por isso não pode doar para ela.' using errcode = 'P0001';
  end if;
  if v_post.ends_at is not null and private.local_day(now()) > private.local_day(v_post.ends_at) then
    raise exception 'Esta campanha foi encerrada e não recebe mais doações.' using errcode = 'P0001';
  end if;
end $$;

-- Pix/cartão: barra na criação do pagamento (antes de cobrar). Um pagamento
-- criado antes do encerramento ainda é entregue normalmente.
create function private.guard_donation_payment() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.kind = 'donation' then
    perform private.assert_can_donate((new.details ->> 'postId')::bigint, new.payer_id);
  end if;
  return new;
end $$;

create trigger payments_donation_guard before insert on public.payments
  for each row execute function private.guard_donation_payment();

-- Moedas: a doação é gravada na hora; se o gatilho recusar, a função
-- donate_coins inteira é desfeita (moedas não são debitadas).
create function private.guard_coin_donation() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.via_coins then
    perform private.assert_can_donate(new.post_id, new.donor_id);
  end if;
  return new;
end $$;

create trigger donations_coin_guard before insert on public.donations
  for each row execute function private.guard_coin_donation();

-- 2 e 3: participação e check-in ---------------------------------------------

create function private.guard_participation() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_post public.posts;
begin
  select * into v_post from public.posts where id = new.post_id;
  if tg_op = 'INSERT' and v_post.author_id = new.profile_id then
    raise exception 'Você organiza esta publicação.' using errcode = 'P0001';
  end if;
  -- Check-in (presença marcada agora) antes do dia da publicação.
  if new.checked_in_at is not null
     and (tg_op = 'INSERT' or old.checked_in_at is null)
     and v_post.starts_at is not null
     and private.local_day(now()) < private.local_day(v_post.starts_at) then
    raise exception 'O check-in libera no dia da publicação (%).',
      to_char(private.local_day(v_post.starts_at), 'DD/MM/YYYY') using errcode = 'P0001';
  end if;
  return new;
end $$;

create trigger participations_guard before insert or update on public.participations
  for each row execute function private.guard_participation();

-- 4: selo de verificação na publicação ---------------------------------------
-- Mesma função da migration 4, com o campo novo "authorVerified".

create or replace function public.post_json(p public.posts, a public.profiles) returns jsonb
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
    'authorVerified', a.verification_status = 'verified',
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

-- 5: nome do objetivo diário ------------------------------------------------

update public.achievements
   set title = 'Publique 1 story', description = 'Publique um story hoje.'
 where id = 'a_daily_share';

-- Permissões (mesmo padrão das outras migrations) ----------------------------
revoke execute on all functions in schema private from public, anon, authenticated;
grant execute on function public.post_json(public.posts, public.profiles) to authenticated;
