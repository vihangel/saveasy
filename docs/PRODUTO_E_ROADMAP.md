# Save Easy · Produto, fluxos e roadmap (documento interno)

> Baseado no protótipo completo do Figma (16 pranchas, out/2026) e no app atual
> (`lib/`). Complementa o [BACKEND_SUPABASE.md](BACKEND_SUPABASE.md), que traz as
> tabelas e as regras de acesso. Textos do protótipo citados entre aspas foram
> lidos de imagens de baixa resolução e podem ter pequenas diferenças.
> **[DECIDIR]** = precisa de definição de produto.

---

## 1. Visão em uma frase

Rede social de boas ações: pessoas, influenciadores, empresas e comunidades
publicam ações (doações, eventos, ações sociais, atividades, tutoriais,
discussões). Quem ajuda ganha **XP e moedas**, e as moedas viram **personalização**
(capas, selos, títulos) patrocinada por marcas e comunidades. O **currículo de
ações** é a vitrine de impacto de cada perfil, inclusive o ESG das empresas.

---

## 2. Inventário do protótipo

### 2.1 Entrada (Fluxo 1)
| Tela | Conteúdo | Observação |
| --- | --- | --- |
| Opening | Logo "SAVEASY · Easiest way to save the world" | Splash |
| Onboard #1–3 | "Faça ações que melhoram o mundo", "Comece a ajudar", "Personalize" | Já implementado |
| Sign Up Page | E-mail, senha, confirmar senha, "Create an account", Facebook/Google, "Already have an account? Log in" | **Mais curto que o cadastro de 5 passos do protótipo antigo** |
| Sign In Page | E-mail, senha, "esqueceu a senha?", "Logar", Facebook/Google, "Crie uma conta" | Mistura PT/EN → padronizar em PT |

### 2.2 Feed e stories
- **Feed 1**: abas, "Recomendados", cards grandes com imagem, autor, contadores.
- **Stories** (11 blood donation, 9 Cards – Another Donate, 10 Stories – Adds):
  imagem em tela cheia, título e texto em caixas, autor com tipo da ação
  (Ação social, Atividade de reciclagem, Evento de doação de sangue). À direita,
  botões **"+" (seguir/salvar?)**, **"$" (enviar moedas)**, **"♥" (curtir)**.
  Embaixo, campo **"Responder…"** (resposta vai para o chat).
- **Story de anúncio**: selo "+20" moedas e tela explicativa "Veja anúncios
  selecionados / Ganhe moedas! Ao assistir até o final você ganha moedas" → "Entendi!".

### 2.3 Detalhe das publicações (todos com cabeçalho de imagem/carrossel, tipo no topo, compartilhar)
| Tipo | Elementos que aparecem |
| --- | --- |
| **Doação** | Status (Recorrente / 40 dias rest.), meta x arrecadado com %, "Visualizado há 1 dia", **atualizações da campanha** com data e fotos ("Atualização 3 Fevereiro 2022"), "Ver mais", avatares de doadores + **Doar**, card do autor (Seguir), comentários |
| **Evento** | Data relativa (Em 5 dias / Em 15 dias / Em 1 dia / Finalizado), local ou link, data/hora, "200 Participaram / 485.000 confirmados" com avatares, **"33 pessoas tiraram fotos deste evento"** (galeria de participantes), **Tenho interesse / Evento salvo**, **Participar**, card do organizador |
| **Ação social** | Texto + imagens, organizador ou patrocinador (empresas como Coca-Cola, Razer, Athletico), **"Ver currículo de ações"** |
| **Atividade** | Duas naturezas: **(a) registro de boa ação** ("Fizemos reciclagem do lixo", "Trilha na reserva", com vídeo) e botão **Enviar Moedas**; **(b) doação de itens** ("Estou doando meu fogão e mais 5 móveis", local Campinas) com botão **Aceitar Itens**. Marca outros participantes |
| **Tutorial** | Duração, **etapas numeradas com imagem/vídeo**, "Ver currículo de ações" |
| **Discussão** | Tópicos, texto longo, "27 Respostas", **respostas aninhadas**, curtidas por resposta |

