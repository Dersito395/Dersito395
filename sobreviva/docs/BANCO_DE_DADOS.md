# Banco de dados

Dois arquivos SQLite em `<Application Support>/sobreviva/`:

| Arquivo | Conteúdo | Quem altera |
|---|---|---|
| `library.db` | conteúdo editorial + índice de pesquisa | somente importação de pacotes |
| `user.db` | dados pessoais | somente ações do usuário |

Separar os arquivos garante, por construção, que **atualizações não apagam favoritos, anotações, listas ou
preferências**. Todo artigo tem um identificador estável (`id`), usado como chave nas tabelas do usuário.

## `library.db` (esquema v3 — `app/lib/data/library_db.dart`)

| Entidade do projeto | Tabela | Observações |
|---|---|---|
| Categoria | `category` | id, nome, ícone, descrição, ordem |
| Subcategoria | `subcategory` | (category_id, id) |
| Artigo | `article` | id único, **versão**, **idioma** (`lang`), **status editorial**, dificuldade, tempo, objetivo, essencial, revisão técnica (exigida/status/revisor/data), `updated_at` (data de revisão), pacote de origem |
| Etapa do procedimento | `article_step` | texto + imagem opcional, ordenadas |
| Material necessário | `article_material` | ordenado |
| Cuidados / Alternativas | `article_caution`, `article_alternative` | ordenados |
| Ambiente | `article_environment` | urbano, doméstico, mata, montanha, rural, litoral, qualquer |
| Imagem | `image`, `article_image` | arquivo, tipo, SHA-256, tamanho, crédito, licença, local (`asset` ou `file`); legenda e texto alternativo por artigo |
| Fonte bibliográfica | `source`, `article_source` | instituição, autor, título, editora, ano, URL, licença, idioma; nota do que a fonte fundamenta no artigo |
| Etiqueta | `tag`, `article_tag` | `kind` = `tag` (exibida) ou `keyword` (só pesquisa) |
| Artigo relacionado | `article_related` | ordenado (curadoria editorial) |
| Pacote de conteúdo | `content_package`, `package_article` | versão, data de publicação e de instalação, tamanho, se é embarcado |
| Versão editorial | `editorial_version` | histórico das versões de cada artigo instaladas no aparelho |
| Guias de emergência | `emergency_guide` | seções em JSON (reconhecer, segurança, fazer, evitar, pedir socorro) |
| Cenários de crise (v2) | `scenario` | roteiro por fases em JSON |
| Consultas (v3) | `reference_item` | `kind` = `document` (PDF offline com destaques por página) ou `link` (endereço externo, oficial ou de comunidade); dados em JSON |
| Números de emergência | `emergency_number` | número, nome, finalidade, prioridade |
| Sinônimos | `synonym_term` | grupos de termos normalizados |
| Índice de pesquisa | `article_fts` (FTS5) + `article_vocab` (fts5vocab) | colunas: título, etiquetas, resumo, corpo; `unicode61 remove_diacritics 2` |
| Metadados | `meta` | `library_version`, `last_update` |

Regras de importação: uma transação por pacote; artigos com versão igual ou menor que a instalada são ignorados
(nunca há rebaixamento); filhos são removidos por `ON DELETE CASCADE` e reinseridos; o índice FTS é atualizado
na mesma transação.

## `user.db` (esquema v1 — `app/lib/data/user_db.dart`)

| Entidade do projeto | Tabela |
|---|---|
| Favorito | `favorite (article_id, created_at)` |
| Nota pessoal | `note (article_id, text, updated_at)` |
| Histórico de leitura | `history (article_id, viewed_at, view_count)` |
| Histórico de pesquisa | `search_history (query, created_at)` — últimas 50 |
| Checklist / lista de equipamentos / mochila | `checklist (title, kind, article_id, params)` + `checklist_item (text, done, section, position)` |
| Preferências | `pref (key, value)` — tema, fonte, modos, servidor, verificação automática |

## Formato de exportação de dados do usuário

```json
{
  "app": "sobreviva", "format": 1, "exported_at": "…",
  "favorites": ["ps-rcp-adulto"],
  "notes": [{ "article_id": "…", "text": "…", "updated_at": "…" }],
  "checklists": [{ "title": "…", "kind": "mochila", "article_id": null,
                   "items": [{ "text": "…", "done": false, "section": "…" }] }]
}
```

A importação **mescla**: não apaga nada; notas diferentes para o mesmo artigo são concatenadas.

## Migrações

Cada banco guarda a versão do esquema em `PRAGMA user_version`. Uma nova versão do app adiciona um bloco
`if (current < N) { … }` executado em transação. Pacotes de conteúdo têm um campo `format`; o app recusa formatos
mais novos que conhece e orienta o usuário a atualizar o aplicativo.

- v2: tabela `scenario` (roteiros de crise).
- v3: tabela `reference_item` (aba Consultas). Bancos antigos recebem a tabela vazia; o conteúdo chega com o
  pacote essencial embarcado na nova versão do app ou com a próxima atualização.
