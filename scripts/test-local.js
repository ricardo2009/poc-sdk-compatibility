#!/usr/bin/env node

/**
 * test-local.js - Testa o sistema localmente simulando eventos
 * 
 * Uso: node scripts/test-local.js
 * 
 * Este script simula o fluxo de eventos para teste local sem precisar
 * do GitHub Actions.
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
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
    gray: '\x1b[90m',
};

// ============================================================
// SIMULADOR DE EVENTOS
// ============================================================

function loadConfig() {
    const configPath = path.join(process.cwd(), '.compatibility/config.yml');
    if (!fs.existsSync(configPath)) {
        throw new Error('config.yml não encontrado');
    }
    return fs.readFileSync(configPath, 'utf8');
}

function loadConsumers() {
    const consumersPath = path.join(process.cwd(), '.compatibility/consumers.yml');
    if (!fs.existsSync(consumersPath)) {
        throw new Error('consumers.yml não encontrado');
    }
    return fs.readFileSync(consumersPath, 'utf8');
}

function parseConsumers(content) {
    const consumers = [];
    const blocks = content.split('- id:').slice(1);
    
    for (const block of blocks) {
        const lines = block.split('\n');
        const id = lines[0].trim();
        
        let enabled = true;
        let repository = '';
        let priority = 5;
        
        for (const line of lines) {
            if (line.includes('enabled:')) {
                enabled = line.includes('true');
            }
            if (line.includes('repository:')) {
                repository = line.split(':')[1].trim().replace(/['"]/g, '');
            }
            if (line.includes('priority:')) {
                priority = parseInt(line.split(':')[1].trim()) || 5;
            }
        }
        
        consumers.push({ id, enabled, repository, priority });
    }
    
    return consumers;
}

function simulateSDKRelease(version) {
    console.log(`\n${colors.magenta}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`);
    console.log(`${colors.magenta}  SIMULAÇÃO: SDK Release Event                            ${colors.reset}`);
    console.log(`${colors.magenta}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}\n`);

    const event = {
        event_type: 'sdk.released',
        client_payload: {
            sdk: {
                version: version,
                breaking_changes: false,
                release_url: `https://github.com/example/sdk/releases/v${version}`,
                released_at: new Date().toISOString()
            },
            metadata: {
                source: 'local-test',
                correlation_id: `test-${Date.now()}`
            }
        }
    };

    console.log(`${colors.blue}📦 SDK Version:${colors.reset} ${version}`);
    console.log(`${colors.blue}📅 Released At:${colors.reset} ${event.client_payload.sdk.released_at}`);
    console.log(`${colors.blue}🔗 Correlation:${colors.reset} ${event.client_payload.metadata.correlation_id}`);
    
    console.log(`\n${colors.gray}Event Payload:${colors.reset}`);
    console.log(colors.gray + JSON.stringify(event, null, 2) + colors.reset);
    
    return event;
}

function simulateOrchestrator(event, consumers) {
    console.log(`\n${colors.cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`);
    console.log(`${colors.cyan}  SIMULAÇÃO: Orchestrator Processing                       ${colors.reset}`);
    console.log(`${colors.cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}\n`);

    console.log(`${colors.blue}📋 Consumers registrados:${colors.reset} ${consumers.length}`);
    console.log(`${colors.blue}✅ Consumers habilitados:${colors.reset} ${consumers.filter(c => c.enabled).length}`);
    
    const enabledConsumers = consumers.filter(c => c.enabled).sort((a, b) => a.priority - b.priority);
    
    console.log(`\n${colors.yellow}⚡ Ordem de dispatch (por prioridade):${colors.reset}`);
    for (const consumer of enabledConsumers) {
        console.log(`   ${colors.green}→${colors.reset} [P${consumer.priority}] ${consumer.id} (${consumer.repository})`);
    }
    
    return enabledConsumers;
}

function simulateDispatch(consumers, event) {
    console.log(`\n${colors.green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`);
    console.log(`${colors.green}  SIMULAÇÃO: Dispatch para Consumers                       ${colors.reset}`);
    console.log(`${colors.green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}\n`);

    for (const consumer of consumers) {
        console.log(`${colors.blue}📤 Dispatching to:${colors.reset} ${consumer.repository}`);
        
        const dispatchEvent = {
            event_type: 'sdk.validation.request',
            client_payload: {
                ...event.client_payload,
                consumer: {
                    id: consumer.id,
                    repository: consumer.repository
                }
            }
        };
        
        console.log(`   ${colors.gray}Event: sdk.validation.request${colors.reset}`);
        console.log(`   ${colors.gray}Consumer ID: ${consumer.id}${colors.reset}`);
        console.log(`   ${colors.green}✓ Dispatch simulado com sucesso${colors.reset}\n`);
    }
}

function simulateConsumerValidation(consumers) {
    console.log(`\n${colors.yellow}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`);
    console.log(`${colors.yellow}  SIMULAÇÃO: Consumer Validation                           ${colors.reset}`);
    console.log(`${colors.yellow}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}\n`);

    const results = [];
    
    for (const consumer of consumers) {
        // Simula resultado aleatório (para demo)
        const success = Math.random() > 0.2; // 80% de sucesso
        const duration = Math.floor(Math.random() * 60) + 10;
        
        results.push({
            consumer: consumer.id,
            success,
            duration
        });
        
        const icon = success ? colors.green + '✓' : colors.red + '✗';
        const status = success ? 'PASSED' : 'FAILED';
        
        console.log(`${icon} ${consumer.id}${colors.reset}: ${status} (${duration}s)`);
    }
    
    return results;
}

function printSummary(results) {
    console.log(`\n${colors.magenta}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}`);
    console.log(`${colors.magenta}  RESUMO DA SIMULAÇÃO                                      ${colors.reset}`);
    console.log(`${colors.magenta}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${colors.reset}\n`);

    const passed = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;
    const total = results.length;
    
    console.log(`${colors.blue}📊 Resultados:${colors.reset}`);
    console.log(`   Total:   ${total}`);
    console.log(`   ${colors.green}Passed:${colors.reset}  ${passed}`);
    console.log(`   ${colors.red}Failed:${colors.reset}  ${failed}`);
    
    const successRate = ((passed / total) * 100).toFixed(1);
    const color = successRate >= 80 ? colors.green : successRate >= 50 ? colors.yellow : colors.red;
    console.log(`   ${color}Rate:${colors.reset}    ${successRate}%`);
    
    console.log(`\n${colors.gray}Nota: Esta é uma simulação local. Os resultados reais`);
    console.log(`dependerão da execução no GitHub Actions.${colors.reset}\n`);
}

// ============================================================
// MAIN
// ============================================================

function main() {
    console.log(`\n${colors.cyan}╔════════════════════════════════════════════════════════╗${colors.reset}`);
    console.log(`${colors.cyan}║     SDK COMPATIBILITY SYSTEM - LOCAL TEST              ║${colors.reset}`);
    console.log(`${colors.cyan}╚════════════════════════════════════════════════════════╝${colors.reset}`);

    try {
        // 1. Carregar configurações
        console.log(`\n${colors.blue}📂 Carregando configurações...${colors.reset}`);
        loadConfig();
        console.log(`   ${colors.green}✓${colors.reset} config.yml carregado`);
        
        const consumersContent = loadConsumers();
        console.log(`   ${colors.green}✓${colors.reset} consumers.yml carregado`);
        
        const consumers = parseConsumers(consumersContent);
        console.log(`   ${colors.green}✓${colors.reset} ${consumers.length} consumers parseados`);

        // 2. Simular SDK Release
        const version = process.argv[2] || '1.0.0-test';
        const event = simulateSDKRelease(version);

        // 3. Simular Orchestrator
        const enabledConsumers = simulateOrchestrator(event, consumers);

        // 4. Simular Dispatch
        simulateDispatch(enabledConsumers, event);

        // 5. Simular Validação dos Consumers
        const results = simulateConsumerValidation(enabledConsumers);

        // 6. Resumo
        printSummary(results);

    } catch (error) {
        console.error(`\n${colors.red}❌ Erro: ${error.message}${colors.reset}\n`);
        process.exit(1);
    }
}

main();
