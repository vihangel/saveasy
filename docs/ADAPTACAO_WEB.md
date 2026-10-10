# Adaptação do Save Easy para a web

Documento de planejamento: como transformar o app (desenhado para celular) numa
versão web **funcional e com cara de site**, sem refazer o que já existe e sem
virar "o app do celular esticado".

Data: 10/10/2026 · Versão publicada: https://vihangel.github.io/saveasy/

---

## 1. Como está hoje

| Item | Situação |
| --- | --- |
| Moldura | `lib/app/responsive_frame.dart` mostra o app numa coluna de **430 px** (como um celular) quando a janela tem 600 px ou mais; a partir de 1000 px aparece o painel lateral com logo e descrição. |
| Truque do `MediaQuery` | A moldura reescreve o tamanho da tela para 430 px. Por isso **todas as telas, diálogos e bottom sheets se comportam como no celular** — nada quebra, mas nada aproveita a tela grande. |
| Navegação | `HomeShell`: barra inferior (Início, Mensagens, Notificações, Perfil) + botão laranja "Criar" + menu lateral (`AppDrawer`) com o resto (Carteira, Loja, Recompensas, Configurações…). |
| Rotas | `go_router` com URLs reais (`/post/123`, `/users/abc`, `/transparencia`), já funcionando na web com o `404.html` de fallback. |
| Funções que já tratam a web | Login por e-mail (redirect para a URL da web), compra de moedas só na web, AdMob desligado na web (fica o "Anuncie aqui"). |
| Testes | `test/overflow_test.dart` já visita todas as rotas em 320×568, 360×640 e **1280×800**, com fonte normal e grande. |
| Tamanho | `main.dart.js` com ~4,8 MB (primeiro carregamento lento em 4G). |

**Conclusão:** a base está pronta para web (rotas, backend, autenticação). O que
falta é **layout**: hoje o desktop vê um "celular no meio da tela".

---

## 2. Princípios (para não perder o que foi feito)

1. **Abaixo de 600 px nada muda.** O layout de celular continua igual; todo
   código novo de web fica atrás de um teste de largura.
2. **Reaproveitar os widgets.** `PostCard`, `LevelCard`, `UserAvatar`,
   `ReactionBar`, formulários, cubits e repositórios continuam os mesmos. Muda
   só *onde* eles são posicionados.
3. **Conteúdo com largura máxima, não esticado.** Texto e cards nunca passam de
   ~680 px de largura; o espaço que sobra vira colunas laterais úteis (menu,
   saldo, sugestões), não margem esticada.
4. **Três tamanhos de tela**, centralizados num só lugar:

| Nome | Largura | Navegação | Conteúdo |
| --- | --- | --- | --- |
| Compacto | < 600 px | barra inferior (como hoje) | tela inteira |
| Médio (tablet, janela pequena) | 600–1023 px | trilho lateral só com ícones | 1 coluna, máx. 680 px |
| Largo (notebook/desktop) | ≥ 1024 px | menu lateral com ícones e nomes | coluna central + coluna direita (≥ 1280 px) |

---

## 3. Base técnica (fazer primeiro)

São mudanças pequenas e centrais que destravam todas as telas.

### 3.1 Breakpoints num só lugar
Criar `lib/app/breakpoints.dart` com `enum WindowSize { compact, medium, expanded }`
e uma extensão `context.windowSize` (em cima do `MediaQuery.sizeOf`). Nenhuma tela
deve comparar larguras "na mão".

### 3.2 Trocar a moldura de celular pelo layout real
Em `ResponsiveFrame`:
- **Remover a reescrita do `MediaQuery`** e a coluna de 430 px quando a tela for
  média ou larga. Hoje ela é o que impede o app de "ver" a tela grande.
- Manter a moldura só como **opção** (ex.: `--dart-define=PHONE_FRAME=true`) para
  apresentações do protótipo.
