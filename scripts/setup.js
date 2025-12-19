#!/usr/bin/env node
/**
 * ═══════════════════════════════════════════════════════════════════════════════
 * 🔧 SDK COMPATIBILITY SYSTEM - SETUP SCRIPT
 * ═══════════════════════════════════════════════════════════════════════════════
 * 
 * Configura o sistema para uma organização específica.
 * 
 * Uso:
 *   node scripts/setup.js <github-org>
 *   node scripts/setup.js ricardo2009
 *   node scripts/setup.js --verify
 * 
 * ═══════════════════════════════════════════════════════════════════════════════
 */

const fs = require('fs');
const path = require('path');

// ═══════════════════════════════════════════════════════════════════════════════
// CONFIGURAÇÃO
// ═══════════════════════════════════════════════════════════════════════════════

const ROOT = path.join(__dirname, '..');

const FILES_TO_UPDATE = [
  '.compatibility/config.yml',
  '.compatibility/consumers.yml',
];

const REQUIRED_FILES = [
  '.github/workflows/sdk-release-emit.yml',
  '.github/workflows/orchestrator-receive.yml',
  '.compatibility/config.yml',
  '.compatibility/consumers.yml',
  'examples/consumer-workflow/consumer-validate.yml',
  'README.md',
  'ARCHITECTURE.md',
  'DEMO.md',
];

// ═══════════════════════════════════════════════════════════════════════════════
// UTILITÁRIOS
// ═══════════════════════════════════════════════════════════════════════════════

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function banner() {
  console.log(`
${colors.cyan}╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   🔧 SDK COMPATIBILITY SYSTEM - SETUP                                       ║
║                                                                              ║
║   Event-Driven │ Zero-Coupling │ Configuration-as-Code                      ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝${colors.reset}
`);
}

// ═══════════════════════════════════════════════════════════════════════════════
// FUNÇÕES PRINCIPAIS
// ═══════════════════════════════════════════════════════════════════════════════

function verifyStructure() {
  log('\n📁 Verificando estrutura...', 'blue');
  
  let allPresent = true;
  
  for (const file of REQUIRED_FILES) {
    const fullPath = path.join(ROOT, file);
    const exists = fs.existsSync(fullPath);
    
    if (exists) {
      log(`  ✅ ${file}`, 'green');
    } else {
      log(`  ❌ ${file} (FALTANDO)`, 'red');
      allPresent = false;
    }
  }
  
  return allPresent;
}

function updateFile(filePath, org) {
  const fullPath = path.join(ROOT, filePath);
  
  if (!fs.existsSync(fullPath)) {
    log(`  ⚠️  Não encontrado: ${filePath}`, 'yellow');
    return false;
  }
  
  let content = fs.readFileSync(fullPath, 'utf8');
  const original = content;
  
  // Substituições
  content = content.replace(/\$\{GITHUB_ORG:-[^}]+\}/g, `\${GITHUB_ORG:-${org}}`);
  content = content.replace(/\$\{GITHUB_ORG\}/g, `\${GITHUB_ORG:-${org}}`);
  content = content.replace(/your-organization/g, org);
  
  if (content !== original) {
    fs.writeFileSync(fullPath, content, 'utf8');
    log(`  ✅ Atualizado: ${filePath}`, 'green');
    return true;
  }
  
  log(`  ℹ️  Sem alterações: ${filePath}`, 'blue');
  return true;
}

