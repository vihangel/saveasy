# Save Easy · Back-end no Supabase (documento interno)

> Rascunho de arquitetura a partir do app (`lib/`) e do protótipo completo do
> Figma. A **seção 13** traz o que o protótipo completo acrescentou. Produto,
> lacunas, monetização e roadmap estão em [PRODUTO_E_ROADMAP.md](PRODUTO_E_ROADMAP.md).
> As seções marcadas com **[DECIDIR]** precisam de definição antes de virar migration.

---

## 1. Princípios

1. **Supabase como back-end único**: Auth, Postgres (com RLS), Storage,
   Realtime, Edge Functions e Cron. Nada de servidor próprio.
2. **Acesso orientado a telas.** Cada tela faz **uma leitura principal** que já
   devolve tudo o que ela mostra (autor, contadores, "eu curti?", "eu participo?").
   Isso evita o app montando dados com várias chamadas (N+1).
   - **Leituras** → *views* com `security_invoker = true` (listas simples) ou
     funções RPC `security invoker` (telas compostas). A RLS continua valendo.
   - **Escritas simples** (curtir, comentar, seguir, editar perfil, mandar
     mensagem) → `insert/update/delete` direto na tabela, protegido por RLS.
   - **Escritas com regra de negócio** (doar, resgatar recompensa, enviar moedas,
     participar, comprar, criar publicação com XP) → **RPC `security definer`**
     que faz tudo numa transação: valida, grava, credita moedas/XP, atualiza
     conquistas e cria notificação. **O app nunca altera moedas, XP ou nível direto.**
3. **Os repositórios do app não mudam de assinatura.** Hoje eles falam com o
   `MockDatabase`; depois passam a chamar `supabase_flutter`. Cubits e telas
   continuam iguais.
4. **Contadores denormalizados** (curtidas, comentários, seguidores, arrecadado,
   participantes) mantidos por *trigger*. O feed não faz `count(*)`.
5. **Saldo de moedas = livro-razão (ledger).** Toda moeda que entra ou sai é uma
   linha em `coin_ledger`. O saldo em `profiles.coins` é um cache atualizado na
   mesma transação, e dá para auditar e recalcular a qualquer momento.

---

## 2. O que existe hoje no app (mapa funcional)

| Área | Telas (rotas) | O que faz |
| --- | --- | --- |
| Onboarding / Auth | `/`, `/welcome`, `/login`, `/forgot-password/*`, `/signup/*` | Splash, 3 boas-vindas, login (e-mail, Google, Facebook), recuperar senha por código, cadastro em 5 passos |
| Feed | `/home` | Stories, abas Popular / Região / Seguindo, busca, filtro por categoria, recomendados, cards |
| Publicação | `/post/:id`, `/post/:id/donate`, `/post/:id/confirmed` | Detalhe por tipo, curtir, salvar, compartilhar, comentar, seguir autor, doar, participar, enviar moedas ao autor |
| Criar | `/create`, `/create/:type`, `/create/ad-info` | 7 tipos de publicação, capa com imagem, tags, categorias, planos de propaganda |
| Stories | `/stories/:i`, `/stories/new` | Visualizar (marca como visto), criar (texto + imagem), +20 moedas ao ver anúncio |
| Perfis | `/profile`, `/users/:id`, `/profile/edit`, `/users/:id/subscribe` | Perfil próprio ou de terceiros, abas Publicações / Currículo / Álbum, seguir, editar (foto, título, selos), inscrição em comunidade |
| Social | `/messages`, `/messages/:id`, `/notifications` | Conversas Pessoas / Comunidades / Empresas, chat com post compartilhado, notificações |
| Economia | `/wallet`, `/wallet/send`, `/users/:id/send-coins` | Saldo R$, moedas, comprar pacotes, histórico, enviar moedas |
| Gamificação | `/rewards`, `/rewards/:id`, `/achievements` | Capas, selos e títulos (resgate com moedas), conquistas diárias e gerais |
| Loja | `/store`, `/store/:id` | Produtos das comunidades, comprar |

---

## 3. Níveis de perfil e permissões

### 3.1 Tipo de conta (`account_type`)
Já existe no app e é escolhido no cadastro:

| Valor | Rótulo | Para quem |
| --- | --- | --- |
| `personal` | Pessoal | Pessoa física que acompanha, ajuda e cria vaquinhas |
| `business` | Empresarial | Empresa que divulga boas ações e anúncios |
| `influencer` | Influenciador | Criador com público, mobiliza doações e patrocina itens |
| `community` | Comunidade | ONG / projeto sem fins lucrativos (recebe doações, tem loja e inscritos) |

### 3.2 Papel no sistema (`app_role`, novo)
Separado do tipo de conta: `user` (padrão), `moderator`, `admin`. Fica em
`profiles.role` e é usado nas policies de moderação e do painel.

### 3.3 Verificação (novo, recomendado)
`verification_status`: `unverified` · `pending` · `verified` · `rejected`.
Contas `community` e `business` precisam estar **verificadas (CNPJ/documentos)**
para receber dinheiro (doação, loja, inscrição). Sem isso, o app pode ser usado
para golpe de vaquinha. **[DECIDIR]**: se pessoas físicas podem criar vaquinha
sem verificação (o texto do tipo "Pessoal" diz que sim).

### 3.4 Matriz de permissões (proposta) **[DECIDIR]**

