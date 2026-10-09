-- Conteúdo de demonstração (foco: Cuiabá - MT). Nomes e organizações são
-- fictícios; os lugares são públicos da cidade. As contas não têm senha, então
-- ninguém entra com elas: servem só para o feed não começar vazio.
-- Rodar só em desenvolvimento/homologação.

do $$
declare
  v_ids uuid[] := array[
    'a1000000-0000-4000-8000-000000000001', -- Banco de Sangue Vida MT
    'a1000000-0000-4000-8000-000000000002', -- Instituto Pantanal Vivo
    'a1000000-0000-4000-8000-000000000003', -- Abrigo Patas do Coxipó
    'a1000000-0000-4000-8000-000000000004', -- EcoCuiabá Reciclagem
    'a1000000-0000-4000-8000-000000000005', -- Coletivo Mãos do Porto
    'a1000000-0000-4000-8000-000000000006', -- Lu do Bem (influencer)
    'a1000000-0000-4000-8000-000000000007', -- Ana Ribeiro
    'a1000000-0000-4000-8000-000000000008'  -- Pedro Campos
  ]::uuid[];
  v_names text[] := array['Banco de Sangue Vida MT', 'Instituto Pantanal Vivo', 'Abrigo Patas do Coxipó',
                          'EcoCuiabá Reciclagem', 'Coletivo Mãos do Porto', 'Lu do Bem', 'Ana Ribeiro', 'Pedro Campos'];
  v_users text[] := array['vidamt', 'pantanalvivo', 'patasdocoxipo', 'ecocuiaba', 'maosdoporto', 'ludobem',
                          'anaribeiro', 'pedrocampos'];
  v_types public.account_type[] := array['community', 'community', 'community', 'business', 'community',
                                         'influencer', 'personal', 'personal']::public.account_type[];
  v_bios text[] := array[
    'Doe sangue, doe vida. Campanhas mensais em Cuiabá e Várzea Grande.',
    'Proteção do Pantanal e brigadas voluntárias contra incêndios.',
    'Resgate e adoção de cães e gatos no Coxipó.',
    'Coleta seletiva e reciclagem para empresas e condomínios de Cuiabá.',
    'Sopão solidário e apoio a pessoas em situação de rua no Porto.',
    'Criadora de conteúdo do bem direto de Cuiabá 🌞',
    'Voluntária nos fins de semana. Amo bicho e plantas.',
    'Professor e ciclista. Bora fazer Cuiabá mais verde!'];
  i int;
  p_blood bigint; p_fire bigint; p_dog bigint; p_clean bigint; p_soup bigint; p_recycle bigint;
  p_tutorial bigint; p_disc bigint; p_items bigint;
