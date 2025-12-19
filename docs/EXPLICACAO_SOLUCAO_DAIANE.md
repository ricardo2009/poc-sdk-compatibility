# 🚀 Automação de Compatibilidade SDK - SuperApp CAIXA

**Para:** Daiane  
**De:** Ricardo Lima  
**Data:** 19 de Dezembro de 2025  
**Assunto:** Explicação da Solução de Automação de Dependências SDK

---

## 📋 Sumário Executivo

Desenvolvemos uma **solução automatizada** para gerenciar as dependências do SDK nos mini-apps do SuperApp CAIXA. O objetivo é **evitar obsolescência, prevenir builds desnecessários e garantir compatibilidade** entre todos os módulos.

---

## 🎯 O Problema que Resolvemos

### Cenário Atual (Sem Automação)

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SUPERAPP HOST                               │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  SDK v1.0.0 (react: 19.1.0, react-native: 0.80.2)            │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                              ▼                                      │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐   │
│  │ Mini-App   │  │ Mini-App   │  │ Mini-App   │  │ Mini-App   │   │
│  │ PIX        │  │ Pagamentos │  │ Crédito    │  │ Conta      │   │
│  │ SDK v1.0.0 │  │ SDK v0.9.0 │  │ SDK v1.0.0 │  │ SDK v0.8.0 │   │
│  │ ✅ OK      │  │ ❌ ANTIGO  │  │ ✅ OK      │  │ ❌ ANTIGO  │   │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### Problemas Identificados

| Problema | Descrição | Impacto |
|----------|-----------|---------|
| **Obsolescência** | Mini-apps com SDK desatualizado | Incompatibilidade em runtime, crashes |
| **Divergência de Versões** | Cada time atualiza quando quer | Versões diferentes do React coexistindo |
| **Breaking Changes Não Comunicados** | SDK muda API sem aviso | Mini-apps quebram em produção |
| **Builds Desnecessários** | Atualizar todos sempre | Custo de CI/CD, tempo de desenvolvimento perdido |
| **Falta de Visibilidade** | Não saber quem está atualizado | Dificuldade de governança |

---

## ✅ A Solução Implementada

### Arquitetura da Automação

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FLUXO AUTOMATIZADO                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1️⃣ SDK Release (tag v1.2.0)                                       │
│         │                                                           │
│         ▼                                                           │
│  2️⃣ GitHub Actions Workflow                                        │
│         │                                                           │
│         ├── Build & Test SDK                                        │
│         ├── Publish to GitHub Packages                              │
│         ├── Analisa tipo de mudança (patch/minor/major)             │
│         │                                                           │
│         ▼                                                           │
│  3️⃣ Carrega Registry de Consumers                                  │
│         │ (poc-sdk-compatibility/.compatibility/consumers.yml)      │
│         │                                                           │
│         ▼                                                           │
│  4️⃣ Dispara repository_dispatch para cada mini-app                 │
│         │                                                           │
│         ├──────────────────┬──────────────────┐                     │
│         ▼                  ▼                  ▼                     │
│  ┌────────────┐     ┌────────────┐     ┌────────────┐              │
│  │ PIX        │     │ Pagamentos │     │ Crédito    │              │
│  │ Recebe     │     │ Recebe     │     │ Recebe     │              │
│  │ Webhook    │     │ Webhook    │     │ Webhook    │              │
│  └─────┬──────┘     └─────┬──────┘     └─────┬──────┘              │
│        │                  │                  │                      │
│        ▼                  ▼                  ▼                      │
│  5️⃣ Cada mini-app:                                                 │
│     • Cria branch sdk-update/vX.X.X                                │
│     • Atualiza package.json                                        │
│     • Roda testes de compatibilidade                               │
│     • Abre PR automaticamente                                      │
│     • Se breaking change → Cria Issue também                       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Componentes da Solução

#### 1. **Registry Central de Consumers**
```yaml
# Arquivo: poc-sdk-compatibility/.compatibility/consumers.yml
consumers:
  - name: "miniapp-pix-poc"
    repository: "ricardo2009/miniapp-pix-poc"
    priority: "critical"
    config:
      auto_merge_patch: true   # Patches = merge automático
      auto_merge_minor: true   # Minor = merge automático
      auto_merge_major: false  # Major = revisão humana obrigatória
```

#### 2. **Workflow de Release do SDK**
```yaml
# superapp-sdk-poc/.github/workflows/sdk-release.yml
# Dispara quando: tag v* é criada
# 
# Jobs:
#   1. validate   → TypeScript check, testes
#   2. publish    → Build e publica no GitHub Packages
#   3. analyze    → Detecta tipo de mudança (breaking ou não)
#   4. notify     → Dispara webhook para cada consumer
#   5. release    → Cria GitHub Release
```

#### 3. **Handler nos Mini-Apps**
```yaml
# miniapp-*/sdk-update-handler.yml
# Recebe: repository_dispatch com event_type: "sdk.update"
#
# Ações:
#   • Cria branch
#   • Atualiza SDK no package.json
#   • Roda testes
#   • Abre PR
#   • Se breaking → Abre Issue
```

