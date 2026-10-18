# SOBREVIVA | Biblioteca de Campo

Biblioteca virtual de sobrevivencialismo, preparação para emergências, primeiros socorros e autossuficiência,
**feita para funcionar sem internet**. MVP executável para Android e iOS (Flutter), com biblioteca local SQLite + FTS5,
pesquisa em linguagem natural offline, central de emergências, pacotes de conteúdo versionados e painel editorial.

> ⚠️ O aplicativo é informativo e **não substitui** os serviços de emergência (192, 193, 190) nem atendimento profissional.
> Os 8 artigos de primeiros socorros estão marcados como **revisão técnica pendente** até a validação por profissional
> habilitado (veja [docs/EDITORIAL.md](docs/EDITORIAL.md)).

## Estrutura

```
sobreviva/
├── app/          Aplicativo mobile (Flutter, Android + iOS)
│   ├── lib/core        tema, paleta, normalização de texto
│   ├── lib/data        banco da biblioteca (library.db) e banco do usuário (user.db)
│   ├── lib/search      motor de pesquisa offline (FTS5 + sinônimos + correção)
│   ├── lib/services    atualização de pacotes, conteúdo embarcado, planejador de mochila
│   ├── lib/ui          telas: Início, Explorar, Emergências, Salvos, Ajustes, artigo, busca…
│   ├── assets/content  biblioteca essencial embarcada (gerada pelo construtor)
│   └── assets/media    ilustrações essenciais (geradas pelo construtor)
├── content/      Repositório editorial (fonte da verdade): artigos, fontes, sinônimos,
│                 categorias, guias de emergência, números, pacotes, mídia + créditos
├── server/       Plataforma de administração + construtor de pacotes + serviço de atualização
│   ├── src/            Node.js 22, sem dependências externas
│   ├── public/admin    painel web (HTML/CSS/JS)
│   └── dist/updates    pacotes publicados (manifest.json + packages/*.json)
├── tools/        Gerador das ilustrações originais (SVG)
└── docs/         Arquitetura, banco de dados, pesquisa, editorial, atualizações, testes, publicação
```

## Início rápido

**Aplicativo** (Flutter 3.47+ / Dart 3.13+):

```bash
cd app
flutter pub get
flutter test                 # 43 testes: dados, pesquisa, atualizações, planejador e interface
flutter run                  # em um aparelho ou emulador
flutter build apk --release  # APK de instalação (veja docs/PUBLICACAO.md para assinatura)
```

**Conteúdo e servidor** (Node.js 22+, sem `npm install`):

```bash
cd server
npm run build:content        # valida o conteúdo e gera pacotes + biblioteca embarcada no app
npm test                     # 10 testes: autenticação, CSRF, fluxo editorial, publicação, integridade
node scripts/create-user.js admin admin "Seu Nome"   # cria o primeiro administrador
npm start                    # painel em http://127.0.0.1:8787/admin/  ·  API em /api/v1/
```

Para testar atualizações no emulador Android, rode o servidor com `HOST=0.0.0.0` e configure no app
(Ajustes › Pacotes e atualizações › Servidor) o endereço `http://10.0.2.2:8787/api/v1/`.
Em produção use HTTPS: o app recusa HTTP fora da rede local.

## O que está implementado

| Requisito | Onde |
|---|---|
| Biblioteca inicial com **37 artigos essenciais + 2 complementares**, 12 categorias, fontes reais | `content/articles`, `content/sources.json` |
| **Funciona em modo avião desde o primeiro acesso** (biblioteca embarcada, sem login) | `app/lib/services/bundled_content.dart` |
| SQLite + **FTS5** (SQLite 3.54 embarcado pelo pacote `sqlite3`, igual em Android e iOS) | `app/lib/data/library_db.dart` |
| Pesquisa: texto integral, autocompletar, correção de digitação, sinônimos, filtros (categoria, dificuldade, ambiente), relevância, histórico, relacionados | `app/lib/search/search_engine.dart` |
| Central de emergências: 11 guias (reconhecer, segurança, fazer, evitar, pedir socorro) + 190/192/193/199 com finalidade | `content/emergencies.json`, `app/lib/ui/screens/emergency_screens.dart` |
| 23 ilustrações originais (SVG, CC BY 4.0) disponíveis offline | `content/media`, `tools/make_illustrations.py` |
| Favoritos, anotações privadas, checklists, listas de equipamentos, planejador de mochila, histórico pesquisável, exportação/importação | `app/lib/data/user_db.dart`, telas em `app/lib/ui/screens` |
| Tamanho de fonte, modo claro/escuro, **modo ambiente externo** (alto contraste), **economia de bateria** | `app/lib/core/theme.dart`, Ajustes |
| Pacotes versionados com tamanho, data, espaço livre, SHA-256, cancelamento e **instalação atômica** (falhas não apagam nada) | `app/lib/services/package_service.dart`, `server/src/builder.js` |
| Dados do usuário em banco separado: atualizações nunca apagam favoritos/notas/listas | `user.db` × `library.db` |
| Painel administrativo com login, papéis, rascunho → revisão → aprovação (revisão técnica para saúde) → publicação, histórico de versões, mídia com licença obrigatória | `server/src/server.js`, `server/public/admin` |

## Etapas do desenvolvimento

| Etapa | Situação |
|---|---|
| 1. Projeto técnico, arquitetura, banco, telas | ✅ concluída — [docs/ARQUITETURA.md](docs/ARQUITETURA.md), [docs/BANCO_DE_DADOS.md](docs/BANCO_DE_DADOS.md) |
| 2. Biblioteca inicial (30+ artigos) | ✅ 39 artigos com fontes; **revisão técnica profissional dos 8 artigos de saúde pendente** |
| 3. Pesquisa offline, categorias, favoritos, leitura, checklists | ✅ concluída e testada |
| 4. Central de emergências e ilustrações | ✅ 11 guias, 23 ilustrações originais |
| 5. Downloads, atualizações, pacotes | ✅ concluída e testada (integridade, falhas, cancelamento) |
| 6. Painel administrativo e revisão editorial | ✅ concluída e testada (inclusive no navegador) |
| 7. Testes em dispositivos físicos | ⏳ roteiro pronto em [docs/TESTES.md](docs/TESTES.md); requer aparelhos Android/iOS |
| 8. Instalação, documentação, lojas | 📄 guia em [docs/PUBLICACAO.md](docs/PUBLICACAO.md); falta conta de desenvolvedor, chave de assinatura e servidor HTTPS |

## Documentação

- [Arquitetura](docs/ARQUITETURA.md) · [Banco de dados](docs/BANCO_DE_DADOS.md) · [Pesquisa offline](docs/PESQUISA.md)
- [Processo editorial e fontes](docs/EDITORIAL.md) · [Pacotes e atualizações](docs/ATUALIZACOES.md)
- [Testes e critérios de aceitação](docs/TESTES.md) · [Publicação nas lojas](docs/PUBLICACAO.md)
