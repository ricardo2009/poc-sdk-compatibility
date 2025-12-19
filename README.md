# 🚀 POC: Event-Driven SDK Compatibility System

[![Architecture](https://img.shields.io/badge/Architecture-Event--Driven-blue)]()
[![Coupling](https://img.shields.io/badge/Coupling-Zero-green)]()
[![Config](https://img.shields.io/badge/Config-As%20Code-orange)]()

> **Enterprise-grade solution for SDK compatibility validation across multiple repositories**

## 🎯 Objetivo

Sistema automatizado que detecta releases do SDK e dispara validações em todos os mini-apps consumidores, criando PRs automaticamente quando necessário.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   SDK Release  ──►  Orchestrator  ──►  Mini-App 1  ──►  Auto PR + Tests    │
│                          │                                                  │
│                          ├─────────►  Mini-App 2  ──►  Auto PR + Tests    │
│                          │                                                  │
│                          └─────────►  Mini-App N  ──►  Auto PR + Tests    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## ✨ Características

| Feature | Descrição |
|---------|-----------|
| **Zero-Coupling** | SDK não conhece os consumidores |
| **Event-Driven** | Comunicação via GitHub Events |
| **Config as Code** | Toda configuração em YAML |
| **Policy as Code** | Regras de automação declarativas |
| **Multi-Repo** | Funciona com N repositórios |
| **Portable** | Sem hardcoding, 100% configurável |

## 📁 Estrutura

```
poc-sdk-compatibility/
├── README.md                           # Este arquivo
├── ARCHITECTURE.md                     # Documentação técnica
├── DEMO.md                             # Roteiro de demonstração
│
├── .github/
│   └── workflows/
│       ├── sdk-release-emit.yml        # 📤 Emite eventos de release
│       └── orchestrator-receive.yml    # 🎯 Recebe e despacha para consumers
│
├── .compatibility/
│   ├── config.yml                      # ⚙️ Configuração master
│   └── consumers.yml                   # 📋 Registry de consumers
│
├── examples/
│   └── consumer-workflow/
│       └── consumer-validate.yml       # 📥 Template para consumers
│
├── scripts/
│   ├── setup.js                        # 🔧 Setup automatizado
│   └── validate-config.js              # ✅ Validação de configuração
│
└── docs/
    ├── quick-start.md                  # Início rápido
    ├── adding-consumer.md              # Como adicionar consumer
    └── troubleshooting.md              # Resolução de problemas
```

## 🚀 Quick Start

### 1. Clone e Configure

```bash
git clone https://github.com/ricardo2009/poc-sdk-compatibility.git
cd poc-sdk-compatibility
node scripts/setup.js <sua-organizacao>
```

### 2. Configure Secrets no GitHub

Em **Settings → Secrets → Actions**, adicione:

| Secret | Descrição |
|--------|-----------|
| `DISPATCH_TOKEN` | PAT com scopes `repo` e `workflow` |

### 3. Adicione Consumers

Edite `.compatibility/consumers.yml`:

```yaml
consumers:
  - name: meu-miniapp
    repository: minha-org/meu-miniapp
    priority: high
```

### 4. Teste o Fluxo

1. Vá para **Actions** → **📤 SDK Release - Emit Event**
2. Click **Run workflow**
3. Observe os workflows disparando nos consumers!

## 📖 Documentação

- [📐 Arquitetura Completa](ARCHITECTURE.md)
- [🎬 Roteiro de Demo](DEMO.md)
- [📚 Quick Start](docs/quick-start.md)
- [➕ Adicionar Consumer](docs/adding-consumer.md)

## 🔄 Fluxo de Eventos

```
1. SDK é publicado (release)
           │
           ▼
2. sdk-release-emit.yml executa
   • Extrai informações da release
   • Gera contrato de compatibilidade
   • Emite evento 'sdk.released'
           │
           ▼
3. orchestrator-receive.yml recebe
   • Carrega registry de consumers
   • Aplica regras de automação
   • Despacha 'sdk.validate' para cada consumer
           │
           ▼
4. Consumer recebe (em seu próprio repo)
   • Atualiza SDK para nova versão
   • Executa testes
   • Cria PR se sucesso
   • Reporta resultado ao orchestrator
           │
           ▼
5. Orchestrator agrega resultados
   • Gera summary consolidado
   • Notifica stakeholders
```

## 🛠️ Tecnologias

- **GitHub Actions** - Workflows e automação
- **Repository Dispatch** - Comunicação entre repos
- **YAML** - Configuração declarativa
- **Node.js** - Scripts de setup

## 📊 Work Item

> **#139 - Super App - Ajustes Esteiras DevOps**
> 
> Solução enterprise-grade para validação automática de compatibilidade SDK em arquitetura multi-repo.

## 📜 Licença

Proprietary - CAIXA Econômica Federal

---

<div align="center">

**[⭐ Star this repo](https://github.com/ricardo2009/poc-sdk-compatibility)** se achou útil!

</div>
