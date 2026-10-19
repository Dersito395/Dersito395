// Construtor de pacotes de conteúdo versionados.
//
// Gera, a partir do repositório editorial:
//  - dist/updates/manifest.json e dist/updates/packages/<id>-v<versão>.json (serviço de atualização)
//  - opcionalmente, o pacote essencial embarcado no app (assets/content/essencial.json + assets/media/)

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { normalizeArticle, validateArticle, validateEmergency, validateScenario, validateDocument, validateLink } from './validate.js';

export const PACKAGE_FORMAT = 1;

const MIME = { svg: 'image/svg+xml', webp: 'image/webp', avif: 'image/avif', png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg', pdf: 'application/pdf' };

function articleMedia(a) {
  return [...new Set([...a.images.map((i) => i.file), ...a.steps.map((s) => s.image).filter(Boolean)])];
}

function selects(pkg, a) {
  const s = pkg.select || {};
  if (s.all) return true;
  if (s.essential && a.essential) return true;
  if (s.categories && s.categories.includes(a.category)) return true;
  if (s.environments && a.environments.some((e) => s.environments.includes(e))) return true;
  if (s.hasImages && a.images.length > 0) return true;
  if (s.ids && s.ids.includes(a.id)) return true;
  return false;
}

/**
 * Carrega, normaliza e valida todo o conteúdo publicado.
 * @returns {{articles, report}}
 */
export function collect(store, { strict = false } = {}) {
  const categories = store.categories();
  const sources = store.sources();
  const sourceIds = new Set(sources.map((s) => s.id));
  const media = new Set(store.mediaFiles());
  const report = { errors: [], warnings: [], excluded: [] };

  const releasedAt = store.release().released_at;
  const published = store
    .publishedArticles()
    .map(normalizeArticle)
    .filter((a) => a.status === 'publicado')
    .map((a) => ({ ...a, updated_at: a.updated_at || releasedAt }));
  const articleIds = new Set(published.map((a) => a.id));
  const articles = [];
  for (const a of published) {
    const { errors, warnings } = validateArticle(a, { categories, sources: sourceIds, media, articleIds });
    errors.forEach((e) => report.errors.push(`${a.id}: ${e}`));
    warnings.forEach((w) => report.warnings.push(`${a.id}: ${w}`));
    if (errors.length) continue;
    if (strict && a.review.technical_required && a.review.technical_status !== 'aprovado') {
      report.excluded.push(`${a.id}: revisão técnica pendente (modo estrito)`);
      continue;
    }
    articles.push(a);
  }
  const emergencies = store.emergencies();
  for (const e of emergencies) {
    validateEmergency(e).forEach((err) => report.errors.push(`emergência ${err}`));
    for (const r of e.related || []) if (!articleIds.has(r)) report.warnings.push(`emergência ${e.id}: artigo relacionado inexistente ${r}`);
    for (const s of e.sources || []) if (!sourceIds.has(s)) report.errors.push(`emergência ${e.id}: fonte desconhecida ${s}`);
  }
  const scenarios = store.scenarios();
  for (const sc of scenarios) {
    validateScenario(sc).forEach((err) => report.errors.push(err));
    for (const r of sc.related || []) if (!articleIds.has(r)) report.warnings.push(`cenário ${sc.id}: artigo relacionado inexistente ${r}`);
    for (const s of sc.sources || []) if (!sourceIds.has(s)) report.errors.push(`cenário ${sc.id}: fonte desconhecida ${s}`);
  }
  const documents = store.documents();
  for (const d of documents) {
    validateDocument(d, { media, sources: sourceIds }).forEach((err) => report.errors.push(err));
    for (const r of d.related || []) if (!articleIds.has(r)) report.warnings.push(`documento ${d.id}: artigo relacionado inexistente ${r}`);
  }
  const links = store.links();
  links.forEach((l) => validateLink(l).forEach((err) => report.errors.push(err)));
  return { articles, categories, sources, emergencies, scenarios, documents, links, report };
}

function packagePayload(store, pkg, data, { version, releasedAt, embedMedia }) {
  const articles = data.articles.filter((a) => selects(pkg, a));
  const usedSources = new Set();
  articles.forEach((a) => a.sources.forEach((s) => usedSources.add(s.ref)));
  data.emergencies.forEach((e) => (e.sources || []).forEach((s) => usedSources.add(s)));
  data.scenarios.forEach((sc) => (sc.sources || []).forEach((s) => usedSources.add(s)));
  // Documentos de consulta (PDFs) são grandes: só entram nos pacotes marcados com "documents": true.
  const documents = pkg.documents ? data.documents : [];
  documents.forEach((d) => usedSources.add(d.source));
  const mediaMeta = store.mediaMeta();
  const mediaFiles = [...new Set([...articles.flatMap(articleMedia), ...documents.map((d) => d.file)])].sort();
  const media = mediaFiles.map((file) => {
    const buf = fs.readFileSync(store.mediaPath(file));
    const entry = {
      file,
      mime: MIME[file.split('.').pop()],
      sha256: crypto.createHash('sha256').update(buf).digest('hex'),
      size: buf.length,
      credit: mediaMeta[file]?.credit || null,
      license: mediaMeta[file]?.license || null,
    };
    if (embedMedia) entry.data = buf.toString('base64');
    return entry;
  });
  return {
    format: PACKAGE_FORMAT,
    package: { id: pkg.id, title: pkg.title, description: pkg.description, version, released_at: releasedAt, bundled: !!pkg.bundled },
    categories: data.categories,
    sources: data.sources.filter((s) => usedSources.has(s.id)),
    synonyms: store.synonyms(),
    numbers: store.numbers(),
    emergencies: data.emergencies,
    scenarios: data.scenarios,
    ...(pkg.documents ? { documents } : {}), // ausente = o pacote não altera os documentos instalados
    links: data.links,
    articles,
    media,
  };
}

/**
 * Executa a construção completa.
 * @param {ContentStore} store
 * @param {{outDir: string, appDir?: string, strict?: boolean, baseUrl?: string}} opts
 */
export function build(store, { outDir, appDir, strict = false } = {}) {
  const data = collect(store, { strict });
  if (data.report.errors.length) {
    return { ok: false, report: data.report };
  }
  const release = store.release();
  const version = release.library_version;
  const releasedAt = release.released_at;
  const pkgDir = path.join(outDir, 'packages');
  fs.mkdirSync(pkgDir, { recursive: true });

  const manifest = { format: PACKAGE_FORMAT, library_version: version, generated_at: new Date().toISOString(), packages: [] };
  const written = [];
  for (const pkg of store.packages()) {
    const payload = packagePayload(store, pkg, data, { version, releasedAt, embedMedia: true });
    const body = Buffer.from(JSON.stringify(payload));
    const file = `${pkg.id}-v${version}.json`;
    fs.writeFileSync(path.join(pkgDir, file), body);
    manifest.packages.push({
      id: pkg.id,
      title: pkg.title,
      description: pkg.description,
      version,
      released_at: releasedAt,
      bundled: !!pkg.bundled,
      url: `packages/${file}`,
      size_bytes: body.length,
      sha256: crypto.createHash('sha256').update(body).digest('hex'),
      article_count: payload.articles.length,
      media_count: payload.media.length,
      format: PACKAGE_FORMAT,
    });
    written.push(file);

    if (pkg.bundled && appDir) {
      const assetPayload = packagePayload(store, pkg, data, { version, releasedAt, embedMedia: false });
      const contentDir = path.join(appDir, 'assets', 'content');
      const mediaDir = path.join(appDir, 'assets', 'media');
      fs.mkdirSync(contentDir, { recursive: true });
      fs.rmSync(mediaDir, { recursive: true, force: true });
      fs.mkdirSync(mediaDir, { recursive: true });
      fs.writeFileSync(path.join(contentDir, `${pkg.id}.json`), JSON.stringify(assetPayload));
      for (const m of assetPayload.media) fs.copyFileSync(store.mediaPath(m.file), path.join(mediaDir, m.file));
    }
  }
  const manifestTmp = path.join(outDir, 'manifest.json.tmp');
  fs.writeFileSync(manifestTmp, JSON.stringify(manifest, null, 2));
  fs.renameSync(manifestTmp, path.join(outDir, 'manifest.json'));
  return { ok: true, report: data.report, manifest, written };
}
