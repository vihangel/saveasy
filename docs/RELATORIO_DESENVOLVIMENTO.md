# Relatório de desenvolvimento · Save Easy

Documento vivo: cada entrega adiciona uma seção com o que foi feito, como validar
e o que ficou pendente. Ordem: mais recente primeiro.

Legenda: ✅ no Supabase · 🟡 ainda no mock local · ⏳ pendente

---

## Entrega 4 · Pagamentos (sandbox), doações, inscrições e loja (08/10/2026)

### Resumo
- Migration `20261008000009_payments_store.sql` (aplicada).
- Acabou o "saldo fictício" da carteira: tudo em R$ passa por **cobrança Pix**
  criada no banco (o valor é calculado no servidor). Hoje o ambiente está em
  **sandbox**: o checkout mostra QR/copia-e-cola e um botão "Simular pagamento
  aprovado". Em produção a confirmação vem só do gateway (webhook).
- Doação com **dinheiro** (Pix) ou com **moedas** (pagas pelo fundo de doações).
- Pacotes de moedas, inscrições em comunidades com planos do banco, loja com
  pedidos, estoque, avaliações e gestão do vendedor, painel financeiro com
  pedido de repasse.
- Edge Functions prontas no repositório (`supabase/functions/payment-pix`,
  `payment-webhook`) para Mercado Pago, **não publicadas** (precisam de credenciais).
- 34 testes automatizados (carteira reescrita + 4 rotas novas no overflow).

### Banco (o que entrou)
| Área | Tabelas | Regras principais |
| --- | --- | --- |
| Configuração | `private.settings` | `payments_mode` (sandbox/live), `coins_per_real` (100), `platform_fee_percent` (0), `min_reward_donation` (R$ 5) |
| Pagamentos | `payments` | Valor e descrição definidos pelo banco. Status pending → paid/expired/refunded. Entrega idempotente (`private.fulfill_payment`). Pix expira em 30 min (cron) |
| Doações | `donations` | Soma no "arrecadado" do post. Recompensa só a partir de R$ 5 e 1× por dia por campanha (evita farm de moedas com doações de R$ 1) |
| Fundo de doações | `fund_ledger` | Aporte inicial de R$ 500. Doação com moedas: 100 moedas = R$ 1 pagos pelo fundo; recusa se o fundo não tiver saldo. Recebe 30% dos anúncios na Entrega 5 |
| Moedas | `coin_packages` | 1.000 / 2.500 / 5.000 moedas (R$ 4,99 / 11,99 / 24,90) |
| Inscrições | `subscription_plans`, `community_subscriptions` | Toda comunidade ganha Mensal (R$ 9,90) e Anual (R$ 99) automaticamente; pode editar. Renovar soma o período; cancelar mantém até o fim do período. +50 moedas/+80 XP na 1ª inscrição |
| Loja | `products`, `orders`, `product_reviews` | Só comunidade e empresa vendem. Pedido nasce "aguardando pagamento"; pago baixa o estoque e dá +20 moedas/+30 XP. Vendedor marca enviado/entregue ou cancela (reembolso). Só quem comprou avalia (média automática) |
| Repasses | `payouts` | Só contas verificadas, mínimo R$ 10, até o disponível (doações + inscrições + vendas − taxa − repasses) |

### Funcionalidades e como validar