function printInstructions(org) {
  console.log(`
${colors.cyan}═══════════════════════════════════════════════════════════════════════════════
📋 PRÓXIMOS PASSOS
═══════════════════════════════════════════════════════════════════════════════${colors.reset}

${colors.yellow}1️⃣  CRIAR TOKEN DE ACESSO (PAT)${colors.reset}
    
    Vá para: ${colors.blue}https://github.com/settings/tokens/new${colors.reset}
    
    Scopes necessários:
    ${colors.green}✓${colors.reset} repo (Full control)
    ${colors.green}✓${colors.reset} workflow (Update GitHub Actions)

${colors.yellow}2️⃣  CONFIGURAR SECRET NO REPOSITÓRIO${colors.reset}
    
    Vá para: ${colors.blue}https://github.com/${org}/poc-sdk-compatibility/settings/secrets/actions${colors.reset}
    
    Adicione:
    • Nome: ${colors.cyan}DISPATCH_TOKEN${colors.reset}
    • Valor: <seu-token-gerado>

${colors.yellow}3️⃣  PUSH DOS ARQUIVOS${colors.reset}
    
    ${colors.blue}cd poc-sdk-compatibility
    git add .
    git commit -m "feat: initial commit - SDK Compatibility System"
    git push origin main${colors.reset}

${colors.yellow}4️⃣  TESTAR O FLUXO${colors.reset}
    
    1. Vá para: ${colors.blue}https://github.com/${org}/poc-sdk-compatibility/actions${colors.reset}
    2. Selecione "📤 SDK Release - Emit Event"
    3. Click "Run workflow"
    4. Preencha:
       • Version: 1.0.0
       • Breaking changes: false
    5. Observe os logs!

${colors.cyan}═══════════════════════════════════════════════════════════════════════════════${colors.reset}
`);
}

function printSummary(org) {
  console.log(`
${colors.green}╔══════════════════════════════════════════════════════════════════════════════╗
║                          ✅ SETUP COMPLETO!                                  ║
╚══════════════════════════════════════════════════════════════════════════════╝${colors.reset}

${colors.cyan}📊 RESUMO:${colors.reset}

   Organização:  ${colors.yellow}${org}${colors.reset}
   Repositório:  ${colors.blue}${org}/poc-sdk-compatibility${colors.reset}

${colors.cyan}📁 ESTRUTURA:${colors.reset}

   .github/workflows/
   ├── sdk-release-emit.yml      ${colors.green}← Emite eventos${colors.reset}
   └── orchestrator-receive.yml  ${colors.green}← Orquestra consumers${colors.reset}
   
   .compatibility/
   ├── config.yml                ${colors.green}← Configuração master${colors.reset}
   └── consumers.yml             ${colors.green}← Registry de consumers${colors.reset}
   
   examples/
   └── consumer-workflow/
       └── consumer-validate.yml ${colors.green}← Template para consumers${colors.reset}

${colors.cyan}📖 DOCUMENTAÇÃO:${colors.reset}

   • README.md        → Overview
   • ARCHITECTURE.md  → Diagrama técnico
   • DEMO.md          → Roteiro de demo

`);
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════════

function main() {
  banner();
  
  const args = process.argv.slice(2);
  
  if (args.includes('--help') || args.length === 0) {
    console.log(`
${colors.yellow}Uso:${colors.reset}
  node scripts/setup.js <github-org>

${colors.yellow}Exemplos:${colors.reset}
  node scripts/setup.js ricardo2009
  node scripts/setup.js my-organization

${colors.yellow}Opções:${colors.reset}
  --help    Mostra esta ajuda
  --verify  Apenas verifica estrutura
`);
    process.exit(0);
  }
  
  const verifyOnly = args.includes('--verify');
  const org = args.find(arg => !arg.startsWith('--'));
  
  // Verifica estrutura
  if (!verifyStructure()) {
    log('\n❌ Alguns arquivos estão faltando!', 'red');
    process.exit(1);
  }
  
  if (verifyOnly) {
    log('\n✅ Verificação completa!', 'green');
    process.exit(0);
  }
  
  if (!org) {
    log('\n❌ Organização não especificada', 'red');
    process.exit(1);
  }
  
  log(`\n🎯 Configurando para: ${org}`, 'cyan');
  
  // Atualiza arquivos
  log('\n📝 Atualizando configurações...', 'blue');
  
  for (const file of FILES_TO_UPDATE) {
    updateFile(file, org);
  }
  
  // Instruções
  printInstructions(org);
  
  // Resumo
  printSummary(org);
}

main();
