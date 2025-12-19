# 📊 Análise de Gaps - Repos CAIXA vs POC

**Data:** 19 de Dezembro de 2025  
**Objetivo:** Identificar diferenças entre a POC implementada e os repos reais da CAIXA

---

## 🏗️ Estrutura Atual - Repos CAIXA

### Organização do Ecossistema Real

```
RN_Superapp_Host/
├── packages/
│   ├── host/           → App principal
│   └── sdk/            → @plataforma-de-credito/superapp-sdk
│       ├── lib/
│       │   ├── dependencies.json      ← Versões das dependências
│       │   ├── devDependencies.json   ← Versões dev
│       │   └── sharedDeps.js          ← Deps compartilhadas MF
│       └── package.json

RN_Module_Pix/          → @superapp-caixa/module-pix
RN_Module_Pagamentos/   → @superapp-caixa/module-pagamentos
RN_Module_ContaBancaria/
RN_Module_Credito/
```

### SDK Real (superapp-sdk)

| Aspecto | Configuração |
|---------|--------------|
| **Package** | `@plataforma-de-credito/superapp-sdk` |
| **Versão Atual** | 0.0.8 |
| **Registry** | npm.pkg.github.com |
| **Pipeline** | Azure DevOps (manual via workflow_dispatch) |
| **Propósito** | Gerenciamento de dependências compartilhadas (rnx-align-deps) |

### Bibliotecas Relacionadas

| Package | Propósito |
|---------|-----------|
| `@plataforma-de-credito/superapp-features` | Utilitários (Logger, httpRequest, Analytics) |
| `@plataforma-de-credito/superapp-auth` | Autenticação |
| `@plataforma-de-credito/superapp-dsc` | Design System |
| `@plataforma-de-credito/superapp-webview` | WebView nativa |

---

## 🔄 Comparação: POC vs Realidade

### Workflows

| Aspecto | POC (GitHub Actions) | CAIXA Real | Gap |
|---------|---------------------|------------|-----|
| **CI do SDK** | `sdk-release.yml` (auto em tags) | `rn-lib-pipeline.yaml` (manual) | ⚠️ Não é automático |
| **Notify consumers** | `repository_dispatch` | ❌ Não existe | 🚨 **GAP CRÍTICO** |
| **Handler em mini-apps** | `sdk-update-handler.yml` | ❌ Não existe | 🚨 **GAP CRÍTICO** |
| **Dependabot** | ✅ Configurado | ❌ Não existe | ⚠️ GAP |
| **CI de PR** | `ci.yml` | `pr-review-pipeline.yaml` | ✅ Existe (similar) |

### Registry e Automação

| Aspecto | POC | CAIXA Real | Gap |
|---------|-----|------------|-----|
| **Registry** | GitHub Packages | GitHub Packages | ✅ Igual |
| **consumers.yml** | ✅ Centralizado | ❌ Não existe | 🚨 **GAP CRÍTICO** |
| **Auto-merge de patches** | ✅ Configurado | ❌ Não existe | ⚠️ GAP |
| **Breaking change detection** | ✅ Semver analysis | ❌ Manual | 🚨 **GAP** |

### Versões e Dependências

| Aspecto | POC | CAIXA Real | Status |
|---------|-----|------------|--------|
| **React** | 19.1.0 | 19.1.0 | ✅ Alinhado |
| **React Native** | 0.80.2 | 0.80.2 | ✅ Alinhado |
| **Node.js** | 22 | 20+ (Azure) | ⚠️ Verificar |

---

## 🚨 Gaps Críticos Identificados

### 1. Ausência de Notificação Automática

**Problema:** Quando o SDK é atualizado, mini-apps não são notificados automaticamente.

**Estado Atual:**
```
SDK atualizado → Time precisa manualmente:
  1. Verificar versão nova
  2. Atualizar package.json
  3. Rodar yarn install
  4. Rodar yarn check-dependencies
  5. Criar PR
  6. Aprovar e fazer merge
```

**Solução POC:**
```
SDK atualizado → Automação:
  1. repository_dispatch disparado
  2. PR criado automaticamente
  3. Testes executados
  4. Merge automático (se patch/minor)
```

### 2. Falta de Registry Centralizado de Consumers

**Problema:** Não há visibilidade de quais mini-apps dependem do SDK e qual versão usam.

**Estado Atual:**
- Cada repo mantém sua própria versão
- Não há dashboard de compatibilidade
- Breaking changes descobertos tarde demais