| Ação | personal | influencer | business | community |
| --- | :-: | :-: | :-: | :-: |
| Doação (vaquinha) | ✅ (limite / verificação) | ✅ | ✅ | ✅ |
| Evento | ✅ | ✅ | ✅ | ✅ |
| Ação social / Atividade | ✅ | ✅ | ✅ | ✅ |
| Tutorial / Discussão | ✅ | ✅ | ✅ | ✅ |
| Propaganda (impulsionar) | ✅* | ✅ | ✅ | ✅ |
| Story | ✅ | ✅ | ✅ | ✅ |
| Receber inscrição (assinatura) | ❌ | ✅? | ❌ | ✅ |
| Ter loja | ❌ | ❌ | ✅? | ✅ |
| Patrocinar recompensa (capa/selo/título) | ❌ | ✅ | ✅ | ✅ |
| Avaliação (nota ⭐ no perfil) | ❌ | ❌ | ✅ | ✅ |

\* No Figma: "propaganda **ou currículo de boas ações**". Pessoa física pode
impulsionar o próprio currículo.

A matriz vira uma função `private.can_create_post(account_type, post_type)` usada
na policy de insert de `posts` e na RPC `create_post`.

---

## 4. Regras de negócio

> Hoje as regras estão nos repositórios mockados (`lib/shared/data/repositories`).
> No back-end, elas vão para as RPCs.

### 4.1 Conta e autenticação
- Login por e-mail/senha, Google e Facebook (Supabase Auth). **Confirmação de
  e-mail obrigatória** (o passo 5 do cadastro já fala em "link de ativação").
- O cadastro coleta os dados em 5 passos e chama `signUp` **só no fim**, enviando
  nome, @, pronomes, nascimento, tipo, endereço e opt-in em `options.data`. Um
  trigger `on auth.users insert` cria a linha em `profiles`.
- `username`: único, sem diferenciar maiúsculas (`citext` ou índice em `lower()`),
  só `[a-z0-9._]`, de 3 a 30 caracteres. A RPC pública `is_username_available(text)`
  serve para validar no passo 3.
- E-mail único (garantido pelo Auth).
- Recuperar senha: Supabase manda um código OTP de **6 dígitos** e o protótipo
  usa 5. **Ajustar a tela para 6.**
- Pronomes: `ele_dele` · `ela_dela` · `elu_delu` (enum, com opção de texto livre no futuro).
- Idade mínima **[DECIDIR]** (sugestão: 13 anos, ou 18 para movimentar dinheiro).
- Bônus de boas-vindas: o mock dá **+100 moedas** ao criar a conta.

### 4.2 Nível e XP
- `level = floor(xp / 300) + 1` (regra atual, constante `xpPerLevel`).
  **[DECIDIR]** curva progressiva (ex.: 300 × nível) para não ficar linear demais.
- XP nunca diminui. Só RPCs concedem XP, sempre registrando em `xp_ledger`.
- Tabela de XP/moedas atual (no mock):

| Evento | XP | Moedas |
| --- | --: | --: |
| Criar publicação | +30 | 0 |
| Doar | `post.reward_xp` (50–150) | `post.reward_coins` (10–150) |
| Participar de evento/ação/atividade | `post.reward_xp` | `post.reward_coins` |
| Enviar moedas | moedas ÷ 2 | −moedas |
| Comprar na loja | +30 | +20 |
| Inscrever-se em comunidade | +80 | +50 |
| Publicar story | +20 | +20 |
| Assistir story de anúncio (1×) | 0 | +20 |
| Resgatar conquista | 0 | `achievement.reward_coins` |
| Cadastro | 0 | +100 |

**[DECIDIR]** recompensa de doação fixa por post (como hoje) ou proporcional
ao valor doado. Fixa permite farmar com doações de R$ 1. Sugestão: valor mínimo
para ganhar recompensa, com teto diário.

### 4.3 Moedas (moeda virtual)
- Inteiro, nunca negativo (`check (coins >= 0)` em `profiles` e validação na RPC).
- **Não são convertíveis em dinheiro.** Servem para resgatar recompensas e para
  enviar a outras pessoas (apoio).
- Pacotes atuais: 1.000 / 2.500 / 5.000 por R$ 4,99 / 11,99 / 24,90 (tabela
  `coin_packages`, editável sem deploy).
- Enviar moedas: valor > 0, saldo suficiente, não pode enviar para si mesmo.
  Mensagem opcional (até 140 caracteres). Gera notificação para quem recebe.

### 4.4 Dinheiro (R$) **[DECIDIR, ponto crítico]**
O protótipo tem um **"saldo em R$" dentro do app** que paga doação, loja,
inscrição e moedas. Guardar dinheiro de usuário é atividade regulada (instituição
de pagamento) e um risco grande. **Recomendação:**
- **Não ter saldo em R$.** Cada pagamento vai **direto para um gateway** (Pix /
  cartão via Mercado Pago, Stripe ou Asaas), com *split* para a comunidade
  recebedora.
- A "Carteira" passa a mostrar **moedas + histórico de pagamentos**.
- A tabela `payments` registra a intenção e o status, e o webhook (Edge Function)
  confirma. Só depois do `paid` a doação soma em `raised_amount` e as
  recompensas são liberadas.
- O botão "Adicionar saldo" do protótipo sai.

### 4.5 Publicações
Comum a todos os tipos: título (3–120), descrição (até 5.000), capa opcional,
categorias (1 ou mais, enum), tags (até 10, texto livre normalizado em minúsculas),
`subtype` (lista por tipo, ver 5.2), visibilidade, status.

| Tipo | Campos específicos | Regras |
| --- | --- | --- |
| `donation` | `target_amount` (> 0), `ends_at` (obrigatório, exceto recorrente), `recurring`, `location` opcional | Arrecadado só soma pagamentos confirmados. Encerrada após `ends_at` (não aceita doação). Meta pode ser ultrapassada **[DECIDIR]** |
| `event` | `starts_at` (obrigatório, futuro), `ends_at` (> início), `location` **ou** `link`, `capacity` opcional | Confirmar presença até o fim. Lotado = `attending_count >= capacity`. Status Finalizado após `ends_at` |
| `social_action` | `starts_at` opcional, `location` | Participar / sair |
| `activity` | `location` (obrigatório), `capacity` | Participar / sair. Nota do Figma: "retirar data e tipo" |
| `tutorial` | `duration_minutes`, `steps text[]` | — |
| `discussion` | — | Foco em comentários |
| `ad` | `ad_plan` (diário / semanal / mensal), alvo (post ou currículo) | Pago, vira `ad_campaigns` com período de exibição |

