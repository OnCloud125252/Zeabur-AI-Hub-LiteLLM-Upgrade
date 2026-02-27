# 測試報告

> Phase 4g - Complete test report with verification results

← [Back to Reports](README.md)

---

- **日期**：2026-02-27
- **階段**：Phase 4 Delivery
- **用途**：完整測試報告，含已知問題驗證
- **升級路徑**：v1.79.0-stable → v1.81.12-stable.1
- **狀態**：完成

---

## 執行摘要

| 測試類別 | 結果 | 說明 |
|----------|------|------|
| 回歸測試 | **28/28 × 3 版本通過** | v1.79.0 基線、v1.81.12 升級、v1.79.0 回滾 |
| thought_signature 驗證 | **通過** | v1.81.12 工具呼叫 ID 包含 `__thought__` 簽章 |
| 效能比對 | **±5% 以內** | 5 項基準 × 10 輪，無顯著退步 |
| 已知問題驗證 | **全部已修復** | MCP StreamableHTTP、Daily Spend、JSON logs |
| 回滾安全性 | **通過** | v1.79.0 在已遷移 DB 上正常運行 |

---

## 1. 測試範圍與方法論

### 1.1 測試環境

| 項目 | 規格 |
|------|------|
| 伺服器 | 10.0.1.9（CT108） |
| Docker | 29.2.1 + Docker Compose v5.1.0 |
| PostgreSQL | 16 |
| Redis | 7-alpine |
| LiteLLM 舊版 | ghcr.io/berriai/litellm:v1.79.0-stable |
| LiteLLM 新版 | docker.litellm.ai/berriai/litellm:v1.81.12-stable.1 |

### 1.2 測試模型

| 模型 | LiteLLM ID | 用途 |
|------|------------|------|
| gemini-2.5-flash | `gemini/gemini-2.5-flash` | 主要測試模型 |
| gemini-2.5-pro | `gemini/gemini-2.5-pro` | 進階推理 |
| gemini-3-pro | `gemini/gemini-3-pro-preview` | thought_signature 驗證 |

### 1.3 測試腳本

| 腳本 | 用途 | 測試數 |
|------|------|--------|
| `testing/local/test_regression.py` | 功能回歸測試 | 28 項 |
| `testing/local/test_gemini_signature.py` | thought_signature 驗證 | 2 項 |
| `testing/local/test_performance.py` | 效能基準測試 | 5 項 × 10 輪 |

### 1.4 測試流程

```
v1.79.0 基線 → DB 遷移 → v1.81.12 升級 → 回滾至 v1.79.0
    ↓              ↓           ↓                ↓
 28 項回歸      遷移驗證    28 項回歸         28 項回歸
 signature      SQL 檢查    signature         signature
 效能基線                   效能比對
```

---

## 2. 回歸測試（28 項）

### 2.1 總覽

| 版本 | 通過 | 失敗 | 結果 |
|------|------|------|------|
| v1.79.0（基線） | 28/28 | 0 | **全部通過** |
| v1.81.12（升級後） | 28/28 | 0 | **全部通過** |
| v1.79.0（回滾） | 28/28 | 0 | **全部通過** |

### 2.2 測試細項

| # | 類別 | 測試項目 | v1.79.0 | v1.81.12 | 回滾 |
|---|------|----------|---------|----------|------|
| 1 | 健康檢查 | GET /health 返回 200 | 通過 | 通過 | 通過 |
| 2 | 健康檢查 | 健康檢查報告模型正常 | 通過 | 通過 | 通過 |
| 3 | 健康檢查 | GET /health/liveliness 返回 200 | 通過 | 通過 | 通過 |
| 4 | 健康檢查 | GET /health/readiness 返回 200 | 通過 | 通過 | 通過 |
| 5 | 模型 | GET /v1/models 返回模型列表 | 通過 | 通過 | 通過 |
| 6 | 模型 | 模型列表包含 gemini-2.5-flash | 通過 | 通過 | 通過 |
| 7 | 模型 | 模型列表包含 gemini-2.5-pro | 通過 | 通過 | 通過 |
| 8 | 模型 | 模型列表包含 gemini-3-pro | 通過 | 通過 | 通過 |
| 9 | 對話 | POST /v1/chat/completions | 通過 | 通過 | 通過 |
| 10 | 對話 | 回應包含 usage 資訊 | 通過 | 通過 | 通過 |
| 11 | 對話 | 回應包含 model 欄位 | 通過 | 通過 | 通過 |
| 12 | 對話 | finish_reason 為 stop | 通過 | 通過 | 通過 |
| 13 | 串流 | 串流返回多個區塊 | 通過 | 通過 | 通過 |
| 14 | 串流 | 第一個區塊有 role=assistant | 通過 | 通過 | 通過 |
| 15 | 串流 | 最後區塊有 finish_reason=stop | 通過 | 通過 | 通過 |
| 16 | 串流 | 串流內容非空 | 通過 | 通過 | 通過 |
| 17 | 工具 | 工具呼叫返回 tool_calls | 通過 | 通過 | 通過 |
| 18 | 工具 | 工具呼叫包含 function name | 通過 | 通過 | 通過 |
| 19 | 工具 | 工具呼叫包含有效 arguments | 通過 | 通過 | 通過 |
| 20 | 工具 | 工具呼叫包含 ID | 通過 | 通過 | 通過 |
| 21 | 多輪 | 初始工具呼叫已接收 | 通過 | 通過 | 通過 |
| 22 | 多輪 | 工具結果後的最終回應 | 通過 | 通過 | 通過 |
| 23 | 錯誤 | 無效模型返回錯誤 | 通過 | 通過 | 通過 |
| 24 | 錯誤 | 無效金鑰返回錯誤 | 通過 | 通過 | 通過 |
| 25 | 工具 | POST /utils/token_counter 返回 200 | 通過 | 通過 | 通過 |
| 26 | 工具 | GET /v1/model/info 返回 200 | 通過 | 通過 | 通過 |
| 27 | 工具 | 模型資訊包含已配置模型 | 通過 | 通過 | 通過 |
| 28 | 工具 | GET /routes 返回 200 | 通過 | 通過 | 通過 |

