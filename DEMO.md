# 🎬 Demo: SDK Compatibility System

> Roteiro de demonstração para o cliente

## ⏱️ Duração Total: ~20 minutos

---

## 📋 Agenda

1. **Contexto e Problema** (3 min)
2. **Arquitetura da Solução** (5 min)
3. **Demo ao Vivo** (8 min)
4. **Discussão e Q&A** (4 min)

---

## 🎯 1. Contexto e Problema (3 min)

### Slide: O Desafio

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   "Como garantir que 20+ mini-apps permaneçam compatíveis      │
│    quando o SDK central é atualizado?"                          │
│                                                                 │
│   Problemas atuais:                                             │
│   ❌ Processo manual e propenso a erros                         │
│   ❌ Descoberta tardia de incompatibilidades                    │
│   ❌ Times diferentes, tempos diferentes                        │
│   ❌ Sem visibilidade centralizada                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Falar:

> "Hoje, quando liberamos uma nova versão do SDK, cada time de mini-app 
> precisa manualmente verificar compatibilidade, atualizar dependências e 
> criar PRs. Com 20+ mini-apps, isso consome tempo e gera inconsistências."

---

## 🏗️ 2. Arquitetura da Solução (5 min)

### Slide: Event-Driven Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   SDK Release  ──►  Orchestrator  ──►  Mini-Apps               │
│       │                  │                 │                    │
│       │                  │                 │                    │
│   "Publiquei            "Vou avisar       "Recebemos,          │
│    versão 1.2.0"         todos"            validando..."        │
│                          │                 │                    │
│                          ▼                 ▼                    │
│                     ┌────────┐        ┌────────┐               │
│                     │Registry│        │   PR   │               │
│                     └────────┘        │ criado │               │
│                                       └────────┘               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Princípios-chave:

| Princípio | Benefício |
|-----------|-----------|
| **Zero-Coupling** | SDK não conhece mini-apps |
| **Config as Code** | Tudo versionado, auditável |
| **Policy as Code** | Regras de automação declarativas |
| **Event-Driven** | Desacoplamento total |

---

## 🖥️ 3. Demo ao Vivo (8 min)

### Passo 1: Mostrar Estrutura (1 min)

```bash
# Mostrar estrutura do repositório
ls -la poc-sdk-compatibility/

# Mostrar configuração de consumers
cat .compatibility/consumers.yml
```

**Destacar:**
- Registry centralizado
- Configuração declarativa
- Zero hardcoding

---

### Passo 2: Mostrar Workflows (2 min)

Abrir no GitHub:
1. `.github/workflows/sdk-release-emit.yml`
2. `.github/workflows/orchestrator-receive.yml`

**Destacar:**
- Uso de `repository_dispatch`
- Comunicação via eventos
- Não há dependência direta

---

### Passo 3: Executar Fluxo (3 min)

1. **Ir para Actions**
   ```
   https://github.com/ricardo2009/poc-sdk-compatibility/actions
   ```

2. **Selecionar "📤 SDK Release - Emit Event"**

3. **Click "Run workflow"**
   - Version: `1.0.0`
   - Breaking changes: `false`

4. **Observar execução**
   - Mostrar logs do SDK Emitter
   - Mostrar evento sendo despachado

5. **Ir para repositórios dos consumers**
   - Mostrar workflow sendo disparado automaticamente
   - Mostrar testes executando
   - Mostrar PR sendo criado

---

### Passo 4: Mostrar PR Criado (2 min)

Abrir o PR automático no consumer:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   ⬆️ SDK Update: 1.0.0                                         │
│                                                                 │
│   ## 🔄 SDK Compatibility Update                                │
│                                                                 │
│   This PR was automatically created by the SDK Compatibility   │
│   System.                                                       │
│                                                                 │
│   ### ✅ Validation Results                                     │
│   - [x] Dependencies installed                                  │
│   - [x] All tests passed                                        │
│   - [x] No breaking changes                                     │
│                                                                 │
│   Labels: [sdk-update] [automated]                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Destacar:**
- PR automático com descrição completa
- Labels para rastreabilidade
- Checklist de validação

---

## 💬 4. Discussão e Q&A (4 min)

### Perguntas Esperadas

#### Q: "Como adicionar um novo mini-app?"

```yaml
# Apenas editar consumers.yml
consumers:
  - name: "novo-miniapp"
    repository: "org/novo-miniapp"
    priority: "high"
    enabled: true
```

#### Q: "E se um mini-app falhar?"

> "O sistema continua validando os outros. Cada consumer é independente.
> O orchestrator agrega todos os resultados ao final."

#### Q: "Funciona com Azure DevOps?"

> "Esta POC usa GitHub Actions, mas o conceito é portável.
> Azure DevOps suporta Service Hooks que podem disparar pipelines
> de forma similar."

#### Q: "Posso customizar as regras?"

```yaml
# config.yml - Policy as Code
automation:
  rules:
    - name: "Custom rule"
      condition:
        version_type: "major"
      action:
        require_review: true
        reviewers: ["@tech-leads"]
```

---

## 📊 Resumo Executivo

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   ANTES                          DEPOIS                        │
│   ──────                         ──────                        │
│   ❌ Manual                      ✅ Automatizado               │
│   ❌ Lento (dias)                ✅ Rápido (minutos)           │
│   ❌ Propenso a erros            ✅ Consistente                │
│   ❌ Sem visibilidade            ✅ Tracking centralizado      │
│   ❌ Hardcoded                   ✅ Configuration as Code      │
│                                                                 │
│   ROI Esperado:                                                 │
│   • 90% redução em tempo de propagação de updates              │
│   • 100% de cobertura de validação                              │
│   • 0 updates manuais necessários                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔗 Links Úteis

- [📐 Arquitetura Completa](ARCHITECTURE.md)
- [📚 Quick Start](docs/quick-start.md)
- [📖 Documentação](README.md)

---

## ✅ Checklist Pré-Demo

- [ ] Repositório criado e acessível
- [ ] Secret `DISPATCH_TOKEN` configurado
- [ ] Consumers configurados em `consumers.yml`
- [ ] Workflows validados (sem erros de sintaxe)
- [ ] Testar execução uma vez antes do demo
- [ ] Ter backup de screenshots caso GitHub esteja lento

---

**Boa demo! 🚀**