begin
  if exists (select 1 from public.profiles where is_demo) then
    raise notice 'Seed já aplicado.';
    return;
  end if;

  for i in 1 .. array_length(v_ids, 1) loop
    -- Campos de token vazios ('' e não null) evitam erro do GoTrue ao listar usuários.
    insert into auth.users (id, instance_id, aud, role, email, encrypted_password,
                            raw_app_meta_data, raw_user_meta_data, created_at, updated_at, email_confirmed_at,
                            confirmation_token, recovery_token, email_change_token_new, email_change)
    values (v_ids[i], '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
            v_users[i] || '@demo.saveeasy.app', '',
            '{"provider":"email","providers":["email"]}', jsonb_build_object('name', v_names[i]),
            now() - interval '60 days', now(), now() - interval '60 days', '', '', '', '');

    update public.profiles
       set username = v_users[i], name = v_names[i], account_type = v_types[i], bio = v_bios[i],
           city = 'Cuiabá', state = 'MT', onboarding_completed = true, is_demo = true,
           verification_status = case when v_types[i] in ('community', 'business') then 'verified'::public.verification_status
                                      else 'unverified'::public.verification_status end
     where id = v_ids[i];
  end loop;

  -- Seguidores entre as contas demo.
  insert into public.follows (follower_id, followed_id)
  select a, b from unnest(v_ids) a cross join unnest(v_ids) b
   where a <> b and (get_byte(decode(md5(a::text || b::text), 'hex'), 0) % 3) <> 0;

  insert into public.posts (author_id, type, subtype, title, description, categories, tags, reward_coins, reward_xp,
                            starts_at, ends_at, location_text, city, state, capacity, created_at)
  values (v_ids[1], 'event', 'Presencial', 'Mutirão de doação de sangue',
          'Os estoques de O- e A- estão baixos. Venha doar! Leve documento com foto, esteja alimentado e descansado. Doadores ganham lanche e o selo da campanha.',
          '{health}', '{sangue,saude}', 25, 60, now() + interval '2 days 9 hours', now() + interval '2 days 17 hours',
          'Centro de Cuiabá - Av. Getúlio Vargas', 'Cuiabá', 'MT', 300, now() - interval '1 day')
  returning id into p_blood;

  insert into public.posts (author_id, type, subtype, title, description, categories, tags, reward_coins, reward_xp,
                            target_amount, raised_amount, ends_at, created_at)
  values (v_ids[2], 'donation', 'Vaquinha', 'Equipamentos para brigadistas do Pantanal',
          'Abafadores, bombas costais e EPIs para 40 brigadistas voluntários que atuam na temporada de seca. Cada doação vira equipamento de verdade.',
          '{environment}', '{pantanal,queimadas}', 50, 100, 30000, 18450, now() + interval '25 days', now() - interval '6 days')
  returning id into p_fire;

  insert into public.posts (author_id, type, subtype, title, description, categories, tags, reward_coins, reward_xp,
                            target_amount, raised_amount, ends_at, created_at)
  values (v_ids[3], 'donation', 'Vaquinha', 'Cirurgia da Mel, resgatada no Coxipó',
          'A Mel foi resgatada com a pata fraturada perto da Av. Fernando Corrêa. Precisamos cobrir a cirurgia e 30 dias de recuperação.',
          '{animal,health}', '{caes,resgate}', 50, 100, 3500, 2210, now() + interval '9 days', now() - interval '2 days')
  returning id into p_dog;

  insert into public.posts (author_id, type, subtype, title, description, categories, tags, reward_coins, reward_xp,
                            starts_at, ends_at, location_text, city, state, capacity, created_at)
  values (v_ids[4], 'event', 'Presencial', 'Limpeza do Parque Mãe Bonifácia',
          'Mutirão de limpeza das trilhas e separação dos recicláveis. Levamos luvas, sacos e água. Ponto de encontro na entrada principal às 7h.',
          '{environment}', '{reciclagem,parque}', 25, 60, now() + interval '5 days 7 hours', now() + interval '5 days 11 hours',
          'Parque Mãe Bonifácia - entrada principal', 'Cuiabá', 'MT', 80, now() - interval '3 days')
  returning id into p_clean;

  insert into public.posts (author_id, type, subtype, title, description, categories, tags, reward_coins, reward_xp,
                            starts_at, location_text, city, state, created_at)
  values (v_ids[5], 'social_action', 'Voluntariado', 'Sopão solidário de quinta no Porto',
          'Toda quinta servimos sopa e pão para cerca de 150 pessoas. Precisamos de mãos para cozinhar (16h) e servir (18h30).',
          '{health}', '{alimentacao,voluntariado}', 40, 80, now() + interval '1 day 16 hours',
          'Praça Luís de Albuquerque - Porto', 'Cuiabá', 'MT', now() - interval '12 hours')
  returning id into p_soup;

  insert into public.posts (author_id, type, subtype, activity_kind, title, description, categories, tags,
                            reward_coins, reward_xp, location_text, city, state, created_at)
  values (v_ids[6], 'activity', 'Reciclagem', 'good_deed', 'Recolhemos 40 kg de lixo no Parque das Águas',
          'Juntei uns amigos no domingo e enchemos 12 sacos. Bora repetir no próximo mês? Comenta aqui quem topa!',
          '{environment}', '{reciclagem}', 20, 50, 'Parque das Águas', 'Cuiabá', 'MT', now() - interval '20 hours')
  returning id into p_recycle;

  insert into public.posts (author_id, type, subtype, title, description, categories, tags, reward_coins, reward_xp,
                            duration_minutes, steps, created_at)
  values (v_ids[4], 'tutorial', 'Sustentabilidade', 'Composteira caseira que aguenta o calor de Cuiabá',
          'Reduza o lixo orgânico e produza adubo mesmo com 40 °C.', '{environment,education}', '{compostagem}', 15, 40, 90,
          array['Use dois baldes com tampa e faça furos no fundo de um deles.',
                'Coloque terra e folhas secas no balde furado.',
                'Adicione restos de frutas, verduras e borra de café.',
                'Cubra sempre com folhas secas e mantenha à sombra.',
                'No calor, umedeça levemente 2x por semana. Em ~45 dias o adubo está pronto.'],
          now() - interval '4 days')
  returning id into p_tutorial;

  insert into public.posts (author_id, type, subtype, title, description, categories, tags, reward_coins, reward_xp, created_at)
  values (v_ids[8], 'discussion', 'Ideias', 'Como deixar Cuiabá mais arborizada?',
          'Com o calor batendo recorde, quais ruas e bairros mais precisam de sombra? Bora mapear e propor um mutirão de plantio para a prefeitura.',
          '{environment}', '{arborizacao,calor}', 5, 20, now() - interval '8 hours')
  returning id into p_disc;

  insert into public.posts (author_id, type, subtype, activity_kind, title, description, categories, tags,
                            reward_coins, reward_xp, location_text, city, state, created_at)
  values (v_ids[7], 'activity', 'Doação de itens', 'item_giveaway', 'Estou doando um fogão e 5 móveis',
          'Mudança de apartamento: fogão 4 bocas, sofá, mesa com 4 cadeiras e estante. Prioridade para famílias e projetos sociais. Retirada no CPA.',
          '{children}', '{doacao,moveis}', 20, 50, 'CPA I', 'Cuiabá', 'MT', now() - interval '5 hours')
  returning id into p_items;

  -- Comentários e curtidas.
  insert into public.comments (post_id, author_id, body, created_at) values
    (p_blood, v_ids[7], 'Vou com minha irmã! Precisa agendar?', now() - interval '20 hours'),
    (p_blood, v_ids[1], 'Não precisa, Ana. É só chegar com documento 💙', now() - interval '19 hours'),
    (p_fire, v_ids[6], 'Já doei e compartilhei nos stories! 🔥🚒', now() - interval '3 days'),
    (p_dog, v_ids[7], 'Que dó da Mel 😢 doei um pouquinho.', now() - interval '1 day'),
    (p_clean, v_ids[8], 'Vou de bike com a turma do pedal!', now() - interval '2 days'),
    (p_soup, v_ids[6], 'Quinta estou aí para servir.', now() - interval '6 hours'),
    (p_recycle, v_ids[4], 'Que demais! Os recicláveis podem vir para a nossa central.', now() - interval '10 hours'),
    (p_disc, v_ids[2], 'Av. CPA e região do Coxipó são as mais quentes nos nossos registros.', now() - interval '6 hours'),
    (p_tutorial, v_ids[7], 'Fiz a minha e funcionou! Dica: tampa sempre fechada por causa das moscas.', now() - interval '2 days');

  insert into public.post_likes (post_id, profile_id)
  select p, u from unnest(array[p_blood, p_fire, p_dog, p_clean, p_soup, p_recycle, p_tutorial, p_disc, p_items]) p
  cross join unnest(v_ids) u
  where (get_byte(decode(md5(p::text || u::text), 'hex'), 0) % 2) = 0;

  insert into public.participations (post_id, profile_id, status, reward_granted_at)
  select p, u, 'going', now() from unnest(array[p_blood, p_clean, p_soup]) p cross join unnest(v_ids[6:8]) u;
