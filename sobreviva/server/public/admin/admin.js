// Painel editorial do SOBREVIVA. Sem dependências; o DOM é criado com el() (sem innerHTML com dados).

const state = { me: null, meta: null };
const app = document.getElementById('app');

function el(tag, attrs = {}, ...children) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v === null || v === undefined || v === false) continue;
    if (k.startsWith('on')) node.addEventListener(k.slice(2), v);
    else if (k === 'class') node.className = v;
    else if (k === 'value') node.value = v;
    else if (k === 'checked') node.checked = !!v;
    else node.setAttribute(k, v === true ? '' : v);
  }
  for (const c of children.flat()) {
    if (c === null || c === undefined || c === false) continue;
    node.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
  return node;
}

/** Substitui o conteúdo principal ignorando partes condicionais vazias. */
function render(...nodes) {
  app.replaceChildren(...nodes.flat().filter((n) => n !== null && n !== undefined && n !== false));
}

function toast(msg, error = false) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.className = `show${error ? ' error' : ''}`;
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => (t.className = ''), 4000);
}

async function api(method, url, body) {
  const res = await fetch(url, {
    method,
    credentials: 'same-origin',
    headers: { 'Content-Type': 'application/json', ...(state.me ? { 'X-CSRF-Token': state.me.csrf } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (res.status === 401 && url !== '/api/admin/login') {
    state.me = null;
    renderLogin();
    throw new Error('sessão expirada');
  }
  if (!res.ok) throw new Error(data.error || `erro ${res.status}`);
  return data;
}

const can = (perm) => !!state.me && state.me.permissions.includes(perm);
const statusLabel = { rascunho: 'Rascunho', em_revisao: 'Em revisão', aprovado: 'Aprovado', publicado: 'Publicado', arquivado: 'Arquivado' };
const badge = (s, text) => el('span', { class: `badge ${s || ''}` }, text || statusLabel[s] || s || '—');
const lines = (v) => String(v || '').split('\n').map((s) => s.trim()).filter(Boolean);
const csv = (v) => String(v || '').split(',').map((s) => s.trim()).filter(Boolean);

// Sessão ----------------------------------------------------------------------------
function renderLogin() {
  document.getElementById('nav').hidden = true;
  document.getElementById('who').replaceChildren();
  const user = el('input', { autocomplete: 'username', required: true });
  const pass = el('input', { type: 'password', autocomplete: 'current-password', required: true });
  const form = el('form', { class: 'card login', onsubmit: async (e) => {
    e.preventDefault();
    try {
      state.me = await api('POST', '/api/admin/login', { username: user.value, password: pass.value });
      await boot();
    } catch (err) {
      toast(err.message, true);
    }
  } },
  el('h1', {}, 'Entrar'),
  el('p', { class: 'muted' }, 'Acesso restrito à equipe editorial. O aplicativo não exige conta.'),
  el('label', {}, 'Usuário'), user,
  el('label', {}, 'Senha'), pass,
  el('div', { class: 'row' }, el('button', { type: 'submit' }, 'Entrar')));
  render(form);
  user.focus();
}

async function boot() {
  state.meta = await api('GET', '/api/admin/meta');
  const nav = document.getElementById('nav');
  nav.hidden = false;
  nav.querySelectorAll('[data-perm]').forEach((a) => a.classList.toggle('hidden', !can(a.dataset.perm)));
  document.getElementById('who').replaceChildren(
    el('span', {}, `${state.me.name} · ${state.me.role}`),
    el('button', { class: 'secondary', onclick: async () => { await api('POST', '/api/admin/logout', {}); state.me = null; renderLogin(); } }, 'Sair'),
  );
  route();
}

// Roteamento -------------------------------------------------------------------------
async function route() {
  if (!state.me) return;
  const [, view, id] = location.hash.split('/');
  document.querySelectorAll('nav a').forEach((a) => a.classList.toggle('active', a.getAttribute('href') === `#/${view || 'artigos'}`));
  try {
    if (view === 'artigo' && id) await viewArticle(decodeURIComponent(id));
    else if (view === 'fontes') await viewSources();
    else if (view === 'emergencias') await viewEmergencies();
    else if (view === 'cenarios') await viewScenarios();
    else if (view === 'midia') await viewMedia();
    else if (view === 'publicacao') await viewRelease();
    else if (view === 'usuarios') await viewUsers();
    else await viewArticles();
  } catch (e) {
    render(el('div', { class: 'card errors' }, e.message));
  }
}
window.addEventListener('hashchange', route);

// Artigos ----------------------------------------------------------------------------
async function viewArticles() {
  const list = await api('GET', '/api/admin/articles');
  const cats = Object.fromEntries(state.meta.categories.map((c) => [c.id, c.name]));
  const q = el('input', { placeholder: 'Filtrar por título ou id' });
  const statusSel = el('select', {}, el('option', { value: '' }, 'Todos os estados'), ...Object.entries(statusLabel).map(([k, v]) => el('option', { value: k }, v)), el('option', { value: 'tecnica' }, 'Revisão técnica pendente'));
  const tbody = el('tbody');
  const draw = () => {
    const f = q.value.toLowerCase();
    const s = statusSel.value;
    tbody.replaceChildren(...list
      .filter((a) => (!f || a.title.toLowerCase().includes(f) || a.id.includes(f)))
      .filter((a) => !s || (s === 'tecnica' ? a.technical_required && a.technical_status !== 'aprovado' : a.draft_status === s || a.published_status === s))
      .map((a) => el('tr', { class: 'click', onclick: () => (location.hash = `#/artigo/${encodeURIComponent(a.id)}`) },
        el('td', {}, el('strong', {}, a.title), el('div', { class: 'muted' }, a.id)),
        el('td', {}, cats[a.category] || a.category),
        el('td', {}, a.published_version ? badge(a.published_status, `${statusLabel[a.published_status]} v${a.published_version}`) : '—'),
        el('td', {}, a.draft_status ? badge(a.draft_status) : '—'),
        el('td', {}, a.technical_required ? badge(a.technical_status === 'aprovado' ? 'publicado' : 'pendente', a.technical_status === 'aprovado' ? 'Aprovada' : 'Pendente') : el('span', { class: 'muted' }, 'não exigida')))));
  };
  q.addEventListener('input', draw);
  statusSel.addEventListener('change', draw);
  const newId = el('input', { placeholder: 'id-do-artigo (letras minúsculas e hífens)' });
  const newTitle = el('input', { placeholder: 'Título' });
  const newCat = el('select', {}, ...state.meta.categories.map((c) => el('option', { value: c.id }, c.name)));
  draw();
  render(
    el('h1', {}, `Artigos (${list.length})`),
    can('article:edit') && el('details', { class: 'card' }, el('summary', {}, 'Novo artigo'),
      el('div', { class: 'grid3' }, el('div', {}, el('label', {}, 'Id'), newId), el('div', {}, el('label', {}, 'Título'), newTitle), el('div', {}, el('label', {}, 'Categoria'), newCat)),
      el('div', { class: 'row' }, el('button', { onclick: async () => {
        try {
          await api('POST', '/api/admin/articles', { id: newId.value.trim(), title: newTitle.value.trim(), category: newCat.value });
          location.hash = `#/artigo/${encodeURIComponent(newId.value.trim())}`;
        } catch (e) { toast(e.message, true); }
      } }, 'Criar rascunho'))),
    el('div', { class: 'row card' }, el('div', { class: 'grow' }, q), statusSel),
    el('table', {}, el('thead', {}, el('tr', {}, ...['Artigo', 'Categoria', 'Publicado', 'Rascunho', 'Revisão técnica'].map((h) => el('th', {}, h)))), tbody),
  );
}

function listEditor(items, makeRow, makeEmpty) {
  const wrap = el('div');
  const rows = [];
  const add = (item) => {
    const row = makeRow(item);
    const box = el('div', { class: row.className }, ...row.fields, el('button', { class: 'secondary', type: 'button', onclick: () => { box.remove(); rows.splice(rows.indexOf(entry), 1); } }, '✕'));
    const entry = { box, read: row.read };
    rows.push(entry);
    wrap.append(box);
  };
  items.forEach(add);
  return {
    node: el('div', {}, wrap, el('button', { class: 'secondary', type: 'button', onclick: () => add(makeEmpty()) }, '+ Adicionar')),
    read: () => rows.map((r) => r.read()),
  };
}

async function viewArticle(id) {
  const data = await api('GET', `/api/admin/articles/${encodeURIComponent(id)}`);
  const draft = data.draft;
  const a = draft || data.published;
  const editable = !!draft && draft.status === 'rascunho' && can('article:edit');
  const meta = state.meta;
  const mediaOptions = ['', ...meta.media.map((m) => m.file)];
  const mediaSelect = (value) => el('select', { disabled: !editable }, ...mediaOptions.map((f) => el('option', { value: f, selected: f === value }, f || '(sem imagem)')));

  const f = {
    title: el('input', { value: a.title }),
    summary: el('textarea', { value: a.summary || '' }),
    category: el('select', {}, ...meta.categories.map((c) => el('option', { value: c.id, selected: c.id === a.category }, c.name))),
    subcategory: el('select'),
    difficulty: el('select', {}, ...meta.difficulties.map((d) => el('option', { value: d, selected: d === a.difficulty }, d))),
    time: el('input', { value: a.time_estimate || '' }),
    essential: el('input', { type: 'checkbox', checked: a.essential !== false }),
    objective: el('textarea', { value: a.objective || '' }),
    materials: el('textarea', { value: (a.materials || []).join('\n') }),
    cautions: el('textarea', { value: (a.cautions || []).join('\n') }),
    alternatives: el('textarea', { value: (a.alternatives || []).join('\n') }),
    tags: el('input', { value: (a.tags || []).join(', ') }),
    keywords: el('input', { value: (a.keywords || []).join(', ') }),
    related: el('input', { value: (a.related || []).join(', ') }),
  };
  const fillSubs = () => {
    const cat = meta.categories.find((c) => c.id === f.category.value);
    f.subcategory.replaceChildren(el('option', { value: '' }, '(nenhuma)'), ...(cat?.subcategories || []).map(([sid, name]) => el('option', { value: sid, selected: sid === a.subcategory }, name)));
  };
  f.category.addEventListener('change', fillSubs);
  fillSubs();
  const envChecks = meta.environments.map((env) => el('label', {}, el('input', { type: 'checkbox', value: env, checked: (a.environments || []).includes(env) }), env));

  const steps = listEditor(
    (a.steps || []).map((s) => (typeof s === 'string' ? { text: s } : s)),
    (s) => { const t = el('textarea', { value: s.text || '' }); const img = mediaSelect(s.image || ''); return { className: 'list-item', fields: [t, img], read: () => ({ text: t.value.trim(), ...(img.value ? { image: img.value } : {}) }) }; },
    () => ({ text: '' }),
  );
  const images = listEditor(
    a.images || [],
    (im) => { const file = mediaSelect(im.file); const cap = el('input', { value: im.caption || '', placeholder: 'Legenda' }); const alt = el('input', { value: im.alt || '', placeholder: 'Texto alternativo (acessibilidade)' }); return { className: 'list-item img', fields: [file, cap, alt], read: () => ({ file: file.value, caption: cap.value.trim(), alt: alt.value.trim() }) }; },
    () => ({ file: '' }),
  );
  const sources = listEditor(
    a.sources || [],
    (s) => { const ref = el('select', {}, el('option', { value: '' }, '(escolha a fonte)'), ...meta.sources.map((x) => el('option', { value: x.id, selected: x.id === s.ref }, `${x.institution} — ${x.title}`.slice(0, 90)))); const note = el('input', { value: s.note || '', placeholder: 'O que esta fonte fundamenta no artigo' }); return { className: 'list-item src', fields: [ref, note], read: () => ({ ref: ref.value, note: note.value.trim() }) }; },
    () => ({ ref: '' }),
  );

  const collect = () => ({
    ...a,
    id,
    title: f.title.value.trim(),
    summary: f.summary.value.trim(),
    category: f.category.value,
    subcategory: f.subcategory.value || null,
    difficulty: f.difficulty.value,
    environments: envChecks.map((l) => l.querySelector('input')).filter((i) => i.checked).map((i) => i.value),
    time_estimate: f.time.value.trim(),
    essential: f.essential.checked,
    objective: f.objective.value.trim(),
    materials: lines(f.materials.value),
    steps: steps.read().filter((s) => s.text),
    cautions: lines(f.cautions.value),
    alternatives: lines(f.alternatives.value),
    tags: csv(f.tags.value),
    keywords: csv(f.keywords.value),
    images: images.read().filter((i) => i.file),
    sources: sources.read().filter((s) => s.ref),
    related: csv(f.related.value),
  });

  const formNode = el('fieldset', { disabled: !editable, class: 'card' },
    el('label', {}, 'Título'), f.title,
    el('label', {}, 'Resumo'), f.summary,
    el('div', { class: 'grid3' },
      el('div', {}, el('label', {}, 'Categoria'), f.category),
      el('div', {}, el('label', {}, 'Subcategoria'), f.subcategory),
      el('div', {}, el('label', {}, 'Dificuldade'), f.difficulty)),
    el('div', { class: 'grid2' },
      el('div', {}, el('label', {}, 'Tempo estimado'), f.time),
      el('div', {}, el('label', {}, 'Biblioteca essencial (embarcada no app)'), el('div', { class: 'checks' }, el('label', {}, f.essential, 'incluir no pacote essencial')))),
    el('label', {}, 'Ambientes'), el('div', { class: 'checks' }, ...envChecks),
    el('label', {}, 'Objetivo'), f.objective,
    el('label', {}, 'Materiais necessários (um por linha)'), f.materials,
    el('h2', {}, 'Instruções (passo a passo)'), steps.node,
    el('label', {}, 'Cuidados (um por linha)'), f.cautions,
    el('label', {}, 'Alternativas (uma por linha)'), f.alternatives,
    el('h2', {}, 'Imagens'), images.node,
    el('h2', {}, 'Fontes bibliográficas'), sources.node,
    el('div', { class: 'grid3' },
      el('div', {}, el('label', {}, 'Etiquetas (vírgulas)'), f.tags),
      el('div', {}, el('label', {}, 'Palavras-chave de busca (vírgulas)'), f.keywords),
      el('div', {}, el('label', {}, 'Artigos relacionados (ids, vírgulas)'), f.related)));

  const v = data.validation;
  const validation = el('div', { class: 'card' }, el('h2', {}, 'Validação editorial'),
    v.errors.length ? el('ul', { class: 'errors' }, ...v.errors.map((e) => el('li', {}, e))) : el('p', {}, '✓ Sem erros.'),
    v.warnings.length ? el('ul', { class: 'warnings' }, ...v.warnings.map((w) => el('li', {}, w))) : null);

  const act = async (action, needsComment = false) => {
    let comment;
    if (needsComment) {
      comment = prompt('Comentário para o histórico editorial:');
      if (comment === null) return;
    }
    try {
      await api('POST', `/api/admin/articles/${encodeURIComponent(id)}/transition`, { action, comment });
      toast('Feito.');
      route();
    } catch (e) { toast(e.message, true); }
  };
  const buttons = [];
  if (!draft && data.published && can('article:edit')) buttons.push(el('button', { onclick: async () => { try { await api('POST', `/api/admin/articles/${encodeURIComponent(id)}/draft`); route(); } catch (e) { toast(e.message, true); } } }, 'Criar nova versão (editar)'));
  if (editable) {
    buttons.push(el('button', { onclick: async () => { try { const r = await api('PUT', `/api/admin/articles/${encodeURIComponent(id)}/draft`, { article: collect() }); toast(r.validation.errors.length ? `Salvo com ${r.validation.errors.length} erro(s)` : 'Rascunho salvo'); route(); } catch (e) { toast(e.message, true); } } }, 'Salvar rascunho'));
    if (can('article:submit')) buttons.push(el('button', { class: 'warn', onclick: () => act('submit') }, 'Enviar para revisão'));
  }
  if (draft?.status === 'em_revisao' && can('article:review')) {
    buttons.push(el('button', { onclick: () => act('approve', true) }, normalizeTechnical(a) ? 'Aprovar (inclui revisão técnica)' : 'Aprovar'));
    buttons.push(el('button', { class: 'secondary', onclick: () => act('return', true) }, 'Devolver para edição'));
  }
  if (draft?.status === 'aprovado' && can('article:publish')) {
    buttons.push(el('button', { class: 'warn', onclick: () => act('publish') }, 'Publicar'));
    if (can('article:review')) buttons.push(el('button', { class: 'secondary', onclick: () => act('return', true) }, 'Devolver para edição'));
  }
  if (draft && can('article:edit')) buttons.push(el('button', { class: 'danger', onclick: async () => { if (!confirm('Descartar o rascunho? A versão publicada não é afetada.')) return; await api('DELETE', `/api/admin/articles/${encodeURIComponent(id)}/draft`); route(); } }, 'Descartar rascunho'));
  if (!draft && data.published?.status === 'publicado' && can('article:publish')) buttons.push(el('button', { class: 'danger', onclick: () => confirm('Arquivar este artigo? Ele deixará de ser incluído nos próximos pacotes.') && act('archive') }, 'Arquivar'));

  render(
    el('p', {}, el('a', { href: '#/artigos' }, '← Artigos')),
    el('h1', {}, a.title),
    el('div', { class: 'row card' },
      el('span', {}, 'Publicado: ', data.published ? badge(data.published.status, `${statusLabel[data.published.status]} v${data.published.version}`) : '—'),
      el('span', {}, 'Rascunho: ', draft ? badge(draft.status) : '—'),
      el('span', {}, 'Revisão técnica: ', normalizeTechnical(a) ? badge(a.review?.technical_status === 'aprovado' ? 'publicado' : 'pendente', a.review?.technical_status === 'aprovado' ? `Aprovada por ${a.review.reviewer} em ${a.review.reviewed_at}` : 'Pendente') : 'não exigida'),
      data.history.length ? el('span', { class: 'muted' }, `Versões anteriores: ${data.history.map((h) => `v${h.version}`).join(', ')}`) : null),
    !editable && draft ? el('p', { class: 'muted' }, 'Rascunho em revisão/aprovado: somente leitura. Devolva para edição para alterar.') : null,
    !draft ? el('p', { class: 'muted' }, 'Exibindo a versão publicada. Clique em “Criar nova versão” para editar sem afetar o que está no ar.') : null,
    validation,
    formNode,
    draft?.workflow?.log?.length ? el('div', { class: 'card' }, el('h2', {}, 'Histórico editorial'), el('ul', { class: 'log' }, ...draft.workflow.log.slice().reverse().map((l) => el('li', {}, `${l.at.slice(0, 16).replace('T', ' ')} — ${l.by}: ${l.action}${l.comment ? ` — “${l.comment}”` : ''}`)))) : null,
    el('div', { class: 'row sticky-actions' }, ...buttons),
  );
}

function normalizeTechnical(a) {
  return a.category === 'primeiros-socorros' || a.review?.technical_required === true;
}

// Fontes -----------------------------------------------------------------------------
async function viewSources() {
  const list = await api('GET', '/api/admin/sources');
  const fields = ['id', 'institution', 'author', 'title', 'publisher', 'year', 'url', 'license', 'language'];
  const labels = { id: 'Id', institution: 'Instituição', author: 'Autor', title: 'Título', publisher: 'Editora/Publicação', year: 'Ano', url: 'Link', license: 'Licença de uso', language: 'Idioma' };
  const inputs = Object.fromEntries(fields.map((k) => [k, el('input', { placeholder: labels[k] })]));
  const edit = (s) => fields.forEach((k) => (inputs[k].value = s[k] || ''));
  render(
    el('h1', {}, `Fontes bibliográficas (${list.length})`),
    can('catalog:edit') && el('div', { class: 'card' }, el('h2', {}, 'Cadastrar ou editar fonte'),
      el('div', { class: 'grid3' }, ...fields.map((k) => el('div', {}, el('label', {}, labels[k]), inputs[k]))),
      el('div', { class: 'row' }, el('button', { onclick: async () => {
        try { await api('POST', '/api/admin/sources', Object.fromEntries(fields.map((k) => [k, inputs[k].value.trim()]))); toast('Fonte salva'); route(); } catch (e) { toast(e.message, true); }
      } }, 'Salvar fonte'))),
    el('table', {}, el('thead', {}, el('tr', {}, ...['Instituição / título', 'Ano', 'Licença', 'Link'].map((h) => el('th', {}, h)))),
      el('tbody', {}, ...list.map((s) => el('tr', { class: 'click', onclick: () => { edit(s); window.scrollTo(0, 0); } },
        el('td', {}, el('strong', {}, s.institution), el('div', {}, s.title), el('div', { class: 'muted' }, s.id)),
        el('td', {}, s.year), el('td', {}, s.license), el('td', {}, el('a', { href: s.url, target: '_blank', rel: 'noopener noreferrer' }, 'abrir')))))),
  );
}

// Emergências ------------------------------------------------------------------------
async function viewEmergencies() {
  const list = await api('GET', '/api/admin/emergencies');
  const ta = el('textarea', { class: 'code', value: JSON.stringify(list, null, 2), readonly: !can('catalog:edit') });
  render(
    el('h1', {}, `Guias de emergência (${list.length})`),
    el('p', { class: 'muted' }, 'Cada guia precisa de: recognize (como reconhecer), safety (segurança imediata), do (o que fazer), avoid (o que evitar) e call (números, quando e como pedir socorro).'),
    ta,
    can('catalog:edit') && el('div', { class: 'row sticky-actions' }, el('button', { onclick: async () => {
      let parsed;
      try { parsed = JSON.parse(ta.value); } catch { return toast('JSON inválido', true); }
      try { await api('PUT', '/api/admin/emergencies', parsed); toast('Guias salvos'); } catch (e) { toast(e.message, true); }
    } }, 'Validar e salvar')),
  );
}

// Cenários de crise --------------------------------------------------------------------
async function viewScenarios() {
  const list = await api('GET', '/api/admin/scenarios');
  const ta = el('textarea', { class: 'code', value: JSON.stringify(list, null, 2), readonly: !can('catalog:edit') });
  render(
    el('h1', {}, `Cenários de crise (${list.length})`),
    el('p', { class: 'muted' }, 'Cada cenário tem: id, title, icon, summary, phases (title + items por fase: preparação, primeiras 72 horas, semanas, longo prazo), related (ids de artigos) e sources (ids de fontes).'),
    ta,
    can('catalog:edit') && el('div', { class: 'row sticky-actions' }, el('button', { onclick: async () => {
      let parsed;
      try { parsed = JSON.parse(ta.value); } catch { return toast('JSON inválido', true); }
      try { await api('PUT', '/api/admin/scenarios', parsed); toast('Cenários salvos'); } catch (e) { toast(e.message, true); }
    } }, 'Validar e salvar')),
  );
}

// Mídia -------------------------------------------------------------------------------
async function viewMedia() {
  state.meta = await api('GET', '/api/admin/meta');
  const file = el('input', { type: 'file', accept: '.svg,.webp,.avif,.png,.jpg,.jpeg' });
  const name = el('input', { placeholder: 'nome-do-arquivo.webp (minúsculas e hífens)' });
  const credit = el('input', { placeholder: 'Autor / instituição' });
  const license = el('input', { placeholder: 'Ex.: CC BY 4.0, domínio público' });
  const source = el('input', { type: 'url', placeholder: 'https://… (origem da imagem)' });
  file.addEventListener('change', () => { if (file.files[0] && !name.value) name.value = file.files[0].name.toLowerCase().replace(/[^a-z0-9.]+/g, '-'); });
  render(
    el('h1', {}, `Repositório de mídia (${state.meta.media.length})`),
    el('p', { class: 'muted' }, 'Prefira WebP/AVIF para fotos e SVG para diagramas. Nunca envie imagens com direitos autorais desconhecidos: crédito e licença são obrigatórios.'),
    can('media:upload') && el('div', { class: 'card' }, el('h2', {}, 'Enviar imagem'),
      el('div', { class: 'grid2' }, el('div', {}, el('label', {}, 'Arquivo (até 2 MB)'), file), el('div', {}, el('label', {}, 'Nome no repositório'), name),
        el('div', {}, el('label', {}, 'Crédito'), credit), el('div', {}, el('label', {}, 'Licença'), license), el('div', {}, el('label', {}, 'Origem'), source)),
      el('div', { class: 'row' }, el('button', { onclick: async () => {
        const fl = file.files[0];
        if (!fl) return toast('Escolha um arquivo', true);
        const buf = new Uint8Array(await fl.arrayBuffer());
        let bin = '';
        for (let i = 0; i < buf.length; i += 0x8000) bin += String.fromCharCode(...buf.subarray(i, i + 0x8000));
        try { await api('POST', '/api/admin/media', { file: name.value.trim(), data: btoa(bin), credit: credit.value.trim(), license: license.value.trim(), source_url: source.value.trim() }); toast('Imagem enviada'); route(); } catch (e) { toast(e.message, true); }
      } }, 'Enviar'))),
    el('div', { class: 'media-grid' }, ...state.meta.media.map((m) => el('figure', {}, el('img', { src: `/media/${encodeURIComponent(m.file)}`, alt: m.file, loading: 'lazy' }), el('figcaption', {}, el('strong', {}, m.file), el('div', {}, m.credit || 'sem crédito'), el('div', { class: 'muted' }, m.license || 'sem licença'))))),
  );
}

// Publicação ---------------------------------------------------------------------------
async function viewRelease() {
  state.meta = await api('GET', '/api/admin/meta');
  const r = state.meta.release;
  const notes = el('textarea', { placeholder: 'Notas desta versão (o que mudou)' });
  const strict = el('input', { type: 'checkbox', checked: true });
  const out = el('div');
  render(
    el('h1', {}, 'Publicação de pacotes'),
    el('div', { class: 'card' }, el('p', {}, `Versão atual da biblioteca: v${r.library_version} (publicada em ${r.released_at}).`), r.notes ? el('p', { class: 'muted' }, r.notes) : null,
      el('p', { class: 'muted' }, 'Gerar uma nova versão empacota todos os artigos publicados, valida fontes, imagens e guias, calcula SHA-256 e atualiza o manifesto lido pelos aplicativos. Apps instalados preservam favoritos e anotações.')),
    can('release:build') ? el('div', { class: 'card' },
      el('label', {}, 'Notas da versão'), notes,
      el('div', { class: 'checks' }, el('label', {}, strict, 'Modo estrito: excluir conteúdos de saúde sem revisão técnica aprovada (recomendado para produção)')),
      el('div', { class: 'row' }, el('button', { class: 'warn', onclick: async () => {
        if (!confirm('Publicar nova versão para todos os aplicativos?')) return;
        try {
          const res = await api('POST', '/api/admin/release', { notes: notes.value, strict: strict.checked });
          out.replaceChildren(el('div', { class: 'card' }, el('h2', {}, `Versão v${res.release.library_version} publicada`),
            el('table', {}, el('thead', {}, el('tr', {}, ...['Pacote', 'Artigos', 'Imagens', 'Tamanho', 'SHA-256'].map((h) => el('th', {}, h)))),
              el('tbody', {}, ...res.manifest.packages.map((p) => el('tr', {}, el('td', {}, p.title), el('td', {}, p.article_count), el('td', {}, p.media_count), el('td', {}, `${(p.size_bytes / 1024).toFixed(1)} KB`), el('td', { class: 'muted' }, `${p.sha256.slice(0, 16)}…`))))),
            res.report.excluded.length ? el('ul', { class: 'warnings' }, ...res.report.excluded.map((x) => el('li', {}, x))) : null));
          toast('Nova versão publicada');
        } catch (e) { toast(e.message, true); }
      } }, 'Gerar e publicar nova versão'))) : el('p', { class: 'muted' }, 'Somente administradores publicam versões.'),
    out,
  );
}

// Usuários ------------------------------------------------------------------------------
async function viewUsers() {
  const list = await api('GET', '/api/admin/users');
  const u = el('input', { placeholder: 'usuario' });
  const n = el('input', { placeholder: 'Nome completo' });
  const role = el('select', {}, ...['editor', 'revisor', 'admin'].map((r) => el('option', { value: r }, r)));
  const p = el('input', { type: 'password', placeholder: 'Senha (mín. 10 caracteres)', autocomplete: 'new-password' });
  render(
    el('h1', {}, 'Usuários'),
    el('p', { class: 'muted' }, 'editor: escreve e envia para revisão · revisor: revisa (inclusive revisão técnica de saúde) e publica artigos · admin: tudo, incluindo publicar versões e gerenciar usuários.'),
    el('div', { class: 'card' }, el('div', { class: 'grid2' }, el('div', {}, el('label', {}, 'Usuário'), u), el('div', {}, el('label', {}, 'Nome'), n), el('div', {}, el('label', {}, 'Papel'), role), el('div', {}, el('label', {}, 'Senha'), p)),
      el('div', { class: 'row' }, el('button', { onclick: async () => { try { await api('POST', '/api/admin/users', { username: u.value.trim(), name: n.value.trim(), role: role.value, password: p.value }); toast('Usuário salvo'); route(); } catch (e) { toast(e.message, true); } } }, 'Salvar usuário'))),
    el('table', {}, el('thead', {}, el('tr', {}, el('th', {}, 'Usuário'), el('th', {}, 'Nome'), el('th', {}, 'Papel'))), el('tbody', {}, ...list.map((x) => el('tr', {}, el('td', {}, x.username), el('td', {}, x.name), el('td', {}, x.role))))),
  );
}

// Início --------------------------------------------------------------------------------
(async () => {
  try {
    state.me = await api('GET', '/api/admin/me');
    await boot();
  } catch {
    renderLogin();
  }
})();