- Autor pode editar (exceto tipo, meta já atingida e datas passadas) e
  arquivar. Exclusão é **soft delete** (`deleted_at`), porque doações apontam
  para o post.
- `reward_coins` e `reward_xp` **não são definidos pelo autor**: vêm de uma
  tabela de regras por tipo (`post_reward_rules`), para ninguém criar "evento
  que paga 10.000 moedas".

### 4.6 Participação (evento, ação social, atividade)
- Uma participação por pessoa e post (`unique (post_id, profile_id)`).
- **Bug do protótipo a não repetir:** hoje confirmar → cancelar → confirmar dá
  recompensa toda vez. Regra: **a recompensa sai uma única vez**
  (`reward_granted_at`).
- **[DECIDIR]** quando dar a recompensa: ao confirmar (simples, fácil de
  burlar) ou no **check-in** (QR code / organizador marca presença,
  `status = attended`). Sugestão: no confirmar dá só o XP; as moedas saem no check-in.
- Status: `going` · `cancelled` · `attended` · `no_show`.

### 4.7 Interações
- Curtir / salvar: uma linha por pessoa (tabelas de junção). Hoje é um booleano
  global no post (bug do mock).
- Compartilhar: contador mais registro (`post_shares`) para métricas.
- Comentários: até 1.000 caracteres, com **respostas** (`parent_id`, um nível).
  Curtida em comentário. Autor do comentário e do post podem apagar.
- Seguir: não pode seguir a si mesmo. Contadores de seguidores/seguindo por trigger.

### 4.8 Stories
- Duram **24 h** (`expires_at`); um cron limpa. Hoje não expiram.
- Visto é **por pessoa** (`story_views`); hoje é global.
- Pode apontar para uma publicação (`post_id`) e ter imagem.
- Anúncio em story: +20 moedas **uma vez por pessoa e por campanha**.

### 4.9 Gamificação
- **Recompensas** (capa, selo, título): catálogo com preço em moedas,
  patrocinador (`sponsor_id` → perfil influencer/comunidade/empresa), ativo/inativo,
  estoque opcional, e opcionalmente **exclusiva para inscritos** de uma comunidade
  (o onboarding promete "desbloquear itens diretamente dos influencers").
- Posse **por pessoa** (`user_rewards`), comprada uma vez só.
- Equipar: no máximo **1 capa, 1 título e 3 selos** (regra atual de 3 selos).
- **Conquistas**: definição (`achievements`) com métrica, meta, recompensa e
  período (`once` / `daily` / `weekly`). Progresso **por pessoa** (`user_achievements`).
  O progresso é atualizado pelas RPCs e triggers. As diárias "zeram" pelo
  `period_start`, sem apagar linhas. Resgatar: só completas, uma vez por período.
- Métricas que já aparecem no app: `donations_count`, `recycle_activities`,
  `events_attended`, `friends_invited`, `likes_given`, `comments_made`, `shares_made`.

### 4.10 Comunidades: inscrição e loja
- Inscrição = assinatura paga (Mensal R$ 9,90 / Anual R$ 99,00 hoje). Planos
  por comunidade (`subscription_plans`), status `active` / `past_due` / `cancelled` /
  `expired`, `current_period_end`. Renovação via gateway.
- Benefícios: selo de apoiador, itens exclusivos, chat de apoiadores, +50 moedas
  por mês (cron mensal).
- Loja: produtos com preço, estoque, imagens, seção. Pedido (`orders`) com
  status de pagamento e entrega **[DECIDIR]** (retirada, frete, digital?). Nota
  ⭐ do produto e da comunidade vem de avaliações (`reviews`), não é fixa.

### 4.11 Mensagens
- Conversa direta (2 pessoas) ou grupo de comunidade (membros = apoiadores/seguidores
  **[DECIDIR]**). As abas Pessoas / Comunidades / Empresas são um filtro pelo tipo
  de conta do outro participante.
- Não lidas = mensagens depois de `last_read_at` do membro.
- Mensagem pode compartilhar um post (`shared_post_id`).
- Realtime no canal da conversa. Bloquear usuário **[DECIDIR]**.

### 4.12 Notificações
Geradas **no banco** (dentro das RPCs e triggers), nunca pelo app: nova
doação na sua campanha, novo seguidor, comentário/resposta, moedas recebidas,
lembrete de evento (cron 24 h antes), conquista desbloqueada, inscrição nova.
Push via Edge Function (FCM) disparada por *database webhook*.

### 4.13 Moderação (não existe no protótipo, recomendado)
Denúncia de post, comentário, perfil e mensagem (`reports`). Moderador oculta
conteúdo (`status = hidden`). Necessário antes de abrir doações ao público.

---

## 5. Tipos (enums)

Os valores batem com os `@JsonValue` atuais do app, para não quebrar os modelos.

