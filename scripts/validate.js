#!/usr/bin/env node

/**
 * validate.js - Valida configurações do SDK Compatibility System
 * 
 * Uso: node scripts/validate.js
 */

const fs = require('fs');
const path = require('path');

// ============================================================
// CORES
// ============================================================
const colors = {
    reset: '\x1b[0m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    cyan: '\x1b[36m',
};

const icons = {
    success: `${colors.green}✓${colors.reset}`,
    error: `${colors.red}✗${colors.reset}`,
    warning: `${colors.yellow}⚠${colors.reset}`,
    info: `${colors.blue}ℹ${colors.reset}`,
};

// ============================================================
// VALIDADORES
// ============================================================

function fileExists(filePath) {
    return fs.existsSync(filePath);
}

function isValidYaml(content) {
    try {
        // Validação básica de YAML (sem dependência externa)
        // Verifica estrutura básica
        if (content.includes('\t')) {
            return { valid: false, error: 'YAML não deve conter tabs, use espaços' };
        }
        return { valid: true };
    } catch (e) {
        return { valid: false, error: e.message };
    }
}

function validateConfig(filePath) {
    const issues = [];
    
    if (!fileExists(filePath)) {
        issues.push({ type: 'error', message: 'Arquivo não encontrado' });
        return issues;
    }

    const content = fs.readFileSync(filePath, 'utf8');
    
    // Verifica estrutura básica
    const requiredSections = ['metadata:', 'organization:', 'events:', 'automation:'];
    for (const section of requiredSections) {
        if (!content.includes(section)) {
            issues.push({ type: 'error', message: `Seção '${section}' não encontrada` });
        }
    }

    // Verifica variáveis não substituídas
    const placeholderMatch = content.match(/\$\{[^}]+\}/g);
    if (placeholderMatch) {
        const unique = [...new Set(placeholderMatch)];
        issues.push({ 
            type: 'warning', 
            message: `Variables encontradas (execute setup.js): ${unique.join(', ')}` 
        });
    }

    return issues;
}

function validateConsumers(filePath) {
    const issues = [];
    
    if (!fileExists(filePath)) {
        issues.push({ type: 'error', message: 'Arquivo não encontrado' });
        return issues;
    }

    const content = fs.readFileSync(filePath, 'utf8');
    
    // Verifica estrutura básica
    if (!content.includes('consumers:')) {
        issues.push({ type: 'error', message: "Seção 'consumers:' não encontrada" });
    }

    // Verifica se há consumers definidos
    if (!content.includes('- id:')) {
        issues.push({ type: 'warning', message: 'Nenhum consumer definido' });
    }

    // Verifica campos obrigatórios para cada consumer
    const consumerBlocks = content.split('- id:').slice(1);
    consumerBlocks.forEach((block, index) => {
        const idMatch = block.match(/^\s*(\S+)/);
        const id = idMatch ? idMatch[1] : `#${index + 1}`;
        
        if (!block.includes('repository:')) {
            issues.push({ type: 'error', message: `Consumer '${id}': falta 'repository:'` });
        }
        if (!block.includes('enabled:')) {
            issues.push({ type: 'warning', message: `Consumer '${id}': falta 'enabled:' (default: false)` });
        }
    });

    return issues;
}

function validateWorkflow(filePath) {
    const issues = [];
    
    if (!fileExists(filePath)) {
        issues.push({ type: 'error', message: 'Arquivo não encontrado' });
        return issues;
    }

    const content = fs.readFileSync(filePath, 'utf8');
    
    // Verifica trigger repository_dispatch
    if (!content.includes('repository_dispatch:')) {
        issues.push({ type: 'warning', message: 'Workflow não usa repository_dispatch' });
    }

    // Verifica uso de secrets
    if (content.includes('${{ secrets.DISPATCH_TOKEN }}')) {
        issues.push({ type: 'info', message: 'Workflow usa DISPATCH_TOKEN (certifique-se de configurar)' });
    }

    return issues;
}

// ============================================================
// MAIN
// ============================================================

function main() {
    console.log(`\n${colors.cyan}╔════════════════════════════════════════════════════════╗${colors.reset}`);
    console.log(`${colors.cyan}║     SDK COMPATIBILITY SYSTEM - VALIDATOR               ║${colors.reset}`);
    console.log(`${colors.cyan}╚════════════════════════════════════════════════════════╝${colors.reset}\n`);

    const baseDir = process.cwd();
    let hasErrors = false;
    let hasWarnings = false;

    // Lista de arquivos para validar
    const files = [
        { path: '.compatibility/config.yml', validator: validateConfig, name: 'Config' },
        { path: '.compatibility/consumers.yml', validator: validateConsumers, name: 'Consumers' },
        { path: '.github/workflows/sdk-release-emit.yml', validator: validateWorkflow, name: 'SDK Emitter' },
        { path: '.github/workflows/orchestrator-receive.yml', validator: validateWorkflow, name: 'Orchestrator' },
    ];

    for (const file of files) {
        const fullPath = path.join(baseDir, file.path);
        console.log(`${colors.blue}▶ Validando ${file.name}${colors.reset} (${file.path})`);
        
        const issues = file.validator(fullPath);
        
        if (issues.length === 0) {
            console.log(`  ${icons.success} Nenhum problema encontrado\n`);
        } else {
            for (const issue of issues) {
                const icon = issue.type === 'error' ? icons.error : 
                            issue.type === 'warning' ? icons.warning : icons.info;
                console.log(`  ${icon} ${issue.message}`);
                
                if (issue.type === 'error') hasErrors = true;
                if (issue.type === 'warning') hasWarnings = true;
            }
            console.log('');
        }
    }

    // Resumo
    console.log(`${colors.cyan}═══════════════════════════════════════════════════════════${colors.reset}`);
    
    if (hasErrors) {
        console.log(`\n${icons.error} ${colors.red}Validação falhou - corrija os erros acima${colors.reset}\n`);
        process.exit(1);
    } else if (hasWarnings) {
        console.log(`\n${icons.warning} ${colors.yellow}Validação passou com avisos${colors.reset}\n`);
        process.exit(0);
    } else {
        console.log(`\n${icons.success} ${colors.green}Validação passou - tudo OK!${colors.reset}\n`);
        process.exit(0);
    }
}

main();
