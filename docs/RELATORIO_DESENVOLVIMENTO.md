# Relatório de desenvolvimento · Save Easy

Documento vivo: cada entrega adiciona uma seção com o que foi feito, como validar
e o que ficou pendente. Ordem: mais recente primeiro.

Legenda: ✅ no Supabase · 🟡 ainda no mock local · ⏳ pendente

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
| 24 | Stories, mensagens, notificações, recompensas, conquistas | 🟡 | Conteúdo mock (não é de Cuiabá). Tocar no autor de um story mock mostra "Perfil não encontrado" |

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
