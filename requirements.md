---
Title: Zeabur AI Hub LiteLLM Upgrade
---

> Original Document: [Zeabur AI Hub LiteLLM Upgrade](https://zeabur.notion.site/Zeabur-AI-Hub-LiteLLM-Upgrade-307a221c948e80e5bd6bd917216619b2)

# 前情提要

Zeabur AI Hub 是 Zeabur 平台上的 AI 模型聚合服務，底層基於 LiteLLM 建構，為使用者提供統一的 API 介面來存取多家 LLM 供應商的模型。LiteLLM 作為開源專案由 BerriAI 維護，迭代頻率極高，新版本會持續修復效能問題、安全漏洞，並改善既有功能特性。

目前 Zeabur AI Hub 使用的 LiteLLM 映像檔版本為 v1.79.0-stable（發布於 2025 年 10 月 26 日），而上游已經持續發布了多個穩定版本。長時間不升級可能意味著已知的效能問題未修復、安全性修補未套用，以及部分功能特性和 bug fix 無法受益。

我們目前已經確認存在的一個具體問題是：Gemini thinking mode 下的 thought_signature 處理缺陷。當 OpenClaw 等用戶端透過 OpenAI 格式發送請求到 Zeabur AI Hub (LiteLLM) 時，LiteLLM 在轉換為 Vertex AI 格式的過程中，未能正確產生或傳遞 Gemini 要求的 `thought_signature`，導致長對話（如 307 個 block）情境下回傳 HTTP 503 錯誤。這是 LiteLLM 端的 bug，官方已在後續版本中透過以下兩個 PR 修復：

- [PR #16895](https://github.com/BerriAI/litellm/pull/16895)（merged 2025-11-21，included in v1.80.5-nightly）— 將 Gemini thought signature 儲存在 tool call id 中，使用戶端能自動回傳
- [PR #18374](https://github.com/BerriAI/litellm/pull/18374)（merged 2025-12-23，included in v1.80.12-nightly）— 將該功能從實驗狀態提升為正式功能，並新增 pre-call hook

關於 LiteLLM 的詳細介紹，可以參考 [LiteLLM 官方文件](https://docs.litellm.ai/)。

# 需求說明

本次任務的核心目標是：將 LiteLLM 從 v1.79.0-stable 升級到最新穩定版本，確保 downtime 盡量少，升級後所有功能和資料都正常。

## 已知問題

升級需要驗證修復的已知問題：

### Gemini thought_signature 503 錯誤

```json
{
  "error": {
    "message": "litellm.ServiceUnavailableError: litellm.MidStreamFallbackError: litellm.BadRequestError: Vertex_ai_betaException BadRequestError - {\"error\": {\"code\": 400, \"message\": \"Unable to submit request because function call read in the 307. content block is missing a thought_signature. Learn more: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/thought-signatures\", \"status\": \"INVALID_ARGUMENT\"}}. Received Model Group=gemini-3-pro-preview\nAvailable Model Group Fallbacks=None",
    "type": null,
    "param": null,
    "code": "503"
  }
}
```

#### Google Vertex AI error (Extracted from LiteLLM logs)

```json
{
  "error": {
    "code": 400,
    "message": "Unable to submit request because function call read in the 307. content block is missing a thought_signature. Learn more: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/thought-signatures",
    "status": "INVALID_ARGUMENT"
  }
}
```

該問題由 [PR #16895](https://github.com/BerriAI/litellm/pull/16895) 和 [PR #18374](https://github.com/BerriAI/litellm/pull/18374) 修復，升級後需驗證此情境是否正常運作。

## 任務要求

請按以下步驟完成升級方案的調研與執行：

### 第一階段：環境準備與舊版本運行驗證

1. 在本機環境安裝並運行當前版本 v1.79.0-stable 的 LiteLLM
2. 記錄當前 LiteLLM 使用的完整設定（config.yaml、環境變數、資料庫 schema 等）
3. 盤點當前正在使用的功能清單（模型列表、API 端點、驗證方式等）
4. 建立功能迴歸測試基準線：記錄各核心功能的預期行為

### 第二階段：版本差異分析與升級方案設計

1. 確認上游最新穩定版本號，逐版本閱讀 [Release Notes](https://github.com/BerriAI/litellm/releases)
2. 標記與當前使用情境相關的變更，識別所有潛在的 breaking changes 並記錄影響範圍
3. 重點檢查資料庫 schema 變更：比對 Prisma migration files，詳細記錄每個版本引入的資料庫異動
4. 檢查設定檔格式是否有變更
5. 檢查相依套件版本變更（如 FastAPI、Starlette 等）是否影響現有功能
6. 輸出一份詳細的版本變更 changelog，包含：升級帶來的新功能、bug fix、效能改善、breaking changes、資料庫遷移項目
7. 設計升級方案，明確：回滾策略、資料遷移步驟、預估 downtime

### 第三階段：遠端環境升級驗證

> **變更說明**：線上版本為「本機環境升級驗證」，但考量開發者本機環境可能為 macOS (ARM) 等非 Linux x86 架構，升級驗證應在 **可控的 Linux x86 伺服器** 上進行，以確保與生產部署環境一致，避免架構差異導致的問題漏測。

1. 在遠端 Docker 環境中執行升級（從 v1.79.0 → 最新穩定版）
2. 執行資料庫遷移，驗證資料完整性
3. 執行功能迴歸測試，逐項確認核心功能正常
4. 驗證已知問題修復：建構 Gemini thinking mode + 長對話情境，確認 thought_signature 問題已解決
5. 進行基本負載測試，比對升級前後的效能指標
6. 記錄升級過程中遇到的所有問題及解決方案

### 第四階段：方案交付與上線建議

輸出完整的升級方案文件，包含：

- 版本變更 changelog（新功能、bug fix、效能改善、breaking changes）
- 資料庫遷移說明（逐版本的 schema 異動記錄）
- 設定變更對照表
- 升級步驟（step-by-step）
- 回滾方案
- 預估 downtime 及減少 downtime 的策略（如藍綠部署、滾動更新）
- 測試報告（含已知問題驗證結果）

如果評估後認為無法進行升級，需要詳細說明原因，包括具體的技術障礙和風險點。

## 升級原則

1. **Downtime 盡量少**：優先考慮能實現零停機或近零停機的升級方案
2. **資料安全第一**：升級前必須完成資料庫備份，確保可回滾
3. **功能完整性**：升級後所有現有功能必須正常運作
4. **善用 AI**：鼓勵使用 Claude、Cursor 等 AI 工具輔助程式碼審查、設定遷移和問題排查

## 你會需要

- LiteLLM 官方儲存庫：<https://github.com/BerriAI/litellm>
- LiteLLM 官方文件：<https://docs.litellm.ai/>
- LiteLLM Release Notes：<https://github.com/BerriAI/litellm/releases>
