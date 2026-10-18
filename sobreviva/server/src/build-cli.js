#!/usr/bin/env node
// Uso: node src/build-cli.js [--strict] [--no-app]
//  --strict  exclui artigos com revisão técnica obrigatória pendente (usar em releases de loja)
//  --no-app  não atualiza o pacote embarcado no aplicativo
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ContentStore } from './content-store.js';
import { build } from './builder.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..', '..');
const args = new Set(process.argv.slice(2));

const result = build(new ContentStore(path.join(root, 'content')), {
  outDir: path.join(root, 'server', 'dist', 'updates'),
  appDir: args.has('--no-app') ? undefined : path.join(root, 'app'),
  strict: args.has('--strict'),
});

const { report } = result;
report.warnings.forEach((w) => console.warn(`aviso: ${w}`));
report.excluded.forEach((w) => console.warn(`excluído: ${w}`));
report.errors.forEach((e) => console.error(`ERRO: ${e}`));
if (!result.ok) {
  console.error('Construção interrompida: corrija os erros acima.');
  process.exit(1);
}
for (const p of result.manifest.packages) {
  console.log(`${p.id.padEnd(22)} v${p.version}  ${String(p.article_count).padStart(3)} artigos  ${String(p.media_count).padStart(3)} imagens  ${(p.size_bytes / 1024).toFixed(1)} KB`);
}
