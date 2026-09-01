# Check - Incêndios (Fire Command) — Simulador de Risco de Incêndio + Vitrine de Produtos

MVP de um app mobile-first (PWA-ready) para uma empresa de equipamentos de segurança contra incêndio. Ele engaja o usuário com um simulador visual de risco e converte o resultado em recomendações de compra de 3 produtos do catálogo, funcionando também como ferramenta de validação de mercado (qual produto tem mais aderência).

## Stack

- React 19 + TypeScript + Vite
- Tailwind CSS v4 (via `@tailwindcss/vite`)
- React Router (navegação entre etapas do simulador e da vitrine)
- Zustand (estado global do simulador)
- Framer Motion (microanimações) + Lucide (ícones)

## Fluxo implementado (prioridade 1 — MVP do simulador)

`/` → `/tipo-imovel` → `/areas` → `/perguntas` → `/processando` → `/resultado` → `/produtos` → `/produtos/:id`

1. **Boas-vindas** com proposta de valor e disclaimer de que é uma ferramenta educativa.
2. **Tipo de imóvel** (apartamento, casa urbana, casa com quintal, sítio/rural, comércio, indústria) — já pré-seleciona áreas sugeridas.
3. **Seleção de áreas/cômodos** (multi-seleção com ícones): cozinha, sala, quarto, garagem, área de serviço, depósito, área externa com vegetação, baterias/veículos elétricos, quadro elétrico.
4. **Perguntas de risco** por área selecionada (uma por vez, poucos cliques), cobrindo materiais inflamáveis, baterias de lítio, instalação elétrica, proximidade de vegetação e equipamentos já existentes.
5. **Processamento visual** com animação de "varredura".
6. **Resultado**: score de segurança 0–100 geral e por ambiente (termômetro circular), riscos identificados em linguagem simples, e recomendação dos equipamentos do catálogo mais aderentes.
7. **Vitrine de produtos** (prioridade 2), com 9 equipamentos do catálogo, pré-ordenada pela relevância do resultado, com ficha de produto (specs, classes de incêndio aplicáveis, sugestão de quantidade, CTA de WhatsApp/orçamento).

Barra de progresso visível durante todo o simulado. Um botão "Voltar" em cada pergunta permite retroceder e alterar uma resposta já dada, mantendo a seleção anterior destacada.

## Motor de risco

`src/engine/riskEngine.ts` implementa a matriz de decisão como dados (`src/data/questions.ts`, `src/data/propertyTypes.ts`, `src/data/products.ts`): cada resposta carrega pontos de risco, classes de incêndio (A, B, C, D, K, Lítio) e peso de relevância para cada um dos 9 produtos do catálogo. O motor:

- Calcula um score de segurança (0–100) por área e um geral, ponderado pelo tipo de imóvel e por equipamentos de proteção já existentes. O score geral fica em vermelho quando o risco é crítico.
- Classifica o nível de risco (baixo/médio/alto/crítico).
- Agrega os pesos de produto de todas as respostas, ordena os produtos por relevância e sugere uma quantidade por item: produtos "por ambiente" (ex. detector de fumaça) recomendam 1 unidade por cômodo/área que gerou a recomendação; produtos "fixos" (ex. kit de incêndio florestal) recomendam 1 unidade para a propriedade toda.

A matriz e o catálogo hoje vivem em arquivos TypeScript tipados — trocar/ajustar perguntas, pesos ou produtos não exige mexer no motor de cálculo.

> O app deixa explícito na UI que o resultado é educativo/orientativo, com base nas normas do Corpo de Bombeiros de São Paulo, não um laudo técnico nem substitui vistoria (AVCB).

## Conversão e contato

Todos os preços do catálogo são exibidos como "Sob consulta" e cada produto (na vitrine, no resultado e na ficha de detalhe) linka para o WhatsApp da empresa (`src/lib/contact.ts`) com uma mensagem pré-preenchida. Dois botões flutuantes persistentes (menos na tela de boas-vindas, para não competir com o CTA de iniciar o simulador) abrem o mesmo WhatsApp para "Solicitar uma vistoria no local" e "Cotação de equipamentos de proteção". O rodapé do app traz os dados institucionais da empresa.

"Receber por e-mail" abre o cliente de e-mail do usuário (`mailto:`) com o resumo do resultado pré-preenchido, e "Baixar PDF" gera um PDF real no navegador (via `jspdf`, carregado sob demanda) com o mesmo resumo — nenhum dos dois depende de um backend.

## Analytics (funil e aderência de produto)

`src/lib/analytics.ts` centraliza todo o rastreamento de eventos (início do simulado, resposta por etapa, conclusão, produto recomendado visualizado, clique em produto, clique em CTA de contato, resultado salvo). Hoje persiste em `localStorage` para permitir validar a lógica sem backend — `track()` é o único ponto de integração, então trocar seu corpo por uma chamada de API é suficiente para plugar um backend real sem tocar nas páginas.

## Rodando localmente

```bash
npm install
npm run dev       # ambiente de desenvolvimento
npm run build     # build de produção
```

## Roadmap (fora do escopo deste MVP)

Por ordem de prioridade, conforme solicitado:

1. ~~Simulador (matriz de risco + recomendação)~~ — feito
2. ~~Vitrine de conversão~~ — feito
3. Backend/API para persistir respostas de todos os usuários e alimentar analytics agregado entre sessões/dispositivos
4. Painel administrativo para editar a matriz de risco e o catálogo sem código
5. Integrações: WhatsApp Business API real (hoje é link `wa.me`), gateway de pagamento/checkout, envio automático de e-mail via backend (hoje é `mailto:` client-side)
6. Apps nativos (hoje é PWA/web responsivo mobile-first)
