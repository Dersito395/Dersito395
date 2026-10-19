# Processo editorial e fontes

## Princípios

- **Textos originais**, escritos em português brasileiro a partir das referências. Nada é copiado ou traduzido
  integralmente de obras protegidas.
- **Toda informação técnica cita fonte verificável** (instituição, autor, título, editora, ano, link, licença) e a
  nota do que a fonte fundamenta. Suposições não são apresentadas como procedimento comprovado.
- **Saúde e procedimentos críticos exigem revisão técnica** por profissional habilitado antes de serem publicados
  em versão de loja.
- **Imagens só com crédito e licença conhecidos.** As 30 ilustrações atuais são desenhos originais do projeto
  (`tools/make_illustrations.py`), licenciados CC BY 4.0.

## Fontes usadas na biblioteca inicial

Defesa Civil Nacional (MIDR) e Defesa Civil estaduais, Ministério da Saúde (incl. BVS e cartilha de queimaduras),
Secretarias de Saúde de SP e MG (hipoclorito 2,5%), Instituto Butantan, ABRACIT/CIATox, CEMADEN, INPE/ELAT, IBGE,
Embrapa, Anatel, OMS (qualidade da água; WASH em emergências), Eawag (SODIS), CDC, FEMA/Ready.gov, USDA FSIS,
National Park Service, US Forest Service (Smokey Bear), NOAA/NWS, AHA 2025 (RCP e engasgo), IFRC 2020 (Cruz Vermelha),
American College of Surgeons (Stop the Bleed), Wilderness Medical Society (hipotermia 2019, calor 2024),
Leave No Trace, Exército dos EUA (ATP 3-50.21 Survival; TC 3-97.61 Military Mountaineering).

Lista completa com links e licenças: `content/sources.json` (também visível no app em Ajustes › Fontes bibliográficas).

**Verificação**: os links e as afirmações centrais (dose de hipoclorito 2,5%, fervura de 1/3 min, sequência de
engasgo da AHA 2025, condutas em acidentes ofídicos, SMS 40199, Disque-Intoxicação 0800 722 6001, DOI das diretrizes
da WMS) foram conferidos por pesquisa em 18/10/2026. Antes de cada publicação, o revisor deve abrir as fontes,
confirmar se continuam vigentes e registrar a revisão no painel.

## Documentos de consulta (aba Consultas) e PDFs de referência

- O app **só distribui PDFs de livre distribuição**: documentos do governo dos EUA marcados *Approved for public
  release; distribution is unlimited*, publicações sob licença aberta ou com autorização por escrito. Cada documento
  em `content/documents.json` traz licença, fonte, resumo em português, destaques por página e, quando for o caso,
  aviso de que foi substituído por edição mais nova.
- **Livros comerciais e documentos de distribuição restrita** (ex.: *Distribution Restriction B*) **não entram no
  app**: suas ideias podem ser usadas como fonte, sempre reescritas e citadas.
- Partes sobre armamento, explosivos, demolição, sabotagem ou ação militar ofensiva não são aproveitadas, mesmo
  quando o documento é público (veja *Limites de conteúdo*).
- Links externos (`content/links.json`) são `oficial` ou `comunidade`. Links de comunidade (blogs, fóruns) exigem
  nota avisando que o conteúdo não é revisado e **não servem como fonte** de artigos.

### Material de referência recebido em 19/10/2026

| Documento | Situação | Uso |
|---|---|---|
| FM 3-97.6 Mountain Operations (2000) | domínio público, distribuição ilimitada; substituído pelo ATP 3-90.97 | PDF na aba Consultas + artigos `mont-*` |
| Pewtherer, *Wilderness Survival Handbook* (McGraw-Hill, 2010) | protegido por direitos autorais | só ideias, reescritas e citadas: artigos `pw-*` |
| FM 4-02.283 Treatment of Nuclear and Radiological Casualties (2001) | distribuição restrita (B) | não usado |
| JP 3-50.21 Combat Search and Rescue (1998) | doutrina militar de resgate em combate | não usado |
| ST 31-180 Special Forces Handbook (1965) | demolição, explosivos e sabotagem | não usado |

## Pendências conhecidas

- **Revisão técnica profissional** dos 8 artigos de primeiros socorros (RCP, engasgo, hemorragia, queimaduras,
  fraturas, hipotermia, calor/desidratação, animais peçonhentos) e dos guias de emergência correspondentes.
  Enquanto pendente, o app exibe um aviso no artigo, e a publicação em **modo estrito** (padrão do painel) exclui
  esses artigos dos pacotes.