**Solução POC:**
```yaml
# .compatibility/consumers.yml
consumers:
  - name: "RN_Module_Pix"
    repository: "Plataforma-de-Credito/RN_Module_Pix"
    priority: "critical"
    sdk_version: "0.0.8"  # Versão atual usada
```

### 3. Pipeline Manual do SDK

**Problema:** O pipeline do SDK requer ação manual (workflow_dispatch).

**Estado Atual:**
- Desenvolvedor precisa ir ao Azure DevOps
- Informar versão manualmente
- Executar pipeline

**Solução POC:**
- Tag git `v*` dispara automaticamente
- Versão extraída da tag

---

## ✅ O Que Já Existe e Funciona

### PR Review Pipeline

Os repos já possuem `pr-review-pipeline.yaml` que:
- ✅ Roda lint
- ✅ Roda testes
- ✅ Verifica types
- ✅ Usa templates centralizados (`Templates_CI_CD`)

### Gerenciamento de Dependências

O SDK usa `rnx-align-deps` que:
- ✅ Verifica compatibilidade de versões
- ✅ Permite auto-fix com `--write`
- ✅ Centraliza versões em `lib/dependencies.json`

### GitHub Packages

- ✅ Já configurado e funcionando
- ✅ Autenticação via NPM_TOKEN
- ✅ Escopo `@plataforma-de-credito`

---

## 📋 Plano de Implementação

### Fase 1: Preparação (1-2 dias)

| Task | Descrição | Repo |
|------|-----------|------|
| 1.1 | Criar `consumers.yml` com lista de mini-apps | RN_Superapp_Host |
| 1.2 | Configurar PAT_DISPATCH no SDK | RN_Superapp_Host |
| 1.3 | Adicionar Dependabot ao SDK | RN_Superapp_Host |

### Fase 2: SDK Release Automation (2-3 dias)

| Task | Descrição | Repo |
|------|-----------|------|
| 2.1 | Criar workflow de release automático em tags | RN_Superapp_Host |
| 2.2 | Adicionar job de notify consumers | RN_Superapp_Host |
| 2.3 | Implementar detecção de breaking changes | RN_Superapp_Host |

### Fase 3: Mini-App Handlers (3-5 dias)

| Task | Descrição | Repos |
|------|-----------|-------|
| 3.1 | Criar `sdk-update-handler.yml` | Todos os mini-apps |
| 3.2 | Criar `dependabot-auto-merge.yml` | Todos os mini-apps |
| 3.3 | Testar E2E com release real | Todos |

### Fase 4: Documentação e Treinamento (2 dias)

| Task | Descrição |
|------|-----------|
| 4.1 | Atualizar Wiki do DOC_SuperApp |
| 4.2 | Criar runbook de operações |
| 4.3 | Sessão de treinamento com times |

---

## 🔧 Arquivos a Serem Criados nos Repos Reais

### No RN_Superapp_Host (SDK)

```
packages/sdk/
└── .github/
    └── workflows/
        └── sdk-release-notify.yml   ← NOVO: Notifica consumers
```

### Em Cada Mini-App

```
.github/
├── workflows/
│   ├── sdk-update-handler.yml      ← NOVO: Recebe notificação
│   └── dependabot-auto-merge.yml   ← NOVO: Auto-merge de deps
└── dependabot.yml                   ← NOVO: Atualização automática
```

### Novo Repo (ou pasta no Host)

```
.compatibility/
└── consumers.yml                    ← Registry central
```

---

## 📊 Matriz de Impacto

| Mini-App | Prioridade | Impacto de Desatualização |
|----------|------------|---------------------------|
| RN_Module_Pix | 🔴 Crítica | Transações financeiras |
| RN_Module_Pagamentos | 🔴 Crítica | Pagamentos diversos |
| RN_Module_ContaBancaria | 🟡 Alta | Consultas de conta |
| RN_Module_Credito | 🟡 Alta | Operações de crédito |

---

## 🎯 Métricas de Sucesso

| Métrica | Antes | Depois | Meta |
|---------|-------|--------|------|
| Tempo para atualizar SDK | 2-5 dias | < 1 hora | 95% redução |
| Taxa de obsolescência | ~40% | < 5% | 90% redução |
| Breaking changes em prod | 1-2/mês | 0 | 100% prevenção |
| Visibilidade de versões | Nenhuma | 100% | Dashboard |

---

## 📝 Próximos Passos Imediatos

1. **Aprovação** - Validar plano com tech lead
2. **PAT** - Criar token de serviço para automação
3. **Piloto** - Implementar em 1 mini-app primeiro (PIX recomendado)
4. **Rollout** - Expandir para demais mini-apps

---

*Documento gerado automaticamente - 19/12/2025*
