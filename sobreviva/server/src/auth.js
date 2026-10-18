// Autenticação do painel administrativo.
//
// - Senhas com scrypt + sal individual (node:crypto), comparação em tempo constante.
// - Sessões em memória, cookie HttpOnly + SameSite=Strict, expiração por inatividade.
// - Token CSRF por sessão, exigido no cabeçalho X-CSRF-Token em requisições que alteram dados.
// - Limite de tentativas de login por usuário/IP.
//
// O aplicativo móvel NÃO usa autenticação: a leitura da biblioteca é livre e offline.

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

export const ROLES = {
  editor: ['article:edit', 'article:submit', 'media:upload'],
  revisor: ['article:edit', 'article:submit', 'media:upload', 'article:review', 'article:technical-review', 'article:publish'],
  admin: ['article:edit', 'article:submit', 'media:upload', 'article:review', 'article:technical-review', 'article:publish', 'release:build', 'catalog:edit', 'user:manage'],
};

const SESSION_TTL_MS = 2 * 60 * 60 * 1000;
const MAX_ATTEMPTS = 5;
const LOCK_MS = 15 * 60 * 1000;

export function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  const hash = crypto.scryptSync(password, salt, 64, { N: 16384, r: 8, p: 1 }).toString('hex');
  return `scrypt$${salt}$${hash}`;
}

export function verifyPassword(password, stored) {
  const [alg, salt, hash] = String(stored).split('$');
  if (alg !== 'scrypt' || !salt || !hash) return false;
  const candidate = Buffer.from(hashPassword(password, salt).split('$')[2], 'hex');
  const expected = Buffer.from(hash, 'hex');
  return candidate.length === expected.length && crypto.timingSafeEqual(candidate, expected);
}

export class UserStore {
  constructor(file) {
    this.file = file;
  }

  all() {
    if (!fs.existsSync(this.file)) return [];
    return JSON.parse(fs.readFileSync(this.file, 'utf8'));
  }

  find(username) {
    return this.all().find((u) => u.username === username) || null;
  }

  upsert({ username, password, role, name }) {
    if (!/^[a-z0-9._-]{3,32}$/.test(username)) throw Object.assign(new Error('usuário inválido (3–32 caracteres: a-z 0-9 . _ -)'), { status: 400 });
    if (!ROLES[role]) throw Object.assign(new Error('papel inválido'), { status: 400 });
    if (password !== undefined && String(password).length < 10) throw Object.assign(new Error('a senha deve ter pelo menos 10 caracteres'), { status: 400 });
    const users = this.all();
    const existing = users.find((u) => u.username === username);
    const record = {
      username,
      name: name || existing?.name || username,
      role,
      password: password !== undefined ? hashPassword(String(password)) : existing?.password,
    };
    if (!record.password) throw Object.assign(new Error('senha obrigatória'), { status: 400 });
    const next = existing ? users.map((u) => (u.username === username ? record : u)) : [...users, record];
    fs.mkdirSync(path.dirname(this.file), { recursive: true });
    fs.writeFileSync(this.file, JSON.stringify(next, null, 2), { mode: 0o600 });
    return { username: record.username, name: record.name, role: record.role };
  }
}

export class Sessions {
  constructor() {
    this.sessions = new Map();
    this.attempts = new Map();
  }

  create(user) {
    const id = crypto.randomBytes(32).toString('base64url');
    const csrf = crypto.randomBytes(24).toString('base64url');
    this.sessions.set(id, { username: user.username, name: user.name, role: user.role, csrf, expires: Date.now() + SESSION_TTL_MS });
    return { id, csrf };
  }

  get(id) {
    const s = id && this.sessions.get(id);
    if (!s) return null;
    if (s.expires < Date.now()) {
      this.sessions.delete(id);
      return null;
    }
    s.expires = Date.now() + SESSION_TTL_MS;
    return s;
  }

  destroy(id) {
    this.sessions.delete(id);
  }

  isLocked(key) {
    const a = this.attempts.get(key);
    return !!a && a.count >= MAX_ATTEMPTS && Date.now() - a.last < LOCK_MS;
  }

  fail(key) {
    const a = this.attempts.get(key) || { count: 0, last: 0 };
    if (Date.now() - a.last > LOCK_MS) a.count = 0;
    a.count += 1;
    a.last = Date.now();
    this.attempts.set(key, a);
  }

  succeed(key) {
    this.attempts.delete(key);
  }
}

export function can(session, permission) {
  return !!session && (ROLES[session.role] || []).includes(permission);
}

export function parseCookies(header = '') {
  const out = {};
  for (const part of header.split(';')) {
    const i = part.indexOf('=');
    if (i > 0) out[part.slice(0, i).trim()] = decodeURIComponent(part.slice(i + 1).trim());
  }
  return out;
}