```sql
create type account_type        as enum ('personal', 'business', 'influencer', 'community');
create type app_role            as enum ('user', 'moderator', 'admin');
create type verification_status as enum ('unverified', 'pending', 'verified', 'rejected');
create type pronouns            as enum ('ele_dele', 'ela_dela', 'elu_delu');

create type post_type      as enum ('donation', 'event', 'social_action', 'activity', 'tutorial', 'discussion', 'ad');
create type post_category  as enum ('education', 'health', 'animal', 'environment', 'children', 'culture');
create type post_status    as enum ('draft', 'published', 'finished', 'archived', 'hidden');

create type participation_status as enum ('going', 'cancelled', 'attended', 'no_show');

create type reward_kind      as enum ('cover', 'badge', 'title');
create type achievement_period as enum ('once', 'daily', 'weekly');

create type coin_reason as enum (
  'signup_bonus', 'coin_purchase', 'donation_reward', 'participation_reward',
  'post_created', 'story_created', 'ad_viewed', 'coins_sent', 'coins_received',
  'reward_redeemed', 'achievement_claimed', 'store_purchase_reward',
  'subscription_reward', 'admin_adjustment'
);

create type payment_purpose as enum ('donation', 'coin_package', 'store_order', 'subscription', 'ad_campaign');
create type payment_status  as enum ('pending', 'paid', 'failed', 'refunded', 'cancelled');
create type payment_method  as enum ('pix', 'card', 'boleto');

create type subscription_status as enum ('active', 'past_due', 'cancelled', 'expired');
create type subscription_interval as enum ('month', 'year');
create type ad_plan          as enum ('daily', 'weekly', 'monthly');
create type ad_status        as enum ('pending_payment', 'active', 'finished', 'rejected');
create type order_status     as enum ('pending_payment', 'paid', 'shipped', 'delivered', 'cancelled');
create type store_section    as enum ('popular', 'top_rated', 'nearby');   -- calculada, ver 7

create type conversation_kind as enum ('direct', 'community_group');
create type notification_type as enum (
  'donation_received', 'new_follower', 'comment', 'comment_reply', 'coins_received',
  'event_reminder', 'achievement_completed', 'subscription_new', 'post_liked', 'system'
);
create type report_target as enum ('post', 'comment', 'profile', 'message', 'story');
create type report_status as enum ('open', 'reviewing', 'actioned', 'dismissed');
```

`subtype` fica como `text` + tabela de referência (`post_subtypes(type, slug, label)`),
porque a lista muda com frequência (Vaquinha, Doação recorrente, Presencial, Online…).

---

## 6. Tabelas

Convenções:
- `snake_case`;
- `timestamptz` com `created_at default now()`;
- IDs `bigint generated always as identity`, exceto `profiles.id` (= `auth.users.id`, uuid);
- dinheiro em `numeric(12,2)`;
- índice em toda FK;
- RLS ligada em **todas** as tabelas.

### 6.1 Identidade
| Tabela | Colunas principais | Observações |
| --- | --- | --- |
| `profiles` | `id uuid pk → auth.users`, `username citext unique`, `name`, `account_type`, `role`, `pronouns`, `bio`, `avatar_path`, `birth_date`, `verification_status`, `xp`, `level` (gerada), `coins` (cache do ledger, `>= 0`), `followers_count`, `following_count`, `posts_count`, `rating_avg`, `rating_count`, `equipped_title_id`, `equipped_cover_id`, `email_news`, `city`, `state`, `created_at`, `deleted_at` | `email` fica no Auth (não duplicar). Leitura pública só dos campos públicos (view `public_profiles`) |
| `profile_addresses` | `profile_id pk`, `cep`, `street`, `complement`, `city`, `state`, `lat`, `lng` | **Privado** (só o dono). Cidade e UF copiadas para `profiles` para o feed "Região" |
| `follows` | `follower_id`, `followed_id`, `created_at` · pk composta | `check (follower_id <> followed_id)` |
| `organization_details` | `profile_id pk`, `legal_name`, `document (CNPJ)`, `payout_account_id`, `verified_at` | Comunidade e empresa. Só dono e admin |

### 6.2 Conteúdo
| Tabela | Colunas principais | Observações |
| --- | --- | --- |
| `posts` | `id`, `author_id`, `type`, `subtype`, `status`, `title`, `description`, `cover_path`, `categories post_category[]`, `tags text[]`, `reward_coins`, `reward_xp`, contadores (`likes_count`, `comments_count`, `shares_count`, `saves_count`, `participants_count`), **doação**: `target_amount`, `raised_amount`, `recurring`, **agenda**: `starts_at`, `ends_at`, `location_text`, `city`, `state`, `link_url`, `capacity`, **tutorial**: `duration_minutes`, `steps text[]`, `created_at`, `updated_at`, `deleted_at` | **Uma tabela só** com colunas por tipo e `check` por tipo (ex.: `type <> 'donation' or target_amount > 0`). Isso mantém o feed sem joins. GIN em `categories` e `tags` |
| `post_likes` · `post_saves` | `post_id`, `profile_id`, `created_at` · pk composta | Triggers atualizam contadores |
| `post_shares` | `id`, `post_id`, `profile_id`, `channel`, `created_at` | Métrica |
| `comments` | `id`, `post_id`, `author_id`, `parent_id` (resposta), `body`, `likes_count`, `replies_count`, `created_at`, `deleted_at` | |
| `comment_likes` | `comment_id`, `profile_id` · pk | |
| `participations` | `post_id`, `profile_id`, `status`, `checked_in_at`, `reward_granted_at`, `created_at` · pk composta | Regras em 4.6 |
| `stories` | `id`, `author_id`, `post_id?`, `post_type`, `body`, `image_path`, `ad_campaign_id?`, `created_at`, `expires_at` | |
| `story_views` | `story_id`, `profile_id`, `viewed_at`, `rewarded` · pk | |

