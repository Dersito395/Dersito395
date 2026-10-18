// SOBREVIVA — servidor de administração editorial e de atualização de conteúdo.
//
// Separação de responsabilidades:
//   /api/v1/*      serviço de atualização (público, somente leitura; pode ser servido por CDN)
//   /api/admin/*   plataforma de administração (autenticada)
//   /admin/*       interface web do painel
//   /media/*       repositório de mídia (pré-visualização para editores)

import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

import { ContentStore } from './content-store.js';
import { build } from './builder.js';
import { normalizeArticle, validateArticle, validateEmergency, DIFFICULTIES, ENVIRONMENTS, STATUSES } from './validate.js';
import { UserStore, Sessions, can, parseCookies, verifyPassword, ROLES } from './auth.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..', '..');

const STATIC_TYPES = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.svg': 'image/svg+xml', '.png': 'image/png', '.webp': 'image/webp', '.avif': 'image/avif', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.json': 'application/json' };

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

const today = () => new Date().toISOString().slice(0, 10);

export function createServer(options = {}) {
  const contentDir = options.contentDir || process.env.CONTENT_DIR || path.join(root, 'content');
  const distDir = options.distDir || process.env.DIST_DIR || path.join(root, 'server', 'dist', 'updates');
  const dataDir = options.dataDir || process.env.DATA_DIR || path.join(root, 'server', 'data');
  const secureCookie = options.secureCookie ?? process.env.COOKIE_SECURE === '1';
  const store = new ContentStore(contentDir);
  const users = new UserStore(path.join(dataDir, 'users.json'));
  const sessions = new Sessions();
  const adminDir = path.join(here, '..', 'public', 'admin');

  // Utilidades -----------------------------------------------------------------
  function send(res, status, body, headers = {}) {
    const isBuffer = Buffer.isBuffer(body);
    const payload = isBuffer || typeof body === 'string' ? body : JSON.stringify(body);
    res.writeHead(status, {
      'Content-Type': isBuffer || typeof body === 'string' ? 'text/plain; charset=utf-8' : 'application/json; charset=utf-8',
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'Referrer-Policy': 'no-referrer',
      'Content-Security-Policy': "default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self'; frame-ancestors 'none'",
      ...headers,
    });
    res.end(payload);
  }

  async function readJson(req, limit = 6 * 1024 * 1024) {
    const chunks = [];
    let size = 0;
    for await (const chunk of req) {
      size += chunk.length;
      if (size > limit) throw new HttpError(413, 'requisição muito grande');
      chunks.push(chunk);
    }
    if (!chunks.length) return {};
    try {
      return JSON.parse(Buffer.concat(chunks).toString('utf8'));
    } catch {
      throw new HttpError(400, 'JSON inválido');
    }
  }

  function serveFile(res, file, { cache = 'no-cache', req } = {}) {
    if (!fs.existsSync(file) || !fs.statSync(file).isFile()) throw new HttpError(404, 'não encontrado');
    const body = fs.readFileSync(file);
    const etag = `"${crypto.createHash('sha1').update(body).digest('hex')}"`;
    if (req && req.headers['if-none-match'] === etag) {
      res.writeHead(304, { ETag: etag });
      return res.end();
    }
    send(res, 200, body, { 'Content-Type': STATIC_TYPES[path.extname(file)] || 'application/octet-stream', 'Cache-Control': cache, ETag: etag });
  }

  function session(req) {
    return sessions.get(parseCookies(req.headers.cookie).sv_session);
  }

  function requireSession(req, permission) {
    const s = session(req);
    if (!s) throw new HttpError(401, 'faça login');
    if (req.method !== 'GET' && req.headers['x-csrf-token'] !== s.csrf) throw new HttpError(403, 'token CSRF inválido');
    if (permission && !can(s, permission)) throw new HttpError(403, 'sem permissão para esta ação');
    return s;
  }

  function validationContext() {
    const published = store.publishedArticles().filter((a) => a.status !== 'arquivado');
    return {
      categories: store.categories(),
      sources: new Set(store.sources().map((s) => s.id)),
      media: new Set(store.mediaFiles()),
      articleIds: new Set([...published.map((a) => a.id), ...store.drafts().map((d) => d.id)]),
    };
  }

  function logEntry(s, action, comment) {
    return { at: new Date().toISOString(), by: s.username, action, comment: comment || null };
  }

  // Rotas da administração ---------------------------------------------------------
  async function admin(req, res, url) {
    const parts = url.pathname.replace(/^\/api\/admin\/?/, '').split('/').filter(Boolean);
    const [resource, id, sub] = parts;
    const m = req.method;

    if (resource === 'login' && m === 'POST') {
      const { username, password } = await readJson(req);
      const key = `${username}|${req.socket.remoteAddress}`;
      if (sessions.isLocked(key)) throw new HttpError(429, 'muitas tentativas; aguarde 15 minutos');
      const user = users.find(String(username || ''));
      if (!user || !verifyPassword(String(password || ''), user.password)) {
        sessions.fail(key);
        throw new HttpError(401, 'usuário ou senha incorretos');
      }
      sessions.succeed(key);
      const { id: sid, csrf } = sessions.create(user);
      const cookie = `sv_session=${sid}; HttpOnly; SameSite=Strict; Path=/; Max-Age=7200${secureCookie ? '; Secure' : ''}`;
      return send(res, 200, { username: user.username, name: user.name, role: user.role, csrf, permissions: ROLES[user.role] }, { 'Set-Cookie': cookie });
    }
    if (resource === 'logout' && m === 'POST') {
      const sid = parseCookies(req.headers.cookie).sv_session;
      sessions.destroy(sid);
      return send(res, 200, { ok: true }, { 'Set-Cookie': 'sv_session=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0' });
    }
    if (resource === 'me' && m === 'GET') {
      const s = requireSession(req);
      return send(res, 200, { username: s.username, name: s.name, role: s.role, csrf: s.csrf, permissions: ROLES[s.role] });
    }

    if (resource === 'meta' && m === 'GET') {
      requireSession(req);
      const mediaMeta = store.mediaMeta();
      return send(res, 200, {
        categories: store.categories(),
        sources: store.sources(),
        media: store.mediaFiles().map((f) => ({ file: f, ...(mediaMeta[f] || {}) })),
        difficulties: DIFFICULTIES,
        environments: ENVIRONMENTS,
        statuses: STATUSES,
        release: store.release(),
      });
    }

    if (resource === 'articles') {
      if (!id && m === 'GET') {
        requireSession(req);
        const map = new Map();
        for (const a of store.publishedArticles().map(normalizeArticle)) {
          map.set(a.id, { id: a.id, title: a.title, category: a.category, published_version: a.version, published_status: a.status, draft_status: null, technical_required: a.review.technical_required, technical_status: a.review.technical_status, updated_at: a.updated_at });
        }
        for (const d of store.drafts().map(normalizeArticle)) {
          const row = map.get(d.id) || { id: d.id, published_version: null, published_status: null };
          map.set(d.id, { ...row, title: d.title, category: d.category, draft_status: d.status, technical_required: d.review.technical_required, technical_status: d.review.technical_status, updated_at: d.workflow?.log?.at?.(-1)?.at || row.updated_at });
        }
        return send(res, 200, [...map.values()].sort((a, b) => a.category.localeCompare(b.category) || a.title.localeCompare(b.title)));
      }
      if (!id && m === 'POST') {
        const s = requireSession(req, 'article:edit');
        const body = await readJson(req);
        ContentStore.assertId(body.id);
        if (store.published(body.id) || store.draft(body.id)) throw new HttpError(409, 'já existe um artigo com este id');
        const draft = {
          id: body.id,
          title: String(body.title || 'Novo artigo'),
          summary: '',
          category: body.category,
          subcategory: null,
          difficulty: 'basica',
          environments: ['qualquer'],
          time_estimate: '',
          materials: [],
          objective: '',
          steps: [],
          cautions: [],
          alternatives: [],
          tags: [],
          keywords: [],
          images: [],
          sources: [],
          related: [],
          status: 'rascunho',
          workflow: { log: [logEntry(s, 'criado')], last_editor: s.username },
        };
        store.saveDraft(draft);
        return send(res, 201, draft);
      }
      ContentStore.assertId(id);

      if (!sub && m === 'GET') {
        requireSession(req);
        const published = store.published(id);
        const draft = store.draft(id);
        if (!published && !draft) throw new HttpError(404, 'artigo não encontrado');
        const target = draft || published;
        return send(res, 200, {
          published,
          draft,
          history: store.history(id).map((h) => ({ version: h.version, updated_at: h.updated_at, status: h.status })),
          validation: validateArticle(normalizeArticle(target), validationContext()),
        });
      }
      if (sub === 'draft' && m === 'POST') {
        const s = requireSession(req, 'article:edit');
        if (store.draft(id)) throw new HttpError(409, 'já existe um rascunho em andamento');
        const published = store.published(id);
        if (!published) throw new HttpError(404, 'artigo não encontrado');
        const draft = { ...published, status: 'rascunho', workflow: { log: [logEntry(s, 'edição iniciada', `a partir da v${published.version || 1}`)], last_editor: s.username } };
        delete draft.published_by;
        store.saveDraft(draft);
        return send(res, 201, draft);
      }
      if (sub === 'draft' && m === 'PUT') {
        const s = requireSession(req, 'article:edit');
        const current = store.draft(id);
        if (!current) throw new HttpError(404, 'rascunho não encontrado');
        if (current.status === 'aprovado') throw new HttpError(409, 'rascunho aprovado: devolva para edição antes de alterar');
        const body = await readJson(req);
        const incoming = body.article || {};
        if (incoming.id !== id) throw new HttpError(400, 'id do artigo não pode ser alterado');
        const next = {
          ...incoming,
          status: 'rascunho',
          // Qualquer alteração invalida uma revisão técnica anterior.
          review: { ...(incoming.review || {}), technical_status: 'pendente', reviewer: null, reviewed_at: null },
          workflow: { log: [...(current.workflow?.log || []), logEntry(s, 'editado')], last_editor: s.username },
        };
        delete next.version;
        store.saveDraft(next);
        return send(res, 200, { draft: next, validation: validateArticle(normalizeArticle(next), validationContext()) });
      }
      if (sub === 'draft' && m === 'DELETE') {
        requireSession(req, 'article:edit');
        store.deleteDraft(id);
        return send(res, 200, { ok: true });
      }
      if (sub === 'transition' && m === 'POST') {
        const s = requireSession(req);
        const { action, comment } = await readJson(req);
        if (action === 'archive') {
          if (!can(s, 'article:publish')) throw new HttpError(403, 'sem permissão');
          store.archive(id, { date: today() });
          return send(res, 200, { ok: true });
        }
        const draft = store.draft(id);
        if (!draft) throw new HttpError(404, 'rascunho não encontrado');
        const normalized = normalizeArticle(draft);
        const log = draft.workflow?.log || [];
        const save = (status, extra = {}) => {
          const next = { ...draft, ...extra, status, workflow: { ...draft.workflow, log: [...log, logEntry(s, action, comment)] } };
          store.saveDraft(next);
          return next;
        };
        switch (action) {
          case 'submit': {
            if (!can(s, 'article:submit')) throw new HttpError(403, 'sem permissão');
            if (draft.status !== 'rascunho') throw new HttpError(409, 'somente rascunhos podem ser enviados para revisão');
            const v = validateArticle(normalized, validationContext());
            if (v.errors.length) throw new HttpError(422, `corrija antes de enviar: ${v.errors.join('; ')}`);
            return send(res, 200, save('em_revisao'));
          }
          case 'return': {
            if (!can(s, 'article:review')) throw new HttpError(403, 'sem permissão');
            if (!comment) throw new HttpError(400, 'explique o motivo da devolução');
            return send(res, 200, save('rascunho'));
          }
          case 'approve': {
            if (!can(s, 'article:review')) throw new HttpError(403, 'sem permissão');
            if (draft.status !== 'em_revisao') throw new HttpError(409, 'o artigo não está em revisão');
            if (draft.workflow?.last_editor === s.username) throw new HttpError(409, 'a revisão deve ser feita por outra pessoa, não por quem editou');
            const review = { ...normalized.review };
            if (review.technical_required) {
              if (!can(s, 'article:technical-review')) throw new HttpError(403, 'conteúdo de saúde exige revisor técnico');
              review.technical_status = 'aprovado';
              review.reviewer = s.name;
              review.reviewed_at = today();
            }
            return send(res, 200, save('aprovado', { review }));
          }
          case 'publish': {
            if (!can(s, 'article:publish')) throw new HttpError(403, 'sem permissão');
            if (draft.status !== 'aprovado') throw new HttpError(409, 'somente artigos aprovados podem ser publicados');
            save('aprovado');
            return send(res, 200, store.publishDraft(id, { publishedBy: s.username, date: today() }));
          }
          default:
            throw new HttpError(400, 'ação desconhecida');
        }
      }
    }

    if (resource === 'sources') {
      if (m === 'GET') {
        requireSession(req);
        return send(res, 200, store.sources());
      }
      if (m === 'POST') {
        requireSession(req, 'catalog:edit');
        const src = await readJson(req);
        ContentStore.assertId(src.id);
        for (const k of ['institution', 'title', 'year', 'url', 'license']) if (!src[k]) throw new HttpError(400, `campo obrigatório: ${k}`);
        if (!/^https?:\/\//.test(src.url)) throw new HttpError(400, 'URL inválida');
        const list = store.sources().filter((x) => x.id !== src.id);
        list.push({ id: src.id, institution: src.institution, author: src.author || src.institution, title: src.title, publisher: src.publisher || '', year: String(src.year), url: src.url, license: src.license, language: src.language || 'pt-BR' });
        store.saveSources(list);
        return send(res, 200, { ok: true });
      }
    }

    if (resource === 'emergencies') {
      if (m === 'GET') {
        requireSession(req);
        return send(res, 200, store.emergencies());
      }
      if (m === 'PUT') {
        requireSession(req, 'catalog:edit');
        const list = await readJson(req);
        if (!Array.isArray(list)) throw new HttpError(400, 'esperado um array de guias');
        const errors = list.flatMap(validateEmergency);
        if (errors.length) throw new HttpError(422, errors.join('; '));
        store.saveEmergencies(list);
        return send(res, 200, { ok: true });
      }
    }

    if (resource === 'media' && m === 'POST') {
      requireSession(req, 'media:upload');
      const body = await readJson(req, 4 * 1024 * 1024);
      if (typeof body.data !== 'string') throw new HttpError(400, 'arquivo ausente');
      store.saveMedia(String(body.file || ''), Buffer.from(body.data, 'base64'), body);
      return send(res, 201, { ok: true, file: body.file });
    }

    if (resource === 'release' && m === 'POST') {
      const s = requireSession(req, 'release:build');
      const body = await readJson(req);
      const current = store.release();
      const next = { library_version: current.library_version + 1, released_at: today(), notes: String(body.notes || ''), released_by: s.username };
      store.saveRelease(next);
      const result = build(store, { outDir: distDir, strict: body.strict !== false });
      if (!result.ok) {
        store.saveRelease(current);
        throw new HttpError(422, `publicação interrompida: ${result.report.errors.join('; ')}`);
      }
      return send(res, 200, { release: next, report: result.report, manifest: result.manifest });
    }

    if (resource === 'users') {
      if (m === 'GET') {
        requireSession(req, 'user:manage');
        return send(res, 200, users.all().map(({ password, ...u }) => u));
      }
      if (m === 'POST') {
        requireSession(req, 'user:manage');
        return send(res, 200, users.upsert(await readJson(req)));
      }
    }

    throw new HttpError(404, 'rota não encontrada');
  }

  // Servidor HTTP -----------------------------------------------------------------
  return http.createServer(async (req, res) => {
    const url = new URL(req.url, 'http://localhost');
    try {
      if (url.pathname === '/health') return send(res, 200, { ok: true });
      if (url.pathname === '/') return send(res, 302, '', { Location: '/admin/' });

      // Serviço de atualização (público).
      if (url.pathname === '/api/v1/manifest.json' || url.pathname === '/api/v1/manifest') {
        if (req.method !== 'GET') throw new HttpError(405, 'método não permitido');
        return serveFile(res, path.join(distDir, 'manifest.json'), { req, cache: 'no-cache' });
      }
      const pkg = url.pathname.match(/^\/api\/v1\/packages\/([a-z0-9-]+-v\d+\.json)$/);
      if (pkg) return serveFile(res, path.join(distDir, 'packages', pkg[1]), { req, cache: 'public, max-age=31536000, immutable' });

      if (url.pathname.startsWith('/api/admin/')) return await admin(req, res, url);

      const media = url.pathname.match(/^\/media\/([^/]+)$/);
      if (media) {
        requireSession(req);
        return serveFile(res, store.mediaPath(media[1]), { req });
      }

      if (url.pathname === '/admin' || url.pathname.startsWith('/admin/')) {
        const rel = url.pathname.replace(/^\/admin\/?/, '') || 'index.html';
        if (!/^[a-z0-9._-]+$/.test(rel)) throw new HttpError(404, 'não encontrado');
        return serveFile(res, path.join(adminDir, rel), { req });
      }
      throw new HttpError(404, 'não encontrado');
    } catch (e) {
      const status = e.status || 500;
      if (status === 500) console.error(e);
      if (!res.headersSent) send(res, status, { error: status === 500 ? 'erro interno' : e.message });
    }
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.PORT || 8787);
  const host = process.env.HOST || '127.0.0.1';
  createServer().listen(port, host, () => {
    console.log(`SOBREVIVA: painel em http://${host}:${port}/admin/  •  atualizações em http://${host}:${port}/api/v1/`);
  });
}