| # | Funcionalidade | Status | Como validar |
| --- | --- | :-: | --- |
| 56 | Checkout Pix (QR + copia e cola) | ✅ | Qualquer pagamento abre a folha "Pagar com Pix" |
| 57 | Simular pagamento aprovado (sandbox) | ✅ | Botão na folha; só funciona com `payments_mode = sandbox` |
| 58 | Pix real (Mercado Pago) | ⏳ | Pendência 8: credenciais + publicar as Edge Functions + trocar para `live` |
| 59 | Cartão de crédito / IAP nas lojas | ⏳ | Pendência 8; moedas no iOS/Android exigem compra no app (ver PRODUTO §6.4) |
| 60 | Doar com Pix | ✅ | Post de doação → Doar → valor → pagar. Arrecadado sobe; +moedas se ≥ R$ 5 |
| 61 | Doar com moedas | ✅ | Doar → aba Moedas → 100/500/1.000. Mostra a conversão e o saldo do fundo |
| 62 | Comprar pacote de moedas | ✅ | Carteira → Comprar moedas |
| 63 | Extrato com moedas e R$ | ✅ | Carteira → Histórico |
| 64 | Inscrever-se numa comunidade | ✅ | Perfil de comunidade → Inscrever-se → plano → pagar |
| 65 | Cancelar renovação | ✅ | Mesma tela, depois de inscrito |
| 66 | Editar planos (comunidade) | 🟡 | RPC `save_subscription_plan` pronta; falta a tela |
| 67 | Loja: vitrine, detalhe, avaliações | ✅ | Menu → Loja |
| 68 | Comprar produto (quantidade + endereço) | ✅ | Produto → Comprar → pagar. Estoque baixa |
| 69 | Meus pedidos + avaliar | ✅ | Loja → ícone de pedidos (ou Carteira → Meus pedidos) |
| 70 | Minha loja: criar/editar/remover produto | ✅ | Conta comunidade/empresa: Loja → ícone de loja → + Produto |
| 71 | Vendas: enviado / entregue / cancelar com reembolso | ✅ | Pedidos → aba Vendas |
| 72 | Painel financeiro + pedido de repasse | ✅ | Carteira → Painel financeiro (contas não pessoais) |
| 73 | Pagar repasses (admin) | ⏳ | Entra no painel admin da Entrega 6 |

### Validação feita
No navegador (conta de teste): doação de R$ 20 por Pix sandbox na "Cirurgia
da Mel" → tela de agradecimento com +50 moedas/+100 XP → loja → Camiseta →
quantidade/endereço → Pix → "Compra realizada" (estoque 30 → 29) → Carteira
com o extrato em R$ e moedas → Meus pedidos com "Avaliar" → planos de
inscrição do Instituto Pantanal Vivo. No SQL: confirmação repetida não
credita de novo, pacote de moedas, doação com moedas debitando o fundo,
inscrição com período, pedido → enviado, avaliação, painel financeiro do
vendedor e saldo do fundo.

### Pendências de configuração (novas)
8. **Gateway de pagamento** (sugestão: Mercado Pago, Pix com taxa baixa):
   criar conta PJ, gerar `MP_ACCESS_TOKEN`, cadastrar como secret das Edge
   Functions, publicar `payment-pix` e `payment-webhook` (esta com
   `verify_jwt = false`), configurar a URL do webhook no painel do Mercado
   Pago e só então mudar `private.settings.payments_mode` para `live`.
   Para moedas no iOS/Android, configurar compras no app (App Store/Play) —
   Pix no app para bens digitais não é permitido pelas lojas.

### Decisões tomadas nesta entrega (validar)
- **100 moedas = R$ 1** no fundo de doações; o fundo começa com R$ 500 da plataforma.
- Doação em dinheiro só dá moedas/XP a partir de **R$ 5** e uma vez por dia por campanha.
- Taxa da plataforma **0%** por enquanto (configurável).
- Planos padrão de toda comunidade: Mensal R$ 9,90 e Anual R$ 99.
- Benefícios da inscrição foram reescritos para só prometer o que existe.

### Problemas conhecidos
- O saldo em R$ antigo do modo mock deixou de existir na interface (no modo mock tudo é sandbox).

---

## Entrega 3 · Gamificação, convites e extras das ações (08/10/2026)

### Resumo
- Migration `20261008000008_gamification.sql` (aplicada).
- Recompensas e conquistas saíram do mock: catálogo, resgate, equipar e
  progresso calculados no banco.
- Novas telas: **Convide amigos**, **Participantes** (com check-in),
  **Pedidos do item** e **Atividades** (currículo + álbum). As abas
  Currículo/Álbum do perfil passaram a usar os dados reais.
- O detalhe da publicação ganhou: pessoas marcadas, participantes, "Meu
  check-in" (QR + código), atualizações da campanha, fotos de quem participou
  e "Quero receber" (doação de itens).
- 30 testes automatizados (3 novos + 4 rotas novas no teste de overflow).