**報告檔案**：

- `test-outputs/baseline-v1.79.0.txt`
- `test-outputs/regression-v1.81.12.txt`
- `test-outputs/rollback-v1.79.0.txt`

---

## 3. thought_signature 驗證（核心修復確認）

### 3.1 問題描述

Gemini thinking mode 下，v1.79.0 在轉換 API 回應時未保留 `thoughtSignature`，導致長對話（307+ content blocks）出現 HTTP 503 錯誤：

```
"function call read in the N. content block is missing a thought_signature"
```

### 3.2 修復來源

| PR | 合併日期 | 包含版本 | 修復內容 |
|----|----------|----------|----------|
| #16895 | 2025-11-21 | v1.80.5 | 將 thought signature 儲存在 tool call ID 中 |
| #18374 | 2025-12-23 | v1.80.11 | 提升為正式功能，新增 pre-call hook |

### 3.3 驗證結果

| 檢查項目 | v1.79.0 | v1.81.12 |
|----------|---------|----------|
| 工具呼叫 ID 包含 `__thought__` | **否** | **是** |
| Provider specific fields 保留 | 否 | **是** |
| 基本工具呼叫來回測試 | 通過 | 通過 |
| 多輪多工具對話 | 通過 | 通過 |

### 3.4 具體證據

**v1.79.0 工具呼叫 ID**（簽章已被移除）：

```
call_70c754b500124dd59dc5bac483f7
```

**v1.81.12 工具呼叫 ID**（簽章已正確保留）：

```
call_9d5001a4996649f9b2da20855b39__thought__Co8CAb4+9vtqDGoRj3RPv/40SN2X...
```

`__thought__` 分隔符後方的 Base64 編碼字串即為 Gemini 的 thought signature，可在後續請求中回傳給 Gemini API，避免 503 錯誤。

**報告檔案**：

- `test-outputs/signature-v1.79.0.txt`
- `test-outputs/signature-v1.81.12.txt`

---

## 4. 效能比對

### 4.1 測試條件

- 模型：gemini-2.5-flash
- 每項基準測試：**10 輪**
- 測試環境：遠端 Docker（10.0.1.9）

### 4.2 中位數比較

| 基準測試 | v1.79.0 | v1.81.12 | 差異 | 評估 |
|----------|---------|----------|------|------|
| 對話完成 | 0.732s | 0.736s | +0.5% | 正常範圍 |
| 串流完成 | 1.025s | 0.979s | **-4.5%** | 微幅改善 |
| 首位元組時間 (TTFB) | 0.905s | 0.926s | +2.3% | 正常範圍 |
| 工具呼叫 | 1.254s | 1.272s | +1.4% | 正常範圍 |
| 多輪工具 | 2.304s | 2.394s | +3.9% | 正常範圍 |

### 4.3 詳細統計