### 6.3 Dinheiro e moedas
| Tabela | Colunas principais | Observações |
| --- | --- | --- |
| `payments` | `id`, `payer_id`, `purpose`, `amount`, `method`, `status`, `gateway`, `gateway_ref`, `metadata jsonb`, `created_at`, `paid_at` | Escrita só por RPC/Edge Function |
| `donations` | `id`, `post_id`, `donor_id`, `payment_id`, `amount`, `message`, `anonymous`, `created_at` | Soma em `posts.raised_amount` quando o pagamento vira `paid` |
| `coin_packages` | `id`, `coins`, `price`, `active` | |
| `coin_ledger` | `id`, `profile_id`, `amount int` (±), `reason coin_reason`, `ref_table`, `ref_id`, `counterpart_id?`, `note`, `created_at` | **Imutável** (sem update/delete). Fonte da verdade do saldo |
| `xp_ledger` | `id`, `profile_id`, `amount`, `reason`, `ref_table`, `ref_id`, `created_at` | Idem para XP |

A tela de histórico da Carteira é uma view `wallet_history` que une `coin_ledger`
e `payments` do usuário.

### 6.4 Gamificação
| Tabela | Colunas principais |
| --- | --- |
| `rewards` | `id`, `kind`, `name`, `description`, `icon`, `image_path`, `price_coins`, `sponsor_id`, `subscribers_only_of?`, `stock?`, `active` |
| `user_rewards` | `profile_id`, `reward_id`, `acquired_at`, `equipped` · pk composta |
| `achievements` | `id`, `code`, `title`, `description`, `metric`, `goal`, `reward_coins`, `period`, `active` |
| `user_achievements` | `profile_id`, `achievement_id`, `period_start date`, `progress`, `completed_at`, `claimed_at` · pk (`profile_id`, `achievement_id`, `period_start`) |
| `post_reward_rules` | `post_type`, `subtype?`, `reward_coins`, `reward_xp` |

### 6.5 Comunidades, loja e anúncios
| Tabela | Colunas principais |
| --- | --- |
| `subscription_plans` | `id`, `community_id`, `name`, `price`, `interval`, `benefits text[]`, `active` |
| `subscriptions` | `id`, `plan_id`, `community_id`, `subscriber_id`, `status`, `current_period_end`, `gateway_ref`, `created_at` · unique ativa por (comunidade, assinante) |
| `products` | `id`, `seller_id`, `name`, `description`, `price`, `stock`, `image_paths text[]`, `rating_avg`, `rating_count`, `active` |
| `orders` | `id`, `product_id`, `buyer_id`, `quantity`, `unit_price`, `status`, `payment_id`, `shipping jsonb`, `created_at` |
| `reviews` | `id`, `target_profile_id?`, `product_id?`, `author_id`, `rating 1..5`, `body` |
| `ad_campaigns` | `id`, `owner_id`, `post_id?`, `promotes_resume bool`, `plan`, `price`, `status`, `starts_at`, `ends_at`, `payment_id` |

### 6.6 Social
| Tabela | Colunas principais |
| --- | --- |
| `conversations` | `id`, `kind`, `community_id?`, `last_message_at`, `last_message_preview` |
| `conversation_members` | `conversation_id`, `profile_id`, `last_read_at`, `muted` · pk |
| `messages` | `id`, `conversation_id`, `sender_id`, `body`, `shared_post_id?`, `created_at`, `deleted_at` |
| `notifications` | `id`, `recipient_id`, `type`, `actor_id?`, `post_id?`, `title`, `body`, `data jsonb`, `read_at`, `created_at` |
| `reports` | `id`, `reporter_id`, `target_type`, `target_id`, `reason`, `status`, `handled_by`, `created_at` |
| `blocks` | `blocker_id`, `blocked_id` · pk |

### 6.7 Storage (buckets)
| Bucket | Público | Caminho | Uso |
| --- | :-: | --- | --- |
| `avatars` | sim | `{profile_id}/{uuid}.jpg` | Foto de perfil |
| `post-covers` | sim | `{author_id}/{uuid}.jpg` | Capa das publicações |
| `stories` | sim | `{author_id}/{uuid}.jpg` | Apagado junto com o story (cron) |
| `products` | sim | `{seller_id}/{uuid}.jpg` | Loja |
| `documents` | **não** | `{profile_id}/...` | Verificação de ONG/empresa |

Policy de escrita: o primeiro segmento do caminho = `auth.uid()`. O app já
redimensiona para 1080 px com qualidade 80 (`MediaPickerService`). No modelo, a
`avatarUrl` / `imageUrl` de hoje vira o **path** do Storage.

---

## 7. Acesso orientado a telas

Uma chamada principal por tela. "View" = `security_invoker`, filtrável via
PostgREST. "RPC" = função que devolve `jsonb` ou `setof` com o formato do modelo.