### Banco (o que entrou)
| Área | Tabelas | Regras principais |
| --- | --- | --- |
| Recompensas | `rewards`, `user_rewards` | Catálogo no banco (13 itens, patrocinadores de Cuiabá). Resgate debita moedas pelo livro-razão. Equipar: 1 título, até 3 selos, 1 capa |
| Conquistas | `achievements`, `achievement_claims` | Diárias, semanais e gerais. O progresso é **contado no banco** (curtidas, comentários, stories, posts, participações, ações de meio ambiente, doações, convites, seguidos). Resgate 1× por período (fuso de Cuiabá) |
| Convites | `invites` | Código pessoal. Quem entra: +100 moedas (até 30 dias após o cadastro). Quem convida: +50 moedas/+20 XP na hora e **+1.000** quando o convidado chega ao nível 20 (trigger) |
| Check-in | `participations.checked_in_at` | Participante mostra QR/código de 6 caracteres; organizador digita o código ou marca Presente/Faltou. Presença dá +10 XP (uma vez) |
| Fotos | `post_photos` | Só autor ou quem confirmou presença envia. Viram o álbum do perfil |
| Atualizações | `post_updates` | Só o autor publica; avisa participantes e interessados (notificação) |
| Doação de itens | `item_requests` | Pedido → aceito/recusado → entregue. Entregue dá a recompensa do post a quem doou (1× por pedido) |
| Marcar pessoas | `post_mentions` | Até 20 por post; marcados recebem notificação |

RPCs novas: `rewards_catalog`, `rewards_by_ids`, `redeem_reward`,
`equip_rewards`, `my_achievements`, `claim_achievement`, `my_invite`,
`redeem_invite`, `action_resume`, `post_participants`, `my_checkin_code`,
`check_in`, `post_photos_list`, `add_post_photo`, `delete_post_photo`,
`profile_album`, `post_updates_list`, `add_post_update`,
`item_requests_for_post`, `request_item`, `update_item_request`,
`set_post_mentions`, `post_mentions_list`, `post_extras`.

### Funcionalidades e como validar

| # | Funcionalidade | Status | Como validar |
| --- | --- | :-: | --- |
| 40 | Catálogo de recompensas do banco | ✅ | Menu → Recompensas |
| 41 | Resgatar recompensa com moedas | ✅ | Abrir um item → Resgatar. Saldo cai; de novo mostra "Você já possui" |
| 42 | Equipar título e até 3 selos | ✅ | Editar perfil → escolher → Salvar. Aparece no perfil para todos |
| 43 | Equipar capa | 🟡 | O banco aceita (`p_cover_id`), mas a tela ainda não tem seletor de capa-recompensa |
| 44 | Conquistas diárias/semanais/gerais com progresso real | ✅ | Comentar algo → "Comente em 1 publicação" fica 1/1 → Resgatar (+10) |
| 45 | Convide amigos (código, copiar convite, usar código) | ✅ | Menu → Convide amigos. Com outra conta nova, usar o código |
| 46 | Recompensa de convite no nível 20 | ✅ | Automática (trigger); conferível em `coin_ledger` |
| 47 | Currículo de ações com filtro de período | ✅ | Perfil → aba Currículo (7 dias / 30 dias / 12 meses / tudo) |
| 48 | Álbum (fotos enviadas nas ações) | ✅ | Perfil → aba Álbum |
| 49 | Lista de participantes | ✅ | Detalhe de evento → Participantes → Ver todos |
| 50 | Check-in por QR/código | ✅ | Participante: "Meu check-in". Organizador: Participantes → digitar o código ou marcar Presente |
| 51 | Leitura do QR pela câmera | ⏳ | Hoje o organizador digita o código de 6 caracteres |
| 52 | Fotos de quem participou | ✅ | Detalhe → "Fotos de quem participou" → Adicionar. Segurar a foto remove |
| 53 | Atualizações de campanha | ✅ | Autor: detalhe → Atualizações → Publicar. Interessados recebem notificação |
| 54 | Doação de itens | ✅ | Post de atividade "doação de itens" → "Quero receber". Autor: Pedidos → Aceitar → Marcar entregue |
| 55 | Marcar pessoas na publicação | ✅ | Criar/editar publicação → "Marcar pessoas". Marcados recebem notificação |

