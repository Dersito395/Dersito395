# Aceiro — Copiloto de Apoio à Decisão para Combate a Incêndios Florestais

MVP de um app de **apoio à decisão** (não de decisão automática) para equipes de
monitoramento de incêndios florestais: traduz a detecção de um foco de fumaça
em uma **recomendação de recursos**, sempre com as premissas visíveis e a
decisão final nas mãos do operador.

## Stack

- React 19 + TypeScript + Vite
- Tailwind CSS v4
- React Router (fluxo das 6 etapas por ocorrência)
- Zustand + **Supabase** (Postgres gerenciado) para persistência real, compartilhada entre operadores
- Framer Motion + Lucide

## Backend (Supabase) — necessário para rodar

O app já não usa mais `localStorage` como fonte de verdade: ocorrências e
configurações vivem no Postgres do Supabase, compartilhadas por todos os
operadores. Para rodar (local ou em produção):

1. Crie um projeto gratuito em [supabase.com](https://supabase.com).
2. No **SQL Editor** do projeto, cole e rode todo o conteúdo de
   [`supabase/schema.sql`](./supabase/schema.sql) — cria as tabelas
   `occurrences` e `app_config` com Row Level Security habilitado.
3. Copie `.env.example` para `.env` e preencha com a URL e a chave `anon`
   públicas do seu projeto (Project Settings → API):
   ```bash
   cp .env.example .env
   ```
4. Rode normalmente:
   ```bash
   npm install
   npm run dev       # ambiente de desenvolvimento
   npm run build     # build de produção
   ```

Sem essas variáveis definidas, o app mostra uma tela de "Backend não
configurado" em vez de quebrar (`src/components/ConnectionGate.tsx`).

**Sobre autenticação**: por decisão de produto, esta primeira versão do
backend roda **sem login por operador** — um workspace único compartilhado
por toda a equipe (mais rápido para começar a operar). Isso significa que a
chave `anon` do Supabase, sozinha, dá acesso total de leitura/escrita às
tabelas para quem tiver a URL do projeto (ver comentário em
`supabase/schema.sql`). Ao crescer o uso real, o próximo passo de segurança
é adicionar Supabase Auth e trocar as policies por regras que checam
`auth.uid()`/papel do operador.

Escritas (`createFocus`, `setConfirmation` etc.) atualizam o estado local
imediatamente — para manter a baixa latência exigida no uso em campo — e
sincronizam com o Supabase em segundo plano; se a sincronização falhar, um
aviso aparece no topo da tela (`syncError` em `occurrenceStore`).

---

## 1. Fluxo de telas

Cada ocorrência percorre 6 etapas, uma rota por etapa (`src/pages`), com barra
de progresso visível (`src/components/Layout.tsx`, `src/lib/steps.ts`):

```
/                                    Painel (Home) — lista de ocorrências + confiança atual do modelo
/novo                                Etapa 1 — Foco: origem, coordenadas, umidade do solo, nota de mídia
/ocorrencias/:id/classificacao       Etapa 2 — Classificação da fumaça: hipóteses de vegetação (%)
/ocorrencias/:id/confirmacao         Etapa 3 — Confirmação/correção do operador + distância/área de risco
/ocorrencias/:id/risco               Etapa 4 — Nível de risco + régua de decisão (rationale)
/ocorrencias/:id/recomendacao        Etapa 5 — Recomendação de recursos: aceitar / ajustar / substituir
/ocorrencias/:id                     Etapa 6 — Registro/auditoria completa da ocorrência
/ocorrencias/:id/feedback            Feedback pós-incêndio (alimenta o loop de aprendizado)
/modelo                              Painel do modelo — indicadores do loop de aprendizado
/configuracoes                       Matriz de risco, recursos e tempos de propagação (parametrizável)
```

Nenhuma tela aciona recursos sozinha: a etapa 5 sempre exige uma ação
explícita do operador (aceitar/ajustar/substituir), e ajustar ou substituir
exige justificativa.

## 2. Modelo de dados

Entidades em `src/types/domain.ts`, todas amarradas por uma **Ocorrência**
(agregado raiz e trilha auditável):

| Entidade | Onde vive | Papel |
|---|---|---|
| `Occurrence` | raiz | liga foco → classificação → confirmação → risco → recomendação → feedback |
| `Focus` (Foco) | `occurrence.focus` | dado bruto: origem, coordenadas, timestamp, umidade do solo, nota de mídia |
| `VegetationType` (Vegetação) | `src/data/vegetationConfig.ts` | catálogo parametrizável: classe de propagação, min/km, assinatura de fumaça |
| `RiskArea` (Área de risco) | `src/data/riskAreasConfig.ts` | plantios/áreas nativas georreferenciadas da empresa |
| `ResourceType` / `ResourceItem` (Recurso) | `src/data/resourcesConfig.ts` | catálogo de recursos (equipe, caminhão-pipa, aeronave, máquina de aceiro) |
| `SmokeClassificationResult` | `occurrence.classification` | hipóteses de vegetação com % (nunca uma afirmação única) |
| `OperatorConfirmation` | `occurrence.confirmation` | correção do operador + distância/área de risco/extensão |
| `RiskCalculation` | `occurrence.riskCalculation` | nível + lista de motivos (auditável) |
| `Recommendation` | `occurrence.recommendation` | pacote sugerido, ação do operador, pacote final, justificativa |
| `Feedback` | `occurrence.feedback` | o que realmente aconteceu — retroalimenta o modelo |

Toda variável usada em cada cálculo fica registrada na própria ocorrência —
é a base da auditabilidade exigida (seção 4 da especificação).

## 3. Lógica de cálculo de risco

`src/engine/riskEngine.ts`, com limiares em `src/data/riskMatrixConfig.ts`
(editáveis em Configurações — nenhum número mágico embutido no motor):

- **Fora da área de risco**: `tempo estimado = distância (km) × min/km da vegetação`.
  Se esse tempo for ≤ `approachWindowMinutes` → **Médio I**; senão → **Baixo**.
- **Dentro da área de risco**: parte de **Alto I** como piso e escala:
  - múltiplos focos, ou propagação "muito rápida", ou extensão ≥ `altissimoExtentHectares` → **Altíssimo**
  - propagação "rápida", ou extensão ≥ `alto2ExtentHectares` → **Alto II**
  - caso contrário → **Alto I**

O resultado sempre carrega uma lista `rationale: string[]` com a régua de
decisão em linguagem natural, mostrada na tela de Risco e na auditoria da
ocorrência. Pacotes de recursos por nível (`src/data/resourcesConfig.ts`) e
os próprios limiares são editáveis em `/configuracoes`, por região e por
época do ano.

## 4. Módulo de classificação de imagem (fumaça)

`src/engine/smokeClassifier.ts` — **heurístico no MVP** (sem modelo de visão
computacional real; é o ponto de integração para um modelo de CV depois).

- **Entradas**: cor predominante da fumaça, densidade, umidade do solo (%).
  Hoje informadas pelo operador a partir da foto/vídeo do foco; numa
  integração real seriam a saída de um classificador de imagem.
- **Saída**: 2-3 hipóteses de vegetação/material, cada uma com percentual de
  confiança (nunca uma única afirmação categórica) — cada vegetação tem uma
  "assinatura de fumaça" (afinidade por cor/densidade + efeito da umidade)
  parametrizada em `src/data/vegetationConfig.ts`.
- Um material industrial (fábrica/carvoaria) é incluído propositalmente como
  hipótese, porque fumaça muito escura e densa mesmo com solo úmido é
  indício de fonte não vegetal — o que o modelo puramente vegetativo erraria.
- O operador confirma ou corrige a hipótese na Etapa 3; a correção é o dado
  que retroalimenta a recalibração do classificador (seção 5).

## 5. Loop de feedback e aprendizado

`src/lib/metrics.ts` computa, a partir do histórico real de ocorrências
(sem dado simulado — se não há ocorrências, o painel diz isso explicitamente):

- **Acurácia da vegetação**: hipótese principal do classificador × confirmação
  do operador em campo; e confirmação em campo × resultado real pós-incêndio
  (via `Feedback`).
- **Adequação da recomendação**: % aceita sem alteração; % de ocorrências com
  recursos insuficientes; % com recursos ociosos.
- **Rótulo de confiança**: "baseado em N ocorrências registradas, M com
  feedback pós-incêndio" — sempre visível no Painel (`/`) e no Painel do
  Modelo (`/modelo`), para deixar claro que é uma ferramenta em evolução.

Mecanismo de captura: `Recommendation.operatorAction` + `justification`
registram toda vez que o operador diverge da sugestão; `FeedbackForm`
(`/ocorrencias/:id/feedback`) registra o resultado real pós-incêndio. Esses
dois pontos são exatamente os dados que, em produção, alimentariam a
recalibração periódica (i) das afinidades de fumaça por vegetação, (ii) do
tempo médio de propagação por vegetação e (iii) da matriz risco × recursos —
hoje esses três são parâmetros manuais em `/configuracoes`; a recalibração
automática a partir do histórico é o próximo passo fora do escopo deste MVP.

## 6. Integrações necessárias (fora do escopo deste MVP, pontos já isolados no código)

| Integração | Status neste MVP | Ponto de integração |
|---|---|---|
| API do software de monitoramento florestal (coordenadas, imagem/vídeo, timestamp do foco) | Simulado via toggle "origem" em `/novo` | `useOccurrenceStore.createFocus` — trocar por handler de webhook/polling da API real |
| Umidade do solo (sensores próprios / API meteorológica-agro) | Inserção manual em `/novo` | mesmo formulário — campo já isolado em `Focus.soilHumidityPercent` |
| Mapas de áreas de risco georreferenciadas (eucalipto/nativa) | Lista estática em `src/data/riskAreasConfig.ts`, seleção manual em `/ocorrencias/:id/confirmacao` | trocar a lista estática por consulta a um serviço de geolocalização/GIS |
| Classificação de imagem por visão computacional | Heurística por cor/densidade informadas manualmente | `src/engine/smokeClassifier.ts` — trocar o cálculo por chamada a um modelo de CV mantendo a mesma assinatura de saída (`SmokeClassificationResult`) |
| Backend/persistência multiusuário | ✅ Implementado — Postgres via Supabase, compartilhado entre operadores (`src/store/occurrenceStore.ts`) | Próximo passo: autenticação por operador (Supabase Auth) para saber quem tomou cada decisão |

## Princípio do produto

O app é um **copiloto, não um piloto automático**: nenhuma tela aciona
recursos sozinha, toda recomendação mostra a régua de decisão, e o operador
sempre pode aceitar, ajustar ou substituir — com justificativa registrada.