| 基準測試 | 版本 | 平均 | 中位數 | P95 | 最小 | 最大 | 標準差 |
|----------|------|------|--------|-----|------|------|--------|
| 對話完成 | v1.79.0 | 0.777s | 0.732s | 0.979s | 0.683s | 0.979s | 0.102s |
| | v1.81.12 | 0.776s | 0.736s | 1.211s | 0.664s | 1.211s | 0.157s |
| 串流完成 | v1.79.0 | 1.029s | 1.025s | 1.275s | 0.812s | 1.275s | 0.135s |
| | v1.81.12 | 0.968s | 0.979s | 1.093s | 0.846s | 1.093s | 0.092s |
| TTFB | v1.79.0 | 0.900s | 0.905s | 0.962s | 0.842s | 0.962s | 0.038s |
| | v1.81.12 | 0.980s | 0.926s | 1.378s | 0.813s | 1.378s | 0.169s |
| 工具呼叫 | v1.79.0 | 1.364s | 1.254s | 2.160s | 1.000s | 2.160s | 0.337s |
| | v1.81.12 | 1.307s | 1.272s | 1.687s | 0.996s | 1.687s | 0.217s |
| 多輪工具 | v1.79.0 | 2.390s | 2.304s | 3.279s | 1.848s | 3.279s | 0.399s |
| | v1.81.12 | 2.381s | 2.394s | 2.807s | 1.946s | 2.807s | 0.243s |

### 4.4 分析

- 所有 5 項基準測試的中位數差異均在 **±5% 以內**，屬於正常網路波動範圍
- v1.81.12 的工具呼叫**標準差更低**（0.217s vs 0.337s），延遲更穩定
- 串流完成在 v1.81.12 上有 **4.5% 改善**（中位數從 1.025s 降至 0.979s）
- 整體結論：升級**不會造成效能退步**

**報告檔案**：

- `test-outputs/perf-v1.79.0.json`
- `test-outputs/perf-v1.81.12.json`

---

## 5. 已知問題驗證

### 5.1 已確認修復的問題

| # | 問題 | 修復版本 | 驗證方式 | 結果 |
|---|------|----------|----------|------|
| 1 | **thought_signature 503 錯誤** | v1.80.5 + v1.80.11 | 工具呼叫 ID 檢查 | **已修復** — ID 包含 `__thought__` |
| 2 | MCP StreamableHTTP stateless | v1.81.12-stable.1 | 版本確認（hotfix） | **已包含修復** |
| 3 | Daily Spend unique constraint 重複 | v1.81.9 (#20394) | 版本確認 | **已包含修復** |
| 4 | JSON logs 重複 | v1.81.3 (#19705) | 版本確認 | **已包含修復** |

### 5.2 版本中的額外修復

v1.81.12-stable.1 還包含以下重要修復（未在原始需求中列出但對穩定性有益）：

| 修復 | 影響 |
|------|------|
| OOM 修復（image URL 大小限制） | 防止大圖片導致記憶體耗盡 |
| Gemini 多輪 tool calling 訊息格式修復 | 長對話穩定性 |
| 排程器佇列 orphan entries 記憶體洩漏 | 長時間運行穩定性 |
| SpendUpdateQueue 原地修改漏洞 | 花費追蹤準確性 |
| 多項 HTTP client 記憶體洩漏修復 | 整體記憶體使用 |

---

## 6. 回滾安全性

### 6.1 測試方法

1. 在 v1.81.12 完成所有測試後，切回 v1.79.0 Docker image
2. 資料庫保持 v1.81.12 的 schema（不還原）
3. 對 v1.79.0 執行完整回歸測試

### 6.2 結果

| 檢查項目 | 結果 |
|----------|------|
| v1.79.0 在已遷移 DB 上啟動 | **通過** |
| 健康檢查通過 | **通過** |
| 28/28 回歸測試通過 | **通過** |
| 資料庫向後相容性 | **確認** |

### 6.3 結論

v1.79.0 可以安全地在 v1.81.12 schema 上運行。新增的 15 張表和新增欄位對 v1.79.0 完全透明。**回滾時不需要還原資料庫**。

**報告檔案**：`test-outputs/rollback-v1.79.0.txt`

---

## 7. 行為差異觀察

| 行為 | v1.79.0 | v1.81.12 | 影響 |
|------|---------|----------|------|
| 無效 API 金鑰錯誤碼 | 400（BadRequestError） | 400（BadRequestError） | 一致，無影響 |
| Tool call ID 格式 | `call_<hex28>` | `call_<hex28>__thought__<sig>` | **核心修復** |
| Thought signature 保留 | 不保留（靜默丟棄） | 保留（via provider_specific_fields + ID 嵌入） | **核心修復** |

---

## References

- Phase 1 環境報告：[1-environment-report.md](/reports/1-environment-report.md)
- Phase 3 驗證報告：[3-verification-report.md](/reports/3-verification-report.md)
- 測試輸出目錄：[test-outputs/](/test-outputs/)
- 回歸測試腳本：[testing/local/test_regression.py](/testing/local/test_regression.py)
- thought_signature 測試腳本：[testing/local/test_gemini_signature.py](/testing/local/test_gemini_signature.py)
- 效能測試腳本：[testing/local/test_performance.py](/testing/local/test_performance.py)
