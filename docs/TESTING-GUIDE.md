# 🧪 Guia de Teste E2E - SDK Compatibility System

## 📋 Pré-requisitos

1. **PAT Token**: Criar um Personal Access Token com scope `repo` e `workflow`
2. **Secrets configurados** em `poc-sdk-compatibility`:
   - `PAT_TOKEN`: Token com permissão para disparar workflows em outros repos

## 🚀 Como Testar

### Opção 1: Teste E2E Completo (GitHub Actions)

1. Acesse: https://github.com/ricardo2009/poc-sdk-compatibility/actions
2. Selecione: **🧪 E2E Test - Full Flow**
3. Clique: **Run workflow**
4. Configure:
   - SDK Version: `1.0.0`
   - Change Type: `patch`
   - Dry Run: `false` (para teste real)

### Opção 2: Teste de Performance (GitHub Actions)

1. Acesse: https://github.com/ricardo2009/poc-sdk-compatibility/actions
2. Selecione: **🧪 Performance Test**
3. Clique: **Run workflow**
4. Escolha cenário: `small`, `medium`, `large`, ou `stress`

### Opção 3: Benchmark Suite (GitHub Actions)

1. Acesse: https://github.com/ricardo2009/poc-sdk-compatibility/actions
2. Selecione: **🚀 Benchmark Suite**
3. Clique: **Run workflow**
4. Escolha: `full-suite` para todos os testes

## 🔧 Configurar PAT Token

### Passo 1: Criar o Token

1. Acesse: https://github.com/settings/tokens
2. Clique: **Generate new token (classic)**
3. Nome: `SDK Compatibility POC`
4. Expiration: 30 days (para POC)
5. Scopes:
   - ✅ `repo` (Full control)
   - ✅ `workflow` (Update GitHub Action workflows)
6. Clique: **Generate token**
7. **COPIE O TOKEN** (não será mostrado novamente!)

### Passo 2: Adicionar como Secret

1. Acesse: https://github.com/ricardo2009/poc-sdk-compatibility/settings/secrets/actions
2. Clique: **New repository secret**
3. Nome: `PAT_TOKEN`
4. Valor: Cole o token gerado
5. Clique: **Add secret**

## 📊 Verificar Resultados

Após executar o teste E2E:

1. **Orchestrator**: Ver summary em poc-sdk-compatibility Actions
2. **Mini-app PIX**: https://github.com/ricardo2009/miniapp-pix-poc/actions
3. **Mini-app Pagamentos**: https://github.com/ricardo2009/miniapp-pagamentos-poc/actions

## 🔄 Fluxo Completo

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                          FLUXO E2E TESTE                                      │
└──────────────────────────────────────────────────────────────────────────────┘

  poc-sdk-compatibility                 miniapp-pix-poc
  ┌────────────────────┐               ┌────────────────────┐
  │  e2e-test.yml      │               │ consumer-validate  │
  │                    │  sdk.validate │                    │
  │  1. Load consumers ├──────────────►│ 1. Receive event   │
  │  2. Check rate     │               │ 2. Run tests       │
  │  3. Dispatch       │               │ 3. Report back     │
  └────────────────────┘               └────────────────────┘
           │
           │  sdk.validate             miniapp-pagamentos-poc
           │                           ┌────────────────────┐
           └──────────────────────────►│ consumer-validate  │
                                       │                    │
                                       │ 1. Receive event   │
                                       │ 2. Run tests       │
                                       │ 3. Report back     │
                                       └────────────────────┘
```

## ❓ Troubleshooting

### Erro: "Resource not accessible by integration"
- **Causa**: Falta o PAT_TOKEN ou não tem scope correto
- **Solução**: Criar novo token com scopes `repo` e `workflow`

### Erro: Rate limit exceeded
- **Causa**: Muitas requisições na última hora
- **Solução**: Esperar reset ou usar modo dry_run

### Workflow não dispara nos consumers
- **Causa**: consumer-validate.yml não está no repositório
- **Solução**: Verificar se o arquivo existe em `.github/workflows/`

## 📁 Repositórios POC

| Repo | Papel | URL |
|------|-------|-----|
| poc-sdk-compatibility | Orchestrator | https://github.com/ricardo2009/poc-sdk-compatibility |
| superapp-sdk-poc | SDK Producer | https://github.com/ricardo2009/superapp-sdk-poc |
| miniapp-pix-poc | Consumer | https://github.com/ricardo2009/miniapp-pix-poc |
| miniapp-pagamentos-poc | Consumer | https://github.com/ricardo2009/miniapp-pagamentos-poc |
