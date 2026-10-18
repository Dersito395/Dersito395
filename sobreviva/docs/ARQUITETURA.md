# Arquitetura

## Princípios

1. **Offline primeiro**: tudo que é essencial (artigos, imagens, guias de emergência, fontes, índice de pesquisa,
   favoritos, notas, histórico) está no aparelho. A rede só é usada, quando permitida, para baixar pacotes.
2. **Sem conta para ler**: o app não tem login. Autenticação existe apenas no painel editorial.
3. **Dados do usuário intocáveis**: conteúdo e dados pessoais ficam em bancos separados.
4. **Atualizações atômicas e verificáveis**: falhar nunca deixa a biblioteca pela metade.
5. **Conteúdo rastreável**: todo artigo cita fontes reais, com licença e data de revisão.

## Componentes (separação exigida no projeto)

```
 ┌──────────────────────────── Aparelho (Android / iOS) ─────────────────────────────┐
 │  1. Aplicativo mobile (Flutter)                                                    │
 │     UI ── AppState ── SearchEngine                                                 │
 │              │            │                                                        │
 │  2. Biblioteca local      ▼                                                        │
 │     library.db (SQLite + FTS5)   user.db (favoritos, notas, listas, histórico)     │
 │     assets/content/essencial.json + assets/media/*.svg   (embarcados no app)       │
 │     <suporte>/sobreviva/media/*  (imagens de pacotes baixados)                     │
 └───────────────────────────────▲───────────────────────────────────────────────────┘
                                 │ HTTPS (opcional): manifest.json + pacotes
 ┌───────────────────────────────┴───────────── Servidor ────────────────────────────┐
 │  4. Serviço de atualização  GET /api/v1/manifest.json, /api/v1/packages/<id>-vN.json │
 │     (arquivos estáticos imutáveis — pode ser servido por qualquer CDN)              │
 │  3. Plataforma de administração  /admin (web) + /api/admin (autenticada)            │
 │  5. Repositório de mídia  content/media + media.json (crédito e licença)            │
 │     Repositório editorial  content/ (JSON versionável em git)                       │
 └────────────────────────────────────────────────────────────────────────────────────┘
```

### 1. Aplicativo mobile — `app/`

- **Flutter** (Material 3), estado com `provider` (`AppState`, um `ChangeNotifier`).
- Navegação inferior: **Início | Explorar | Emergências | Salvos | Ajustes** (`app/lib/app.dart`).
- Consultas SQLite são síncronas e rápidas (milissegundos para ~40 artigos e o índice FTS5); as telas leem
  diretamente dos bancos e se reconstroem com `notifyListeners()`.
- Temas: claro, escuro, **ambiente externo** (alto contraste, texto maior e mais forte) e **economia de bateria**
  (preto puro, sem animações, sem verificação automática de atualizações).
- Plataforma nativa: um `MethodChannel` (`br.app.sobreviva/storage`) informa o espaço livre
  (Android `StatFs`, iOS `volumeAvailableCapacityForImportantUsage`).

### 2. Biblioteca local

- `sqlite3` (Dart FFI) com SQLite **3.54 embarcado** pelo próprio pacote: FTS5 disponível de forma idêntica em
  Android e iOS (o SQLite do sistema Android nem sempre tem FTS5).
- `library.db`: conteúdo + índice. `user.db`: dados pessoais. Ambos com `journal_mode=WAL` e migrações por
  `PRAGMA user_version`.
- Na primeira abertura (e após atualizações do app), `BundledContent.ensureInstalled` importa
  `assets/content/essencial.json` se ele for mais novo que o instalado — sem rede.

### 3. Plataforma de administração — `server/`

- Node.js 22, **zero dependências** (menos superfície de ataque, nada a atualizar).
- Papéis: `editor`, `revisor`, `admin` (detalhes em [EDITORIAL.md](EDITORIAL.md)).
- Senhas com scrypt, sessão em cookie `HttpOnly; SameSite=Strict` (e `Secure` com `COOKIE_SECURE=1`), token CSRF,
  bloqueio após 5 tentativas, CSP restritiva no painel.

### 4. Serviço de atualização

- `server/src/builder.js` gera `manifest.json` e um arquivo JSON por pacote e versão (`<id>-v<N>.json`), com
  tamanho e SHA-256. Arquivos de pacote são imutáveis (cache de 1 ano); o manifesto é `no-cache`.
- Pode ser servido pelo próprio `server.js` ou copiado para qualquer hospedagem estática/CDN.

### 5. Repositório de mídia

- `content/media/` + `content/media.json` (crédito, licença, origem). O painel recusa imagens sem crédito e licença
  e SVGs com conteúdo ativo.

## Fluxos principais

**Primeiro acesso em modo avião**: abrir bancos → importar `essencial.json` embarcado → indexar FTS5 → pronto.

**Pesquisa**: consulta → normalização → correção ortográfica pelo vocabulário do índice (`fts5vocab`) →
expansão por sinônimos → FTS5/BM25 + cobertura de conceitos → filtros → resultados. Ver [PESQUISA.md](PESQUISA.md).

**Atualização**: conexão restabelecida → (máx. 1×/6 h, se permitido) baixa `manifest.json` → mostra pacotes com
tamanho, versão e data → usuário baixa → verificação de tamanho e SHA-256 → imagens verificadas em área temporária →
**importação em uma única transação** → imagens movidas para o lugar → índice de pesquisa recarregado.
Ver [ATUALIZACOES.md](ATUALIZACOES.md).

**Publicação editorial**: rascunho → revisão (técnica, para saúde) → aprovação → publicação do artigo → nova
versão da biblioteca (pacotes + manifesto). Ver [EDITORIAL.md](EDITORIAL.md).

## Uso de IA

Nenhuma função essencial depende de IA ou de API externa. Uma camada opcional de IA (por exemplo, para reformular
perguntas quando houver internet) pode ser adicionada como recurso extra, sempre caindo para a pesquisa local.