### 2.4 Doação (Explicação 1–10, telas 26)
1. **Explicação**: "Como funciona uma Doação? A cada real gasto, além de ajudar,
   você ganha pontos de experiência e moedas. +10 🪙 +100 XP. Suba de nível e
   ganhe recompensas!", LV1 → LV2, carrossel de capas → **Continuar**.
2. **Valor**: "Quanto deseja doar?" R$ ___, aviso de taxa ("cobramos X% de
   taxa"), **Doar com Dinheiro** ou **Doar com Moedas**.
3. **Sucesso**: "Obrigado por sua Doação! R$ 250", card do beneficiário (Seguir),
   Compartilhar, "Você ganhou: 120 🪙 300 XP", barra LV 34 → LV 35 (3.300/5.000),
   **Personalização**.

### 2.5 Enviar moedas
Explicação ("Gostou de algo que um usuário fez? Presenteie com moedas… Faça
publicações interessantes e ganhe moedas!") → "Quantas moedas deseja enviar?" →
"Moedas Enviadas!" com card do destinatário (Seguir), dica "Que tal publicar uma
atividade e ganhar moedas também?", **Compartilhar** e **Criar Atividade**.

### 2.6 Perfil (12. Personal Profile, ~20 variações)
Capa, avatar, **nível (coroa, ex. 35)** à esquerda, **avaliação ⭐ 4,6** à direita,
nome, título ("Doador do Bem", "Lutando pelo Bem", "Vegan World"), 3 contadores,
botão **Seguir/Seguindo** (ou **Editar perfil** no próprio). Comunidades:
**Inscrever-se** e **Ver loja**. Abas **Feed · Currículo · Álbum**, busca e ordenação.

- **Currículo de ações (14)**: filtro de período ("Mensal"), **Total doado
  R$ 5.000**, blocos 15 Doações · 25 Atividades · 3 Tutoriais · 2 Inscrições,
  "Últimas doações feitas", **Ver currículo completo**, **Seguir empresa**.
- **Álbum (15)**: grade de fotos das ações, com selo do tipo.
- **Editar perfil (16)**: nome e sobrenome, **escolher capa**, **selos**
  (vários) e **título**, "Salvar Mudanças".

### 2.7 Comunidade: inscrição (7. Inscrição)
"Apoie Comunidades. Em perfis de comunidades verificadas é possível apoiar de
forma mensal por um valor fixo. Itens personalizáveis: ao se inscrever
mensalmente por R$ 9,90/mês, personalizações dessa comunidade são adicionadas ao
seu perfil. Cancele quando quiser" → **Inscrever-se | R$ 9,90** → "Obrigado por
apoiar uma comunidade! Você desbloqueou itens personalizados" → Compartilhar /
**Personalização**.

### 2.8 Criar e editar publicação (21, 22, Explicação 11)
- **21. Create a post**: grade com Doação, Evento, Ação social, Tutorial,
  Propaganda e Atividade, mais busca.
- **22. Edit post detail** (é o mesmo formulário para criar e editar):
  - **Evento**: título, descrição, início/fim, local ou site, tags;
  - **Doação**: tipo (Recorrente…), valor, tags;
  - **Ação social**: pergunta Sim/Não (provavelmente "já realizada?") e tags;
  - **Tutorial**: pergunta Sim/Não, duração, tags;
  - **Atividade**: tipo (Reciclagem…), **outros participantes** (marcar pessoas), tags.
- **Propaganda (Explicação 11 + 22-5)**: "Para perfis empresariais, é possível
  impulsionar suas **ações sociais ou seu currículo de ações**. Será vista por
  quem não segue o perfil, **no feed e nos cards**. O custo depende de quantos
  usuários e em quantas localidades. **30% do lucro vai para doações da
  plataforma**." Formulário: escolher o que impulsionar (post ou currículo),
  **alcance (nº de pessoas, ex. 500.000)**, **localidades (Brasil, EUA e
  Alemanha)**, **custo calculado (R$ 2.000)** → Criar.

### 2.9 Mensagens e notificações
- **20. Messages**: abas Pessoas · Comunidades · Empresas, busca, prévia, horário.
- **Message detail**: chat com post compartilhado (card com curtidas e
  comentários). Exemplos de empresas e comunidades mandando mensagem ("verifique
  nosso currículo de ações", "não se esqueça de resgatar seus itens
  personalizáveis") → **mensagens de marca** (ver monetização).
- **Notifications**: "Monark doou R$ 50.000 em uma doação que você estava
  seguindo (81% da meta)", "Sadia curtiu sua atividade", "Lucas comentou no seu
  post", "Seu evento … está prestes a começar".

### 2.10 Menu, economia e gamificação
- **17. Menu**: avatar, nome, LV, Tela inicial, Carteira, Conquistas, Recompensas,
  Loja, Configurações, Sair.
- **Carteira**: "Meus Fundos R$ 500,00 (+)", **Comprar moedas** com desconto por
  pacote (1.000 · 2.500 −10% · 5.000 −20%), **Histórico** (moedas, doação,
  inscrição, fundos).
- **Recompensas**: "Meu Progresso" (nível, moedas, **Comprar moedas**), **Convide
  e ganhe pontos** ("quando alguém usar seu convite e atingir o nível 20, ganha
  1.000 moedas", **Compartilhar código de convite**), Capas · Selos · Títulos
  populares. Detalhe: arte em tela cheia, **patrocinador** (Vintage Culture,
  Unicef, Greenpeace), nome, preço, **Resgatar**, salvar.
- **Conquistas**: "Faça objetivos diários" → **Ver objetivos diários**;
  Conquistas populares ("Faça 100 doações": **200 🪙 + 500 XP**), **Resgatadas
  por amigos**, **Quase lá** ("Participe de 50 eventos": 1.000 🪙 + 5.000 XP).
- **Loja**: Meus fundos, busca "Comunidades e Produtos", seções (populares, bem
  avaliados, da sua região). Produto: fotos, vendedor, nome, preço, **Comprar**, salvar.

---

## 3. Regras novas ou ajustadas pelo protótipo

1. **Doar com moedas** é um fluxo oficial ("Doar com Moedas", e "presenteie com
   moedas para que ele possa… fazer doações pelo app"). Impacto: moedas compradas
   com dinheiro podem virar doação real. Regra proposta: **1.000 🪙 = R$ X** pago
   pela plataforma a partir do fundo de doações (seção 6.3), com teto mensal por
   usuário. Moedas **ganhas** (não compradas) podem doar só dentro do fundo.
   **[DECIDIR]**
2. **XP e moedas por real doado**: o protótipo diz "+10 🪙 e +100 XP a cada
   real", mas o sucesso mostra R$ 250 → 120 🪙 e 300 XP. Proposta coerente:
   `XP = 1,2 × reais` e `moedas = 0,5 × reais`, com teto por doação e por dia.
   **[DECIDIR]**
3. **Conquistas dão moedas e XP** (não só moedas, como hoje no app).
4. **Convite**: código pessoal. Quem convidou e o convidado ganham **1.000 🪙**
   quando o convidado chega ao **nível 20** (evita contas falsas).
5. **Tenho interesse / Evento salvo** é diferente de **Participar** (salvar só
   acompanha e recebe lembrete).
6. **Fotos de participantes em eventos**: quem participou pode enviar fotos, e
   elas aparecem no evento e no álbum de quem enviou.
7. **Atualizações de campanha**: o autor de uma doação publica atualizações (texto
   e fotos) e os doadores e seguidores são notificados.
8. **Atividade = boa ação registrada ou doação de itens.** Na doação de itens,
   interessados pedem e o autor **aceita um pedido**, o que abre um chat. O
   item fica como reservado e depois entregue.
9. **Marcar pessoas** em atividades ("outros participantes"). Cada marcado
   confirma e ganha a atividade no currículo.
10. **Seguir publicação**: notificações tipo "doação que você estava seguindo"
    exigem seguir posts, não só perfis (salvar = seguir).
11. **Currículo de ações** com filtro por período, totais por tipo, total doado e
    página completa. Para empresas, **"Seguir empresa"** a partir do currículo.
12. **Avaliação ⭐** existe em perfis de comunidade e empresa (precisa de regra
    de quem avalia: doadores, participantes e compradores).
13. **Inscrição** só em comunidades **verificadas**; o valor é fixo por
    comunidade (R$ 9,90 no protótipo) e libera itens daquela comunidade.
14. **Propaganda** com preço por **alcance e localidades**, exibida a quem não
    segue, **no feed e nos cards**. **30% do lucro** vai para o fundo de doações.
15. **Respostas a stories** viram mensagem direta.

---

## 4. Ajustes de UX recomendados

| Hoje no protótipo | Proposta |
| --- | --- |
| Telas de "Explicação" antes de toda doação, envio de moedas e propaganda | Mostrar **só na primeira vez** (ou como folha "Como funciona?" com link "Saiba mais"). Fluxos repetidos precisam ser rápidos |
| Doação em 3 telas (explicação → valor → sucesso) | **Folha inferior** com valores rápidos (R$ 10 · 25 · 50 · outro), método (Pix, cartão, moedas), taxa/gorjeta transparente e botão único. Sucesso continua em tela cheia (é o momento de recompensa) |
| Cadastro curto (Sign Up) **e** cadastro de 5 passos (protótipo antigo) | **Cadastro curto** (e-mail e senha, ou Google/Apple/Facebook) e depois **completar perfil** em etapas puláveis: tipo de conta, @, foto, cidade. Menos abandono |
| Mistura de inglês e português | Tudo em PT-BR. Preparar i18n (`intl`/ARB) |
| Barra inferior só com ícones (≡, chat, sino, logo) | Ícones **com rótulo** e botão central **Criar** (já no app) |
| Muitos contadores sem legenda no perfil (1,5 mi · 1.250 · 987) | Legendas "seguidores · seguindo · ações" e nível/⭐ com tooltip |
| Detalhe de post muito longo (descrição, atualizações, galeria, autor, comentários) | Seções recolhíveis e **barra fixa inferior** com a ação principal (Doar / Participar / Enviar moedas) |
| Botões flutuantes no story sem rótulo | Manter ícones, com dica na primeira vez e área de toque ≥ 44 px |
| Estilo visual de 2021 (sombras duras, gradientes roxos fortes) | Refresh: superfícies claras, cantos 16–24, tipografia Quicksand/Poppins já usada, cor de destaque por tipo de post, ilustrações atuais. Fazer um **design system** antes de redesenhar telas |
| "Meus Fundos R$ 500" (saldo em dinheiro) em Carteira e Loja | Ver BACKEND 4.4: **sem saldo em R$**; carteira = moedas + histórico de pagamentos |
| Fotos de stock e marcas reais (Coca-Cola, Unicef, Razer…) | Conteúdo fictício ou parceiros com contrato. Usar marca real sem autorização é risco |

Telas **sem sentido ou duplicadas** que podem sair ou ser fundidas:
- "Recompensas" e "Conquistas" têm o mesmo cabeçalho "Meu progresso". Fundir numa
  aba **"Progresso"** com duas sub-abas.
- "Ver loja" no perfil e "Loja" no menu: manter as duas, mas a do perfil
  filtra a loja daquela comunidade.
- Variações de tela no Figma ("Evento salvo", "Seguindo") são **estados** da
  mesma tela, não telas novas.

---

## 5. O que falta (lacunas para o produto funcionar de ponta a ponta)

### 5.1 CRUD e gestão do próprio conteúdo
- [ ] **Editar e excluir publicação** (todas as categorias), com regras: não
      mudar meta e tipo de doação com doações, avisar participantes ao mudar
      data/local de evento, cancelar evento.
- [ ] **Minhas publicações** com rascunhos, publicadas e encerradas.
- [ ] **Publicar atualização** em campanha de doação.
- [ ] **Gerenciar evento**: lista de confirmados, check-in (QR), enviar aviso
      aos participantes, encerrar.
- [ ] **Gerenciar doação de itens**: ver pedidos, aceitar/recusar, marcar como entregue.
- [ ] **Editar e excluir comentário**; denunciar.
- [ ] **Excluir story** e ver quem visualizou.
- [ ] **Enviar fotos** para o evento (participantes).

### 5.2 Conta e perfil
- [ ] **Configurações**: dados da conta, trocar e-mail e senha, notificações,
      privacidade (perfil privado? quem envia mensagem), idioma, **bloqueados**.
- [ ] **Excluir conta** e **exportar dados** (obrigatório pela LGPD e pelas lojas).
- [ ] **Termos de uso e política de privacidade** (aceite no cadastro).
- [ ] **Listas de seguidores e seguindo**.
- [ ] **Salvos / Tenho interesse**.
- [ ] **Verificação** de comunidade/empresa: envio de CNPJ e documentos, status, selo.
- [ ] **Completar perfil** pós-cadastro (tipo de conta, @, foto, cidade).
- [ ] **Confirmação de e-mail** (tela de "verifique seu e-mail" + reenviar).
- [ ] Editar **capa do perfil** (upload próprio além das capas resgatadas).

### 5.3 Dinheiro e economia
- [ ] **Meus pagamentos e recibos** (comprovante de doação; recibo para IR quando
      a ONG emitir).
- [ ] **Minhas inscrições** (ver, cancelar, renovar, trocar cartão).
- [ ] **Meus pedidos** da loja (status, entrega, avaliação).
- [ ] **Painel da comunidade/empresa**: valores recebidos, repasses, extrato,
      dados bancários/split.
- [ ] **Gestão da loja** (vendedor): criar, editar e pausar produtos, estoque, pedidos.
- [ ] **Gestão de planos de inscrição** (comunidade): valor, benefícios, itens exclusivos.
- [ ] **Reembolso e estorno** (doação errada, pedido não entregue).
- [ ] **Objetivos diários** (tela "Ver objetivos diários" não existe).
- [ ] **Convite**: tela do código, histórico de convidados e progresso até nível 20.

### 5.4 Anúncios e empresas
- [ ] **Gerenciador de anúncios**: campanhas ativas, alcance, cliques,
      orçamento consumido, pausar e renovar.
- [ ] **Criativo do banner** (imagem, texto, link/CTA) e aprovação.
- [ ] **Relatório de impacto/ESG** da empresa (exportar PDF do currículo).
- [ ] **Patrocinar recompensa ou conquista** (criação de capa/selo/título de marca).

### 5.5 Descoberta e comunidade
- [ ] **Busca global** (pessoas, comunidades, empresas, posts, tags) e página de **tag**.
- [ ] **Mapa / eventos perto de mim** (aba Região evoluída).
- [ ] **Compartilhar fora do app** com link que abre o post (deep link + página web).
- [ ] **Denunciar** perfil, post, comentário, story e mensagem; **bloquear usuário**.

### 5.6 Plataforma
- [ ] **Painel de administração/moderação** (denúncias, verificação, aprovação
      de anúncios, catálogo de recompensas, conquistas, regras de XP).
- [ ] **Push notifications** e preferências.
- [ ] **Analytics** de produto (eventos de funil) e **crash reporting**.
- [ ] **Estados vazios, erro e offline** em todas as telas.
- [ ] **Acessibilidade** (rótulos, contraste, fonte grande — já tem teste de overflow).

---

## 6. Monetização

### 6.1 Anúncios de empresas (proposta de vocês, detalhada)
| Formato | Onde | Cobrança | Observações |
| --- | --- | --- | --- |
| **Barra de anúncio** (banner fixo) | Acima da barra inferior, em feed, detalhe e perfis. Recolhível, com rodízio | CPM (por mil exibições), segmentado por cidade/UF e categoria | O "barrinha embaixo" pedido. Máx. 1 por tela, nunca em fluxos de pagamento |
| **Post impulsionado** | No feed e nos cards para quem não segue (já no protótipo) | Alcance × localidades (cálculo do formulário) | Marcado "Patrocinado". 30% do lucro → fundo de doações |
| **Story de anúncio com recompensa** | Entre stories, usuário ganha +20 🪙 ao assistir até o fim | CPV (por visualização completa) | Teto diário de moedas por usuário |
| **Recompensa patrocinada** | Capas, selos e títulos de marca na tela de Recompensas | Valor fixo por campanha | Muito alinhado ao app: o usuário escolhe usar a marca |
| **Conquista/desafio patrocinado** | "Recicle 10 vezes com a EcoVerde" | Valor fixo + bônus por participação | Gera ação real e conteúdo |
| **Mensagem de marca** | Aba Empresas do chat | Por envio, só para seguidores | Respeitar opt-out (LGPD) |

**Google AdMob** entra como *fallback* quando não há anúncio direto vendido
(banner e **rewarded ad** para ganhar moedas). Regras das lojas: anúncio com
recompensa só no formato rewarded oficial e sem anúncio em telas de doação.

### 6.2 Outras fontes sugeridas
1. **Gorjeta opcional na doação** (modelo GoFundMe: "Deixe uma gorjeta para o
   Save Easy manter a plataforma", padrão 0%, sugestões 5/10/15%). Gera mais
   confiança que taxa fixa. Alternativa: taxa pequena e explícita (o protótipo
   cita "cobramos X% de taxa").
2. **Pacotes de moedas** (já no protótipo, com desconto progressivo). No iOS e
   no Android, bens digitais **precisam** usar compra dentro do app (Apple e
   Google ficam com 15–30%). Doações a ONGs aprovadas podem ir por fora (seguir
   as diretrizes 3.1.1 e 3.2.1 da App Store).
3. **Comissão sobre inscrições de comunidades** (ex.: 10%).
4. **Comissão na loja das comunidades** (marketplace, ex.: 8–12%).
5. **Plano Empresa (B2B, mensal)**: selo verificado, **relatório de impacto/ESG**
   exportável a partir do currículo de ações, painel de métricas, desconto em
   anúncios e página de empresa personalizada. Provavelmente a fonte mais
   escalável.
6. **Matching corporativo**: a empresa paga para "dobrar" doações de uma
   campanha até um teto. É marketing para ela e mais dinheiro para a causa.
7. **Programas de voluntariado corporativo**: a empresa contrata o app para
   engajar funcionários (desafios internos, ranking, relatório).
8. **Ingressos de eventos beneficentes pagos** (taxa por ingresso).
9. **Save Easy+** (assinatura do usuário, opcional e cosmética): capas
   animadas, moldura de avatar, mais selos equipados, sem banner. **Nunca** vender
   vantagem que pareça "comprar boa ação".

### 6.3 Fundo de doações da plataforma
O protótipo promete 30% do lucro de anúncios para doações. Proposta: um
**fundo único** recebe 30% do lucro de anúncios, mais uma parte das moedas
compradas e doadas. Mensalmente, o fundo é distribuído entre campanhas
verificadas, proporcionalmente às **doações em moedas** feitas pelos usuários.
Transparência: página pública "Para onde foi o dinheiro". **[DECIDIR]** com
jurídico e contabilidade (o percentual vem do **lucro** ou da **receita**?).

---

## 6.4 Taxas das lojas (Apple e Google): o que é permitido

**Declarar moedas ou itens digitais como "produto físico" para fugir da compra
dentro do app não é uma opção.** A Apple revisa o fluxo: as diretrizes 3.1.1 e
2.3 exigem que bens digitais usados no app (moedas, capas, selos, títulos,
impulsionamento) sejam vendidos pela compra dentro do app. A consequência é
rejeição ou remoção do app e risco para a conta de desenvolvedor, e o Google
Play tem a mesma regra. Formas legítimas de pagar menos ou nada:

| Caso | Como fica | Taxa da loja |
| --- | --- | --- |
| **Doação para ONG** (comunidade verificada) | Fora da compra dentro do app (Pix/cartão no gateway). Permitido para organizações sem fins lucrativos aprovadas (3.2.1 vi) | 0% |
| **Doação/presente de pessoa para pessoa** (vaquinha pessoal) | Fora da compra dentro do app, **desde que 100% vá para quem recebe** e não libere nada digital (3.2.1 vii). Taxa da plataforma ou recompensa em moedas atrelada à doação pode quebrar a exceção | 0% |
| **Produto físico da loja** (caneca, camiseta) | Pix/cartão normal, é bem físico de verdade (3.1.3 e) | 0% |
| **Anúncios e Plano Empresa** (B2B) | Vender pelo **painel web** para empresas (serviço corporativo, 3.1.3 c), sem botão de compra no app | 0% |
| **Moedas e itens cosméticos** | Compra dentro do app | 15% com o Small Business Program da Apple e a taxa reduzida do Google (até US$ 1 mi/ano); 30% acima disso |
| Venda das mesmas moedas **na web** | Permitido vender no site; no app só não pode ter botão nem link para comprar mais barato fora (exceto onde a lei local obriga, como os EUA e decisões de concorrência; acompanhar o caso do CADE no Brasil) | 0% na web |

**Recomendações:**
1. Moedas são **ganhas** principalmente por ações; pacotes pagos são um extra
   cosmético e entram na compra dentro do app (15%).
2. Doações sem recompensa em moedas compradas. O XP e o selo de doador podem
   continuar, mas validar com um especialista o quanto "ganhar moedas por
   doar" afeta a exceção.
3. Empresas pagam anúncios e o plano pelo **painel web** (Stripe ou Asaas),
   fora do app.
4. Ativar o **Small Business Program** (Apple) e a taxa de 15% do Google no
   primeiro dia.

---

## 6.5 Lançamento em Cuiabá - MT

- Feed "Região" usa Cuiabá-MT como padrão; o cadastro já vem com Cuiabá/MT
  preenchido e o CEP completa o endereço.
- O seed de demonstração tem organizações e ações em lugares conhecidos da
  cidade (Parque Mãe Bonifácia, Parque das Águas, Porto, CPA, Coxipó).
- Antes de abrir: cadastrar 10 a 20 **comunidades reais verificadas** de Cuiabá
  e Várzea Grande (hemocentro, abrigos de animais, ONGs ambientais e do
  Pantanal, coletivos de bairro) e 3 a 5 empresas locais como primeiros
  anunciantes.
- Anúncios segmentados por **bairro/região de Cuiabá** no começo (CPA, Coxipó,
  Centro, Porto), não por estado.
- Eventos-âncora: mutirões em parques, campanhas de doação de sangue e a
  temporada de queimadas no Pantanal (julho a outubro).

---

## 7. Roadmap

Estimativas em semanas para 1 dev full-stack Flutter + Supabase (ajustar ao time).
Cada fase entrega algo utilizável e testável.

### Fase 0 · Fundação (2–3 sem.)
- Design system (cores, tipografia, componentes, estados) e refresh das telas-base.
- Projeto Supabase (dev/prod), enums, `profiles`, Storage, RLS base, CI com
  testes e análise, ambientes e flavors no app.
- Analytics, crash reporting, i18n (PT-BR) e textos fora do código.

### Fase 1 · Conta e perfil (2–3 sem.)
- Cadastro curto + **completar perfil**, login social (Google, Apple, Facebook),
  confirmação de e-mail, recuperar senha (OTP 6 dígitos).
- Perfil público e próprio, **editar perfil** (foto, capa, bio), seguir,
  **listas de seguidores**, **configurações**, **excluir conta**, termos.
- Verificação de comunidade/empresa (envio de documentos + aprovação manual no painel).

### Fase 2 · Publicações (3–4 sem.)
- Criar, **editar, arquivar e excluir** os 7 tipos (formulário único por tipo),
  capa e galeria, tags, categorias, **marcar pessoas**.
- Feed (Popular / Região / Seguindo), busca global, página de tag.
- Detalhe com curtir, salvar/**Tenho interesse**, compartilhar (deep link),
  comentários com **respostas**, editar e excluir comentário, denunciar.
- **Minhas publicações** e **Salvos**.

### Fase 3 · Participação e gamificação (3 sem.)
- Participar, cancelar, **lista de participantes**, **check-in por QR**,
  **fotos dos participantes**, lembretes.
- Doação de itens (**pedidos, aceitar, entregue**).
- XP, níveis, ledger de moedas, conquistas (diárias e gerais), **objetivos
  diários**, recompensas (resgatar, equipar), **convite com código**.
- Currículo de ações (filtro por período, página completa) e álbum.

### Fase 4 · Stories, mensagens e notificações (2–3 sem.)
- Stories 24 h (criar, ver, excluir, quem viu, responder → DM).
- Chat 1:1 e grupos de comunidade (Realtime), post compartilhado, bloquear.
- Notificações in-app e push, preferências, **seguir publicação**.

### Fase 5 · Dinheiro (4–5 sem.)
- Gateway (Pix e cartão) com split, **doação com dinheiro**, atualizações de
  campanha, recibos, reembolso.
- Compra de moedas (IAP nas lojas, Pix na web), **doação com moedas** e fundo de doações.
- **Inscrições** em comunidades (planos, cancelar, itens exclusivos).
- **Painel financeiro** da comunidade/empresa (recebidos, repasses).

### Fase 6 · Monetização com empresas (3–4 sem.)
- **Gerenciador de anúncios**: post impulsionado (alcance e localidades), **barra
  de anúncio**, story com recompensa, aprovação, métricas.
- AdMob como fallback; recompensas e conquistas patrocinadas.
- **Plano Empresa** (relatório de impacto/ESG em PDF).

### Fase 7 · Loja (2–3 sem.)
- Gestão de produtos e pedidos (vendedor), compra, status, entrega, avaliações,
  comissão.

### Fase 8 · Plataforma e lançamento (2–3 sem., em paralelo a partir da Fase 2)
- Painel admin/moderação (denúncias, verificação, anúncios, catálogos e regras).
- Página pública de transparência do fundo.
- Testes de carga das RPCs de feed, auditoria de RLS, LGPD, publicação nas lojas.

**Ordem sugerida de lançamento:** um **MVP público** depois das Fases 0–4
(sem dinheiro real: só moedas e ações), para validar engajamento e formar base.
Dinheiro (Fase 5) entra com as primeiras comunidades verificadas. Anúncios (Fase 6)
entram quando houver audiência para vender.

---

## 8. Decisões em aberto (produto)

1. Doar com moedas: conversão, origem do dinheiro (fundo) e tetos.
2. Fórmula de XP/moedas por real doado (o protótipo tem números inconsistentes).
3. Taxa na doação **ou** gorjeta opcional.
4. Quem pode anunciar (só empresas, como diz o protótipo, ou também comunidades
   e influenciadores) e preço base de CPM/alcance.
5. "30% do lucro" de anúncios: lucro ou receita, e como distribuir o fundo.
6. Quem pode avaliar (⭐) comunidades e empresas.
7. Perfil privado existe?
8. Mensagens de marca: permitidas? Só para seguidores? Com limite?
9. Pergunta Sim/Não dos formulários de Ação social e Tutorial (o texto está
   ilegível no protótipo).
10. Uso de marcas reais (Unicef, Greenpeace, Coca-Cola…) só com parceria formal.
