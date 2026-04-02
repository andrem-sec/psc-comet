'use strict';

const readline = require('readline');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const SETTINGS_PATH = path.join(
  process.env.HOME || process.env.USERPROFILE,
  '.claude',
  'settings.json'
);
const ENV_PATH = path.join(__dirname, '.env');
const SERVER_PATH = path.join(__dirname, 'src', 'index.js');

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const ask = (q) => new Promise(resolve => rl.question(q, resolve));

function log(msg) { process.stdout.write(msg + '\n'); }
function ok(msg) { log(`  [ok] ${msg}`); }
function info(msg) { log(`  [..] ${msg}`); }
function warn(msg) { log(`  [!]  ${msg}`); }
function fail(msg) { log(`  [x]  ${msg}`); }

async function checkNode() {
  info('Checking Node.js version...');
  const version = process.versions.node;
  const major = parseInt(version.split('.')[0], 10);
  if (major < 18) {
    fail(`Node.js 18+ required. Found: ${version}`);
    process.exit(1);
  }
  ok(`Node.js ${version}`);
}

async function installDeps() {
  info('Installing dependencies...');
  try {
    execSync('npm install --silent', { cwd: __dirname, stdio: 'inherit' });
    ok('Dependencies installed');
  } catch {
    fail('npm install failed. Is Node.js installed?');
    process.exit(1);
  }
}

async function promptApiKey() {
  log('');
  log('  Obsidian setup requires two community plugins:');
  log('  1. "Local REST API" — open Obsidian > Settings > Community Plugins > search "Local REST API"');
  log('     Enable it, go to its settings, and copy the API key.');
  log('  2. "Omnisearch" — same path, search "Omnisearch"');
  log('     Enable it, go to its settings, and turn on "HTTP Server".');
  log('');

  const existing = loadEnv();
  if (existing.OBSIDIAN_API_KEY) {
    const reuse = await ask(`  API key found in .env. Press Enter to keep it, or paste a new one: `);
    if (!reuse.trim()) return existing.OBSIDIAN_API_KEY;
    return reuse.trim();
  }

  const key = await ask('  Paste your Obsidian REST API key: ');
  if (!key.trim()) {
    fail('API key cannot be empty');
    process.exit(1);
  }
  return key.trim();
}

function loadEnv() {
  if (!fs.existsSync(ENV_PATH)) return {};
  return Object.fromEntries(
    fs.readFileSync(ENV_PATH, 'utf8')
      .split('\n')
      .filter(l => l.includes('='))
      .map(l => l.split('=').map(s => s.trim()))
  );
}

function writeEnv(apiKey) {
  const lines = [
    `OBSIDIAN_API_KEY=${apiKey}`,
    `OBSIDIAN_HOST=127.0.0.1`,
    `OBSIDIAN_PORT=27124`,
    `OMNISEARCH_PORT=51361`
  ];
  fs.writeFileSync(ENV_PATH, lines.join('\n') + '\n');
  ok('.env written');
}

function updateSettings(apiKey) {
  info('Updating ~/.claude/settings.json...');
  let settings = {};
  if (fs.existsSync(SETTINGS_PATH)) {
    settings = JSON.parse(fs.readFileSync(SETTINGS_PATH, 'utf8'));
  }

  settings.mcpServers = settings.mcpServers || {};
  settings.mcpServers['obsidian'] = {
    command: 'node',
    args: [SERVER_PATH],
    env: {
      OBSIDIAN_API_KEY: apiKey,
      OBSIDIAN_HOST: '127.0.0.1',
      OBSIDIAN_PORT: '27124',
      OMNISEARCH_PORT: '51361',
      NODE_TLS_REJECT_UNAUTHORIZED: '0'
    }
  };

  fs.writeFileSync(SETTINGS_PATH, JSON.stringify(settings, null, 2));
  ok('settings.json updated with obsidian MCP server');
}

async function testObsidian(apiKey) {
  info('Testing Obsidian REST API connection...');
  try {
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
    const res = await fetch('https://127.0.0.1:27124/vault/', {
      headers: { Authorization: `Bearer ${apiKey}` }
    });
    if (res.ok) {
      ok('Obsidian REST API reachable');
      return true;
    }
    warn(`Obsidian REST API returned ${res.status} — check your API key`);
    return false;
  } catch {
    warn('Obsidian REST API not reachable — is Obsidian open with the Local REST API plugin enabled?');
    return false;
  }
}

async function testOmnisearch() {
  info('Testing Omnisearch connection...');
  try {
    const res = await fetch('http://localhost:51361/search?q=test');
    if (res.ok) {
      ok('Omnisearch reachable');
      return true;
    }
    warn(`Omnisearch returned ${res.status}`);
    return false;
  } catch {
    warn('Omnisearch not reachable — is Obsidian open with Omnisearch HTTP server enabled?');
    return false;
  }
}

async function main() {
  log('\n  Obsidian MCP Setup\n');

  await checkNode();
  await installDeps();

  const apiKey = await promptApiKey();
  writeEnv(apiKey);
  updateSettings(apiKey);

  log('');
  const obsidianOk = await testObsidian(apiKey);
  const omnisearchOk = await testOmnisearch();

  log('');
  if (obsidianOk && omnisearchOk) {
    ok('All connections verified. Restart Claude Code to load the MCP server.');
  } else {
    warn('Setup complete, but some connections failed.');
    warn('Open Obsidian, enable the plugins, and re-run: npm run setup');
    warn('Once Obsidian is running, restart Claude Code to load the MCP server.');
  }

  rl.close();
}

main().catch(err => {
  fail(err.message);
  rl.close();
  process.exit(1);
});