### Validação feita (navegador, contra o Supabase real)
Detalhe do mutirão: participantes e "Meu check-in" com QR → lista de
participantes → catálogo de recompensas → resgate do selo Café Solidário
(1.155 → 755 moedas) → equipado em Editar perfil e exibido no perfil →
conquista diária resgatada (+10 moedas, +5 XP) → convite com código →
currículo com o mutirão. No SQL: check-in pelo código (+10 XP uma vez),
atualização notificando 4 pessoas, marcação, pedido → entrega com recompensa
para quem doou, convite (+100/+50), resgate duplicado e sem saldo recusados.
A conta de teste recebeu +1.000 moedas (`admin_adjustment`) para validar o resgate.

### Decisões tomadas nesta entrega (validar)
- "Compartilhe 1 boa ação" (diária) conta **stories publicados** no dia.
- Convite só vale nos primeiros 30 dias de conta; quem convida ganha 50 na
  hora (o protótipo falava em 250 sem regra; o banner foi corrigido).
- Doação de itens recompensa quem **doa** quando o item é entregue.
- Recompensas renomeadas para temas de Cuiabá/MT (Pantanal, Chapada,
  Guardião do Pantanal, Doador de Sangue).

### Problemas conhecidos
- Os itens resgatados no modo mock antes desta entrega não migram (só valia localmente).

---

## Entrega 2 · Stories, mensagens em tempo real e notificações (08/10/2026)

### Resumo
- Migration `20261008000007_stories_chat_notifications.sql` (aplicada).
- Stories, chat e notificações saíram do mock: no modo Supabase tudo vem do banco.
- **Tempo real** (Supabase Realtime): mensagens novas aparecem na conversa
  aberta, a lista de conversas se atualiza e os selos da barra inferior
  (Mensagens / Notificações) mudam sozinhos.
- Notificações **geradas pelo banco** (triggers), sem código no app.
- Lembrete automático 24h antes de evento/ação social (`pg_cron`, a cada 15 min).
- Seed com stories de Cuiabá, uma conversa direta, um grupo de comunidade e
  notificações para a conta de teste.
- 27 testes automatizados passando (3 novos: recompensa do story de anúncio,
  mensagem do Realtime sem duplicar, selos da barra).

### Banco (o que entrou)
| Área | Tabelas | Regras principais |
| --- | --- | --- |
| Stories | `stories`, `story_views` | Duram 24h. Bandeja = meus + de quem sigo + da minha cidade. 1º story do dia dá +20 moedas/+20 XP. Story de **propaganda** dá +20 moedas uma vez por story, no máx. 5 por dia. Só empresa/influenciador/comunidade publica propaganda. Expirados são apagados após 7 dias (cron) |
| Mensagens | `conversations`, `conversation_members`, `messages` | Conversa direta única por par (chave ordenada). Perfil de **comunidade** abre o **grupo** dela (a pessoa entra como membro). Só membros leem (RLS também filtra o Realtime). Não lidas por `last_read_at` |
| Notificações | `notifications` | Geradas por trigger: novo seguidor, comentário no meu post, resposta ao meu comentário, alguém vai participar, moedas recebidas, lembrete de evento (1 por pessoa e evento), sistema |

RPCs novas: `stories_tray`, `view_story`, `create_story`, `delete_story`,
`my_notifications`, `mark_notifications_read`, `unread_counts`,
`my_conversations`, `conversation`, `conversation_messages`, `message_by_id`,
`send_message`, `mark_conversation_read`, `open_conversation`,
`leave_conversation`.

### Funcionalidades e como validar

