#!/usr/bin/env node
// Cria ou atualiza um usuário do painel administrativo.
// Uso: node scripts/create-user.js <usuario> <papel: editor|revisor|admin> ["Nome completo"]
// A senha é lida da variável SOBREVIVA_PASSWORD ou digitada no terminal (não aparece no histórico do shell).
import path from 'node:path';
import readline from 'node:readline';
import { fileURLToPath } from 'node:url';
import { UserStore, ROLES } from '../src/auth.js';

const [username, role, name] = process.argv.slice(2);
if (!username || !ROLES[role]) {
  console.error(`Uso: node scripts/create-user.js <usuario> <${Object.keys(ROLES).join('|')}> ["Nome"]`);
  process.exit(1);
}

async function readPassword() {
  if (process.env.SOBREVIVA_PASSWORD) return process.env.SOBREVIVA_PASSWORD;
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout, terminal: true });
  rl._writeToOutput = () => {};
  process.stdout.write('Senha (mínimo 10 caracteres): ');
  const pw = await new Promise((resolve) => rl.question('', resolve));
  rl.close();
  process.stdout.write('\n');
  return pw;
}

const here = path.dirname(fileURLToPath(import.meta.url));
const dataDir = process.env.DATA_DIR || path.join(here, '..', 'data');
const store = new UserStore(path.join(dataDir, 'users.json'));
try {
  const user = store.upsert({ username, role, name, password: await readPassword() });
  console.log(`Usuário ${user.username} (${user.role}) salvo em ${dataDir}/users.json`);
} catch (e) {
  console.error(`Erro: ${e.message}`);
  process.exit(1);
}
