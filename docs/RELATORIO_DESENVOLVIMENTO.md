# Relatório de desenvolvimento · Save Easy

Documento vivo: cada entrega adiciona uma seção com o que foi feito, como validar
e o que ficou pendente. Ordem: mais recente primeiro.

Legenda: ✅ no Supabase · 🟡 ainda no mock local · ⏳ pendente

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
| 23 | Doação em R$, compra de moedas, loja, inscrição em comunidade | 🟡 | Ainda simulados (fase de pagamentos). Funcionam com saldo fictício local |
| 24 | Stories, mensagens, notificações, recompensas, conquistas | 🟡 | Stories, mensagens e notificações migraram na Entrega 2; recompensas e conquistas ainda mock |

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
