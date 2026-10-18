# Pesquisa offline

Implementação: `app/lib/search/search_engine.dart` e `app/lib/core/text_normalizer.dart`.
Nenhuma etapa usa rede ou IA.

## Etapas

1. **Normalização** — minúsculas, sem acentos, sem pontuação (`"Não tenho água potável."` → `nao tenho agua potavel`).
   Palavras vazias do português ("como", "estou", "o que fazer"…) são removidas.
2. **Correção de digitação** — cada palavra desconhecida é comparada ao vocabulário do índice (`fts5vocab`) e aos
   sinônimos por distância de Damerau-Levenshtein (até 1 para palavras de até 4 letras, até 2 para as demais).
   Desempate: candidatos que restauram uma letra omitida e, depois, os mais frequentes.
   A interface mostra "Mostrando resultados para …".
3. **Expressões e sinônimos** — `content/synonyms.json` define grupos de equivalência, inclusive expressões
   ("purificar água" ≈ "tratamento de água" ≈ "desinfecção de água" ≈ "água potável"). Cada palavra ou expressão vira
   um *conceito* com todos os termos equivalentes. Um radical simples trata plurais ("abrigos" → "abrigo").
4. **Consulta FTS5** — cada conceito vira `("termo"* OR "outro"* OR ("palavra1"* AND "palavra2"*))`; os conceitos
   são unidos por `OR`. O ranking BM25 pondera colunas: título 10, etiquetas/palavras-chave 5, resumo 3, corpo 1.
5. **Relevância final** — `pontuação = 20 × (conceitos atendidos / conceitos da consulta) + BM25 + bônus de título`.
   Artigos que atendem a todos os conceitos sobem; o BM25 desempata.
6. **Filtros** — categoria, dificuldade e tipo de ambiente (artigos "qualquer ambiente" aparecem em todos).
7. **Autocompletar** — histórico local, títulos com prefixo (FTS na coluna título) e termos do vocabulário.
8. **Relacionados** — curadoria editorial (`related`) completada por similaridade de etiquetas via FTS.
9. **Histórico** — salvo apenas no aparelho (`user.db`), com remoção individual e limpeza total.

## Consultas verificadas por testes automatizados (`app/test/search_engine_test.dart`)

| Consulta | Primeiro resultado esperado |
|---|---|
| Estou perdido na mata. | Estou perdido na mata: o que fazer |
| Como montar um abrigo na chuva? | Como montar um abrigo improvisado com lona |
| Não tenho água potável. | Como tornar a água segura para beber |
| Como utilizar uma bússola? | Como utilizar uma bússola com mapa |
| O que fazer após uma picada de cobra? | Picadas de cobras, escorpiões e aranhas |
| purificar água / blecaute / heimlich / massagem cardíaca / inundação | artigos de tratamento de água, apagão, engasgo, RCP, enchente |
| bussula / hipotermya / queimadra / enchnte | bússola, hipotermia, queimaduras, enchente |

## Como melhorar a pesquisa

- Adicione palavras-chave de busca ao artigo (campo `keywords`) — elas entram no índice com peso alto e não
  aparecem na leitura.
- Adicione grupos de sinônimos em `content/synonyms.json` e publique nova versão: o dicionário vai junto com os
  pacotes, sem atualizar o app.
- Registre consultas sem resultado relatadas por usuários (sem coletar dados automaticamente) e transforme-as
  em sinônimos ou palavras-chave.