| Tela | Leitura | Escritas |
| --- | --- | --- |
| Splash / sessão | `auth.getSession()` + `select * from my_profile` (view com saldo, nível, título e selos equipados) | — |
| Cadastro | `rpc is_username_available(text)` | `auth.signUp(data: …)` → trigger cria `profiles` + `profile_addresses` + `+100` no ledger |
| Feed | `rpc feed(tab, category?, query?, cursor?, limit)` → `post_card[]` (autor, contadores, `liked_by_me`, `saved_by_me`, `i_participate`) · `rpc stories_tray()` (agrupado por autor, `seen_by_me`) | `post_likes` insert/delete · `rpc share_post` |
| Detalhe do post | `rpc post_detail(post_id)` → post + autor (`i_follow`) + 20 comentários + recompensa | `post_likes`, `post_saves`, `comments` (insert), `comment_likes`, `follows`, `rpc participate(post_id)` / `rpc cancel_participation` |
| Doar | reaproveita `post_detail` | `rpc create_donation(post_id, amount, method)` → devolve dados do Pix · webhook confirma → `rpc` interna `confirm_payment` |
| Evento confirmado | `post_detail` + `my_profile` | — |
| Criar publicação | `select from post_subtypes`, `coin` / `ad` planos | upload capa → `rpc create_post(payload jsonb)` (valida matriz, aplica `post_reward_rules`, +30 XP) |
| Stories | `rpc stories_tray()` | `rpc view_story(story_id)` (marca visto + recompensa de anúncio) · `rpc create_story(...)` |
| Perfil | `rpc profile_page(profile_id)` → perfil público, `i_follow`, `i_subscribe`, selos/título, contadores | `follows` · navegação |
| Perfil > Publicações / Álbum | view `post_cards` filtrada por `author_id`, cursor | — |
| Perfil > Currículo | `rpc action_resume(profile_id)` (XP, totais por tipo, doações públicas) | — |
| Editar perfil | `my_profile` + `my_rewards` | upload avatar · `profiles` update (campos permitidos) · `rpc equip_rewards(title_id, cover_id, badge_ids[])` |
| Inscrição | `rpc community_subscription_page(community_id)` (planos, benefícios, já inscrito?) | `rpc start_subscription(plan_id)` → pagamento |
| Mensagens | view `my_conversations` (outro participante, prévia, não lidas) filtrada pelo tipo | — |
| Chat | `messages` paginado por `conversation_id` (cursor) + Realtime | `messages` insert · `rpc mark_read(conversation_id)` · `rpc open_direct_conversation(profile_id)` |
| Notificações | `notifications` (minhas, cursor) + Realtime | `rpc mark_notifications_read()` |
| Carteira | `my_profile` + view `wallet_history` (cursor) + `coin_packages` | `rpc buy_coin_package(package_id)` → pagamento |
| Enviar moedas | `public_profiles` (busca) | `rpc send_coins(to_id, amount, message)` |
| Recompensas | `rpc rewards_page()` (catálogo por tipo + `owned_by_me` + `my_profile`) | `rpc redeem_reward(reward_id)` |
| Conquistas | `rpc achievements_page()` (definição + meu progresso do período atual) | `rpc claim_achievement(achievement_id)` |
| Loja | `rpc store_page(query?)` (agrupado por seção) | `rpc create_order(product_id, qty)` → pagamento |
| Menu lateral | `my_profile` (já em memória no `SessionCubit`) | `auth.signOut()` |

### 7.1 Exemplo: o card do feed
```sql
create view public.post_cards with (security_invoker = true) as
select
  p.id, p.type, p.subtype, p.status, p.title, left(p.description, 200) as excerpt,
  p.cover_path, p.categories, p.tags, p.created_at,
  p.likes_count, p.comments_count, p.shares_count, p.participants_count,
  p.target_amount, p.raised_amount, p.recurring, p.starts_at, p.ends_at,
  p.location_text, p.city, p.state, p.link_url, p.capacity, p.duration_minutes,
  p.reward_coins, p.reward_xp,
  a.id as author_id, a.name as author_name, a.username as author_username,
  a.avatar_path as author_avatar_path, a.account_type as author_type,
  exists (select 1 from post_likes  l where l.post_id = p.id and l.profile_id = (select auth.uid())) as liked_by_me,
  exists (select 1 from post_saves  s where s.post_id = p.id and s.profile_id = (select auth.uid())) as saved_by_me,
  exists (select 1 from participations x where x.post_id = p.id and x.profile_id = (select auth.uid()) and x.status = 'going') as i_participate
from posts p
join profiles a on a.id = p.author_id
where p.deleted_at is null and p.status in ('published', 'finished');
```
O `Post` do app já tem quase todos esses campos (`liked`, `saved`, `confirmed`,
`authorName`, `authorType`, `authorAvatarUrl`…). Basta configurar
`fieldRename: FieldRename.snake` no `build.yaml`.

### 7.2 Regras do feed
- **Popular**: `order by` uma pontuação (curtidas + comentários×2 +
  participantes×3 + doações) com decaimento por idade. Coluna `hot_score`
  recalculada por trigger ou cron a cada 10 min.
- **Região**: posts com `city/state` iguais aos do perfil, mais posts sem local
  (online e tutoriais). Raio em km depois, com PostGIS em `lat/lng`.
- **Seguindo**: `author_id in (seguidos) or author_id = eu`, por `created_at desc`.
- Paginação **por cursor** (`created_at, id`), nunca `offset`. Busca textual com
  `tsvector` (português) em título, descrição e tags.

---

## 8. Segurança (RLS)

- RLS ligada em todas as tabelas. Nas policies, usar `(select auth.uid())` (avaliado
  uma vez por consulta) e indexar a coluna usada.
- `profiles`: `select` público pela view `public_profiles` (sem dados sensíveis).
  `update` só do dono, e **colunas protegidas** (`coins`, `xp`, `role`,
  `verification_status`, contadores) são bloqueadas por trigger ou por grant de
  colunas. Só RPCs alteram essas colunas.
- `posts`: `select` publicados ou meus. `insert` só via `create_post`. `update`
  e `delete` lógico só do autor e só em campos editáveis.
- Tabelas de junção (likes, saves, follows, comment_likes): `insert/delete` só
  com `profile_id = auth.uid()`.
- `coin_ledger`, `xp_ledger`, `payments`, `donations`, `user_rewards`,
  `user_achievements`: **somente leitura** para o dono. Escrita só por RPC
  `security definer` (em schema `private` quando interna, com `search_path = ''`
  e checagem de `auth.uid()` no corpo).
- `messages` e `conversations`: só membros da conversa.
- `notifications`: só o destinatário (update apenas em `read_at`).
- `profile_addresses` e `organization_details`: só o dono e admin.
- Storage: escrita só na pasta `{auth.uid()}/`.
- Chave `service_role` **só** nas Edge Functions, nunca no app.

