# 📊 SDK Compatibility - Fluxo Completo com Diagramas

Este documento apresenta diagramas visuais do fluxo completo de automação de compatibilidade SDK-MiniApps.

---

## 🎯 Visão Geral do Sistema

```mermaid
flowchart TB
    subgraph SDK["📦 SDK Repository"]
        A[Developer Push] --> B[sdk-release.yml]
        B --> C{Tag v*.*.* ?}
        C -->|Não| D[Apenas CI/Testes]
        C -->|Sim| E[Build + Publish NPM]
    end
    
    subgraph Registry["📚 GitHub Packages"]
        E --> F["@ricardo2009/superapp-sdk@version"]
    end
    
    subgraph Dispatch["🔔 Notificação"]
        E --> G[repository_dispatch]
        G --> H["Event: sdk.update"]
    end
    
    subgraph MiniApps["📱 Mini-Apps"]
        H --> I[sdk-update-handler.yml]
        I --> J[Cria branch automaticamente]
        J --> K[npm install nova versão]
        K --> L[Executa testes]
        L --> M{Testes OK?}
        M -->|Sim| N[Cria PR automático]
        M -->|Não| O[Alerta/Notifica]
    end
    
    subgraph Review["👀 Revisão"]
        N --> P[Dependabot Auto-merge]
        P --> Q{É patch/minor?}
        Q -->|Sim| R[Merge automático]
        Q -->|Não| S[Review manual]
    end
    
    style SDK fill:#e1f5fe
    style Registry fill:#f3e5f5
    style Dispatch fill:#fff3e0
    style MiniApps fill:#e8f5e9
    style Review fill:#fce4ec
```

---

## 🔄 Diagrama de Sequência - Ciclo Completo

```mermaid
sequenceDiagram
    autonumber
    participant Dev as 👨‍💻 Developer
    participant SDK as 📦 SDK Repo
    participant NPM as 📚 GitHub Packages
    participant GH as 🔔 GitHub API
    participant PIX as 📱 MiniApp Pix
    participant PAG as 📱 MiniApp Pagamentos
    
    rect rgb(225, 245, 254)
        Note over Dev,SDK: Fase 1: Release do SDK
        Dev->>SDK: git push --tags v1.2.3
        SDK->>SDK: Trigger sdk-release.yml
        SDK->>SDK: npm run build
        SDK->>SDK: npm run test
        SDK->>NPM: npm publish
        NPM-->>SDK: ✅ Publicado @ricardo2009/superapp-sdk@1.2.3
    end
    
    rect rgb(255, 243, 224)
        Note over SDK,GH: Fase 2: Notificação via Dispatch
        SDK->>GH: repository_dispatch
        GH->>PIX: Event: sdk.update
        GH->>PAG: Event: sdk.update
    end
    
    rect rgb(232, 245, 233)
        Note over PIX,PAG: Fase 3: Processamento nos Mini-Apps
        par Processamento Paralelo
            PIX->>PIX: sdk-update-handler.yml
            PIX->>PIX: git checkout -b sdk-update/v1.2.3
            PIX->>NPM: npm install @ricardo2009/superapp-sdk@1.2.3
            PIX->>PIX: npm run test
            PIX->>PIX: git commit + push
            PIX->>GH: Criar PR automático
        and
            PAG->>PAG: sdk-update-handler.yml
            PAG->>PAG: git checkout -b sdk-update/v1.2.3
            PAG->>NPM: npm install @ricardo2009/superapp-sdk@1.2.3
            PAG->>PAG: npm run test
            PAG->>PAG: git commit + push
            PAG->>GH: Criar PR automático
        end
    end
    
    rect rgb(252, 228, 236)
        Note over PIX,PAG: Fase 4: Auto-merge (opcional)
        PIX->>PIX: dependabot-auto-merge.yml
        PAG->>PAG: dependabot-auto-merge.yml
    end
```

---

## 📁 Estrutura dos Repositórios

```mermaid
flowchart LR
    subgraph Central["🎛️ poc-sdk-compatibility"]
        A[README.md]
        B[ARCHITECTURE.md]
        C[docs/]
    end
    
    subgraph SDK["📦 superapp-sdk-poc"]
        D[src/]
        E[.github/workflows/]
        F[sdk-release.yml]
        G[ci.yml]
    end
    
    subgraph Consumers["📱 Mini-Apps Consumidores"]
        subgraph PIX["miniapp-pix-poc"]
            H[src/features/pix/]
            I[sdk-update-handler.yml]
            J[dependabot-auto-merge.yml]
        end
        subgraph PAG["miniapp-pagamentos-poc"]
            K[src/features/pagamentos/]
            L[sdk-update-handler.yml]
            M[dependabot-auto-merge.yml]
        end
    end
    
    Central -.->|Documenta| SDK
    Central -.->|Documenta| Consumers
    SDK -->|Publica| N["📚 npm.pkg.github.com"]
    N -->|Instala| PIX
    N -->|Instala| PAG
    SDK -->|repository_dispatch| PIX
    SDK -->|repository_dispatch| PAG
    
    style Central fill:#fff9c4
    style SDK fill:#e1f5fe
    style Consumers fill:#e8f5e9
```

---

## 🔐 Fluxo de Autenticação

