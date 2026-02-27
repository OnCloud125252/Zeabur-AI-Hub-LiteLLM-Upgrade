# 摘要

> LiteLLM 升級文件的快速參考指南

---

## 目錄

- [專案概覽 (README)](README.md)

### 指南

| 文件 | 說明 |
|----------|-------------|
| [文件撰寫指南](guides/documentation-guide.md) | 建立文件的標準規範 |
| [Python 環境設定](guides/python-setup.md) | 使用 UV 的 Python 開發環境 |
| [遠端 Docker 伺服器](guides/remote-docker-server.md) | 遠端環境使用說明 |

### 研究

| 文件 | 說明 |
|----------|-------------|
| [研究索引](research/README.md) | 所有研究文件 |
| [升級變更日誌](research/upgrade-changelog-v1.79-to-v1.81.md) | 11 個版本的變更日誌分析 |
| [資料庫結構遷移](research/db-schema-migration-v1.79-to-v1.81.md) | 資料庫遷移分析 |
| [PR #16895](research/pr-16895.md) | Thought signature 初始修復 |
| [PR #18374](research/pr-18374.md) | Thought signature 最終修復 |
| [PR 相容性](research/pr-compatibility.md) | 相容性矩陣 |

### 階段報告

| 文件 | 階段 | 說明 |
|----------|-------|-------------|
| [報告索引](reports/README.md) | — | 所有報告概覽 |
| [1. 環境報告](reports/1-environment-report.md) | 第一階段 | 基線文件 |
| [2. 升級計畫](reports/2-upgrade-plan.md) | 第二階段 | 規劃與策略 |
| [3. 驗證報告](reports/3-verification-report.md) | 第三階段 | 測試與驗證 |
| [4. 交付報告](reports/4-delivery-report.md) | 第四階段 | 最終交付 |
| [4a. 變更日誌](reports/4a-changelog.md) | 第四階段 | 執行摘要 |
| [4b. 資料庫遷移指南](reports/4b-db-migration-guide.md) | 第四階段 | 資料庫操作 |
| [4c. 設定比較](reports/4c-config-comparison.md) | 第四階段 | 設定變更 |
| [4d. 升級步驟](reports/4d-upgrade-steps.md) | 第四階段 | 逐步指南 |
| [4e. 回滾計畫](reports/4e-rollback-plan.md) | 第四階段 | 緊急回滾 |
| [4f. 停機策略](reports/4f-downtime-strategy.md) | 第四階段 | 最小化停機時間 |
| [4g. 測試報告](reports/4g-test-report.md) | 第四階段 | 測試結果 |

### 測試

| 文件 | 說明 |
|----------|-------------|
| [測試索引](testing/README.md) | 所有測試文件 |
| [本機測試](testing/local/README.md) | 本機測試環境 |
| [遠端測試](testing/remote/README.md) | 遠端 Docker 部署 |
| [測試輸出](test-outputs/README.md) | 測試結果封存 |

---

## 依角色分類

### 維運工程師

1. 從 [4d-upgrade-steps.md](reports/4d-upgrade-steps.md) 開始了解升級程序
2. 檢閱 [4e-rollback-plan.md](reports/4e-rollback-plan.md) 了解緊急處理程序
3. 參考 [4b-db-migration-guide.md](reports/4b-db-migration-guide.md) 進行資料庫操作

### 開發人員

1. 閱讀 [guides/python-setup.md](guides/python-setup.md) 設定開發環境
2. 遵循 [testing/local/README.md](testing/local/README.md) 進行測試
3. 參閱 [guides/documentation-guide.md](guides/documentation-guide.md) 了解文件標準

### 技術主管

1. 檢閱 [reports/4-delivery-report.md](reports/4-delivery-report.md) 了解執行摘要
2. 查看 [research/upgrade-changelog-v1.79-to-v1.81.md](research/upgrade-changelog-v1.79-to-v1.81.md) 了解技術細節
3. 確認 [reports/4g-test-report.md](reports/4g-test-report.md) 的測試覆蓋率

---

## 外部資源

- [LiteLLM 儲存庫](https://github.com/BerriAI/litellm)
- [LiteLLM 文件](https://docs.litellm.ai/)
- [LiteLLM 發布版本](https://github.com/BerriAI/litellm/releases)
- [原始 Notion 文件](https://zeabur.notion.site/Zeabur-AI-Hub-LiteLLM-Upgrade-307a221c948e80e5bd6bd917216619b2)