| # | Funcionalidade | Status | Como validar |
| --- | --- | :-: | --- |
| 25 | Bandeja de stories de Cuiabá | ✅ | Início → círculos no topo mostram Lu, Banco, EcoCuiabá, Instituto… |
| 26 | Story de propaganda dá moedas uma vez | ✅ | Abrir o story da EcoCuiabá → "+20 moedas". Abrir de novo não dá |
| 27 | Publicar story (+20 moedas no 1º do dia) | ✅ | "Seu story" → escrever → Publicar. O 2º do dia não dá moedas |
| 28 | Excluir o próprio story | ✅ | Abrir seu story → lixeira |
| 29 | Tocar no autor do story abre o perfil | ✅ | (antes dava "Perfil não encontrado") |
| 30 | Lista de conversas por Pessoas / Comunidades / Empresas | ✅ | Mensagens → Ana Ribeiro em Pessoas, Banco de Sangue em Comunidades |
| 31 | Conversa em **tempo real** | ✅ | Abrir a conversa em dois navegadores (duas contas) e mandar mensagem; aparece sem recarregar |
| 32 | Mensagem pelo perfil | ✅ | Perfil de alguém → ícone de mensagem. Pessoa/empresa = conversa direta; comunidade = grupo |
| 33 | Selos de não lidas na barra inferior | ✅ | Chegam/somem sozinhos; abrir a conversa zera |
| 34 | Notificações do banco, ao vivo | ✅ | Seguir alguém, comentar no post de outra conta, enviar moedas: a outra conta recebe na hora |
| 35 | Tocar na notificação | ✅ | Marca como lida e abre o post (ou o perfil de quem gerou) |
| 36 | "Ler todas" | ✅ | Zera o selo |
| 37 | Lembrete de evento (24h antes) | ✅ | Automático para quem confirmou presença; conferível em `cron.job` |
| 38 | Push no celular (fora do app) | ⏳ | Precisa de Firebase (FCM/APNs). Ver pendência 7 |
| 39 | "Online agora" nas conversas | ⏳ | Mostra o @ da pessoa no lugar; presença fica para depois |

### Validação feita (navegador, contra o Supabase real)
Feed com stories de Cuiabá e selos (4 mensagens, 2 notificações) → story da
EcoCuiabá deu +20 moedas → conversa com a Ana → mensagem enviada pelo banco
como a Ana apareceu **sem recarregar** → minha resposta não duplicou →
moedas enviadas pela Ana geraram notificação que apareceu ao vivo (selo foi
de 2 para 3) → "Ler todas" zerou → grupo do Banco de Sangue em Comunidades.
No SQL: conversa direta não duplica, membro de fora não lê mensagens (RLS),
conta pessoal não publica story de propaganda, 2º story do dia sem moedas.

### Pendências de configuração (novas)
7. **Push notifications**: criar projeto no Firebase (Android/iOS) e chave
   APNs da Apple. Depois disso, uma Edge Function envia o push a cada nova
   linha em `notifications`.

### Decisões tomadas nesta entrega (validar)
- Grupo de chat é **um por comunidade** e qualquer pessoa entra ao tocar em
  "Mensagem" no perfil. Moderação do grupo (remover membro, só admins
  falam) fica para a fase de moderação.
- Não há notificação para curtidas (evita excesso); mensagens só geram selo.
- Stories do seed duram 7 dias para a demo não ficar vazia (os reais duram 24h).
- Limite de 5 recompensas de story de propaganda por dia por pessoa.

### Problemas conhecidos
- Bloquear pessoa / denunciar conversa ainda não existe (Entrega 6).
- Conversa carrega as últimas 50 mensagens (sem "carregar mais" ainda).

---

## Entrega 1 · Fundação Supabase, conta, perfil e publicações (08/10/2026)

### Resumo
- Projeto Supabase `Saveeasy` (região `sa-east-1`, São Paulo).
- 6 migrations versionadas em `supabase/migrations/`, já aplicadas.
- Seed de demonstração com conteúdo de **Cuiabá-MT** (`supabase/seed.sql`).
- App com dois modos (`lib/app/dependencies.dart`):
  - `BACKEND=supabase` (padrão): conta, perfil, publicações, interações,
    participação e moedas no banco;
  - `BACKEND=mock`: tudo local, usado nos testes e para demo offline.
- Telas novas: cadastro com código de e-mail, completar perfil, configurações,
  seguidores/seguindo, salvos e edição/exclusão de publicação.
- 24 testes automatizados passando (inclui o detector de overflow em 3 tamanhos de tela).

