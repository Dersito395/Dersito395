// Repositório editorial em arquivos JSON (fácil de versionar no git e de revisar em diffs).
//
// content/
//   articles/<id>.json        versão publicada (ou arquivada) de cada artigo
//   drafts/<id>.json          versão de trabalho em edição/revisão
//   history/<id>/v<N>.json    versões publicadas anteriores
//   media/                    repositório de mídia + media.json (créditos e licenças)
//   categories.json sources.json synonyms.json packages.json numbers.json emergencies.json release.json

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const ID_RE = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const MEDIA_RE = /^[a-z0-9][a-z0-9-]*\.(svg|webp|avif|png|jpg|jpeg)$/;

export class ContentStore {
  constructor(root) {
    this.root = path.resolve(root);
  }

  p(...parts) {
    return path.join(this.root, ...parts);
  }

  readJson(rel, fallback = undefined) {
    const file = this.p(rel);
    if (!fs.existsSync(file)) {
      if (fallback !== undefined) return fallback;
      throw new Error(`arquivo não encontrado: ${rel}`);
    }
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  }

  // Escrita atômica: grava em arquivo temporário e renomeia.
  writeJson(rel, data) {
    const file = this.p(rel);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    const tmp = `${file}.${crypto.randomBytes(4).toString('hex')}.tmp`;
    fs.writeFileSync(tmp, `${JSON.stringify(data, null, 2)}\n`, 'utf8');
    fs.renameSync(tmp, file);
  }

  static assertId(id) {
    if (typeof id !== 'string' || !ID_RE.test(id)) throw Object.assign(new Error('id inválido'), { status: 400 });
  }

  categories() { return this.readJson('categories.json'); }
  sources() { return this.readJson('sources.json'); }
  synonyms() { return this.readJson('synonyms.json').groups; }
  packages() { return this.readJson('packages.json'); }
  numbers() { return this.readJson('numbers.json'); }
  emergencies() { return this.readJson('emergencies.json'); }
  release() { return this.readJson('release.json'); }
  mediaMeta() { return this.readJson('media.json', {}); }

  saveSources(list) { this.writeJson('sources.json', list); }
  saveEmergencies(list) { this.writeJson('emergencies.json', list); }
  saveRelease(r) { this.writeJson('release.json', r); }

  listDir(rel) {
    const dir = this.p(rel);
    if (!fs.existsSync(dir)) return [];
    return fs.readdirSync(dir).filter((f) => f.endsWith('.json')).sort();
  }

  publishedArticles() {
    return this.listDir('articles').map((f) => this.readJson(path.join('articles', f)));
  }

  published(id) {
    ContentStore.assertId(id);
    return this.readJson(path.join('articles', `${id}.json`), null);
  }

  drafts() {
    return this.listDir('drafts').map((f) => this.readJson(path.join('drafts', f)));
  }

  draft(id) {
    ContentStore.assertId(id);
    return this.readJson(path.join('drafts', `${id}.json`), null);
  }

  saveDraft(article) {
    ContentStore.assertId(article.id);
    this.writeJson(path.join('drafts', `${article.id}.json`), article);
  }

  deleteDraft(id) {
    ContentStore.assertId(id);
    const f = this.p('drafts', `${id}.json`);
    if (fs.existsSync(f)) fs.unlinkSync(f);
  }

  history(id) {
    ContentStore.assertId(id);
    return this.listDir(path.join('history', id))
      .map((f) => this.readJson(path.join('history', id, f)))
      .sort((a, b) => b.version - a.version);
  }

  /**
   * Publica o rascunho: a versão publicada anterior vai para o histórico,
   * o rascunho vira a nova versão publicada (versão + 1) e é removido de drafts/.
   */
  publishDraft(id, { publishedBy, date }) {
    const draft = this.draft(id);
    if (!draft) throw Object.assign(new Error('rascunho não encontrado'), { status: 404 });
    const current = this.published(id);
    if (current) this.writeJson(path.join('history', id, `v${current.version || 1}.json`), current);
    const next = {
      ...draft,
      status: 'publicado',
      version: current ? (current.version || 1) + 1 : 1,
      updated_at: date,
      published_by: publishedBy,
    };
    delete next.workflow;
    this.writeJson(path.join('articles', `${id}.json`), next);
    this.deleteDraft(id);
    return next;
  }

  archive(id, { date }) {
    const current = this.published(id);
    if (!current) throw Object.assign(new Error('artigo não publicado'), { status: 404 });
    this.writeJson(path.join('history', id, `v${current.version || 1}.json`), current);
    this.writeJson(path.join('articles', `${id}.json`), { ...current, status: 'arquivado', updated_at: date });
  }

  mediaFiles() {
    const dir = this.p('media');
    if (!fs.existsSync(dir)) return [];
    return fs.readdirSync(dir).filter((f) => MEDIA_RE.test(f)).sort();
  }

  mediaPath(file) {
    if (!MEDIA_RE.test(file)) throw Object.assign(new Error('nome de arquivo de mídia inválido'), { status: 400 });
    return this.p('media', file);
  }

  /** Salva um arquivo de mídia com metadados de crédito e licença (obrigatórios). */
  saveMedia(file, buffer, meta) {
    const target = this.mediaPath(file);
    if (!meta || !meta.credit || !meta.license) {
      throw Object.assign(new Error('crédito e licença são obrigatórios para qualquer imagem'), { status: 400 });
    }
    if (buffer.length > 2 * 1024 * 1024) throw Object.assign(new Error('arquivo maior que 2 MB'), { status: 400 });
    if (file.endsWith('.svg')) {
      const text = buffer.toString('utf8');
      if (!text.includes('<svg') || /<script|\son[a-z]+\s*=|javascript:/i.test(text)) {
        throw Object.assign(new Error('SVG inválido ou com conteúdo ativo'), { status: 400 });
      }
    } else if (!sniffImage(buffer)) {
      throw Object.assign(new Error('conteúdo do arquivo não corresponde a uma imagem suportada'), { status: 400 });
    }
    fs.writeFileSync(target, buffer);
    const all = this.mediaMeta();
    all[file] = {
      credit: String(meta.credit),
      license: String(meta.license),
      source_url: meta.source_url ? String(meta.source_url) : null,
      created_at: new Date().toISOString().slice(0, 10),
    };
    this.writeJson('media.json', all);
  }
}

function sniffImage(b) {
  if (b.length < 12) return false;
  const ascii = (s, e) => b.subarray(s, e).toString('latin1');
  if (b[0] === 0x89 && ascii(1, 4) === 'PNG') return true;
  if (b[0] === 0xff && b[1] === 0xd8) return true;
  if (ascii(0, 4) === 'RIFF' && ascii(8, 12) === 'WEBP') return true;
  if (ascii(4, 8) === 'ftyp' && /avi[fs]/.test(ascii(8, 12))) return true;
  return false;
}
