# Save Easy

**Demo online:** https://vihangel.github.io/saveasy/

Protótipo front-end do app Save Easy (Flutter), baseado no Figma "Telas - Protótipo".
Não há back-end: os dados são mockados e as alterações ficam salvas localmente
(`shared_preferences`), então cadastro, doações, publicações etc. persistem entre execuções.

**Conta de teste:** `demo@saveeasy.com` / `123456` · código de verificação: `12345`

## Rodando

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Para zerar os dados mockados, desinstale o app (ou limpe o `localStorage` na web).

Na web as URLs não usam `#` (`usePathUrlStrategy`). Por isso o servidor precisa
devolver o `index.html` para qualquer rota. Para testar localmente:

```bash
flutter build web && python3 tool/serve_web.py 8765
```

## Deploy (GitHub Pages)

```bash
tool/deploy_pages.sh
```

O script gera o build com `--base-href /saveasy/`, cria o `404.html` (fallback
das URLs sem `#`) e publica na branch `gh-pages`. O workflow
`.github/workflows/deploy-pages.yml` faz o mesmo automaticamente a cada push na
`main`, mas só roda com o GitHub Actions ativado no repositório.

## Stack

| Pacote | Uso |
| --- | --- |
| `flutter_bloc` (Cubit) | Gerenciamento de estado |
| `go_router` | Navegação, redirect por sessão, shell com barra inferior |
| `freezed` + `json_serializable` | Modelos imutáveis, estados e (de)serialização JSON |
| `shared_preferences` | Persistência local dos dados mockados |
| `image_picker` | Câmera e galeria (foto de perfil, capa de publicação, story) |
| `permission_handler` | Pedido e tratamento das permissões de câmera/fotos |
| `path_provider` + `path` | Cópia das imagens para a pasta do app |
| `google_fonts`, `intl` | Poppins/Quicksand, formatação pt-BR |
| `bloc_test` | Testes dos cubits |

### Por que Cubit?

Cubit (do `flutter_bloc`) tem o estado imutável e explícito do Bloc, mas sem a
cerimônia de eventos. Cada tela chama métodos (`load()`, `donate()`...) e emite
estados `freezed` com `copyWith`. Fica simples de ler e de testar com `bloc_test`,
e se algum fluxo crescer dá para trocar só aquele Cubit por um Bloc.
`ChangeNotifier` seria mais simples, mas mistura estado mutável com a UI e
complica testar os estados intermediários.

## Arquitetura

```
lib/
├── main.dart                 # inicializa storage + banco mockado
├── app/                      # app, tema, rotas (go_router)
├── shared/                   # tudo que é geral
│   ├── data/
│   │   ├── models/           # AppUser, Post, Reward... (freezed + json)
│   │   ├── datasources/      # LocalStorage, MockDatabase e MockSeed (JSON inicial)
│   │   └── repositories/     # Auth, Post, Wallet, Gamification, Chat...
│   ├── notifiers/            # estado global: SessionCubit (usuário logado)
│   ├── services/             # MediaPickerService (permissões + câmera/galeria)
│   ├── widgets/              # componentes reutilizáveis (PostCard, AppTextField...)
│   └── utils/                # formatadores, validadores, ViewStatus
└── features/                 # uma pasta por tela/fluxo: página + cubit + state
    ├── auth/{login, forgot_password, sign_up}
    ├── feed, post_detail, create_post, stories
    ├── donate, send_coins, event_confirmed
    ├── profile, edit_profile, community_subscription
    ├── messages, chat, notifications
    └── wallet, rewards, achievements, store
```

- **Repositórios** são a única porta para os dados. Hoje falam com o `MockDatabase`.
  Quando o back-end existir, basta trocar a implementação interna (mesma assinatura).
- **SessionCubit** guarda o usuário logado. Toda ação que muda moedas, saldo ou XP
  chama `session.updateUser(...)`, e o app inteiro reflete a mudança.
- **Fluxos de várias telas** (cadastro, recuperar senha) usam um `ShellRoute` que
  provê um único Cubit para todas as etapas.
- O `MockDatabase` simula latência (350 ms) para os estados de carregamento aparecerem.

## Fluxos implementados

- Abertura → Boas-vindas (3) → Login (e-mail/senha, Google/Facebook mock)
- Recuperar senha: e-mail → código → nova senha
- Cadastro: tipo de conta → e-mail/senha/termos → perfil → endereço → sucesso
  (o voltar do 1º passo pede confirmação, como na anotação do Figma)
- Feed com stories, abas (Popular / Na sua região / Seguindo), busca e categorias
- Detalhe de publicação por tipo: doação, evento, ação social, atividade, tutorial,
  discussão e propaganda, com curtidas, comentários, salvar, seguir autor
- Doar (valor → sucesso com moedas/XP), confirmar presença em evento, participar
  de ação/atividade, enviar moedas para o autor ou para um amigo
- Criar publicação: seletor de tipo e formulários de Evento, Doação, Ação social,
  Tutorial, Atividade, Discussão e Propaganda (info → planos)
- Stories: visualizador com progresso automático e criação de story
- Perfis (pessoal, influencer, comunidade, empresa) com abas Publicações,
  Currículo de ações e Álbum; editar perfil (título e selos); inscrição em comunidade
- Mensagens (Pessoas / Comunidades / Empresas) e conversa com post compartilhado
- Notificações, Carteira (saldo, compra de moedas, histórico), Recompensas
  (capas, selos, títulos, resgate), Conquistas (diárias e gerais), Loja da comunidade
- Menu lateral e "Sair"

## Imagens e permissões

Fluxo (`showImagePickerSheet`): escolher **Tirar foto / Escolher da galeria / Remover** →
`MediaPickerService` pede a permissão → abre câmera ou galeria (redimensiona para
1080px, qualidade 80) → `ImageStorage` salva localmente e devolve uma referência
que vai no modelo (`avatarUrl`, `imageUrl`). Usado no cadastro (passo 3), em
Editar perfil, na capa de todas as publicações e no story.

| Plataforma | Câmera | Galeria |
| --- | --- | --- |
| iOS | `NSCameraUsageDescription` | `NSPhotoLibraryUsageDescription` |
| Android | `CAMERA` no manifest | Photo Picker do sistema, sem permissão |
| Web | navegador | navegador (imagem salva como data URI) |

- Permissão negada: mostra uma explicação. Bloqueada de vez: oferece **Abrir configurações**.
- Sem câmera (ex.: simulador de iOS): avisa e sugere a galeria.
- O iOS usa Swift Package Manager. O `permission_handler` liga cada permissão a
  partir das chaves `NS*UsageDescription` do `Info.plist`. Se o projeto migrar
  para CocoaPods, é preciso definir `PERMISSION_CAMERA=1` e `PERMISSION_PHOTOS=1`
  no `Podfile`.
- No mobile, a imagem é salva como `local:images/<arquivo>` (caminho relativo,
  porque o caminho absoluto do container do iOS muda a cada atualização).

## Testes

```bash
flutter test
```

- Repositórios de autenticação e carteira (incluindo a persistência) e cubits de sessão e cadastro.
- **`test/overflow_test.dart`**: abre todas as rotas em 320×568 e 360×640, com
  fonte 1,0x e 1,3x, rola as listas e falha se aparecer qualquer overflow ou erro
  de layout (mostra o arquivo:linha). Rode sempre que mexer em layout.
- Fluxo de imagem com seletor falso: foto salva e exibida, e permissão bloqueada
  levando às configurações.

Para decisões e pendências de design, veja [docs/RELATORIO_FIGMA.md](docs/RELATORIO_FIGMA.md).
