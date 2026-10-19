// Validação editorial dos artigos. Usada pelo construtor de pacotes e pelo painel administrativo.

export const DIFFICULTIES = ['basica', 'intermediaria', 'avancada'];
export const ENVIRONMENTS = ['qualquer', 'urbano', 'domestico', 'mata', 'montanha', 'rural', 'litoral'];
export const STATUSES = ['rascunho', 'em_revisao', 'aprovado', 'publicado', 'arquivado'];

// Categorias cujo conteúdo exige revisão técnica por profissional habilitado antes da publicação.
export const TECHNICAL_REVIEW_CATEGORIES = ['primeiros-socorros'];

const ID_RE = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

function isNonEmptyString(v) {
  return typeof v === 'string' && v.trim().length > 0;
}

/**
 * Normaliza um artigo vindo do repositório editorial, preenchendo valores padrão.
 * Não altera o objeto original.
 */
export function normalizeArticle(raw) {
  const a = structuredClone(raw);
  a.version = Number.isInteger(a.version) && a.version > 0 ? a.version : 1;
  a.lang = a.lang || 'pt-BR';
  a.status = a.status || 'publicado';
  a.essential = a.essential !== false;
  a.environments = Array.isArray(a.environments) && a.environments.length ? a.environments : ['qualquer'];
  a.materials = a.materials || [];
  a.cautions = a.cautions || [];
  a.alternatives = a.alternatives || [];
  a.tags = a.tags || [];
  a.keywords = a.keywords || [];
  a.images = a.images || [];
  a.related = a.related || [];
  a.steps = (a.steps || []).map((s) => (typeof s === 'string' ? { text: s } : s));
  const requiresTechnical = TECHNICAL_REVIEW_CATEGORIES.includes(a.category);
  a.review = {
    technical_required: requiresTechnical,
    technical_status: 'pendente',
    reviewer: null,
    reviewed_at: null,
    ...(a.review || {}),
  };
  a.updated_at = a.updated_at || null;
  return a;
}

/**
 * Valida um artigo normalizado.
 * @param {object} a artigo normalizado
 * @param {object} ctx { categories, sources: Map|Set de ids, media: Set de arquivos, articleIds: Set }
 * @returns {{errors: string[], warnings: string[]}}
 */
export function validateArticle(a, ctx = {}) {
  const errors = [];
  const warnings = [];
  const req = (cond, msg) => { if (!cond) errors.push(msg); };

  req(isNonEmptyString(a.id) && ID_RE.test(a.id), 'id inválido (use letras minúsculas, números e hífens)');
  req(isNonEmptyString(a.title), 'título obrigatório');
  req(isNonEmptyString(a.summary), 'resumo obrigatório');
  req(isNonEmptyString(a.objective), 'objetivo obrigatório');
  req(isNonEmptyString(a.time_estimate), 'tempo estimado obrigatório');
  req(DIFFICULTIES.includes(a.difficulty), `dificuldade deve ser uma de: ${DIFFICULTIES.join(', ')}`);
  req(STATUSES.includes(a.status), 'status editorial inválido');
  req(Array.isArray(a.steps) && a.steps.length > 0, 'pelo menos uma etapa é obrigatória');
  (a.steps || []).forEach((s, i) => req(isNonEmptyString(s.text), `etapa ${i + 1} sem texto`));
  req(Array.isArray(a.cautions) && a.cautions.length > 0, 'cuidados são obrigatórios');
  req(Array.isArray(a.sources) && a.sources.length > 0, 'pelo menos uma fonte bibliográfica é obrigatória');

  for (const env of a.environments || []) {
    if (!ENVIRONMENTS.includes(env)) errors.push(`ambiente desconhecido: ${env}`);
  }

  if (ctx.categories) {
    const cat = ctx.categories.find((c) => c.id === a.category);
    if (!cat) errors.push(`categoria desconhecida: ${a.category}`);
    else if (a.subcategory && !cat.subcategories.some(([id]) => id === a.subcategory)) {
      errors.push(`subcategoria ${a.subcategory} não pertence a ${a.category}`);
    }
  }
  if (ctx.sources) {
    for (const s of a.sources || []) {
      if (!s || !ctx.sources.has(s.ref)) errors.push(`fonte desconhecida: ${s && s.ref}`);
    }
  }
  if (ctx.media) {
    const files = [...(a.images || []).map((i) => i.file), ...(a.steps || []).map((s) => s.image).filter(Boolean)];
    for (const f of files) if (!ctx.media.has(f)) errors.push(`imagem não encontrada no repositório de mídia: ${f}`);
    for (const img of a.images || []) {
      if (!isNonEmptyString(img.alt)) warnings.push(`imagem ${img.file} sem texto alternativo`);
    }
  }
  if (ctx.articleIds) {
    for (const r of a.related || []) {
      if (r === a.id) errors.push('artigo relacionado a si mesmo');
      else if (!ctx.articleIds.has(r)) warnings.push(`artigo relacionado inexistente ou não publicado: ${r}`);
    }
  }
  if (a.review.technical_required && a.review.technical_status !== 'aprovado') {
    warnings.push('revisão técnica profissional pendente');
  }
  return { errors, warnings };
}

export function validateEmergency(e) {
  const errors = [];
  for (const k of ['id', 'title']) if (!isNonEmptyString(e[k])) errors.push(`${k} obrigatório`);
  for (const k of ['recognize', 'safety', 'do', 'avoid']) {
    if (!Array.isArray(e[k]) || e[k].length === 0) errors.push(`${e.id}: seção ${k} obrigatória`);
  }
  if (!e.call || !Array.isArray(e.call.numbers) || e.call.numbers.length === 0) errors.push(`${e.id}: números de socorro obrigatórios`);
  return errors;
}

export function validateScenario(sc) {
  const errors = [];
  for (const k of ['id', 'title', 'summary']) if (!isNonEmptyString(sc[k])) errors.push(`cenário: ${k} obrigatório`);
  if (!Array.isArray(sc.phases) || sc.phases.length === 0) errors.push(`${sc.id}: pelo menos uma fase é obrigatória`);
  for (const ph of sc.phases || []) {
    if (!isNonEmptyString(ph.title) || !Array.isArray(ph.items) || ph.items.length === 0) errors.push(`${sc.id}: fase sem título ou sem ações`);
  }
  return errors;
}
