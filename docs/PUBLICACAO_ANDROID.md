# Publicação no Android (Google Play)

## O que já está pronto no projeto

| Item | Onde | Situação |
| --- | --- | --- |
| Identificador do app | `br.com.saveeasy.app` (`android/app/build.gradle.kts`) | ✅ |
| Nome exibido | "Save Easy" (`AndroidManifest.xml`) | ✅ |
| Ícone (normal e adaptativo) | `assets/icon/` → gerado com `fvm dart run flutter_launcher_icons` | ✅ |
| Versão | `pubspec.yaml` → `version: 1.0.0+1` (nome+código) | ✅ |
| Assinatura de release | chave de upload em `~/.saveeasy-keys/saveeasy-upload.jks`, senhas em `android/key.properties` (fora do git) | ✅ |
| R8 (minificação e encolher recursos) | `isMinifyEnabled`/`isShrinkResources` + `proguard-rules.pro` | ✅ |
| Permissões | Internet, estado da rede, câmera, ID de publicidade (AdMob) | ✅ |
| AdMob | ID do app no manifesto; banner "Barra inferior" | ✅ |
| Deep link | `app.saveeasy://login-callback` | ✅ |
| Política de privacidade (URL pública) | https://vihangel.github.io/saveasy/privacidade.html | ✅ (falta o e-mail de contato) |
| Exclusão de conta (URL pública) | https://vihangel.github.io/saveasy/excluir-conta.html | ✅ (falta o e-mail de contato) |
| App Bundle assinado | `build/app/outputs/bundle/release/app-release.aab` | ✅ |

### Gerar uma nova versão
1. Subir a versão em `pubspec.yaml` (ex.: `1.0.1+2`; o número depois do `+` sempre aumenta).
2. `fvm flutter build appbundle --release`
3. Enviar `build/app/outputs/bundle/release/app-release.aab` no Play Console.

### ⚠️ Chave de upload (guarde com cuidado)
- Arquivo: `~/.saveeasy-keys/saveeasy-upload.jks` · alias `upload`.
- Senhas: `android/key.properties` (cópia em `~/.saveeasy-keys/key.properties.backup`).
- **Faça backup dos dois arquivos** (ex.: gerenciador de senhas + armazenamento seguro). Nunca coloque no git.
- Com a **Assinatura de apps do Google Play** ativada (padrão), se perder a chave de upload dá para pedir
  a troca ao suporte do Google; a chave final do app fica com o Google.

## Antes de enviar (pendências)
1. **E-mail de contato** nas páginas `web/privacidade.html` e `web/excluir-conta.html` (trocar o texto entre colchetes).
2. **Conta de desenvolvedor Google Play** (US$ 25, uma vez). Contas pessoais novas precisam de **teste fechado
   com 12 testadores por 14 dias** antes de liberar a produção; contas de organização (CNPJ + D-U-N-S) não.
3. Remover a conta de teste e as contas demo do banco (pendência 5 do relatório) e mudar pagamentos para produção
   quando o gateway estiver pronto (enquanto isso o app mostra "ambiente de testes" no checkout).
4. **Moedas são bem digital:** na Play, a venda de moedas dentro do app precisa usar o **Google Play Billing**.
   Doações para causas, inscrições e produtos físicos da loja podem usar Pix/cartão. Até integrar o Billing,
   a opção é esconder a compra de moedas no app Android (ver PRODUTO_E_ROADMAP §6.4).

## Passo a passo no Play Console
1. **Criar app:** nome "Save Easy", idioma português (Brasil), tipo App, gratuito.
2. **Configurar o app** (painel "Configurar seu app"):
   - Acesso ao app: "Algumas funcionalidades são restritas" → informar uma conta de teste para a revisão do Google.
   - Anúncios: **Sim, contém anúncios**.
   - Classificação de conteúdo: questionário IARC (categoria "Rede social / comunicação"; tem interação entre
     usuários, compartilhamento de localização (cidade) e compras digitais).
   - Público-alvo: **13+** (não é voltado para crianças).
   - App de notícias: não. Apps de saúde: não. Financeiro: não (é doação/marketplace, não serviço financeiro).
   - Segurança dos dados: respostas abaixo.
   - Política de privacidade: URL acima.
   - Exclusão de conta: URL acima e "o usuário pode excluir dentro do app".
3. **Ficha da loja principal:** textos abaixo; ícone 512×512 (`assets/icon/icon_full.png` redimensionado);
   imagem de destaque 1024×500; pelo menos 2 capturas de tela de celular.
4. **Teste interno** → enviar o `.aab` → adicionar testadores por e-mail → testar.
5. **Teste fechado** (12 testadores, 14 dias, se a conta for pessoal) → **Produção**.
6. Depois de publicado: no **AdMob**, em cada app, "Adicionar loja" (liga o app ao anúncio da Play) e publicar o
   `app-ads.txt` no domínio do desenvolvedor informado na ficha.

## Segurança dos dados (respostas sugeridas)
| Pergunta | Resposta |
| --- | --- |
| Coleta ou compartilha dados? | Sim |
| Dados criptografados em trânsito? | Sim (HTTPS) |
| Usuário pode pedir exclusão? | Sim (no app e pela URL) |
| **Informações pessoais** | Nome, e-mail, endereço (CEP/rua/cidade), outros (CPF/CNPJ só na verificação) — coletados, não compartilhados; finalidade: funcionalidade do app, gerenciamento da conta |
| **Informações financeiras** | Histórico de compras — coletado; compartilhado com o processador de pagamento; finalidade: funcionalidade do app |
| **Fotos** | Coletadas (perfil, publicações, stories, documentos de verificação); finalidade: funcionalidade do app |
| **Mensagens** | Outras mensagens no app — coletadas; finalidade: funcionalidade do app |
| **Atividade no app** | Interações, conteúdo gerado pelo usuário — coletados; finalidade: funcionalidade do app, análise |
| **Identificadores do dispositivo** | ID de publicidade — coletado e compartilhado com o Google AdMob; finalidade: publicidade |
| **Localização** | Aproximada? Não (só a cidade digitada no perfil, que entra em "Informações pessoais") |

## Textos da ficha da loja

**Nome (até 30):** Save Easy: boas ações

**Descrição curta (até 80):**
Doe, participe de ações sociais em Cuiabá e ganhe moedas fazendo o bem.

**Descrição completa:**
O Save Easy reúne quem quer ajudar e quem precisa de ajuda em Cuiabá e Várzea Grande.

• Encontre doações, eventos, mutirões e ações sociais perto de você
• Participe, faça check-in e ganhe moedas e XP a cada boa ação
• Doe por Pix ou com suas moedas — o fundo de doações transforma moedas em dinheiro para a causa
• Siga comunidades, converse em tempo real e acompanhe as novidades das campanhas
• Troque moedas por selos, títulos e capas para o seu perfil
• Compre na loja das comunidades e ajude a manter os projetos
• Empresas e influenciadores anunciam para a região, e 30% do valor vai para o fundo de doações
• Transparência: veja quanto entrou e saiu do fundo de doações

Comunidades verificadas recebem doações e repasses via Pix. Faça parte da rede do bem de Mato Grosso.

**Categoria:** Social · **Tags:** caridade, voluntariado, doação