---

## 9. Peças além do banco

| Peça | Uso |
| --- | --- |
| **Auth** | E-mail/senha com confirmação, Google, Facebook, OTP de recuperação. Redirect para web (`vihangel.github.io/saveasy`) e deep link mobile |
| **Realtime** | `messages` (por conversa), `notifications` (por destinatário). Opcional: contador de arrecadação no detalhe da doação |
| **Edge Functions** | `payments-create` (cria cobrança Pix/cartão no gateway) · `payments-webhook` (confirma e chama `confirm_payment`) · `push-dispatch` (FCM a partir de `notifications`) |
| **Cron (pg_cron)** | Expirar stories (de hora em hora) · marcar eventos/doações como `finished` · lembrete de evento 24 h antes · `hot_score` · moedas mensais de inscritos · fechar campanhas de anúncio |
| **Database webhooks** | `notifications` insert → `push-dispatch` |

---

## 10. Simplificações do protótipo que **não** podem ir para produção

| No mock hoje | No back-end |
| --- | --- |
| `liked`, `saved`, `confirmed` são booleanos **globais** no post | Tabelas por pessoa + flags `*_by_me` na view |
| `Reward.owned`, `Achievement.claimed/current`, `Story.seen` são globais | `user_rewards`, `user_achievements`, `story_views` |
| Cancelar participação mantém a recompensa (dá para farmar) | `reward_granted_at` e recompensa única |
| Recompensa de doação independe do valor | Mínimo e teto **[DECIDIR]** |
| Saldo em R$ dentro do app e "Adicionar saldo" | Pagamento direto no gateway **[DECIDIR]** |
| Post guarda `authorName` / `authorAvatarUrl` copiados | Vem do join na view (sempre atualizado) |
| Comentário tem `replies` e `lastReplyAuthor` fixos | `parent_id` + `replies_count` |
| Notificações são seed fixo | Geradas pelos eventos do banco |
| Conquistas não reagem a nada (exceto doação) | Progresso atualizado pelas RPCs e triggers |
| Stories nunca expiram | `expires_at` de 24 h |
| Código de recuperação fixo `12345` | OTP do Supabase (6 dígitos) |
| Avaliação ⭐ e seção da loja são fixas no seed | Calculadas (`reviews`, vendas, região) |
| Imagens em arquivo local / data URI | Storage + path no registro |

---

## 11. Plano de implementação sugerido

