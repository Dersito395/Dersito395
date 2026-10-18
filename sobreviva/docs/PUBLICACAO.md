# Instalação e publicação nas lojas (Etapa 8)

## Pré-requisitos

- Flutter 3.47+ (Dart 3.13+), Android SDK 36 / Xcode 26 para iOS.
- Conta Google Play Console e Apple Developer Program.
- Servidor HTTPS para o serviço de atualização (opcional para o app funcionar; necessário para pacotes extras).
- **Revisão técnica dos artigos de saúde concluída** no painel. Em seguida, gerar a biblioteca embarcada em modo
  estrito para a versão de loja:

```bash
cd server && npm run build:release   # exclui saúde sem revisão aprovada e atualiza app/assets
```

## Android

1. Gerar a chave de assinatura (uma vez; guarde-a em local seguro — perder a chave impede atualizações):
   ```bash
   keytool -genkey -v -keystore ~/sobreviva-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Criar `app/android/key.properties` (já ignorado pelo git):
   ```
   storeFile=/caminho/para/sobreviva-upload.jks
   storePassword=…
   keyAlias=upload
   keyPassword=…
   ```
3. Build:
   ```bash
   cd app
   flutter build appbundle --release --dart-define=UPDATE_SERVER=https://SEU-DOMINIO/api/v1/   # Play Store (.aab)
   flutter build apk --release --split-per-abi --dart-define=UPDATE_SERVER=https://SEU-DOMINIO/api/v1/   # instalação direta
   ```
4. Identificador do app: `br.app.sobreviva.sobreviva` (altere em `android/app/build.gradle.kts` e no Xcode antes
   da primeira publicação, se desejar outro).

## iOS

1. `open app/ios/Runner.xcworkspace`, selecionar a equipe em *Signing & Capabilities* e o Bundle Identifier.
2. `flutter build ipa --release --dart-define=UPDATE_SERVER=https://SEU-DOMINIO/api/v1/`
3. Enviar com Transporter ou Xcode Organizer; testar via TestFlight (roteiro em [TESTES.md](TESTES.md)).

## Servidor (painel + atualizações)

```bash
cd server
node scripts/create-user.js admin admin "Nome"
HOST=127.0.0.1 PORT=8787 COOKIE_SECURE=1 npm start
```

Coloque atrás de um proxy TLS (Caddy, nginx). Variáveis: `CONTENT_DIR`, `DATA_DIR` (usuários; **não** versionar),
`DIST_DIR`. Faça backup de `content/` (de preferência em git) e de `data/`. O diretório `dist/updates/` pode ser
publicado em uma CDN estática.

## Ficha da loja (sugestão)

- **Nome**: SOBREVIVA | Biblioteca de Campo
- **Categoria**: Livros e referências (Android) / Referência (iOS)
- **Descrição curta** (80): Manual de sobrevivência e emergências que funciona sem internet.
- **Descrição**: veja [loja/descricao.md](loja/descricao.md).
- **Política de privacidade**: [loja/privacidade.md](loja/privacidade.md) (publicar em URL pública).
- **Ícone 1024×1024**: [loja/icone-1024.png](loja/icone-1024.png). Capturas de tela: gerar com
  `SCREENSHOTS=1 flutter test test/screenshots/` e complementar com capturas do aparelho.
- **Segurança dos dados (Play) / Privacidade (App Store)**: nenhum dado coletado; nenhum compartilhamento;
  nenhuma conta; dados ficam no aparelho.
- **Classificação indicativa**: conteúdo informativo de saúde e segurança, sem violência gráfica.

## Cuidados com políticas das lojas

- Conteúdo de saúde: manter os avisos de que o app **não substitui** atendimento profissional e citar fontes
  (exigência comum das lojas para apps de informação médica).
- Não prometer resultados ("salva vidas") nem sugerir que o app substitui o 192/193/190.
- O app usa a rede apenas para baixar conteúdo; declare isso na revisão.
- Permissões Android: apenas `INTERNET` e `ACCESS_NETWORK_STATE`. iOS: nenhuma permissão sensível.