---

## 🔄 Tipos de Atualização

| Tipo | Exemplo | Ação Automática | Revisão Humana |
|------|---------|-----------------|----------------|
| **Patch** | 1.0.0 → 1.0.1 | PR + Auto-merge | ❌ Não necessária |
| **Minor** | 1.0.0 → 1.1.0 | PR + Auto-merge | ⚠️ Opcional |
| **Major** | 1.0.0 → 2.0.0 | PR + Issue | ✅ Obrigatória |

### Detecção de Breaking Changes

```
SDK v2.0.0 (Breaking Change)
         │
         ▼
┌─────────────────────────────┐
│ Análise automática detecta  │
│ mudança de major version    │
└─────────────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ Para cada mini-app:         │
│  • PR com label [BREAKING]  │
│  • Issue de alerta criada   │
│  • Auto-merge DESABILITADO  │
│  • Notificação para o time  │
└─────────────────────────────┘
```

---

## 📊 Benefícios da Solução

### Antes vs Depois

| Aspecto | Antes (Manual) | Depois (Automatizado) |
|---------|----------------|----------------------|
| **Tempo para atualizar** | Dias/Semanas | Minutos |
| **Cobertura** | Depende do time lembrar | 100% dos mini-apps |
| **Visibilidade** | Nenhuma | Dashboard de PRs abertos |
| **Breaking Changes** | Descobertos em produção | Detectados antes do merge |
| **Consistência** | Versões divergentes | Todos sincronizados |

### Métricas Possíveis

```yaml
ecosystem_health:
  sdk_version: "1.5.0"
  consumers:
    - name: "PIX"
      version: "1.5.0"
      status: "current"      # ✅ Atualizado
      
    - name: "Pagamentos"  
      version: "1.5.0"
      status: "current"      # ✅ Atualizado
      
    - name: "Crédito"
      version: "1.4.0"
      status: "behind"       # ⚠️ PR pendente
      pr_pending: "#45"
      days_behind: 7
```

---

## 🧪 POC - Prova de Conceito

### Repositórios Criados

| Repo | Função | URL |
|------|--------|-----|
| `superapp-sdk-poc` | Simula o SDK real | github.com/ricardo2009/superapp-sdk-poc |
| `miniapp-pix-poc` | Simula RN_Module_Pix | github.com/ricardo2009/miniapp-pix-poc |
| `miniapp-pagamentos-poc` | Simula RN_Module_Pagamentos | github.com/ricardo2009/miniapp-pagamentos-poc |
| `poc-sdk-compatibility` | Registry central e docs | github.com/ricardo2009/poc-sdk-compatibility |

### Teste Realizado

```bash
# 1. Criamos tag v0.0.3 no SDK
git tag -a v0.0.3 -m "release: v0.0.3"
git push origin v0.0.3

# 2. Workflow executou automaticamente:
#    ✅ Build & Test
#    ✅ Publish to GitHub Packages
#    ✅ Notify miniapp-pix-poc
#    ✅ Notify miniapp-pagamentos-poc

# 3. PRs criados automaticamente:
#    ✅ miniapp-pix-poc PR #9: "Update SDK to v0.0.3"
#    ✅ miniapp-pagamentos-poc PR #6: "Update SDK to v0.0.3"
```

---

## 🏢 Aplicação no Ambiente Real CAIXA

### Mapeamento POC → Produção

| POC | Produção CAIXA |
|-----|----------------|
| `superapp-sdk-poc` | `@plataforma-de-credito/superapp-features` |
| `miniapp-pix-poc` | `RN_Module_Pix` |
| `miniapp-pagamentos-poc` | `RN_Module_Pagamentos` |
| `poc-sdk-compatibility` | Novo repo de governance |

### O que Precisa ser Configurado

1. **PAT_DISPATCH** - Token com permissão para disparar workflows entre repos
2. **consumers.yml** - Lista de todos os mini-apps reais
3. **Workflows** - Adaptar para cada repo de mini-app

---

## 🔒 Segurança

- **PAT com escopo mínimo**: Apenas `repo` e `workflow`
- **Secrets seguros**: Armazenados no GitHub Secrets
- **Sem credenciais no código**: Tudo via variáveis de ambiente
- **Audit trail**: Todas as ações logadas no GitHub Actions

---

## 📈 Próximos Passos

1. ✅ POC validada e funcionando
2. ⏳ Aprovação da arquitetura
3. ⏳ Implementação nos repos reais
4. ⏳ Configuração do registry com todos os mini-apps
5. ⏳ Treinamento dos times

---

## 🤔 Dúvidas?

Se tiver qualquer dúvida sobre a solução, podemos agendar uma call para demonstrar o fluxo funcionando na POC.

**Links Úteis:**
- [POC SDK](https://github.com/ricardo2009/superapp-sdk-poc)
- [Workflow de Release](https://github.com/ricardo2009/superapp-sdk-poc/actions)
- [PRs gerados automaticamente](https://github.com/ricardo2009/miniapp-pix-poc/pulls)

---

*Documento gerado em 19/12/2025*