- O painel lateral de apresentação passa a existir só nas telas sem login
  (boas-vindas, login, cadastro), veja 4.1.

### 3.3 Navegação adaptativa no `HomeShell`
- **Compacto:** como hoje (barra inferior + botão Criar + drawer).
- **Médio/Largo:** `NavigationRail` (ou um menu lateral próprio) com:
  Início · Mensagens (com selo) · Notificações (com selo) · Perfil, um botão
  **"Criar"** em destaque no topo e, abaixo, os itens que hoje estão no drawer
  (Carteira, Loja, Recompensas, Conquistas, Salvos, Configurações). O drawer
  deixa de ser necessário.
- A `AdBar` sai do rodapé e vira um card na coluna direita (telas largas).
- Os selos de não lidas continuam vindo do `BadgesCubit` — nada muda na lógica.

### 3.4 `AppPage`: largura máxima para todas as telas empurradas
Telas abertas com `context.push` (post, configurações, carteira…) ficam fora do
shell. Criar um wrapper `AppPage`/`ContentWidth` (`Center` + `ConstrainedBox`
de 680 px) e aplicar no `body` dos `Scaffold`s. Dá para fazer em massa porque
quase todas as telas usam `Scaffold(appBar:…, body: ListView(...))`.

Em telas largas, essas telas também podem abrir **dentro do shell** (menu
lateral continua visível) usando `ShellRoute` — recomendado para Post, Perfil de
outra pessoa, Loja e Carteira.

### 3.5 Bottom sheets viram diálogos
Criar `showAdaptiveSheet(...)`: no compacto chama `showModalBottomSheet` (como
hoje); no médio/largo chama `showDialog` com largura de 480 px. Trocar nos 6
pontos que usam bottom sheet: **checkout/Pix, denúncia, escolher imagem,
marcar pessoas, termos de uso (cadastro) e textos de Configurações**.

### 3.6 Mouse e teclado
- `Esc` fecha diálogos (já é padrão), `Enter` envia formulários (já feito no
  login/cadastro/chat), setas no visualizador de stories.
- Estados de *hover* nos cards (`PostCard`, itens de lista): leve elevação/borda.
- `SelectionArea` nos textos longos (descrição do post, bio) para permitir
  copiar com o mouse.
- Rodinha do mouse já funciona; arrastar carrosséis com o mouse já foi habilitado
  (`AppScrollBehavior`).

---

## 4. Telas principais — o que fazer em cada uma

Ordem pensada por impacto: as primeiras são as que todo mundo vê.

### 4.1 Boas-vindas, login, cadastro, recuperar senha, onboarding
Hoje: `IllustratedScaffold` (ilustração em cima, formulário embaixo).
**Web:** tela dividida — **à esquerda** a ilustração grande + logo + frase
("Ações que mudam o mundo") sobre o fundo laranja/creme da marca; **à direita**
o formulário num card de 420 px. É o mesmo conteúdo de hoje, só reorganizado
dentro do `IllustratedScaffold` (um `if (wide) Row(...) else Column(...)`).
O carrossel de boas-vindas pode virar uma única tela com os 3 destaques lado a lado.

### 4.2 Feed (Início) — prioridade máxima
Layout em 3 colunas no largo:

```
┌──────────────┬──────────────────────────┬────────────────────┐
│ Menu lateral │ Stories (linha)          │ Meu nível/moedas   │
│ (3.3)        │ Abas + filtros (chips)   │ (LevelCard)        │
│              │ PostCard                 │ Comunidades para   │
│              │ PostCard                 │ seguir             │
│              │ ... (máx. 640 px)        │ Anúncio (AdBar)    │
│              │                          │ Transparência      │
│              │                          │ (resumo do fundo)  │
└──────────────┴──────────────────────────┴────────────────────┘
```
- A coluna central é exatamente o `CustomScrollView` atual, só limitado em largura.
- A coluna direita só aparece a partir de 1280 px; reaproveita `LevelCard`,
  `CoinChip`, `AdBar` e dados que já existem nos repositórios.
