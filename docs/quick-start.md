# 🚀 Quick Start

> Guia rápido para começar a usar o SDK Compatibility System

## ⏱️ Tempo estimado: 10 minutos

---

## Pré-requisitos

- [ ] Conta no GitHub
- [ ] GitHub CLI (`gh`) instalado (opcional)
- [ ] Node.js 18+ instalado

---

## Passo 1: Clone o repositório

```bash
git clone https://github.com/ricardo2009/poc-sdk-compatibility.git
cd poc-sdk-compatibility
```

---

## Passo 2: Execute o setup

```bash
node scripts/setup.js sua-organizacao
```

Isso irá:
- ✅ Verificar estrutura de arquivos
- ✅ Atualizar configurações com sua organização
- ✅ Gerar instruções personalizadas

---

## Passo 3: Crie o Token (PAT)

1. Acesse: https://github.com/settings/tokens/new
2. Nome: `SDK Compatibility Token`
3. Selecione scopes:
   - [x] `repo` (Full control)
   - [x] `workflow` (Update workflows)
4. Clique **Generate token**
5. **Copie o token!** (você não verá novamente)

---

## Passo 4: Configure o Secret

1. Vá para seu repositório no GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Clique **New repository secret**
4. Nome: `DISPATCH_TOKEN`
5. Value: Cole o token do Passo 3
6. Clique **Add secret**

---

## Passo 5: Push para GitHub

```bash
git add .
git commit -m "feat: initial setup"
git push origin main
```

---

## Passo 6: Teste!

1. Vá para **Actions** no seu repositório
2. Selecione **📤 SDK Release - Emit Event**
3. Clique **Run workflow**
4. Preencha:
   - Version: `1.0.0`
   - Breaking changes: `false`
5. Clique **Run workflow**

---

## ✅ Sucesso!

Se tudo funcionou, você verá:

1. Workflow **sdk-release-emit** executando
2. Evento sendo despachado para o Orchestrator
3. Orchestrator carregando consumers e despachando eventos

---

## Próximos passos

- [➕ Adicionar um Consumer](adding-consumer.md)
- [📐 Entender a Arquitetura](../ARCHITECTURE.md)
- [🎬 Preparar Demo](../DEMO.md)

---

## Problemas?

Veja [Troubleshooting](troubleshooting.md) ou abra uma issue.