end $$;

-- Conta de teste para validar o app (login com senha, sem precisar do e-mail).
-- E-mail: teste@saveeasy.dev · senha: SaveEasy#2026 · começa sem perfil completo.
do $$
declare
  v_id uuid := 'b2000000-0000-4000-8000-000000000001';
begin
  if exists (select 1 from auth.users where id = v_id) then return; end if;
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password, raw_app_meta_data,
                          raw_user_meta_data, created_at, updated_at, email_confirmed_at,
                          confirmation_token, recovery_token, email_change_token_new, email_change)
  values (v_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'teste@saveeasy.dev',
          extensions.crypt('SaveEasy#2026', extensions.gen_salt('bf')),
          '{"provider":"email","providers":["email"]}', '{}', now(), now(), now(), '', '', '', '');
  insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
  values (gen_random_uuid(), v_id, v_id::text, 'email',
          jsonb_build_object('sub', v_id::text, 'email', 'teste@saveeasy.dev', 'email_verified', true),
          now(), now(), now());
end $$;

-- Entrega 2: stories, conversas e notificações de demonstração. Os stories
-- demo duram 7 dias (os reais duram 24h) para a bandeja não ficar vazia.
do $$
declare
  v_test uuid := 'b2000000-0000-4000-8000-000000000001';
  v_vida uuid := 'a1000000-0000-4000-8000-000000000001';
  v_pantanal uuid := 'a1000000-0000-4000-8000-000000000002';
  v_patas uuid := 'a1000000-0000-4000-8000-000000000003';
  v_eco uuid := 'a1000000-0000-4000-8000-000000000004';
  v_ludo uuid := 'a1000000-0000-4000-8000-000000000006';
  v_ana uuid := 'a1000000-0000-4000-8000-000000000007';
  v_pedro uuid := 'a1000000-0000-4000-8000-000000000008';
  v_direct bigint;
  v_group bigint;