### Banco (o que existe)
| Área | Tabelas | Regras principais |
| --- | --- | --- |
| Perfis | `profiles`, `profile_private`, `follows` | Perfil criado por trigger no cadastro; dados pessoais (nascimento, CEP, rua) só para o dono; colunas de sistema (moedas, XP, papel, contadores) bloqueadas para o app |
| Moedas/XP | `coin_ledger`, `xp_ledger` | Livro-razão imutável; saldo em `profiles.coins` só muda por função do banco; +100 moedas no cadastro |
| Publicações | `posts`, `post_reward_rules` | 7 tipos numa tabela com regras por tipo; recompensa definida pelo banco (não pelo autor); exclusão lógica; busca em português |
| Interações | `post_likes`, `post_interests`, `comments`, `comment_likes` | Contadores por trigger; "Tenho interesse"/salvar = seguir o post |
| Participação | `participations` | Recompensa **uma vez** por pessoa e post (corrige o bug do protótipo) |
| Storage | buckets `avatars`, `post-covers`, `stories` | Cada pessoa só escreve na própria pasta |

Funções de tela (RPC) que devolvem JSON no formato dos modelos do app:
`feed`, `post_detail`, `profile_page`, `my_profile`, `author_posts`,
`search_profiles`, `follow_list`, `my_interests`, `complete_profile`,
`update_my_profile`, `create_post`, `update_post`, `delete_post`,
`toggle_post_like`, `toggle_post_interest`, `share_post`, `add_comment`,
`toggle_comment_like`, `delete_comment`, `participate`, `cancel_participation`,
`toggle_follow`, `send_coins`, `delete_my_account`, `is_username_available`.

Verificado com SQL simulando um usuário logado: feed (popular, região,
seguindo, busca), detalhe, curtir, participar e cancelar (recompensa não
repete), enviar moedas, criar post (herda a cidade do autor), comentário,
bloqueio de alteração direta de moedas e de inserção direta de posts. Advisors
do Supabase revisados (ver "Pendências de configuração").

### Funcionalidades e como validar

| # | Funcionalidade | Status | Como validar |
| --- | --- | :-: | --- |
| 1 | Login com e-mail e senha | ✅ | Entrar com a conta de teste (abaixo). Senha errada mostra "E-mail ou senha inválidos." |
| 2 | Cadastro (e-mail, senha, termos) + código de 6 dígitos | ✅* | "Criar conta" → e-mail real → digitar o código recebido. *Depende de configurar o template do e-mail (pendência 1) |
| 3 | Completar perfil: tipo de conta → foto, nome, @, pronomes, nascimento → endereço com CEP | ✅ | Ao entrar com conta nova o app leva para o onboarding; @ repetido mostra erro; CEP preenche rua/cidade (ViaCEP); ao finalizar aparece "+100 moedas" |
| 4 | Sair do cadastro no 1º passo | ✅ | Voltar no "Tipo de conta" → diálogo → sai (a conta continua criada) |
| 5 | Recuperar senha com código de 6 dígitos | ✅* | "esqueceu a senha?" → código do e-mail → nova senha → entrar. *Pendência 1 |
| 6 | Login Google/Facebook | ⏳ | Botões ligados ao Supabase; falta configurar os provedores (pendência 3) |
| 7 | Feed: Popular / Região (Cuiabá) / Seguindo, busca e categorias | ✅ | Abas mudam a lista; "sangue" na busca acha o mutirão |
| 8 | Detalhe de publicação (post + autor + comentários numa chamada) | ✅ | Abrir qualquer card |
| 9 | Curtir, salvar ("Tenho interesse"), compartilhar | ✅ | Contadores mudam e persistem ao recarregar |
| 10 | Comentar e excluir o próprio comentário | ✅ | "Excluir" só aparece nos seus comentários |
| 11 | Participar / cancelar (evento, ação social, atividade) | ✅ | Participar → tela de confirmação com +moedas; cancelar e participar de novo **não** dá moedas outra vez |
| 12 | Criar publicação (7 tipos) com capa | ✅ | "+" → tipo → formulário → Criar. Capa vai para o bucket `post-covers` |
| 13 | **Editar** publicação | ✅ | ⋮ no detalhe (só autor) → Editar → Salvar |
| 14 | **Excluir** publicação | ✅ | ⋮ → Excluir → some do feed e do perfil |
| 15 | Perfil próprio e de outros, seguir/deixar de seguir | ✅ | Contadores atualizam |
| 16 | **Seguidores / Seguindo** | ✅ | Tocar nos números do perfil |
| 17 | Editar perfil: foto, **capa**, nome, @, bio, pronomes | ✅ | Configurações → Editar perfil. Título e selos ainda vêm do catálogo mock |
| 18 | **Configurações**: alterar senha, termos, privacidade, sair | ✅ | Ícone de engrenagem no perfil ou menu lateral |
| 19 | **Excluir conta** (LGPD) | ✅ | Configurações → Excluir conta → digitar EXCLUIR. Apaga tudo em cascata |
| 20 | **Salvos e interesses** | ✅ | Menu lateral → Salvos |
| 21 | Enviar moedas para o autor / amigo | ✅ | Débito e crédito no ledger; extrato na Carteira |
| 22 | Extrato de moedas na Carteira | ✅ | Mostra bônus, participação e envios |
| 23 | Doação em R$, compra de moedas, loja, inscrição em comunidade | ✅ | Migrados na Entrega 4 (Pix sandbox) |
| 24 | Stories, mensagens, notificações, recompensas, conquistas | ✅ | Migrados nas Entregas 2 e 3 |

