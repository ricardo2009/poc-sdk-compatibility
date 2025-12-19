# 🔧 Troubleshooting

> Soluções para problemas comuns

---

## 🔴 Problemas de Autenticação

### "Resource not accessible by integration"

**Causa:** O token não tem permissões suficientes.

**Solução:**
1. Vá para https://github.com/settings/tokens
2. Crie um novo token com:
   - [x] `repo` (full control)
   - [x] `workflow`
3. Atualize o secret `DISPATCH_TOKEN` nos repos

---

### "Bad credentials"

**Causa:** Token expirado ou incorreto.

**Solução:**
1. Verifique se o token ainda é válido
2. Recrie se necessário
3. Atualize em Settings → Secrets

---

## 🟡 Problemas de Eventos

### Evento não chegou no consumer

**Diagnóstico:**
```bash
# No orchestrator, vá em Actions e veja os logs do dispatch
```

**Possíveis causas:**

1. **Consumer não registrado**
   - Verifique `.compatibility/consumers.yml`
   - Confirme que `enabled: true`

2. **Erro no dispatch**
   - Veja logs do job `dispatch-validation`
   - Verifique se o repositório existe

3. **Token sem permissão**
   - O token precisa ter acesso ao repo do consumer

---

### Workflow do consumer não executou

**Causa 1:** Workflow não existe

```bash
# Verifique se existe
ls -la .github/workflows/
```

**Causa 2:** Trigger incorreto

```yaml
# Deve ter:
on:
  repository_dispatch:
    types: [sdk.validation.request]
```

**Causa 3:** Branch protection

- O workflow precisa existir no branch default

---

## 🟠 Problemas de Configuração

### "Invalid YAML"

**Diagnóstico:**
```bash
# Valide YAML localmente
npx yaml-lint .compatibility/*.yml
```

**Erros comuns:**
- Indentação inconsistente (use 2 espaços)
- Caracteres especiais sem quotes
- Tabs em vez de espaços

---

### Variables não substituídas

**Exemplo:**
```
${GITHUB_ORG:-default} aparece literal
```

**Causa:** O script de setup não foi executado.

**Solução:**
```bash
node scripts/setup.js sua-org
```

---

## 🔵 Problemas de Workflow

### "No jobs were run"

**Causa:** Condições não satisfeitas.

**Verificar:**
```yaml
jobs:
  my-job:
    if: github.event_name == 'repository_dispatch'  # Esta condição passou?
```

---

### Matrix job falhou parcialmente

**Diagnóstico:**
- Veja qual consumer falhou
- Verifique logs específicos desse consumer

**Solução:**
```yaml
strategy:
  fail-fast: false  # Não para todos se um falhar
```

---

## 🟣 Problemas de Rede

### Timeout em dispatch

**Causa:** Muitos consumers ou rede lenta.

**Soluções:**
1. Aumente o timeout:
```yaml
- uses: peter-evans/repository-dispatch@v3
  timeout-minutes: 10
```

2. Reduza paralelismo:
```yaml
strategy:
  max-parallel: 2
```

---

### Rate limiting

**Sintoma:** `API rate limit exceeded`

**Soluções:**
1. Use um token com mais quota (GitHub Enterprise)
2. Adicione delays entre dispatches:
```yaml
- name: Delay
  run: sleep 5
```

---

## 🔍 Debug Avançado

### Habilitar logs detalhados

No repositório, vá em:
1. Settings → Secrets → Actions
2. Adicione: `ACTIONS_STEP_DEBUG` = `true`
3. Adicione: `ACTIONS_RUNNER_DEBUG` = `true`

---

### Ver payload do evento

```yaml
- name: Debug payload
  run: |
    echo "Event: ${{ github.event_name }}"
    echo "Action: ${{ github.event.action }}"
    echo "Payload:"
    cat $GITHUB_EVENT_PATH | jq .
```

---

### Testar dispatch manualmente

```bash
# Via GitHub CLI
gh api repos/org/orchestrator/dispatches \
  -f event_type=sdk.released \
  -f client_payload='{"sdk":{"version":"1.0.0"}}'
```

---

## 📊 Verificações de Saúde

### Script de diagnóstico

```bash
#!/bin/bash
# diagnostics.sh

echo "=== Verificando estrutura ==="
ls -la .compatibility/ || echo "❌ Pasta .compatibility não existe"
ls -la .github/workflows/ || echo "❌ Pasta workflows não existe"

echo ""
echo "=== Verificando YAML ==="
for f in .compatibility/*.yml; do
  echo -n "Validando $f... "
  python -c "import yaml; yaml.safe_load(open('$f'))" 2>/dev/null && echo "✅" || echo "❌"
done

echo ""
echo "=== Verificando workflows ==="
for f in .github/workflows/*.yml; do
  echo -n "Validando $f... "
  python -c "import yaml; yaml.safe_load(open('$f'))" 2>/dev/null && echo "✅" || echo "❌"
done

echo ""
echo "=== Verificando git remote ==="
git remote -v

echo ""
echo "=== Status ==="
git status --short
```

---

## 🆘 Ainda com problemas?

1. **Verifique a documentação:**
   - [Arquitetura](../ARCHITECTURE.md)
   - [Quick Start](quick-start.md)

2. **Abra uma issue** com:
   - Descrição do problema
   - Logs relevantes
   - Passos para reproduzir

3. **Contato:**
   - Crie issue no repositório
   - Inclua versão e ambiente
