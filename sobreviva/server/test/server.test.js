import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

import { createServer } from '../src/server.js';
import { UserStore, hashPassword, verifyPassword } from '../src/auth.js';
import { ContentStore } from '../src/content-store.js';
import { build } from '../src/builder.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'sobreviva-srv-'));
const contentDir = path.join(tmp, 'content');
const distDir = path.join(tmp, 'dist');
const dataDir = path.join(tmp, 'data');
let server;
let base;

before(async () => {
  fs.cpSync(path.join(here, '..', '..', 'content'), contentDir, { recursive: true });
  const users = new UserStore(path.join(dataDir, 'users.json'));
  users.upsert({ username: 'editora', role: 'editor', name: 'Editora', password: 'senha-editora-1' });
  users.upsert({ username: 'medica', role: 'revisor', name: 'Dra. Revisora', password: 'senha-revisora-1' });
  users.upsert({ username: 'admin', role: 'admin', name: 'Admin', password: 'senha-admin-123' });
  build(new ContentStore(contentDir), { outDir: distDir });
  server = createServer({ contentDir, distDir, dataDir });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}`;
});

after(() => {
  server.close();
  fs.rmSync(tmp, { recursive: true, force: true });
});

async function login(username, password) {
  const res = await fetch(`${base}/api/admin/login`, { method: 'POST', body: JSON.stringify({ username, password }) });
  const body = await res.json();
  if (!res.ok) return { status: res.status, body };
  const cookie = res.headers.get('set-cookie').split(';')[0];
  const call = async (method, url, data, { csrf = true } = {}) => {
    const r = await fetch(`${base}${url}`, {
      method,
      headers: { cookie, 'content-type': 'application/json', ...(csrf ? { 'x-csrf-token': body.csrf } : {}) },
      body: data === undefined ? undefined : JSON.stringify(data),
    });
    return { status: r.status, body: await r.json().catch(() => null) };
  };
  return { status: 200, body, call, cookie };
}

test('cenários: leitura e validação ao salvar', async () => {
  const ad = await login('editora', 'senha-editora-1');
  const list = (await ad.call('GET', '/api/admin/scenarios')).body;
  assert.ok(list.length >= 6);
  assert.equal((await ad.call('PUT', '/api/admin/scenarios', list)).status, 403); // editor não edita catálogo
});

test('senhas com scrypt', () => {
  const h = hashPassword('uma-senha-longa');
  assert.ok(h.startsWith('scrypt$'));
  assert.ok(verifyPassword('uma-senha-longa', h));
  assert.ok(!verifyPassword('outra-senha', h));
});

test('serviço de atualização público: manifesto e pacotes com integridade', async () => {
  const res = await fetch(`${base}/api/v1/manifest.json`);
  assert.equal(res.status, 200);
  const manifest = await res.json();
  const essencial = manifest.packages.find((p) => p.id === 'essencial');
  assert.ok(essencial.article_count >= 30);
  const pkg = await fetch(`${base}/api/v1/${essencial.url}`);
  const bytes = Buffer.from(await pkg.arrayBuffer());
  assert.equal(bytes.length, essencial.size_bytes);
  assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'), essencial.sha256);
  assert.match(pkg.headers.get('cache-control'), /immutable/);
  const etag = res.headers.get('etag');
  const again = await fetch(`${base}/api/v1/manifest.json`, { headers: { 'if-none-match': etag } });
  assert.equal(again.status, 304);
});

test('rotas de pacote rejeitam caminhos arbitrários', async () => {
  const r = await fetch(`${base}/api/v1/packages/..%2F..%2Fdata%2Fusers.json`);
  assert.equal(r.status, 404);
});

test('administração exige login, CSRF e permissões', async () => {
  assert.equal((await fetch(`${base}/api/admin/articles`)).status, 401);
  assert.equal((await login('editora', 'errada')).status, 401);
  const ed = await login('editora', 'senha-editora-1');
  assert.equal((await ed.call('GET', '/api/admin/articles')).status, 200);
  const noCsrf = await ed.call('POST', '/api/admin/articles', { id: 'x-teste', title: 'X', category: 'agua' }, { csrf: false });
  assert.equal(noCsrf.status, 403);
  assert.equal((await ed.call('POST', '/api/admin/release', {})).status, 403);
  assert.equal((await ed.call('GET', '/api/admin/users')).status, 403);
});

test('bloqueio após tentativas de login repetidas', async () => {
  for (let i = 0; i < 5; i++) await login('admin', 'errada');
  assert.equal((await login('admin', 'senha-admin-123')).status, 429);
});

test('fluxo editorial completo com revisão técnica e versionamento', async () => {
  const ed = await login('editora', 'senha-editora-1');
  const rev = await login('medica', 'senha-revisora-1');

  // Cria nova versão de um artigo de saúde publicado.
  assert.equal((await ed.call('POST', '/api/admin/articles/ps-engasgo/draft')).status, 201);
  const current = (await ed.call('GET', '/api/admin/articles/ps-engasgo')).body;
  assert.equal(current.published.version, 1);
  const edited = { ...current.draft, summary: `${current.draft.summary} (revisado)` };
  const saved = await ed.call('PUT', '/api/admin/articles/ps-engasgo/draft', { article: edited });
  assert.equal(saved.status, 200);
  assert.deepEqual(saved.body.validation.errors, []);

  assert.equal((await ed.call('POST', '/api/admin/articles/ps-engasgo/transition', { action: 'submit' })).status, 200);
  // Editor não pode aprovar.
  assert.equal((await ed.call('POST', '/api/admin/articles/ps-engasgo/transition', { action: 'approve' })).status, 403);
  // Revisora aprova: revisão técnica registrada.
  const approved = await rev.call('POST', '/api/admin/articles/ps-engasgo/transition', { action: 'approve', comment: 'Conferido com AHA 2025' });
  assert.equal(approved.status, 200);
  assert.equal(approved.body.review.technical_status, 'aprovado');
  assert.equal(approved.body.review.reviewer, 'Dra. Revisora');
  const published = await rev.call('POST', '/api/admin/articles/ps-engasgo/transition', { action: 'publish' });
  assert.equal(published.status, 200);
  assert.equal(published.body.version, 2);
  const after = (await ed.call('GET', '/api/admin/articles/ps-engasgo')).body;
  assert.equal(after.draft, null);
  assert.deepEqual(after.history.map((h) => h.version), [1]);
});

test('quem editou não pode aprovar a própria alteração', async () => {
  const rev = await login('medica', 'senha-revisora-1');
  await rev.call('POST', '/api/admin/articles/urb-apagao/draft');
  const d = (await rev.call('GET', '/api/admin/articles/urb-apagao')).body.draft;
  await rev.call('PUT', '/api/admin/articles/urb-apagao/draft', { article: d });
  await rev.call('POST', '/api/admin/articles/urb-apagao/transition', { action: 'submit' });
  const r = await rev.call('POST', '/api/admin/articles/urb-apagao/transition', { action: 'approve' });
  assert.equal(r.status, 409);
});

test('envio para revisão bloqueado quando há erros de validação', async () => {
  const ed = await login('editora', 'senha-editora-1');
  assert.equal((await ed.call('POST', '/api/admin/articles', { id: 'novo-artigo', title: 'Novo', category: 'agua' })).status, 201);
  const r = await ed.call('POST', '/api/admin/articles/novo-artigo/transition', { action: 'submit' });
  assert.equal(r.status, 422);
  assert.match(r.body.error, /fonte/);
});

test('upload de mídia exige licença e recusa SVG ativo', async () => {
  const ed = await login('editora', 'senha-editora-1');
  const svg = Buffer.from("<svg xmlns='http://www.w3.org/2000/svg'><rect width='1' height='1'/></svg>").toString('base64');
  assert.equal((await ed.call('POST', '/api/admin/media', { file: 'teste.svg', data: svg, credit: 'X' })).status, 400);
  const evil = Buffer.from("<svg onload='alert(1)'></svg>").toString('base64');
  assert.equal((await ed.call('POST', '/api/admin/media', { file: 'mal.svg', data: evil, credit: 'X', license: 'CC0' })).status, 400);
  assert.equal((await ed.call('POST', '/api/admin/media', { file: 'teste.svg', data: svg, credit: 'Equipe', license: 'CC BY 4.0' })).status, 201);
  assert.equal((await ed.call('POST', '/api/admin/media', { file: '../fora.svg', data: svg, credit: 'E', license: 'CC0' })).status, 400);
});

test('publicação de versão gera manifesto novo (modo estrito exclui saúde não revisada)', async () => {
  // O usuário "admin" ficou bloqueado no teste de tentativas; cria outro administrador.
  new UserStore(path.join(dataDir, 'users.json')).upsert({ username: 'admin2', role: 'admin', name: 'Admin 2', password: 'senha-admin-456' });
  const a = await login('admin2', 'senha-admin-456');
  const before = JSON.parse(fs.readFileSync(path.join(contentDir, 'release.json'), 'utf8')).library_version;
  const next = before + 1;
  const r = await a.call('POST', '/api/admin/release', { notes: 'teste', strict: true });
  assert.equal(r.status, 200);
  assert.equal(r.body.release.library_version, next);
  assert.ok(r.body.report.excluded.some((x) => x.startsWith('ps-rcp-adulto')));
  assert.ok(!r.body.report.excluded.some((x) => x.startsWith('ps-engasgo')), 'engasgo foi revisado e deve entrar');
  const manifest = await (await fetch(`${base}/api/v1/manifest.json`)).json();
  assert.equal(manifest.library_version, next);
  assert.ok(manifest.packages.every((p) => p.url.endsWith(`-v${next}.json`)));
});
