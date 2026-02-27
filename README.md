# Zeabur AI Hub LiteLLM Upgrade

> LiteLLM v1.79.0-stable → v1.81.12-stable.1 升級文件

---

## 概覽

本儲存庫記錄 Zeabur AI Hub 底層 LiteLLM 基礎設施的完整升級過程。此次升級解決了關鍵的 Gemini `thought_signature` 503 錯誤，同時納入 4 個月的效能改善、安全修補與新功能。

### 問題說明

當 OpenClaw 等客戶端透過 OpenAI 格式發送請求到 Zeabur AI Hub（LiteLLM）時，LiteLLM 在轉換為 Vertex AI 格式的過程中，未能正確產生或傳遞 Gemini 要求的 `thought_signature`，導致長對話（如 307 個 content block）出現 HTTP 503 錯誤。

```json
{
  "error": {
    "message": "...function call read in the 307. content block is missing a thought_signature...",
    "code": "503"
  }
}
```

### 解決方案

透過兩個上游 PR 修復：

- [PR #16895](https://github.com/BerriAI/litellm/pull/16895) — 將 Gemini thought signature 儲存在 tool call ID 中
- [PR #18374](https://github.com/BerriAI/litellm/pull/18374) — 將該功能從實驗狀態提升為正式功能

---

## 文件結構

```
.
├── README.md                    # 文件首頁（本檔案）
├── SUMMARY.md                   # 快速參考 / 目錄
│
├── guides/                      # 操作指南
│   ├── README.md               # 指南索引
│   ├── documentation-guide.md  # 文件標準
│   ├── python-setup.md         # Python/UV 設定說明
│   └── remote-docker-server.md # 遠端 Docker 環境使用方式
│
├── research/                    # 研究與分析
│   ├── README.md               # 研究索引
│   ├── upgrade-changelog-v1.79-to-v1.81.md
│   ├── db-schema-migration-v1.79-to-v1.81.md
│   ├── pr-16895.md
│   ├── pr-18374.md
│   └── pr-compatibility.md
│
├── reports/                     # 階段報告
│   ├── README.md               # 報告索引
│   ├── 1-environment-report.md # 階段 1：基線
│   ├── 2-upgrade-plan.md       # 階段 2：規劃
│   ├── 3-verification-report.md# 階段 3：驗證
│   └── 4-delivery-report.md    # 階段 4：交付
│   └── 4a-4g-*.md              # 交付子文件
│
├── testing/                     # 測試文件
│   ├── README.md               # 測試索引
│   ├── local/                  # 本機測試環境
│   └── remote/                 # 遠端 Docker 部署
│
└── test-outputs/                # 測試結果
    └── README.md               # 測試結果索引
```

---

## 快速導覽

### 運維人員

| 文件 | 用途 |
|----------|---------|
| [reports/4d-upgrade-steps.md](reports/4d-upgrade-steps.md) | 逐步升級指南 |
| [reports/4e-rollback-plan.md](reports/4e-rollback-plan.md) | 緊急回滾程序 |
| [reports/4b-db-migration-guide.md](reports/4b-db-migration-guide.md) | 資料庫遷移含 SQL 腳本 |
| [reports/4f-downtime-strategy.md](reports/4f-downtime-strategy.md) | 停機時間最小化策略 |

### 開發人員

| 文件 | 用途 |
|----------|---------|
| [guides/python-setup.md](guides/python-setup.md) | Python/UV 開發環境設定 |
| [guides/remote-docker-server.md](guides/remote-docker-server.md) | 遠端 Docker 環境 |
| [testing/local/README.md](testing/local/README.md) | 本機測試指南 |

### 技術負責人

| 文件 | 用途 |
|----------|---------|
| [research/upgrade-changelog-v1.79-to-v1.81.md](research/upgrade-changelog-v1.79-to-v1.81.md) | 完整版本變更日誌 |
| [reports/4a-changelog.md](reports/4a-changelog.md) | 變更摘要 |
| [reports/4g-test-report.md](reports/4g-test-report.md) | 測試結果與驗證 |

---

## 主要發現

| 指標 | 結果 |
|--------|--------|
| **迴歸測試** | 28/28 通過所有版本 |
| **thought_signature 修復** | 已確認 — tool call ID 包含 `__thought__` 簽名 |
| **效能影響** | 在 ±5% 範圍內（無迴歸） |
| **資料庫遷移** | 28 → 55 張表格，95% 為新增變更 |
| **回滾安全性** | 已確認 — v1.79.0 可在遷移後的資料庫上執行 |
| **重大變更** | 7 項（Docker 映像檔、健康檢查、預設值） |
| **建議部署方式** | 藍綠部署，停機時間 < 30 秒 |

---

## 版本分析摘要

**已分析 11 個版本**，從 2025 年 10 月至 2026 年 2 月：

| 版本 | 發布日期 | 主要變更 |
|---------|--------------|-------------|
| v1.79.0-stable | 2025-10-26 | 目前基線版本 |
| v1.80.5-stable | 2025-12-03 | PR #16895 thought_signature 初始修復 |
| v1.80.11-stable | 2026-01-10 | PR #18374 thought_signature 最終修復 |
| v1.81.12-stable.1 | 2026-02-24 | 目標版本 |

詳細資訊請參閱 [research/upgrade-changelog-v1.79-to-v1.81.md](research/upgrade-changelog-v1.79-to-v1.81.md)。

---

## 儲存庫資訊

- **原始文件**：[Zeabur AI Hub LiteLLM Upgrade](https://zeabur.notion.site/Zeabur-AI-Hub-LiteLLM-Upgrade-307a221c948e80e5bd6bd917216619b2)
- **目標版本**：v1.81.12-stable.1
- **來源版本**：v1.79.0-stable
- **上游儲存庫**：<https://github.com/BerriAI/litellm>
- **上游文件**：<https://docs.litellm.ai/>

---

## 貢獻方式

新增文件時請遵循：

1. 遵循 [guides/documentation-guide.md](guides/documentation-guide.md) 中的模式
2. 描述與內部文件使用繁體中文
3. 技術術語、程式碼參考與 PR 標題使用英文
4. 研究文件放置於 `research/`
5. 交付文件放置於 `reports/`

---

*本文件為 Zeabur AI Hub LiteLLM 升級專案所維護。*
