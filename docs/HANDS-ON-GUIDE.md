# 🚀 Hands-On Guide - SDK Compatibility Automation

Este guia detalha passo-a-passo como executar e validar o sistema de automação de compatibilidade SDK-MiniApps.

---

## 📋 Índice

1. [Pré-requisitos](#-pré-requisitos)
2. [Preparação do Ambiente](#-preparação-do-ambiente)
3. [Passo 1: Clonar Repositórios](#passo-1-clonar-repositórios)
4. [Passo 2: Verificar Configurações](#passo-2-verificar-configurações)
5. [Passo 3: Fazer Alteração no SDK](#passo-3-fazer-alteração-no-sdk)
6. [Passo 4: Criar Tag e Push](#passo-4-criar-tag-e-push)
7. [Passo 5: Monitorar Workflows](#passo-5-monitorar-workflows)
8. [Passo 6: Verificar PRs Criados](#passo-6-verificar-prs-criados)
9. [Validação Final](#-validação-final)
10. [Troubleshooting](#-troubleshooting)

---

## 📌 Pré-requisitos

### Software Necessário
- [ ] **Git** (versão 2.30+)
- [ ] **Node.js** (versão 18+)
- [ ] **npm** (versão 9+)
- [ ] **PowerShell** (versão 5.1+) ou Terminal de sua preferência

### Configurações Necessárias
- [ ] **Conta GitHub** com acesso aos repositórios
- [ ] **GitHub Personal Access Token (PAT)** com permissões:
  - `repo` (full control)
  - `write:packages`
  - `read:packages`

### Repositórios (POC Ricardo)
| Repositório | URL |
|-------------|-----|
| SDK | https://github.com/ricardo2009/superapp-sdk-poc |
| Pix | https://github.com/ricardo2009/miniapp-pix-poc |
| Pagamentos | https://github.com/ricardo2009/miniapp-pagamentos-poc |
| Docs | https://github.com/ricardo2009/poc-sdk-compatibility |

---

## 🔧 Preparação do Ambiente

### 1. Configurar npm para GitHub Packages

```powershell
# Criar/editar arquivo .npmrc no diretório home
$npmrcContent = @"
@ricardo2009:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=SEU_PAT_TOKEN_AQUI
"@
Set-Content -Path "$env:USERPROFILE\.npmrc" -Value $npmrcContent
```

### 2. Verificar autenticação npm

```powershell
npm whoami --registry=https://npm.pkg.github.com
```

**Resultado esperado:** Seu username do GitHub

---

## Passo 1: Clonar Repositórios

```powershell
# Definir diretório de trabalho
$WORKSPACE = "C:\poc-sdk-compatibility"
New-Item -ItemType Directory -Force -Path $WORKSPACE
Set-Location $WORKSPACE

# Clonar todos os repositórios
git clone https://github.com/ricardo2009/superapp-sdk-poc.git
git clone https://github.com/ricardo2009/miniapp-pix-poc.git
git clone https://github.com/ricardo2009/miniapp-pagamentos-poc.git
git clone https://github.com/ricardo2009/poc-sdk-compatibility.git

# Verificar estrutura
Get-ChildItem -Directory
```

**Saída esperada:**
```
Directory: C:\poc-sdk-compatibility

Mode    Name
----    ----
d----   superapp-sdk-poc
d----   miniapp-pix-poc
d----   miniapp-pagamentos-poc
d----   poc-sdk-compatibility
```

---

## Passo 2: Verificar Configurações

### 2.1 Verificar Secrets nos Repositórios

Acesse cada repositório no GitHub e verifique em **Settings → Secrets and variables → Actions**:

| Repositório | Secret Necessário |
|-------------|-------------------|
| superapp-sdk-poc | `PAT_DISPATCH` |
| miniapp-pix-poc | (nenhum adicional) |
| miniapp-pagamentos-poc | (nenhum adicional) |

### 2.2 Verificar Workflows

```powershell
# SDK - deve ter sdk-release.yml
Get-Content ".\superapp-sdk-poc\.github\workflows\sdk-release.yml" -Head 20

# Mini-apps - devem ter sdk-update-handler.yml
Get-Content ".\miniapp-pix-poc\.github\workflows\sdk-update-handler.yml" -Head 20
Get-Content ".\miniapp-pagamentos-poc\.github\workflows\sdk-update-handler.yml" -Head 20
```

### 2.3 Verificar package.json do SDK

```powershell
# Verificar versão atual
$pkg = Get-Content ".\superapp-sdk-poc\package.json" | ConvertFrom-Json
Write-Host "Versão atual do SDK: $($pkg.version)"
Write-Host "Nome do pacote: $($pkg.name)"
```

---

## Passo 3: Fazer Alteração no SDK

### 3.1 Entrar no diretório do SDK

```powershell
Set-Location ".\superapp-sdk-poc"
git checkout main
git pull origin main
```

### 3.2 Incrementar versão

```powershell
# Ver versão atual
npm version

# Incrementar patch (ex: 0.0.3 → 0.0.4)
npm version patch --no-git-tag-version

# OU incrementar minor (ex: 0.0.3 → 0.1.0)
# npm version minor --no-git-tag-version

# Verificar nova versão
$pkg = Get-Content ".\package.json" | ConvertFrom-Json
Write-Host "Nova versão: $($pkg.version)"
```

### 3.3 (Opcional) Fazer uma alteração real

```powershell
# Exemplo: adicionar um comentário no Logger
$loggerPath = ".\src\logger\index.ts"
$content = Get-Content $loggerPath -Raw
$newContent = "// Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n$content"
Set-Content -Path $loggerPath -Value $newContent
```

### 3.4 Commit das alterações

```powershell
git add .
git commit -m "chore: bump version to $($pkg.version)"
```

---

## Passo 4: Criar Tag e Push

### 4.1 Criar tag seguindo semver

```powershell
$version = (Get-Content ".\package.json" | ConvertFrom-Json).version
$tag = "v$version"
Write-Host "Criando tag: $tag"

git tag -a $tag -m "Release $tag"
```

### 4.2 Push para GitHub

```powershell
# Push do commit
git push origin main

# Push da tag (isso dispara o workflow!)
git push origin $tag

Write-Host "`n✅ Tag $tag enviada! Workflow sdk-release.yml deve iniciar em segundos..."
```

### 4.3 Verificar push

```powershell
Write-Host "`n📋 Verificando tags no remote:"
git ls-remote --tags origin | Select-Object -Last 5
```

---

## Passo 5: Monitorar Workflows

### 5.1 Abrir GitHub Actions do SDK

```powershell
Start-Process "https://github.com/ricardo2009/superapp-sdk-poc/actions"
```

**O que observar:**
1. ✅ Workflow `sdk-release.yml` iniciado
2. ✅ Build do TypeScript completo
3. ✅ Testes passando
4. ✅ Publicação no npm.pkg.github.com
5. ✅ Repository dispatch enviado

### 5.2 Monitorar workflows dos mini-apps

```powershell
# Abrir Actions de ambos mini-apps
Start-Process "https://github.com/ricardo2009/miniapp-pix-poc/actions"
Start-Process "https://github.com/ricardo2009/miniapp-pagamentos-poc/actions"
```

**O que observar:**
1. ✅ Workflow `sdk-update-handler.yml` iniciado (triggered por repository_dispatch)
2. ✅ Branch `sdk-update/vX.X.X` criada
3. ✅ SDK atualizado no package.json
4. ✅ Testes executados
5. ✅ PR criado automaticamente

### 5.3 Monitorar via linha de comando

```powershell
# Verificar se o pacote foi publicado
npm view @ricardo2009/superapp-sdk-poc versions --registry=https://npm.pkg.github.com

# Ver última versão
npm view @ricardo2009/superapp-sdk-poc version --registry=https://npm.pkg.github.com
```

---

## Passo 6: Verificar PRs Criados

### 6.1 Listar PRs abertos

```powershell
# Abrir PRs do mini-app Pix
Start-Process "https://github.com/ricardo2009/miniapp-pix-poc/pulls"

# Abrir PRs do mini-app Pagamentos
Start-Process "https://github.com/ricardo2009/miniapp-pagamentos-poc/pulls"
```

### 6.2 Verificar conteúdo do PR

Cada PR deve conter:
- **Título:** `chore(deps): update SDK to vX.X.X`
- **Branch:** `sdk-update/vX.X.X`
- **Alterações:**
  - `package.json` atualizado
  - `package-lock.json` atualizado
- **Status:** Testes passando (CI verde)

### 6.3 Via API do GitHub

```powershell
$token = "SEU_PAT_TOKEN"
$headers = @{
    "Authorization" = "token $token"
    "Accept" = "application/vnd.github.v3+json"
}

# Listar PRs do miniapp-pix-poc
$prs = Invoke-RestMethod -Uri "https://api.github.com/repos/ricardo2009/miniapp-pix-poc/pulls" -Headers $headers
$prs | ForEach-Object { 
    Write-Host "PR #$($_.number): $($_.title) - $($_.state)"
}
```

---

## ✅ Validação Final

### Checklist de Sucesso

| Item | Status | Como Verificar |
|------|--------|----------------|
| Tag criada no SDK | ⬜ | `git ls-remote --tags origin` |
| Workflow SDK executou | ⬜ | GitHub Actions do SDK |
| Pacote publicado | ⬜ | `npm view @ricardo2009/superapp-sdk-poc` |
| Dispatch enviado | ⬜ | Logs do workflow SDK |
| Workflow Pix executou | ⬜ | GitHub Actions do miniapp-pix |
| Workflow Pagamentos executou | ⬜ | GitHub Actions do miniapp-pagamentos |
| PR criado no Pix | ⬜ | GitHub PRs do miniapp-pix |
| PR criado no Pagamentos | ⬜ | GitHub PRs do miniapp-pagamentos |
| Testes passaram | ⬜ | CI verde nos PRs |

### Tempo Esperado

| Fase | Tempo Aproximado |
|------|------------------|
| Build + Publish SDK | ~1-2 minutos |
| Dispatch + Trigger | ~10 segundos |
| Processamento mini-apps | ~2-3 minutos cada |
| **Total** | **~5-7 minutos** |

---

## 🔧 Troubleshooting

### ❌ Tag não dispara o workflow

**Verificar:**
```yaml
# sdk-release.yml deve ter:
on:
  push:
    tags:
      - 'v*.*.*'
```

**Solução:** Verificar se o formato da tag está correto (ex: `v1.2.3`)

### ❌ Pacote não publica

**Verificar:**
```powershell
# Verificar .npmrc
Get-Content "$env:USERPROFILE\.npmrc"

# Verificar autenticação
npm whoami --registry=https://npm.pkg.github.com
```

**Solução:** Verificar se o PAT tem permissão `write:packages`

### ❌ Dispatch não chega nos mini-apps

**Verificar nos logs do SDK:**
```
repository_dispatch sent to miniapp-pix-poc
repository_dispatch sent to miniapp-pagamentos-poc
```

**Solução:** Verificar se o secret `PAT_DISPATCH` está configurado e tem permissão `repo`

### ❌ Mini-app não cria PR

**Verificar:**
- Workflow tem permissões `contents: write` e `pull-requests: write`
- Branch `sdk-update/vX.X.X` não existe previamente

**Solução:**
```powershell
# Deletar branch antiga se existir
git push origin --delete sdk-update/vX.X.X
```

### ❌ Testes falham no mini-app

**Verificar:**
- Breaking changes no SDK
- Compatibilidade de versões

**Solução:** Revisar changelog do SDK e ajustar código do mini-app

---

## 📊 Exemplo de Output Esperado

### Console ao final do processo

```
=== SDK Compatibility Automation - Resultado ===

📦 SDK Release:
   ✅ Tag: v0.0.4
   ✅ Package: @ricardo2009/superapp-sdk-poc@0.0.4
   ✅ Published to: npm.pkg.github.com

🔔 Dispatch Status:
   ✅ miniapp-pix-poc: triggered
   ✅ miniapp-pagamentos-poc: triggered

📱 Mini-Apps:
   ✅ miniapp-pix-poc:
      - Branch: sdk-update/v0.0.4
      - PR: #12 - chore(deps): update SDK to v0.0.4
      - Tests: passing
   
   ✅ miniapp-pagamentos-poc:
      - Branch: sdk-update/v0.0.4
      - PR: #8 - chore(deps): update SDK to v0.0.4
      - Tests: passing

⏱️ Tempo total: 6 minutos 23 segundos

🎉 Automação concluída com sucesso!
```

---

## 🔗 Próximos Passos

1. **Merge dos PRs** - Revisar e aprovar os PRs criados
2. **Configurar Auto-merge** - Ativar para patches automáticos
3. **Adicionar mais consumidores** - Ver [adding-consumer.md](./adding-consumer.md)
4. **Monitorar em produção** - Configurar alertas

---

## 📚 Documentação Relacionada

- [COMPLETE-FLOW-DIAGRAM.md](./COMPLETE-FLOW-DIAGRAM.md) - Diagramas visuais
- [TESTING-GUIDE.md](./TESTING-GUIDE.md) - Guia de testes E2E
- [troubleshooting.md](./troubleshooting.md) - Resolução de problemas
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Arquitetura detalhada