- **Fotografias realistas**: o app suporta WebP/AVIF/PNG/JPEG com crédito e licença, mas a biblioteca inicial usa
  apenas diagramas vetoriais originais. Fotos de bancos com licença clara (domínio público de agências dos EUA,
  Wikimedia Commons CC BY/CC0, fotos próprias) podem ser enviadas pelo painel.

## Formato de um artigo (`content/articles/<id>.json`)

```json
{
  "id": "abrigo-lona-improvisado",       // único, estável: favoritos e notas dependem dele
  "version": 1, "lang": "pt-BR", "status": "publicado",
  "title": "Como montar um abrigo improvisado com lona",
  "summary": "…", "category": "abrigos", "subcategory": "lonas",
  "difficulty": "basica",                 // basica | intermediaria | avancada
  "environments": ["mata", "rural"],      // qualquer | urbano | domestico | mata | montanha | rural | litoral
  "time_estimate": "20 a 40 minutos, conforme método e condições",
  "materials": ["…"], "objective": "…",
  "steps": [{ "text": "…", "image": "abrigo-lona-a.svg" }],
  "cautions": ["…"], "alternatives": ["…"],
  "tags": ["…"], "keywords": ["como montar um abrigo na chuva"],
  "images": [{ "file": "abrigo-lona-a.svg", "caption": "…", "alt": "…" }],
  "sources": [{ "ref": "army-atp-3-50-21", "note": "o que esta fonte fundamenta" }],
  "related": ["abrigo-terreno-isolamento"],
  "essential": true,                      // entra na biblioteca embarcada no app
  "review": { "technical_required": false, "technical_status": "pendente", "reviewer": null, "reviewed_at": null },
  "updated_at": "2026-10-18"              // data de revisão exibida no app
}
```

A validação (`server/src/validate.js`) exige título, resumo, objetivo, tempo, dificuldade, etapas, cuidados e ao
menos uma fonte cadastrada; confere categoria/subcategoria, imagens existentes e artigos relacionados.

## Fluxo no painel (`/admin`)

```
 rascunho ──enviar──▶ em revisão ──aprovar──▶ aprovado ──publicar──▶ publicado (versão N+1)
    ▲                    │  (revisão técnica          │
    └──── devolver ◀─────┴──── obrigatória p/ saúde) ─┘
```

| Papel | Pode |
|---|---|
| editor | criar e editar rascunhos, enviar para revisão, enviar imagens |
| revisor | o mesmo + aprovar/devolver (incluindo **revisão técnica** de saúde) e publicar artigos |
| admin | tudo + publicar nova versão da biblioteca, editar fontes e guias de emergência, gerenciar usuários |

Regras:
- Quem editou por último **não pode aprovar** a própria alteração.
- Editar um rascunho invalida qualquer revisão técnica anterior.
- Publicar move a versão anterior para `content/history/<id>/v<N>.json` (histórico de versões).
- "Gerar e publicar nova versão" incrementa `library_version`, valida todo o conteúdo e gera os pacotes. Em
  **modo estrito**, artigos de saúde sem revisão técnica aprovada ficam de fora.

## Limites de conteúdo

O SOBREVIVA trata segurança como **prevenção, discrição, proteção de recursos, organização comunitária e defesa
dentro da lei**. Não publica instruções de fabricação de armas, explosivos, armadilhas para ferir pessoas ou
técnicas de ataque: são crimes no Brasil (Estatuto do Desarmamento; Código Penal), colocam inocentes em risco e
violam as políticas das lojas de aplicativos. Pesquisas como "como fazer uma arma" levam ao artigo
*Defesa pessoal e a lei*. Caça de fauna silvestre é crime (Lei 9.605/1998); o manual orienta produção de alimentos
e criação de pequenos animais como alternativas legais.

## Linha editorial

- Frases curtas, voz ativa, instruções numeradas, uma ação por passo.
- Sempre incluir "quando pedir socorro" e "quando **não** usar a técnica".
- Números de emergência brasileiros com finalidade: 192 (SAMU), 193 (Bombeiros), 190 (PM), 199 (Defesa Civil).
- Evitar quantidades universais; quando houver número, citar a fonte (ex.: 3,8 L/pessoa/dia — FEMA/Ready.gov).
