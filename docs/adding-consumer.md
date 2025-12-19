# ➕ Adicionando um Consumer

> Como integrar um novo mini-app ao SDK Compatibility System

---

## Overview

Um **Consumer** é qualquer repositório que consome o SDK e precisa ser validado quando há uma nova versão.

```
┌──────────────────────────────────────────────────────────────┐
│                    SDK COMPATIBILITY SYSTEM                   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│   Orchestrator  ────dispatch────▶  Seu Consumer (novo!)      │
│                                                              │
│   O orchestrator envia eventos, seu consumer reage           │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## ⏱️ Tempo estimado: 5 minutos

---

## Passo 1: Registre no consumers.yml

Edite `.compatibility/consumers.yml` no repositório do orchestrator:

```yaml
consumers:
  # ... consumers existentes ...

  - id: meu-miniapp
    name: "Meu Mini App"
    repository: "sua-org/seu-repositorio"
    priority: 2  # 1 = mais prioritário
    enabled: true
    groups:
      - miniapps
    config:
      auto_pr: true
      require_approval: false
    contacts:
      - type: email
        value: time@empresa.com
```

### Campos obrigatórios:

| Campo | Descrição |
|-------|-----------|
| `id` | Identificador único (kebab-case) |
| `name` | Nome legível |
| `repository` | `owner/repo` no GitHub |
| `priority` | 1-10 (menor = mais prioritário) |
| `enabled` | `true` para receber eventos |

### Campos opcionais:

| Campo | Descrição | Default |
|-------|-----------|---------|
| `groups` | Tags para agrupar | `[]` |
| `config.auto_pr` | Criar PR automático | `true` |
| `config.require_approval` | Requer aprovação | `false` |
| `contacts` | Lista de contatos | `[]` |

---

## Passo 2: Adicione o workflow ao seu repo

Copie o arquivo:
```
examples/consumer-workflow/consumer-validate.yml
```

Para o seu repositório:
```
.github/workflows/sdk-compatibility-validate.yml
```

### Via GitHub CLI:

```bash
# No seu repositório local
mkdir -p .github/workflows

# Copie e renomeie
curl -o .github/workflows/sdk-compatibility-validate.yml \
  https://raw.githubusercontent.com/ricardo2009/poc-sdk-compatibility/main/examples/consumer-workflow/consumer-validate.yml
```

### Via UI:

1. Vá para `examples/consumer-workflow/consumer-validate.yml`
2. Copie o conteúdo
3. No seu repo, crie `.github/workflows/sdk-compatibility-validate.yml`
4. Cole o conteúdo

---

## Passo 3: Configure secrets no seu repo

O consumer precisa de um secret para reportar de volta:

1. Vá para seu repositório → **Settings** → **Secrets**
2. Adicione **DISPATCH_TOKEN** com um PAT que tenha acesso ao orchestrator

---

## Passo 4: Personalize (opcional)

Edite o workflow copiado para customizar:

```yaml
env:
  # Nome do seu app
  CONSUMER_ID: 'meu-miniapp'
  
  # Repo do orchestrator
  ORCHESTRATOR_REPO: 'sua-org/poc-sdk-compatibility'

jobs:
  validate:
    steps:
      # Adicione steps de validação específicos
      - name: Validação customizada
        run: |
          npm run test:sdk-compat
          npm run lint
```

---

## Passo 5: Commit e Push

No orchestrator:
```bash
git add .compatibility/consumers.yml
git commit -m "feat: add meu-miniapp as consumer"
git push
```

No consumer:
```bash
git add .github/workflows/
git commit -m "feat: add SDK compatibility workflow"
git push
```

---

## ✅ Pronto!

Seu consumer agora:

1. ✅ Está registrado no orchestrator
2. ✅ Tem o workflow para reagir a eventos
3. ✅ Pode reportar resultados de volta

---

## Testando

1. Vá para o orchestrator
2. **Actions** → **📤 SDK Release - Emit Event**
3. Execute manualmente
4. Verifique se seu consumer recebeu o evento

---

## Debugging

### Consumer não recebeu evento?

1. Verifique se `enabled: true` no consumers.yml
2. Verifique se DISPATCH_TOKEN tem permissão no repo do consumer
3. Veja logs do orchestrator em Actions

### Workflow falhou?

1. Verifique se o workflow está em `.github/workflows/`
2. Verifique se o trigger `repository_dispatch` está configurado
3. Veja logs do workflow no consumer

---

## Exemplos de consumers

### Mini-app com testes

```yaml
# .github/workflows/sdk-compatibility-validate.yml
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - run: npm ci
      
      - name: Update SDK
        run: npm install @org/sdk@${{ github.event.client_payload.sdk.version }}
      
      - name: Run tests
        run: npm test
      
      - name: Run linting
        run: npm run lint
```

### Mini-app com validação de tipos

```yaml
jobs:
  validate:
    steps:
      - name: Type checking
        run: npx tsc --noEmit
      
      - name: Check breaking changes
        run: |
          if [ "${{ github.event.client_payload.sdk.breaking_changes }}" = "true" ]; then
            echo "⚠️ Breaking changes detected!"
            npm run check:breaking-changes
          fi
```

---

## Próximos passos

- [🏗️ Arquitetura completa](../ARCHITECTURE.md)
- [🎬 Demo para cliente](../DEMO.md)
- [🔧 Troubleshooting](troubleshooting.md)
