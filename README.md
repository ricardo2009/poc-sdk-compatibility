# 🎯 SDK Ecosystem Registry

Central registry for the SuperApp SDK ecosystem. This repository serves as the single source of truth for:

- **Consumer Registry**: List of all mini-apps that participate in the SDK ecosystem
- **E2E Testing**: Workflow to test the complete SDK update flow

---

## 📋 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        SDK RELEASE FLOW                             │
└─────────────────────────────────────────────────────────────────────┘

  ┌───────────────────┐
  │ superapp-sdk-poc  │
  │  (SDK Package)    │
  └─────────┬─────────┘
            │
            │ 1. Push tag v*
            ▼
  ┌───────────────────┐
  │  sdk-release.yml  │──────┐
  │                   │      │ 2. Load consumers
  └─────────┬─────────┘      │
            │                ▼
            │      ┌───────────────────────┐
            │      │ poc-sdk-compatibility │
            │      │  consumers.yml        │
            │      └───────────────────────┘
            │
            │ 3. Dispatch webhook (sdk.update)
            ▼
  ┌─────────────────────────────────────────┐
  │              Mini-Apps                   │
  │  ┌─────────────┐   ┌─────────────────┐  │
  │  │ miniapp-pix │   │ miniapp-pagam.. │  │
  │  └──────┬──────┘   └────────┬────────┘  │
  │         │                   │           │
  │         ▼                   ▼           │
  │  sdk-update-handler   sdk-update-handler│
  │         │                   │           │
  │         ▼                   ▼           │
  │      ✅ PR               ✅ PR          │
  │      ⚠️ Issue            ⚠️ Issue       │
  │      📢 Notify           📢 Notify      │
  └─────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```
poc-sdk-compatibility/
├── .compatibility/
│   └── consumers.yml      # 📋 Registry of all mini-apps
├── .github/
│   └── workflows/
│       └── e2e-test.yml   # 🧪 E2E test workflow
└── README.md              # 📖 This file
```

---

## 📋 Consumer Registry

The `consumers.yml` file lists all mini-apps that should be notified when SDK releases:

```yaml
# .compatibility/consumers.yml
consumers:
  - repo: "ricardo2009/miniapp-pix-poc"
    name: "PIX Mini-App"
    team: "@pix-team"
    
  - repo: "ricardo2009/miniapp-pagamentos-poc"
    name: "Pagamentos Mini-App"
    team: "@pagamentos-team"
```

### Adding a New Mini-App

1. Add entry to `consumers.yml`
2. Create `.sdk-ecosystem.yml` in the mini-app root
3. Add `sdk-update-handler.yml` workflow to the mini-app

---

## 🧪 Testing the Flow

### Option 1: Using E2E Test Workflow

```bash
# Trigger E2E test via GitHub CLI
gh workflow run "e2e-test.yml" \
  --repo ricardo2009/poc-sdk-compatibility \
  -f version="2.0.0" \
  -f is_breaking="true"
```

### Option 2: Create a Real SDK Tag

```bash
cd superapp-sdk-poc
git tag v1.2.3
git push origin v1.2.3
```

### Expected Results

1. **SDK Repository**: `sdk-release.yml` runs
2. **Mini-Apps**: Receive `repository_dispatch` event
3. **PRs Created**: Branch `sdk-update/v{version}` with updated package.json
4. **Issues Created**: If breaking change, urgent issue opened
5. **Notifications**: Reviewers assigned, comments added

---

## 🔧 Workflow Files Reference

| Repository | Workflow | Purpose |
|------------|----------|---------|
| `superapp-sdk-poc` | `sdk-release.yml` | Detects release, notifies ecosystem |
| `miniapp-*-poc` | `sdk-update-handler.yml` | Receives webhook, creates PR/Issue |
| `poc-sdk-compatibility` | `e2e-test.yml` | Triggers test of complete flow |

---

## 📊 Mini-App Configuration

Each mini-app has `.sdk-ecosystem.yml` at root:

```yaml
sdk:
  package: "@ricardo2009/superapp-sdk-poc"
  update_rules:
    max_versions_behind: 3     # How many versions can be behind
    auto_merge: patch          # none/patch/minor/all
    auto_create_pr: true       # Auto-create PR on SDK update
    create_issue_on_breaking: true  # Create issue for breaking changes

team:
  name: "PIX Team"
  reviewers:
    - "ricardo2009"
    
notifications:
  slack_channel: "#pix-alerts"
  
exports_used:
  - httpRequest
  - Logger
  - useTrackScreen
```

---

## 🚀 Quick Start

### 1. Check Current Consumer List

```bash
cat .compatibility/consumers.yml
```

### 2. Run E2E Test

```bash
gh workflow run e2e-test.yml -f version="2.1.0" -f is_breaking="true"
```

### 3. Monitor Results

- [SDK Actions](https://github.com/ricardo2009/superapp-sdk-poc/actions)
- [PIX PRs](https://github.com/ricardo2009/miniapp-pix-poc/pulls)
- [Pagamentos PRs](https://github.com/ricardo2009/miniapp-pagamentos-poc/pulls)

---

## 📝 Changelog

| Date | Change |
|------|--------|
| 2025-01 | Initial simplified architecture |
| 2025-01 | Removed complex orchestration workflows |
| 2025-01 | Focus on single objective: SDK Release → Mini-app Update |

