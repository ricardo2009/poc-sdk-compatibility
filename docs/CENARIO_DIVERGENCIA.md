# 🔀 Cenário de Divergência - Demonstração

> Documento para demonstrar a detecção automática de incompatibilidades entre mini-apps

---

## 📊 Estado Atual do Ecossistema

| Componente | Versão SDK | React | React Native | Status |
|------------|------------|-------|--------------|--------|
| **superapp-sdk-poc** | 0.0.2 | 19.1.0 | 0.80.2 | ✅ Atualizado |
| **miniapp-pix-poc** | 0.0.2 | 19.1.0 | 0.80.2 | ✅ Compatível |
| **miniapp-pagamentos-poc** | 0.0.1 | 19.1.0 | 0.80.2 | ⚠️ SDK Desatualizado |

---

## 🎯 Cenário de Divergência Simulado

### Situação Inicial

```
┌─────────────────────────────────────────────────────────────────┐
│                     ECOSSISTEMA ATUAL                           │
└─────────────────────────────────────────────────────────────────┘

  SDK v0.0.2 (atual)
       │
       ├──► miniapp-pix-poc (SDK v0.0.2) ✅ OK
       │
       └──► miniapp-pagamentos-poc (SDK v0.0.1) ⚠️ DESATUALIZADO
```

### Após Release SDK v3.0.0 (Breaking Change)

```
┌─────────────────────────────────────────────────────────────────┐
│                     APÓS SDK v3.0.0                             │
└─────────────────────────────────────────────────────────────────┘

  SDK v3.0.0 (BREAKING CHANGE)
       │
       ├──► miniapp-pix-poc
       │    └── Atualizar de v0.0.2 → v3.0.0 (2 major versions)
       │    └── 🔴 PR com label: breaking-change, urgent
       │    └── 🔴 Issue criada com @maintainers
       │
       └──► miniapp-pagamentos-poc
            └── Atualizar de v0.0.1 → v3.0.0 (3 major versions!)
            └── 🔴 PR com label: breaking-change, urgent
            └── 🔴 Issue criada com @maintainers
            └── ⚠️ MAIOR RISCO: estava 2 versões atrasado!
```

---

## 🔬 Demonstração Passo a Passo

### Passo 1: Verificar Estado Atual

```bash
# Ver versão atual do SDK em cada mini-app
cat miniapp-pix-poc/package.json | grep "superapp-sdk"
cat miniapp-pagamentos-poc/package.json | grep "superapp-sdk"
```

**Resultado esperado:**
- PIX: `"@ricardo2009/superapp-sdk-poc": "github:ricardo2009/superapp-sdk-poc"`
- Pagamentos: `"@ricardo2009/superapp-sdk-poc": "^0.0.1"`

### Passo 2: Simular Release SDK com Breaking Change

```bash
# No repositório superapp-sdk-poc
cd superapp-sdk-poc

# Criar tag de breaking change
git tag v3.0.0
git push origin v3.0.0
```

### Passo 3: Observar Automação

1. **GitHub Actions no SDK**
   - Workflow `sdk-release.yml` é acionado
   - Lê registry de consumers
   - Dispara `repository_dispatch` para ambos mini-apps

2. **GitHub Actions nos Mini-Apps**
   - Workflow `sdk-update-handler.yml` recebe evento
   - Detecta que é breaking change
   - Cria PR com labels adequadas
   - Cria Issue para maintainers

### Passo 4: Verificar Resultados

| Mini-App | PR Criado | Labels | Issue | Assignees |
|----------|-----------|--------|-------|-----------|
| miniapp-pix-poc | ✅ #N | `sdk-update`, `breaking-change`, `urgent` | ✅ #N | @maintainers |
| miniapp-pagamentos-poc | ✅ #N | `sdk-update`, `breaking-change`, `urgent`, `sdk-outdated` | ✅ #N | @maintainers |

---

## 📈 Métricas de Divergência

### Detecção Automática

O sistema detecta automaticamente:

1. **Divergência de Versão SDK**
   - Qual versão cada mini-app está usando
   - Quantas versões está atrasado

2. **Tipo de Atualização Necessária**
   - Patch: automático (se auto_merge_patch: true)
   - Minor: automático (se auto_merge_minor: true)
   - Major: manual obrigatório

3. **Prioridade do Mini-App**
   - Critical: notificação imediata
   - High: notificação em 1h
   - Normal: notificação em 24h

---

## 🔧 Configuração para Divergência

### .sdk-ecosystem.yml (Mini-App PIX - Atualizado)

```yaml
sdk:
  name: "@ricardo2009/superapp-sdk-poc"
  currentVersion: "0.0.2"  # Mais atualizado

maintainers:
  - ricardolima@email.com

updatePolicy:
  autoPR: true
  autoMerge:
    patch: true
    minor: true
    major: false
  testRequirements:
    unit: true
    integration: false
    e2e: false
```

### .sdk-ecosystem.yml (Mini-App Pagamentos - Desatualizado)

```yaml
sdk:
  name: "@ricardo2009/superapp-sdk-poc"
  currentVersion: "0.0.1"  # Uma versão atrasada!

maintainers:
  - ricardolima@email.com

updatePolicy:
  autoPR: true
  autoMerge:
    patch: true
    minor: false  # Mais conservador
    major: false
  testRequirements:
    unit: true
    integration: true  # Mais rigoroso
    e2e: false
```

---

## 🚨 Cenários de Risco Detectados

### 1. Mini-App Muito Desatualizado

```
┌───────────────────────────────────────────────────────────────┐
│ ⚠️ ALERTA: miniapp-pagamentos-poc                            │
│                                                               │
│ Versão atual: 0.0.1                                          │
│ Versão disponível: 3.0.0                                      │
│ Versões atrasadas: 3 (0.0.1 → 0.0.2 → 2.0.0 → 3.0.0)        │
│                                                               │
│ RISCO: ALTO                                                   │
│ - Múltiplas breaking changes acumuladas                       │
│ - Maior esforço de migração                                   │
│ - Possíveis conflitos de dependências                         │
└───────────────────────────────────────────────────────────────┘
```

### 2. Incompatibilidade de Dependências

```
┌───────────────────────────────────────────────────────────────┐
│ ⚠️ ALERTA: Dependências Incompatíveis                        │
│                                                               │
│ SDK requer:     react-native >= 0.80.0                        │
│ Mini-app usa:   react-native 0.76.7                           │
│                                                               │
│ AÇÃO: Atualizar react-native primeiro!                        │
└───────────────────────────────────────────────────────────────┘
```

---

## ✅ Resolução da Divergência

### Fluxo Automático

1. **PR Criado Automaticamente**
   - Branch: `sdk-update/v3.0.0`
   - Atualiza `package.json`
   - Executa testes

2. **Issue para Acompanhamento**
   - Assignees: maintainers
   - Labels: `breaking-change`, `urgent`
   - Corpo com detalhes da atualização

3. **Merge Manual Obrigatório**
   - Revisar changelog do SDK
   - Verificar breaking changes
   - Atualizar código se necessário
   - Aprovar e fazer merge

---

## 📋 Checklist de Demonstração

- [ ] Mostrar estado inicial com divergência
- [ ] Criar release do SDK (tag v3.0.0)
- [ ] Observar dispatch para mini-apps
- [ ] Verificar PRs criados
- [ ] Verificar Issues criadas
- [ ] Mostrar labels diferentes para cada cenário
- [ ] Explicar fluxo de resolução

---

## 🔗 Links Úteis

- [SDK Repository](https://github.com/ricardo2009/superapp-sdk-poc)
- [Mini-App PIX](https://github.com/ricardo2009/miniapp-pix-poc)
- [Mini-App Pagamentos](https://github.com/ricardo2009/miniapp-pagamentos-poc)
- [Ecosystem Registry](https://github.com/ricardo2009/poc-sdk-compatibility)
