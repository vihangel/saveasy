# Relatório: protótipo do Figma → app

Arquivo analisado: "Telas - Protótipo (Copy)" (1 página, ~95 frames).

## Como o Figma foi lido

- As telas de **onboarding, login, recuperação de senha, cadastro** e **criar
  publicação** foram vistas por screenshot. Visual, cores e textos seguem o Figma.
  As ilustrações foram recortadas desses screenshots (`assets/images/`), em baixa
  resolução. **Pendência:** exportar as ilustrações originais do Figma em 2x/3x.
- O plano Starter do Figma limitou as chamadas da integração. As telas da seção
  "TELAS - A FAZER" (feed, perfis, doação, evento, carteira...) foram
  implementadas a partir da **estrutura e dos textos das camadas**, não de
  screenshots. Por isso o layout delas segue o fluxo e o conteúdo, não o pixel.
- Os textos dessas telas eram placeholders de UI kit em inglês ("Help Malika to
  school", "Clarence Rodgers", "Donate", "Message friends"). Foram trocados por
  conteúdo em português coerente com o app.
- Fotos de posts e produtos não existem nos dados: usei capas geradas por tipo
  (gradiente + ícone) e avatares com iniciais.

Paleta extraída: laranja `#FA7E2A`, primária `#6176ED`, superfície `#F5F6F7`,
texto `#121526` / `#8F92A1`, link `#519DE0`. Fontes: Quicksand (títulos/botões)
e Poppins (texto).

## Telas que não deu para entender (interpretadas ou pendentes)

| Frame no Figma | O que tinha | O que foi feito |
| --- | --- | --- |
| **iPhone X, XS, 11 Pro – 27** | Busca, lista de contatos com telefone ("Jimmy Sulivan"), um "Balance $115" e botões | Interpretado como **"Enviar moedas para um amigo"** (Carteira → Enviar moedas para um amigo). Confirmar a intenção. |
| **Feed 1 → "Veja seus Cards"** | Um bloco "Cards" no topo do feed | Não implementado: não ficou claro o que são os "cards" (coleção? cartões de doação?). |
| **Feed → aba "First"** | Abas "Popular / Following / First" | Implementado como **Popular / Na sua região / Seguindo**, casando com as seções de Feed 1/2/3. O nome "First" não ficou claro. |
| **Perfil → aba "Analyze"** | Abas "Posts / Analyze" e os frames "Currículo de Ações" e "Álbum de boas ações" com o mesmo cabeçalho | Virou 3 abas: **Publicações / Currículo / Álbum**. O conteúdo do currículo (resumo de XP, doações e ações por tipo) foi definido por mim, porque o frame tinha só placeholders ("Traning Plans"). |
| **Discussão 3** | Marcadores "01:00 / 04:00" | Parece um player de áudio/vídeo. Não implementado: a discussão mostra texto e comentários. |
| **Doar 1** | "+10 / +100", "LV 1 → LV 2" antes de doar | Unido à tela de valor como aviso de recompensa. O sucesso (Doar 3/4) mostra a barra de nível. |
| **Criar Propaganda** | Campos "Phone Number +768-907-6969" com ícone de dinheiro, "Start a Charity" | Interpretado como **planos de divulgação** (Diário / Semanal / Mensal com preço). A anotação "Adicionar opção para uma propaganda ou currículo de boas ações" virou o campo "O que deseja divulgar?". O pagamento do plano não é cobrado. |
| **Criar Atividades** | Dois campos de telefone e a nota "Retirar data e tipo de atividade" | Formulário com local e vagas. Mantive o "tipo" como dropdown opcional. Confirmar se deve sair. |
| **Inscrição Comunidade 1/2** | Só placeholders ("Start an interesting", "Donate") | Benefícios de apoiador + planos Mensal/Anual + confirmação. Benefícios e preços definidos por mim. |
| **Validate código** | Tela solta depois do cadastro | Usada no fluxo de **recuperar senha** (e-mail → código → nova senha). A anotação do Passo 2 ("verificar se tem a necessidade de receber por email") continua em aberto. |
| **Stories 4 / Stories - Add** | "+20" em um anúncio | Assistir um story de propaganda dá +20 moedas (uma vez). Publicar story também dá +20. |
| **Recompensas → "Convide e ganhe pontos"** | Banner | Só copia um link fictício. Não há fluxo de convite. |

## Anotações do Figma e o que foi feito

- "Esse voltar abre um popUp para verificar se deseja realmente sair da criação
  de conta": **feito** (diálogo no 1º passo do cadastro).
- "No lugar de nickname nome de usuário ou @": **feito** ("Nome de usuário @").
- "Pensar aqui nos dados de localização": o endereço é salvo, mas ainda não há
  busca por CEP nem mapa.
- "LOCAL OU SITE: definir local no mapa / Nesse evento irão ganhar 10 moedas +
  capa/título/selo": local e site são campos de texto (sem mapa). A recompensa
  aparece nos detalhes, em moedas e XP.
- "Local (opcional), Dinheiro (opcional), Vincular doações": a doação tem local
  opcional. "Vincular doações" não foi feito.
- "PARTE DE DESENVOLVIMENTO (IGNORAR)": ignorado.

## Regras de negócio que eu inventei (validar)

- Nível = XP ÷ 300 + 1. Ações dão moedas e XP definidos em cada publicação.
- A carteira tem **saldo em R$** (doações, loja, inscrições, compra de moedas) e
  **moedas** (enviar para pessoas, resgatar recompensas). O botão "Adicionar
  saldo" coloca R$ 100 fictícios.
- Pacotes de moedas: 1.000 / 2.500 / 5.000 por R$ 4,99 / 11,99 / 24,90. O Figma
  mostrava "$0.99" em todos.
- Máximo de 3 selos exibidos no perfil.