begin
  if exists (select 1 from public.stories where author_id = v_vida) then return; end if;

  insert into public.stories (author_id, type, body, post_id, created_at, expires_at) values
    (v_vida, 'donation', 'Estoque de O- está crítico. Doe no Hemocentro esta semana!',
     (select id from public.posts where author_id = v_vida order by id limit 1),
     now() - interval '2 hours', now() + interval '7 days'),
    (v_pantanal, 'social_action', 'Brigada voluntária treinando hoje na Chapada. Bora?',
     null, now() - interval '5 hours', now() + interval '7 days'),
    (v_patas, 'event', 'Feira de adoção sábado no Parque das Águas. 30 cães e gatos esperando você.',
     null, now() - interval '8 hours', now() + interval '7 days'),
    (v_eco, 'ad', 'Leve seu reciclável no ecoponto da Av. do CPA e ganhe desconto parceiro.',
     null, now() - interval '3 hours', now() + interval '7 days'),
    (v_ludo, 'tutorial', 'Mostrei no feed como montar uma composteira de balde. Corre lá!',
     null, now() - interval '1 hour', now() + interval '7 days');

  if exists (select 1 from public.profiles where id = v_test) then
    insert into public.conversations (direct_key, last_message_at, last_message_preview)
    values (least(v_test::text, v_ana::text) || ':' || greatest(v_test::text, v_ana::text),
            now() - interval '20 minutes', 'Te vejo no mutirão então!')
    returning id into v_direct;
    insert into public.conversation_members (conversation_id, profile_id, last_read_at) values
      (v_direct, v_test, now() - interval '1 hour'), (v_direct, v_ana, now());
    insert into public.messages (conversation_id, author_id, body, created_at) values
      (v_direct, v_ana, 'Oi! Você vai no mutirão do Mãe Bonifácia?', now() - interval '2 hours'),
      (v_direct, v_test, 'Vou sim! Levo luvas extras.', now() - interval '90 minutes'),
      (v_direct, v_ana, 'Te vejo no mutirão então!', now() - interval '20 minutes');

    insert into public.conversations (is_group, owner_id, last_message_at, last_message_preview)
    values (true, v_vida, now() - interval '40 minutes', 'Obrigado a todos que doaram ontem!')
    returning id into v_group;
    insert into public.conversation_members (conversation_id, profile_id, last_read_at) values
      (v_group, v_vida, now()), (v_group, v_ana, now()), (v_group, v_pedro, now()),
      (v_group, v_test, now() - interval '3 hours');
    insert into public.messages (conversation_id, author_id, body, created_at) values
      (v_group, v_pedro, 'Alguém sabe se precisa agendar?', now() - interval '2 hours'),
      (v_group, v_vida, 'Não precisa! Só levar documento com foto.', now() - interval '100 minutes'),
      (v_group, v_vida, 'Obrigado a todos que doaram ontem!', now() - interval '40 minutes');

    insert into public.notifications (recipient_id, actor_id, kind, title, body, created_at) values
      (v_test, v_ana, 'follow', 'Ana Ribeiro começou a seguir você', '', now() - interval '1 day'),
      (v_test, null, 'system', 'Bem-vindo ao Save Easy Cuiabá!',
       'Participe de ações perto de você e ganhe moedas.', now() - interval '2 days');
  end if;