> O roadmap completo, com as telas que faltam, está em
> [PRODUTO_E_ROADMAP.md §7](PRODUTO_E_ROADMAP.md#7-roadmap). Abaixo, só a ordem do banco.

1. **Fundação**: projeto Supabase, enums, `profiles` + trigger de cadastro, Auth
   (e-mail, Google, Facebook), buckets. App: `supabase_flutter`, `AuthRepository`
   e `UserRepository` reais.
2. **Conteúdo**: `posts`, `post_cards`, `feed`, `post_detail`, likes, saves,
   comentários, follows, `create_post`, Storage das capas.
3. **Gamificação sem dinheiro**: ledgers, `post_reward_rules`, participação,
   stories, recompensas, conquistas, envio de moedas.
4. **Social**: conversas, mensagens (Realtime), notificações e push.
5. **Pagamentos**: gateway, `payments`, doações, pacotes de moedas, loja,
   inscrições e anúncios.
6. **Moderação e verificação** antes de abrir doações ao público.

Cada etapa troca um grupo de repositórios do mock pelo Supabase, e o resto do
app segue funcionando com o mock.

---

## 12. Decisões em aberto (resumo)

1. Saldo em R$ no app **ou** pagamento direto no gateway (recomendado).
2. Qual gateway (Mercado Pago, Asaas, Stripe) e se haverá split para as ONGs.
3. Matriz de permissões por tipo de conta (seção 3.4) e se pessoa física cria vaquinha.
4. Verificação de comunidade e empresa obrigatória para receber dinheiro.
5. Recompensa de participação: ao confirmar ou no check-in.
6. Recompensa de doação: fixa ou proporcional, mínimo e teto.
7. Curva de nível (linear 300 XP ou progressiva).
8. Moedas transferíveis entre usuários sem limite? (risco de mercado paralelo)
9. Grupos de comunidade: quem participa (seguidores ou só inscritos).
10. Loja: tipo de entrega e quem pode vender (comunidade e/ou empresa).
11. Idade mínima.
12. Ajustar a tela de código para 6 dígitos (padrão do Supabase).

---

## 13. Acréscimos a partir do protótipo completo

### 13.1 Enums novos ou alterados
```sql
alter type post_status add value 'cancelled';                 -- evento cancelado
create type interest_kind      as enum ('saved', 'interested'); -- "Tenho interesse" / salvo
create type item_request_status as enum ('pending', 'accepted', 'declined', 'delivered', 'cancelled');
create type activity_kind      as enum ('good_deed', 'item_giveaway');   -- registro x doação de itens
create type donation_method    as enum ('money', 'coins');
create type tag_status         as enum ('pending', 'accepted', 'declined'); -- pessoas marcadas
create type ad_format          as enum ('boosted_post', 'boosted_resume', 'banner', 'story', 'sponsored_reward', 'sponsored_challenge');
create type ad_event_kind      as enum ('impression', 'click', 'completed_view');
create type invite_status      as enum ('joined', 'rewarded');
-- coin_reason ganha: 'coins_donated', 'invite_reward', 'ad_story_reward'
-- notification_type ganha: 'campaign_update', 'followed_post_progress', 'item_request',
--   'item_request_accepted', 'tagged_in_post', 'event_photo', 'story_reply'
```

### 13.2 Tabelas novas
| Tabela | Colunas principais | Para quê |
| --- | --- | --- |
| `post_interests` | `post_id`, `profile_id`, `kind`, `created_at` · pk (`post_id`, `profile_id`) | "Tenho interesse"/salvar. Também é **seguir a publicação** (recebe atualizações e progresso). Substitui `post_saves` |
| `post_media` | `id`, `post_id`, `path`, `kind (image/video)`, `position` | Carrossel do cabeçalho e vídeo das atividades |
| `campaign_updates` | `id`, `post_id`, `body`, `media_paths text[]`, `created_at` | Atualizações de doação → notifica quem segue o post |
| `event_photos` | `id`, `post_id`, `author_id`, `path`, `created_at` | "33 pessoas tiraram fotos". Só participantes enviam, e as fotos aparecem no álbum de quem enviou |
| `post_tags_people` | `post_id`, `profile_id`, `status` · pk | "Outros participantes" da atividade. Aceite conta no currículo do marcado |
| `item_requests` | `id`, `post_id`, `requester_id`, `message`, `status`, `conversation_id`, `created_at` | Doação de itens: pedir → aceitar (abre chat) → entregue. `unique (post_id, requester_id)` |
| `invites` | `code text pk`, `inviter_id`, `invitee_id unique`, `status`, `rewarded_at` | Convite: +1.000 🪙 aos dois quando o convidado chega ao nível 20 (trigger no `level`) |
| `daily_objectives` | usa `achievements` com `period = 'daily'` | Tela "Ver objetivos diários" = filtro |
| `ad_campaigns` (amplia 6.5) | `format`, `post_id?`, `creative_path`, `headline`, `cta_url`, `target_reach`, `target_locations text[]` (UF/país), `target_categories post_category[]`, `budget`, `price`, `spent`, `status`, `starts_at`, `ends_at`, `approved_by` | Post/currículo impulsionado, barra de anúncio e story |
| `ad_events` | `id`, `campaign_id`, `profile_id?`, `kind`, `placement`, `created_at` | Impressões, cliques e views completas (cobrança e métricas). Alto volume: particionar por mês ou agregar diário em `ad_daily_stats` |
| `donation_fund_entries` | `id`, `source (ads_profit/coin_donation/…)`, `amount`, `ref`, `created_at` | Fundo de doações da plataforma (30% dos anúncios + moedas doadas) |
| `fund_distributions` | `id`, `period`, `post_id`, `amount`, `paid_at` | Repasse mensal do fundo e página pública de transparência |
| `donations` (amplia 6.3) | `method donation_method`, `coins_amount?`, `tip_amount`, `platform_fee` | Doar com moedas, gorjeta/taxa |
| `profiles` (amplia) | `cover_path` (capa própria), `invite_code`, `rating_avg/count` só para community/business | |

### 13.3 RPCs novas (orientadas às telas)
| Tela | RPC |
| --- | --- |
| Detalhe de doação | `post_detail` passa a incluir `updates[]`, `top_donors[]` (avatares), `i_follow_post` |
| Detalhe de evento | inclui `participants_preview[]`, `photos_preview[]`, `photos_count`, `my_interest` |
| Doação de itens | `request_item(post_id, message)` · `answer_item_request(request_id, accept)` · `mark_item_delivered(request_id)` |
| Publicar atualização | `add_campaign_update(post_id, body, media_paths[])` |
| Fotos do evento | `add_event_photo(post_id, path)` (só participantes) |
| Doar com moedas | `donate_with_coins(post_id, coins)` (debita ledger, credita o fundo para a campanha) |
| Currículo | `action_resume(profile_id, period)` com `total_donated`, contagens por tipo, `latest_donations[]` |
| Recompensas / Conquistas | `progress_page()` = nível, moedas, convite, catálogo, conquistas (populares, resgatadas por amigos, quase lá) |
| Convite | `invite_page()` (código, convidados e progresso até nível 20) |
| Anúncios | `ad_quote(format, reach, locations[])` → preço · `create_ad_campaign(...)` → pagamento · `ad_manager()` (campanhas + métricas) |
| Barra de anúncio | `next_ad(placement, city, state, categories[])` → um criativo com rodízio e limite de frequência · `track_ad_event(campaign_id, kind)` |
| Gestão de evento | `event_manage(post_id)` (confirmados, check-ins) · `check_in(post_id, profile_id)` |
| Minhas coisas | views `my_posts`, `my_interests`, `my_donations`, `my_subscriptions`, `my_orders`, `my_item_requests` |

### 13.4 Regras de anúncio no banco
- Só perfis `business` verificados criam anúncios **[DECIDIR]** se comunidades e influenciadores também podem.
- Campanha nasce `pending_payment` → pagamento confirmado → `pending_review`
  (moderação) → `active` → `finished` (por data ou orçamento).
- `next_ad` respeita: campanha ativa, orçamento restante, localidade do usuário,
  **limite de frequência** (ex.: o mesmo anúncio no máximo 3×/dia por pessoa) e
  nunca exibe anúncio do próprio usuário.
- Story com recompensa: `ad_events.completed_view` único por (campanha,
  pessoa) → credita +20 🪙 (`ad_story_reward`) com teto diário.
- Fechamento mensal: lucro de anúncios × 30% → `donation_fund_entries`.

### 13.5 Ajustes nas seções anteriores
- 4.4 (dinheiro): o protótipo mostra "Meus Fundos" na carteira e na loja; a
  recomendação de não guardar saldo em R$ continua.
- 4.2 (XP): conquistas também dão XP; doação passa a ser **proporcional ao
  valor** (ver PRODUTO §3.2).
- 6.2: `post_saves` vira `post_interests`.
- 3.4: propaganda no protótipo é "para perfis empresariais"; impulsionar o
  **currículo de ações** também é um formato.