- O ícone de menu (hambúrguer) da AppBar some no largo (o menu já está fixo).

### 4.3 Detalhe da publicação (`/post/:id`) — a maior tela (1.800 linhas)
- **Largo:** duas colunas — à esquerda capa, título, dados (data, local, meta e
  progresso da doação), botões de ação (Participar, Doar, Enviar moedas); à
  direita os **comentários** com o campo de comentário fixo embaixo.
- **Médio:** uma coluna de 680 px (como hoje, centralizada).
- Doação, participantes e pedidos de itens abrem como diálogo/painel em vez de
  tela cheia.

### 4.4 Mensagens + Chat — padrão "lista e conversa"
- **Largo:** lista de conversas à esquerda (360 px) e a conversa aberta à
  direita, como WhatsApp Web. `/messages/:id` passa a renderizar dentro da aba
  Mensagens quando a tela é larga.
- **Médio/compacto:** como hoje (lista → tela da conversa).
- O `ChatPage` e o `MessagesPage` continuam os mesmos widgets; só muda o pai.

### 4.5 Perfil (próprio e de outros)
- Capa em largura cheia (até 960 px), avatar e dados sobrepostos à esquerda,
  botões (Seguir, Mensagem, Apoiar) à direita na mesma linha.
- Abas (publicações, atividades) com as publicações em **grade de 2–3 colunas**
  (`SliverGrid` com `maxCrossAxisExtent` ~320 px) em vez de lista.

### 4.6 Criar/editar publicação e anúncios
- Card central de até 760 px. Campos relacionados lado a lado (data inicial |
  final; local | site; meta | encerramento), já que hoje estão empilhados.
- Capa à esquerda e campos à direita no largo.
- Escolha do tipo (`/create`) em grade de cards em vez de lista.

### 4.7 Loja, produto, pedidos, minha loja
- Produtos em grade (`maxCrossAxisExtent` ~260 px).
- Produto: diálogo ou página de duas colunas (fotos | descrição, preço, comprar).
- Minha loja / pedidos: tabela simples (`DataTable`) no largo.

### 4.8 Carteira, financeiro, recompensas, conquistas
- Carteira: saldo + ações no topo; extrato em tabela no largo.
- Recompensas/conquistas: grade de cards (já são cards, só mudar para grid).
- Painel financeiro (comunidades): cards de resumo lado a lado + tabela de repasses.

### 4.9 Stories
- Abrir como **modal central em 9:16** sobre fundo escuro (não esticar), com
  setas ←/→ e botão fechar. Criar story: mesmo modal.

### 4.10 Notificações, configurações, salvos, seguidores
- Uma coluna de 680 px centralizada (só o `AppPage` de 3.4 resolve).
- Notificações podem, depois, virar um painel suspenso a partir do sino no menu.

### 4.11 Painel da equipe (admin) e transparência
- **Onde a web mais ganha:** moderação é trabalho de computador. Trocar listas
  por **tabelas com filtros** (denúncias, verificações, anúncios, repasses) e
  abrir o detalhe num painel lateral.
- Transparência (`/transparencia`, pública): layout de página institucional
  (números grandes em cards, gráfico do fundo). Por ser a página que vai ser
  compartilhada, vale ter uma versão HTML estática simples para aparecer bem em
  buscadores e prévias de link (Flutter web não é indexado bem).

---

## 5. Itens funcionais específicos da web (checklist)