end $$;

-- Entrega 4: produtos das lojas de Cuiabá (vendas revertidas às causas).
do $$
begin
  if exists (select 1 from public.products) then return; end if;
  insert into public.products (seller_id, name, description, price, icon, stock) values
    ('a1000000-0000-4000-8000-000000000003', 'Camiseta Patas do Coxipó', 'Algodão, estampa de cão e gato. Renda vai para ração e castração.', 49.90, 'pets', 30),
    ('a1000000-0000-4000-8000-000000000003', 'Caneca Adote um Amigo', 'Cerâmica 300 ml.', 34.90, 'coffee', 20),
    ('a1000000-0000-4000-8000-000000000002', 'Ecobag Pantanal Vivo', 'Lona reciclada com ilustração de tuiuiú.', 29.90, 'eco', 50),
    ('a1000000-0000-4000-8000-000000000002', 'Kit sementes do Cerrado', 'Ipê, pequi e baru para plantar em casa.', 24.90, 'forest', 40),
    ('a1000000-0000-4000-8000-000000000004', 'Porta-copos de garrafa PET', 'Feito com material da coleta seletiva.', 19.90, 'recycle', null),
    ('a1000000-0000-4000-8000-000000000005', 'Cesta básica solidária', 'Você compra e a Mãos do Porto entrega a uma família.', 89.90, 'shopping_bag', null);
end $$;

-- Entrega 5: campanhas de anúncio ativas para a demonstração.
do $$
declare
  v_story bigint;
begin
  if exists (select 1 from public.ad_campaigns) then return; end if;
  insert into public.ad_campaigns (owner_id, format, plan, title, body, cta_label, link_url, cities, status, price,
                                   starts_at, ends_at)
  values ('a1000000-0000-4000-8000-000000000004', 'bar', 'monthly', 'Ecoponto da Av. do CPA',
          'Leve seu reciclável e ganhe desconto em parceiros.', 'Ver endereço', 'https://www.google.com/maps/search/ecoponto+cuiaba',
          array['Cuiabá', 'Várzea Grande'], 'active', 207.90, now(), now() + interval '30 days');
  insert into public.ad_campaigns (owner_id, format, plan, title, body, post_id, cities, status, price, starts_at, ends_at)
  select a1, 'boosted_post', 'monthly', p.title, '', p.id, array['Cuiabá'], 'active', 312.90, now(), now() + interval '30 days'
    from (select 'a1000000-0000-4000-8000-000000000003'::uuid as a1) x
    join public.posts p on p.author_id = x.a1 and p.type = 'donation'
   limit 1;
end $$;