```mermaid
flowchart TD
    subgraph Secrets["🔑 Secrets Configurados"]
        A[PAT_DISPATCH]
        B[GH_TOKEN]
        C[NPM_TOKEN]
    end
    
    subgraph Usage["📋 Uso nos Workflows"]
        D["sdk-release.yml<br/>→ Publica NPM<br/>→ Envia dispatch"]
        E["sdk-update-handler.yml<br/>→ Instala pacotes<br/>→ Cria PR"]
    end
    
    A -->|Permissão repo + write:packages| D
    B -->|Autenticação GitHub Actions| E
    C -->|npm.pkg.github.com| D
    
    subgraph Permissões["✅ Permissões Necessárias"]
        F["repo (full control)"]
        G["write:packages"]
        H["read:packages"]
    end
    
    style Secrets fill:#ffebee
    style Usage fill:#e8f5e9
    style Permissões fill:#e3f2fd
```

---

## ⚙️ Estados do Workflow

```mermaid
stateDiagram-v2
    [*] --> Idle: Aguardando
    
    Idle --> TagPushed: git push --tags
    TagPushed --> Building: Workflow iniciado
    Building --> Testing: Build OK
    Testing --> Publishing: Testes OK
    Publishing --> Dispatching: NPM publicado
    Dispatching --> NotifyingConsumers: Evento enviado
    
    NotifyingConsumers --> PIX_Processing: miniapp-pix
    NotifyingConsumers --> PAG_Processing: miniapp-pagamentos
    
    PIX_Processing --> PIX_PR: Testes OK
    PAG_Processing --> PAG_PR: Testes OK
    
    PIX_PR --> PIX_Merged: Auto-merge
    PAG_PR --> PAG_Merged: Auto-merge
    
    PIX_Merged --> [*]
    PAG_Merged --> [*]
    
    Testing --> Failed: Testes falharam
    Publishing --> Failed: Publish falhou
    PIX_Processing --> Failed: Testes falharam
    PAG_Processing --> Failed: Testes falharam
    
    Failed --> [*]: Correção necessária
```

---

## 📊 Comparação: Antes vs Depois

```mermaid
flowchart TB
    subgraph Antes["❌ Processo Manual (Antes)"]
        direction TB
        A1[SDK atualizado] --> A2[Dev percebe manualmente]
        A2 --> A3[Abre PR em cada mini-app]
        A3 --> A4[Atualiza package.json]
        A4 --> A5[Roda testes manualmente]
        A5 --> A6[Solicita review]
        A6 --> A7[Merge manual]
        A7 --> A8["⏱️ ~2-4 horas por mini-app"]
    end
    
    subgraph Depois["✅ Processo Automatizado (Depois)"]
        direction TB
        B1[SDK atualizado + tag] --> B2[Workflow automático]
        B2 --> B3[Notifica todos mini-apps]
        B3 --> B4[PRs criados automaticamente]
        B4 --> B5[Testes executados]
        B5 --> B6[Auto-merge patches/minor]
        B6 --> B7["⏱️ ~5-10 minutos total"]
    end
    
    style Antes fill:#ffebee
    style Depois fill:#e8f5e9
```

---

## 🔔 Configuração do Repository Dispatch

```mermaid
flowchart LR
    subgraph SDK["SDK Repository"]
        A["sdk-release.yml"]
        B["curl POST dispatch"]
    end
    
    subgraph Payload["📦 Payload JSON"]
        C["event_type: sdk.update"]
        D["client_payload.version"]
        E["client_payload.changes"]
    end
    
    subgraph Consumers["Mini-Apps"]
        F["on: repository_dispatch"]
        G["types: [sdk.update]"]
        H["github.event.client_payload"]
    end
    
    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
    
    style SDK fill:#e1f5fe
    style Payload fill:#fff3e0
    style Consumers fill:#e8f5e9
```

---

## 📈 Métricas de Sucesso

| Métrica | Antes | Depois | Melhoria |
|---------|-------|--------|----------|
| Tempo para propagar SDK | 2-4 horas | 5-10 min | **95%** |
| Intervenção manual | Sempre | Só majors | **80%** |
| Erros de sincronização | Frequentes | Raros | **90%** |
| Cobertura de testes | Manual | Automática | **100%** |

---

## 🔗 Links Relacionados

- [HANDS-ON-GUIDE.md](./HANDS-ON-GUIDE.md) - Guia passo-a-passo
- [TESTING-GUIDE.md](./TESTING-GUIDE.md) - Guia de testes E2E
- [troubleshooting.md](./troubleshooting.md) - Resolução de problemas
- [adding-consumer.md](./adding-consumer.md) - Como adicionar mini-apps
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Arquitetura detalhada

---

## ✅ Resumo

Este sistema de automação elimina a necessidade de sincronização manual entre SDK e mini-apps, garantindo:

1. **Propagação automática** de atualizações
2. **Testes de compatibilidade** executados automaticamente
3. **PRs criados sem intervenção** humana
4. **Auto-merge** para atualizações seguras (patch/minor)
5. **Notificação** em caso de breaking changes

> **💡 Dica:** Execute o [hands-on](./HANDS-ON-GUIDE.md) para ver todo este fluxo funcionando na prática!
