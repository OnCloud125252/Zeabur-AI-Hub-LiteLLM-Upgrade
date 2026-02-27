# Zeabur AI Hub LiteLLM Upgrade

> LiteLLM v1.79.0-stable → v1.81.12-stable.1 Upgrade Documentation

---

## Overview

This repository documents the complete upgrade process for Zeabur AI Hub's underlying LiteLLM infrastructure. The upgrade addresses the critical Gemini `thought_signature` 503 error while incorporating 4 months of performance improvements, security patches, and new features.

### The Problem

When OpenClaw and other clients sent requests via OpenAI format to Zeabur AI Hub (LiteLLM), LiteLLM failed to properly generate or pass the `thought_signature` required by Gemini during conversion to Vertex AI format. This caused HTTP 503 errors in long conversations (e.g., 307 content blocks).

```json
{
  "error": {
    "message": "...function call read in the 307. content block is missing a thought_signature...",
    "code": "503"
  }
}
```

### The Solution

Fixed by two upstream PRs:
- [PR #16895](https://github.com/BerriAI/litellm/pull/16895) — Stores Gemini thought signatures in tool call IDs
- [PR #18374](https://github.com/BerriAI/litellm/pull/18374) — Promotes feature from experimental to stable

---

## 概覽

本儲存庫記錄 Zeabur AI Hub 底層 LiteLLM 基礎設施的完整升級過程。此次升級解決了關鍵的 Gemini `thought_signature` 503 錯誤，同時納入 4 個月的效能改善、安全修補與新功能。

### 問題說明

當 OpenClaw 等客戶端透過 OpenAI 格式發送請求到 Zeabur AI Hub（LiteLLM）時，LiteLLM 在轉換為 Vertex AI 格式的過程中，未能正確產生或傳遞 Gemini 要求的 `thought_signature`，導致長對話（如 307 個 content block）出現 HTTP 503 錯誤。

### 解決方案

透過兩個上游 PR 修復：
- **PR #16895** — 將 Gemini thought signature 儲存在 tool call ID 中
- **PR #18374** — 將該功能從實驗狀態提升為正式功能

---

## Documentation Structure

```
.
├── README.md                    # Documentation homepage (this file)
├── SUMMARY.md                   # Quick reference / table of contents
│
├── guides/                      # How-to guides
│   ├── README.md               # Guides index
│   ├── documentation-guide.md  # Documentation standards
│   ├── python-setup.md         # Python/UV setup instructions
│   └── remote-docker-server.md # Remote Docker environment usage
│
├── research/                    # Research & analysis
│   ├── README.md               # Research index
│   ├── upgrade-changelog-v1.79-to-v1.81.md
│   ├── db-schema-migration-v1.79-to-v1.81.md
│   ├── pr-16895.md
│   ├── pr-18374.md
│   └── pr-compatibility.md
│
├── reports/                     # Phase reports
│   ├── README.md               # Reports index
│   ├── 1-environment-report.md # Phase 1: Baseline
│   ├── 2-upgrade-plan.md       # Phase 2: Planning
│   ├── 3-verification-report.md# Phase 3: Verification
│   └── 4-delivery-report.md    # Phase 4: Delivery
│   └── 4a-4g-*.md              # Delivery sub-documents
│
├── testing/                     # Testing documentation
│   ├── README.md               # Testing index
│   ├── local/                  # Local testing environment
│   └── remote/                 # Remote Docker deployment
│
└── test-outputs/                # Test results
    └── README.md               # Test results index
```

---

## Quick Navigation

### For Operations / 運維人員

| Document | Purpose |
|----------|---------|
| [reports/4d-upgrade-steps.md](reports/4d-upgrade-steps.md) | Step-by-step upgrade guide |
| [reports/4e-rollback-plan.md](reports/4e-rollback-plan.md) | Emergency rollback procedures |
| [reports/4b-db-migration-guide.md](reports/4b-db-migration-guide.md) | Database migration with SQL scripts |
| [reports/4f-downtime-strategy.md](reports/4f-downtime-strategy.md) | Downtime minimization strategies |

### For Developers / 開發人員

| Document | Purpose |
|----------|---------|
| [guides/python-setup.md](guides/python-setup.md) | Python/UV development setup |
| [guides/remote-docker-server.md](guides/remote-docker-server.md) | Remote Docker environment |
| [testing/local/README.md](testing/local/README.md) | Local testing guide |

### For Technical Leaders / 技術負責人

| Document | Purpose |
|----------|---------|
| [research/upgrade-changelog-v1.79-to-v1.81.md](research/upgrade-changelog-v1.79-to-v1.81.md) | Complete version changelog |
| [reports/4a-changelog.md](reports/4a-changelog.md) | Executive summary of changes |
| [reports/4g-test-report.md](reports/4g-test-report.md) | Test results and verification |

---

## Key Findings

| Metric | Result |
|--------|--------|
| **Regression Tests** | 28/28 passed across all versions |
| **thought_signature Fix** | Confirmed — tool call IDs include `__thought__` signature |
| **Performance Impact** | Within ±5% (no regression) |
| **Database Migration** | 28 → 55 tables, 95% additive changes |
| **Rollback Safety** | Confirmed — v1.79.0 runs on migrated DB |
| **Breaking Changes** | 7 items (Docker image, health check, defaults) |
| **Recommended Deployment** | Blue-Green, < 30 seconds downtime |

---

## Version Analysis Summary

**11 releases analyzed** from October 2025 to February 2026:

| Version | Release Date | Key Changes |
|---------|--------------|-------------|
| v1.79.0-stable | 2025-10-26 | Current baseline |
| v1.80.5-stable | 2025-12-03 | PR #16895 thought_signature initial fix |
| v1.80.11-stable | 2026-01-10 | PR #18374 thought_signature finalized |
| v1.81.12-stable.1 | 2026-02-24 | Target version |

See [research/upgrade-changelog-v1.79-to-v1.81.md](research/upgrade-changelog-v1.79-to-v1.81.md) for complete details.

---

## Repository Information

- **Original Document**: [Zeabur AI Hub LiteLLM Upgrade](https://zeabur.notion.site/Zeabur-AI-Hub-LiteLLM-Upgrade-307a221c948e80e5bd6bd917216619b2)
- **Target Version**: v1.81.12-stable.1
- **Source Version**: v1.79.0-stable
- **Upstream Repository**: https://github.com/BerriAI/litellm
- **Upstream Documentation**: https://docs.litellm.ai/

---

## Contributing

When adding new documentation:

1. Follow the patterns in [guides/documentation-guide.md](guides/documentation-guide.md)
2. Use Traditional Chinese for descriptions and internal documentation
3. Use English for technical terms, code references, and PR titles
4. Place research documents in `research/`
5. Place deliverables in `reports/`

---

*This documentation is maintained for the Zeabur AI Hub LiteLLM upgrade project.*