**Conta de teste** (só desenvolvimento): definida em `supabase/seed.sql`
(bloco "Conta de teste"). A mesma conta já completou o onboarding e tem uma
participação e um comentário. Para testar o onboarding de novo, crie outra
conta pelo app.

### Validação feita (navegador, contra o Supabase real)
Login → onboarding (@ repetido recusado → @ livre) → CEP 78005-000 preenchido
pelo ViaCEP → feed com o conteúdo de Cuiabá e +100 moedas → participar do
mutirão (+25 moedas, 4 confirmados no banco) → comentar → criar discussão (+30
XP) → editar → excluir → perfil → configurações. Moedas, XP e ledger conferidos
direto no banco.

### Pendências de configuração (painel do Supabase, sem código)
1. **Templates de e-mail com código**: em *Authentication → Email Templates*,
   colocar `{{ .Token }}` nos templates *Confirm signup* e *Reset password*
   (hoje eles só têm o link). O app pede o código de 6 dígitos; o link também
   funciona depois do item 2.
2. **URLs de redirecionamento**: *Authentication → URL Configuration* →
   Site URL `https://vihangel.github.io/saveasy/` e Redirect URLs com
   `http://localhost:8765/**` e `app.saveeasy://login-callback`.
3. **Google e Facebook**: *Authentication → Providers* (client id/secret de
   cada console). No mobile, registrar o deep link `app.saveeasy://` no
   iOS (URL Types) e no Android (intent-filter).
4. **Proteção contra senhas vazadas**: *Authentication → Policies* → ativar
   "Leaked password protection" (advisor de segurança).
5. **Conta de teste**: o repositório é público e a senha dela está no
   `seed.sql`. Excluir essa conta (e as contas demo, `is_demo = true`) antes do
   lançamento ou ao criar o projeto de produção.
6. **SMTP próprio** antes de abrir para o público (o SMTP padrão do Supabase
   tem limite baixo de envios por hora).

### Decisões tomadas nesta entrega (validar)
- `is_username_available` só para usuários logados (o @ é escolhido depois do login).
- Quem pode criar **propaganda**: empresa, influenciador e comunidade (pessoa física não).
- Enviar moedas dá XP de metade do valor (regra herdada do protótipo). Pode
  virar farm entre contas; sugestão: XP só para o primeiro envio do dia por destinatário.
- Feed "Região" usa cidade/UF do perfil (padrão Cuiabá-MT) + tutoriais e eventos online.
- Ordenação "Popular" = curtidas + 2×comentários + 3×participantes + interesses
  (sem decaimento por idade ainda).

### Problemas conhecidos
- Telas ainda no mock (item 23–24) usam o usuário "espelhado" do Supabase:
  moedas gastas lá (resgatar recompensa, comprar pacote) não voltam para o banco.
- Stories mock mostram autores fora de Cuiabá.
- Paginação do feed por offset (30 por página); trocar por cursor quando houver volume.

### Próxima entrega sugerida
Stories, mensagens (Realtime) e notificações no Supabase (fase 4 do roadmap),
seguidos de recompensas/conquistas com catálogo no banco.