| # | Item | Situação / o que fazer |
| --- | --- | --- |
| 1 | **Compartilhar post** | Hoje mostra "Link copiado!" mas não copia nada. Copiar `https://…/saveasy/post/<id>` com `Clipboard.setData` na web e usar o compartilhamento nativo no celular. |
| 2 | **"Tirar foto"** | A câmera não existe na web; esconder a opção e deixar só "Escolher arquivo" (arrastar e soltar seria um bônus). |
| 3 | **QR de check-in** | Leitura por câmera é do celular; na web mostrar o QR/código para o organizador e um campo para digitar o código. |
| 4 | **Anúncios** | AdMob não roda na web; manter os anúncios próprios ("Anuncie aqui"/campanhas) — AdSense só se fizer sentido depois. |
| 5 | **Notificações push** | Web push (Firebase Cloud Messaging) junto com a pendência 7 (push no celular). |
| 6 | **Carregamento** | Tela de carregamento com o logo no `web/index.html` (hoje fica em branco até o Flutter subir); testar build `--wasm`; carregar admin/loja/anúncios sob demanda (`deferred as`). |
| 7 | **Nova versão** | O GitHub Pages guarda cache por ~10 min; mostrar um aviso "Nova versão disponível — recarregar" comparando `version.json`. |
| 8 | **Prévia de link** | Meta tags Open Graph (título, descrição, imagem) no `index.html`; prévia por post exigiria uma função no servidor (Supabase Edge Function) — deixar para depois. |
| 9 | **Leitor de tela na web** | O Flutter web só liga a acessibilidade quando o usuário ativa; avaliar `SemanticsBinding.instance.ensureSemantics()` para quem usa leitor de tela. |
| 10 | **Endereço próprio** | Domínio (ex.: `app.saveeasy.com.br`) apontando para o Pages ou para Vercel/Netlify/Firebase Hosting (melhor controle de cache). |

---

## 6. Como testar sem quebrar o celular

- **Ampliar o `overflow_test.dart`**: além de 320, 360 e 1280 px, incluir
  **768×1024 (tablet)** e **1440×900**. Ele já percorre todas as rotas — passa a
  pegar estouros nos novos layouts.
- Testes de widget para o `HomeShell` nos três tamanhos (barra inferior x
  trilho x menu largo) e para o `showAdaptiveSheet`.
- Checar no navegador real em 1280, 1440 e com a janela reduzida (redimensionar
  ao vivo não pode quebrar estado: o `StatefulShellRoute` já preserva as abas).

---

## 7. Ordem sugerida e esforço estimado

| Fase | Entrega | Estimativa |
| --- | --- | --- |
| **1. Base** | Breakpoints, sair da moldura de celular, menu lateral adaptativo, `AppPage` com largura máxima, bottom sheet → diálogo | 3–4 dias |
| **2. Telas de entrada** | Boas-vindas, login, cadastro, onboarding em tela dividida | 1–2 dias |
| **3. Núcleo social** | Feed em 3 colunas, detalhe do post em 2 colunas, mensagens lista+conversa, perfil com grade | 5–7 dias |
| **4. Criação e dinheiro** | Criar publicação/anúncio em 2 colunas, loja em grade, carteira e financeiro com tabelas | 3–4 dias |
| **5. Equipe e público** | Painel admin com tabelas, transparência como página institucional, stories em modal | 3–4 dias |
| **6. Acabamento web** | Checklist da seção 5 (compartilhar, câmera, carregamento, nova versão, OG) | 2–3 dias |

Total aproximado: **3 a 4 semanas** de uma pessoa. Depois da **Fase 1** a web já
fica funcional e com aparência de site (menu lateral + conteúdo centralizado);
as fases seguintes são melhorias por tela e podem ser feitas aos poucos, cada
uma publicada separadamente.

### Decisões para você tomar
1. **Manter a moldura de celular como opção** (para apresentar o protótipo) ou
   removê-la de vez quando a Fase 1 estiver pronta?
2. **A web é para todos os públicos ou principalmente para comunidades/empresas
   e equipe?** Se for o segundo caso, vale priorizar a Fase 5 (admin,
   financeiro, anúncios) antes do feed.
3. **Domínio próprio** antes do lançamento (item 10)?
