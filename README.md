# 🎯 POC SDK Ecosystem - Sistema de Compatibilidade

> Sistema automatizado para gerenciamento de releases do SDK SuperApp e compatibilidade com mini-apps

[![E2E Test](https://github.com/ricardo2009/poc-sdk-compatibility/actions/workflows/e2e-test.yml/badge.svg)](https://github.com/ricardo2009/poc-sdk-compatibility/actions/workflows/e2e-test.yml)

---

## 📋 Visão Geral

Este repositório é o **registro central** do ecossistema SDK SuperApp. Ele:

1. **Registra** todos os mini-apps consumidores do SDK
2. **Orquestra** a propagação de releases do SDK
3. **Monitora** a compatibilidade entre mini-apps e SDK
4. **Automatiza** a criação de PRs e Issues para atualizações

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FLUXO DE RELEASE DO SDK                          │
└─────────────────────────────────────────────────────────────────────┘

                    ┌───────────────────────┐
                    │   superapp-sdk-poc    │
                    │   (SDK Package)       │
                    └──────────┬────────────┘
                               │
                               │ 1️⃣ git tag v*.*.*
                               ▼
                    ┌───────────────────────┐
                    │   sdk-release.yml     │
                    │   (GitHub Action)     │
                    └──────────┬────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
          │ 2️⃣ Carrega        │                    │
          │ consumers.yml      │                    │
          ▼                    │                    │
┌──────────────────┐           │                    │
│ poc-sdk-compat.  │           │                    │
│ (Este repo)      │           │                    │
└──────────────────┘           │                    │
                               │
          3️⃣ repository_dispatch (sdk.update)
                               │
          ┌────────────────────┴────────────────────┐
          ▼                                         ▼
┌──────────────────┐                    ┌──────────────────┐
│ miniapp-pix-poc  │                    │ miniapp-pagam... │
│                  │                    │                  │
│ sdk-update-      │                    │ sdk-update-      │
│ handler.yml      │                    │ handler.yml      │
└────────┬─────────┘                    └────────┬─────────┘
         │                                       │
         ▼                                       ▼
    4️⃣ Cria PR                              4️⃣ Cria PR
    5️⃣ Cria Issue                           5️⃣ Cria Issue
    6️⃣ Notifica                             6️⃣ Notifica
```

---

## 📦 Repositórios do Ecossistema

| Repositório | Descrição | Versão |
|-------------|-----------|--------|
| [superapp-sdk-poc](https://github.com/ricardo2009/superapp-sdk-poc) | SDK centralizado | 0.0.2 |
| [miniapp-pix-poc](https://github.com/ricardo2009/miniapp-pix-poc) | Mini-app PIX | 1.0.0 |
| [miniapp-pagamentos-poc](https://github.com/ricardo2009/miniapp-pagamentos-poc) | Mini-app Pagamentos | 1.0.0 |
| [poc-sdk-compatibility](https://github.com/ricardo2009/poc-sdk-compatibility) | Registry (este repo) | - |

---

## 🔧 Compatibilidade de Dependências

Esta POC utiliza as mesmas versões do ambiente de produção do cliente:

| Dependência | Versão POC | Versão Cliente | Status |
|-------------|------------|----------------|--------|
| React | 19.1.0 | 19.1.0 | ✅ Igual |
| React Native | 0.80.2 | 0.80.2 | ✅ Igual |
| Node.js | >=20 | >=20 | ✅ Igual |
| TypeScript | 5.7.2 | 5.7.2 | ✅ Igual |

---

## 📁 Estrutura

```
poc-sdk-compatibility/
├── .compatibility/
│   ├── config.yml          # Configuração geral
│   ├── consumers.yml       # Registro de mini-apps
│   └── learning.json       # Dados de aprendizado
├── .github/
│   └── workflows/
│       └── e2e-test.yml    # Teste E2E do fluxo
├── docs/
│   ├── CENARIO_DIVERGENCIA.md  # Cenário de demonstração
│   ├── adding-consumer.md      # Como adicionar mini-app
│   ├── quick-start.md          # Guia rápido
│   ├── TESTING-GUIDE.md        # Guia de testes
│   └── troubleshooting.md      # Resolução de problemas
├── ARCHITECTURE.md         # Documentação de arquitetura
├── DEMO.md                 # Roteiro de demonstração (20 min)
└── README.md               # Este arquivo
```

---

## 🚀 Quick Start

### 1. Testar o Fluxo Completo

```bash
# Via GitHub CLI
gh workflow run "e2e-test.yml" \
  --repo ricardo2009/poc-sdk-compatibility \
  -f version="2.0.0" \
  -f breaking="false"
```

### 2. Simular Release com Breaking Change

```bash
# No repositório do SDK
cd superapp-sdk-poc
git tag v3.0.0
git push origin v3.0.0
```

### 3. Observar Resultados

1. Acesse [Actions do SDK](https://github.com/ricardo2009/superapp-sdk-poc/actions)
2. Veja o workflow `sdk-release.yml` executando
3. Acesse [PRs do miniapp-pix-poc](https://github.com/ricardo2009/miniapp-pix-poc/pulls)
4. Acesse [PRs do miniapp-pagamentos-poc](https://github.com/ricardo2009/miniapp-pagamentos-poc/pulls)

---

## 📋 Consumer Registry

O arquivo `.compatibility/consumers.yml` lista todos os mini-apps:

```yaml
consumers:
  - name: "miniapp-pix-poc"
    display_name: "Mini-App PIX (POC)"
    repository: "ricardo2009/miniapp-pix-poc"
    priority: "critical"
    enabled: true

  - name: "miniapp-pagamentos-poc"
    display_name: "Mini-App Pagamentos (POC)"
    repository: "ricardo2009/miniapp-pagamentos-poc"
    priority: "high"
    enabled: true
```

---

## 🔀 Cenário de Divergência

Para demonstrar a detecção de incompatibilidades, configuramos:

- **miniapp-pix-poc**: SDK v0.0.2 (atualizado)
- **miniapp-pagamentos-poc**: SDK v0.0.1 (desatualizado)

Ao fazer release do SDK v3.0.0:

| Mini-App | De | Para | Labels |
|----------|-----|------|--------|
| PIX | v0.0.2 | v3.0.0 | `breaking-change`, `urgent` |
| Pagamentos | v0.0.1 | v3.0.0 | `breaking-change`, `urgent`, `sdk-outdated` |

> 📖 Veja detalhes em [docs/CENARIO_DIVERGENCIA.md](docs/CENARIO_DIVERGENCIA.md)

---

## 🔗 Documentação

| Documento | Descrição |
|-----------|-----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Arquitetura detalhada do sistema |
| [DEMO.md](DEMO.md) | Roteiro de demonstração (20 min) |
| [docs/CENARIO_DIVERGENCIA.md](docs/CENARIO_DIVERGENCIA.md) | Cenário de divergência |
| [docs/quick-start.md](docs/quick-start.md) | Guia de início rápido |
| [docs/adding-consumer.md](docs/adding-consumer.md) | Como adicionar novo mini-app |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Resolução de problemas |

---

## ✅ Funcionalidades Implementadas

- [x] **Registry centralizado** de consumers
- [x] **Dispatch automático** via `repository_dispatch`
- [x] **Criação de PRs** com labels apropriados
- [x] **Criação de Issues** para breaking changes
- [x] **Suporte a breaking changes** com tratamento especial
- [x] **Compatibilidade com ambiente cliente** (React 19, RN 0.80)
- [x] **Documentação completa** para demonstração

---

## 📊 Métricas do Fluxo

| Evento | Tempo Médio |
|--------|-------------|
| SDK Release → Dispatch | < 30s |
| Dispatch → Início workflow mini-app | < 10s |
| Validação + Criação PR | < 2min |
| Fluxo completo E2E | < 3min |

---

## 🛠️ Manutenção

### Adicionar Novo Mini-App

1. Adicionar entrada em `.compatibility/consumers.yml`
2. Criar `.sdk-ecosystem.yml` no mini-app
3. Adicionar `sdk-update-handler.yml` no mini-app
4. Criar labels necessários no repositório

### Atualizar Dependências

```bash
# Atualizar versões em todos os repos
# (manter sincronia com ambiente cliente)
```

---

## 📞 Contato

- **Autor**: Ricardo Lima
- **Email**: ricardolima@email.com
- **Documentação**: [DOC_SuperApp](https://github.com/ricardo2009/DOC_SuperApp)

---

## 📜 Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.
