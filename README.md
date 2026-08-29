# FireCheck — Simulador de Risco de Incêndio + Vitrine de Produtos

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
7. **Vitrine de produtos** (prioridade 2) pré-ordenada pela relevância do resultado, com ficha de produto (specs, classes de incêndio aplicáveis, CTA de WhatsApp/orçamento).

Barra de progresso visível durante todo o simulado.

## Motor de risco

`src/engine/riskEngine.ts` implementa a matriz de decisão como dados (`src/data/questions.ts`, `src/data/propertyTypes.ts`, `src/data/products.ts`): cada resposta carrega pontos de risco, classes de incêndio (A, B, C, D, K, Lítio) e peso de relevância para cada um dos 3 produtos. O motor:

- Calcula um score de segurança (0–100) por área e um geral, ponderado pelo tipo de imóvel e por equipamentos de proteção já existentes.
- Classifica o nível de risco (baixo/médio/alto/crítico).
- Agrega os pesos de produto de todas as respostas e ordena os 3 produtos por relevância, com o motivo (pergunta) que gerou a recomendação.

A matriz hoje vive em arquivos TypeScript tipados — trocar/ajustar perguntas, pesos ou produtos não exige mexer no motor de cálculo.

> O app deixa explícito na UI que o resultado é educativo/orientativo, não um laudo técnico nem substitui vistoria do Corpo de Bombeiros (AVCB).

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
5. Integrações: WhatsApp Business API real, gateway de pagamento/checkout, envio de PDF/e-mail do resultado
6. Apps nativos (hoje é PWA/web responsivo mobile-first)
