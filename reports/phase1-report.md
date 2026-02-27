# 第一階段報告：環境準備與舊版本運行驗證

**Date**: 2026-02-26
**Purpose**: 記錄 LiteLLM v1.79.0-stable 的完整基準線——設定、功能清單、迴歸測試結果——作為升級驗證的參考基準。

## Summary

第一階段的四項任務全部完成：

| # | 任務 | 狀態 | 成果物 |
|---|------|------|--------|
| 1 | 本機安裝並運行 v1.79.0 | 完成 | venv 環境 + proxy 成功啟動 |
| 2 | 記錄完整設定 | 完成 | config.yaml、環境變數、DB schema（28 張表） |
| 3 | 盤點功能清單 | 完成 | 200+ API 端點、4 種認證方式、11 項核心能力 |
| 4 | 建立迴歸測試基準線 | 完成 | 28 項測試全數通過（v1.79.0 與 v1.80.11 皆通過） |

額外完成了 thought_signature 修復驗證（對應第三階段第 4 項），確認 v1.80.11 包含完整修復。

---

## 1. 本機環境安裝與運行驗證

### 安裝資訊

| 項目 | 值 |
|------|---|
| 版本 | v1.79.0-stable |
| Git Commit | `8d495f56a9cc46be4a8b475c76cf122f340aa138` |
| Python 版本 | 3.12.12 |
| 套件管理 | uv（遵照 AGENTS.md 指示） |
| 安裝指令 | `uv venv --python 3.12 .venv && uv pip install -e ".[proxy]"` |
| 啟動指令 | `litellm --config config.yaml --port 4000` |
| 運行狀態 | Proxy 成功啟動並處理 API 請求 |

### 驗證方式

1. 使用 `uv` 在 `testing/litellm-v1.79.0/` 建立獨立 Python 虛擬環境
2. 安裝 LiteLLM 及其 proxy 相依套件
3. 使用模擬 config.yaml 啟動 proxy，確認：
   - `/health/liveliness` 回傳 `"I'm alive!"`
   - `/health` 回傳所有模型健康狀態
   - `/v1/chat/completions` 能正常處理 Gemini API 請求

---

## 2. 完整設定記錄

### 2.1 Proxy 設定檔（config.yaml）

模擬環境使用的設定檔：

```yaml
model_list:
  - model_name: gemini-2.5-flash
    litellm_params:
      model: gemini/gemini-2.5-flash
      api_key: os.environ/VERTEX_API_KEY
  - model_name: gemini-2.5-pro
    litellm_params:
      model: gemini/gemini-2.5-pro
      api_key: os.environ/VERTEX_API_KEY
  - model_name: gemini-3-pro
    litellm_params:
      model: gemini/gemini-3-pro-preview
      api_key: os.environ/VERTEX_API_KEY

general_settings:
  master_key: sk-test-key-1234

litellm_settings:
  enable_preview_features: true
```

**設定說明：**

- `model_list`：定義可用模型，每個模型指定 LiteLLM 模型 ID 和 API 金鑰來源
- `general_settings.master_key`：Proxy 管理金鑰，擁有完整管理權限
- `litellm_settings.enable_preview_features`：啟用預覽功能，包含 thought_signature 嵌入 tool call ID 的機制

### 2.2 環境變數

| 變數名稱 | 用途 | 範例值 |
|----------|------|--------|
| `VERTEX_API_KEY` | Google AI Studio API 金鑰 | `AIza...`（以 `AIza` 開頭） |
| `LITELLM_MASTER_KEY` | Proxy 主金鑰（config.yaml 外的替代方式） | `sk-1234` |
| `DATABASE_URL` | PostgreSQL 連線字串 | `postgresql://llmproxy:dbpassword9090@db:5432/litellm` |
| `STORE_MODEL_IN_DB` | 啟用資料庫儲存模型設定 | `True` |

**說明：** 本次測試未使用資料庫（無 `DATABASE_URL`），模型設定完全透過 config.yaml 提供。生產環境通常會搭配 PostgreSQL 資料庫，用於儲存 API 金鑰、團隊、花費記錄等資料。

### 2.3 Docker Compose（生產環境參考架構）

v1.79.0 隨附的 `docker-compose.yml` 定義了三個服務：

```yaml
services:
  litellm:
    image: ghcr.io/berriai/litellm:main-stable
    ports: ["4000:4000"]
    environment:
      DATABASE_URL: "postgresql://llmproxy:dbpassword9090@db:5432/litellm"
      STORE_MODEL_IN_DB: "True"
    depends_on: [db]
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 http://localhost:4000/health/liveliness || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    image: postgres:16
    environment:
      POSTGRES_DB: litellm
      POSTGRES_USER: llmproxy
      POSTGRES_PASSWORD: dbpassword9090
    volumes: [postgres_data:/var/lib/postgresql/data]

  prometheus:
    image: prom/prometheus
    ports: ["9090:9090"]
```

**關鍵架構特徵：**

- LiteLLM proxy 監聽 port 4000
- PostgreSQL 16 作為持久化儲存
- Prometheus 用於監控指標收集
- Health check 使用 `/health/liveliness` 端點
- 啟動後等待 40 秒才開始健康檢查（`start_period: 40s`）

### 2.4 資料庫 Schema（Prisma）

Schema 位於：`litellm/proxy/schema.prisma`

**共計 28 張表，可分為六大類：**

#### 核心管理（7 張表）

| 資料表 | 用途 |
|--------|------|
| `LiteLLM_VerificationToken` | API 金鑰管理（token、權限、預算、速率限制） |
| `LiteLLM_ProxyModelTable` | 模型設定（資料庫儲存模式） |
| `LiteLLM_CredentialsTable` | 供應商 API 憑證管理 |
| `LiteLLM_Config` | Proxy 設定鍵值對儲存 |
| `LiteLLM_GuardrailsTable` | 安全護欄設定 |
| `LiteLLM_PromptTable` | Prompt 模板 |
| `LiteLLM_SearchToolsTable` | 搜尋工具設定 |

#### 組織與團隊（6 張表）

| 資料表 | 用途 |
|--------|------|
| `LiteLLM_OrganizationTable` | 組織管理 |
| `LiteLLM_TeamTable` | 團隊管理（含預算、速率限制） |
| `LiteLLM_UserTable` | 內部使用者追蹤 |
| `LiteLLM_TeamMembership` | 使用者於團隊內的花費追蹤 |
| `LiteLLM_OrganizationMembership` | 使用者與組織的成員關係 |
| `LiteLLM_InvitationLink` | 邀請連結管理 |

#### 預算與花費（5 張表）

| 資料表 | 用途 |
|--------|------|
| `LiteLLM_BudgetTable` | 預算／速率限制（跨組織、團隊、金鑰共用） |
| `LiteLLM_EndUserTable` | 外部終端使用者追蹤 |
| `LiteLLM_TagTable` | 基於標籤的預算管理 |
| `LiteLLM_DailyUserSpend` | 每日使用者花費彙總 |
| `LiteLLM_DailyTeamSpend` | 每日團隊花費彙總 |

#### 日誌與追蹤（4 張表）

| 資料表 | 用途 |
|--------|------|
| `LiteLLM_SpendLogs` | 每筆請求的花費記錄 |
| `LiteLLM_ErrorLogs` | 錯誤追蹤 |
| `LiteLLM_AuditLog` | 管理操作審計日誌 |
| `LiteLLM_DailyTagSpend` | 每日標籤花費彙總 |

#### 進階功能（4 張表）

| 資料表 | 用途 |
|--------|------|
| `LiteLLM_MCPServerTable` | MCP 伺服器設定 |
| `LiteLLM_ObjectPermissionTable` | MCP／向量儲存權限 |
| `LiteLLM_ManagedFileTable` | 統一檔案管理 |
| `LiteLLM_ManagedObjectTable` | Batch／Fine-tune 物件 |

#### 其他（2 張表）

| 資料表 | 用途 |
|--------|------|
| `LiteLLM_ManagedVectorStoresTable` | 向量儲存註冊 |
| `LiteLLM_HealthCheckTable` | 健康檢查歷史記錄 |
| `LiteLLM_CronJob` | Cron job leader 選舉 |
| `LiteLLM_UserNotifications` | 模型存取申請 |

**Enum 定義：** `JobStatus`（ACTIVE, INACTIVE）

---

## 3. 功能清單盤點

### 3.1 已設定模型

| 模型名稱 | 供應商 | LiteLLM 模型 ID | 用途 |
|----------|--------|-----------------|------|
| gemini-2.5-flash | Google AI Studio | `gemini/gemini-2.5-flash` | 快速推理、一般對話 |
| gemini-2.5-pro | Google AI Studio | `gemini/gemini-2.5-pro` | 進階推理、複雜任務 |
| gemini-3-pro | Google AI Studio | `gemini/gemini-3-pro-preview` | 最新模型、需要 thought_signature |

### 3.2 API 端點分類（200+ 端點）

#### OpenAI 相容端點（核心業務）

| 類別 | 數量 | 關鍵端點 | 說明 |
|------|------|----------|------|
| Chat Completions | 4 | `/v1/chat/completions` | 核心對話完成 API（含 Azure 相容路徑） |
| Completions | 4 | `/v1/completions` | 文字完成 API |
| Embeddings | 4 | `/v1/embeddings` | 文字向量化 |
| Models | 4 | `/v1/models` | 模型列表與資訊查詢 |
| Moderations | 2 | `/v1/moderations` | 內容審核 |
| Audio | 4 | `/v1/audio/speech`, `/v1/audio/transcriptions` | TTS 與 STT |
| Images | 6 | `/v1/images/generations`, `/v1/images/edits` | 圖片生成與編輯 |
| Files | 9 | `/v1/files` | 檔案上傳、查詢、刪除 |
| Fine-Tuning | 6 | `/v1/fine_tuning/jobs` | 模型微調任務 |
| Batches | 9 | `/v1/batches` | 批次處理 |
| Responses | 10 | `/v1/responses` | Responses API |
| Assistants/Threads | 10+ | `/v1/assistants`, `/v1/threads` | 助手與對話執行緒 |

#### 供應商特定端點

| 類別 | 數量 | 關鍵端點 | 說明 |
|------|------|----------|------|
| Anthropic | 2 | `/v1/messages` | Claude 原生 API 格式 |
| Google Native | 6 | `/v1beta/models/{name}:generateContent` | Gemini 原生 API 格式 |

#### 進階功能端點

| 類別 | 數量 | 關鍵端點 | 說明 |
|------|------|----------|------|
| Rerank | 3 | `/v1/rerank` | 文件重排序 |
| Search | 4 | `/v1/search` | 搜尋查詢 |
| OCR | 2 | `/v1/ocr` | 光學字元辨識 |
| Vector Stores | 4 | `/v1/vector_stores` | 向量儲存管理 |
| Video | 8 | `/v1/videos` | 影片處理 |

#### 管理端點

| 類別 | 數量 | 關鍵端點 | 說明 |
|------|------|----------|------|
| Key 管理 | 13 | `/key/generate`, `/key/info`, `/key/list` | API 金鑰生成、查詢、列表、封鎖 |
| Team 管理 | 19 | `/team/new`, `/team/info`, `/team/list` | 團隊 CRUD、成員管理 |
| User 管理 | 10 | `/user/new`, `/user/info`, `/user/list` | 使用者 CRUD |
| Organization | 8 | `/organization/new`, `/organization/list` | 組織 CRUD |
| Budget | 6 | `/budget/new`, `/budget/list` | 預算管理 |
| Model 管理 | 6 | `/model/new`, `/model/update` | 模型新增、更新、刪除 |
| Tag 管理 | 5 | `/tag/new`, `/tag/list` | 標籤管理 |
| Credentials | 4 | `/credentials` | 憑證 CRUD |
| Guardrails | 7 | `/guardrails` | 安全護欄 CRUD |
| Prompts | 5 | `/prompts` | Prompt 模板管理 |
| MCP | 5 | `/tools`, `/server` | MCP 伺服器管理 |
| Callbacks | 3+ | `/team/{id}/callback` | 團隊回呼設定 |

#### 監控與分析端點

| 類別 | 數量 | 關鍵端點 | 說明 |
|------|------|----------|------|
| Health | 11 | `/health`, `/health/liveliness`, `/health/readiness` | 健康檢查與探針 |
| Spend Tracking | 24+ | `/global/spend`, `/spend/logs` | 花費追蹤與分析 |
| Analytics | 6 | `/tag/dau`, `/tag/wau`, `/tag/mau` | 使用者活躍度分析 |
| Config | 11 | `/config/update`, `/config/yaml` | 設定管理 |
| SSO | 6 | `/sso/callback`, `/sso/key/generate` | SSO 整合 |
| Debugging | 7 | `/memory-usage`, `/debug/memory/summary` | 記憶體與效能除錯 |
| Caching | 4 | `/redis/info`, `/flushall` | 快取管理 |

### 3.3 認證方式

| 方式 | 設定方式 | 說明 |
|------|----------|------|
| **Master Key** | `general_settings.master_key` | 擁有完整管理權限的主金鑰 |
| **API Key（Bearer Token）** | `Authorization: Bearer sk-...` | 透過 `/key/generate` 建立，可設定權限、預算、速率限制 |
| **SSO/OAuth2** | `/sso/callback` 端點 | 企業 SSO 整合 |
| **JWT** | `litellm/proxy/auth/` 模組 | JSON Web Token 認證 |

### 3.4 核心能力

| 能力 | 說明 | 關聯元件 |
|------|------|----------|
| **負載平衡** | Router 將請求分散至多個模型部署 | `litellm/router.py` |
| **自動降級** | 模型失敗時自動切換至備援模型 | `litellm/router_utils/` |
| **速率限制** | 支援 per-key、per-team、per-user 的 RPM/TPM 限制 | `LiteLLM_VerificationToken` |
| **預算管理** | 在金鑰、團隊、組織層級設定花費上限 | `LiteLLM_BudgetTable` |
| **花費追蹤** | 每筆請求記錄花費，支援每日彙總 | `LiteLLM_SpendLogs`, `LiteLLM_DailyUserSpend` |
| **快取** | Redis 或記憶體內回應快取 | `litellm/caching/` |
| **串流** | SSE 串流回應（chat completions） | 所有 chat completion 端點 |
| **工具呼叫** | Function calling / tool use 支援 | Gemini、OpenAI、Anthropic handler |
| **安全護欄** | 內容安全過濾 hooks | `LiteLLM_GuardrailsTable` |
| **審計日誌** | 追蹤管理操作（建立、修改、刪除） | `LiteLLM_AuditLog` |
| **MCP 整合** | Model Context Protocol 伺服器管理 | `LiteLLM_MCPServerTable` |

---

## 4. 功能迴歸測試基準線

### 4.1 測試設計

測試腳本：`testing/test_regression.py`

覆蓋以下核心功能路徑：

1. **Health & Monitoring（4 項）**：健康檢查、存活探針、就緒探針
2. **Model Listing（4 項）**：模型列表完整性
3. **Chat Completions（4 項）**：非串流對話完成、usage 資訊、finish reason
4. **Streaming（4 項）**：串流回應、chunk 結構、內容完整性
5. **Tool Calling（4 項）**：工具呼叫、函式名稱、參數、ID
6. **Multi-turn Tool（2 項）**：多輪工具對話、工具結果回傳
7. **Error Handling（2 項）**：無效模型、無效金鑰錯誤處理
8. **Utilities（4 項）**：Token 計數、模型資訊、路由列表

### 4.2 測試結果

**v1.79.0：28/28 通過**
**v1.80.11：28/28 通過**

| # | 測試項目 | v1.79.0 | v1.80.11 |
|---|----------|---------|----------|
| 1 | `GET /health` 回傳 200 | PASS | PASS |
| 2 | 健康檢查回報健康模型 | PASS | PASS |
| 3 | `GET /health/liveliness` 回傳 200 | PASS | PASS |
| 4 | `GET /health/readiness` 回傳 200 | PASS | PASS |
| 5 | `GET /v1/models` 回傳模型列表 | PASS | PASS |
| 6 | gemini-2.5-flash 在列表中 | PASS | PASS |
| 7 | gemini-2.5-pro 在列表中 | PASS | PASS |
| 8 | gemini-3-pro 在列表中 | PASS | PASS |
| 9 | `POST /v1/chat/completions`（非串流） | PASS | PASS |
| 10 | 回應包含 usage 資訊 | PASS | PASS |
| 11 | 回應包含 model 欄位 | PASS | PASS |
| 12 | finish_reason 為 'stop' | PASS | PASS |
| 13 | 串流回傳多個 chunks | PASS | PASS |
| 14 | 第一個 chunk 包含 role='assistant' | PASS | PASS |
| 15 | 最後一個 chunk 包含 finish_reason='stop' | PASS | PASS |
| 16 | 串流內容不為空 | PASS | PASS |
| 17 | Tool calling 回傳 tool_calls | PASS | PASS |
| 18 | Tool call 包含函式名稱 | PASS | PASS |
| 19 | Tool call 包含有效參數 | PASS | PASS |
| 20 | Tool call 包含 ID | PASS | PASS |
| 21 | 多輪對話：收到初始 tool call | PASS | PASS |
| 22 | 多輪對話：回傳工具結果後完成回應 | PASS | PASS |
| 23 | 無效模型回傳錯誤 | PASS | PASS |
| 24 | 無效金鑰回傳錯誤 | PASS | PASS |
| 25 | `POST /utils/token_counter` 回傳 200 | PASS | PASS |
| 26 | `GET /v1/model/info` 回傳 200 | PASS | PASS |
| 27 | 模型資訊包含已設定模型 | PASS | PASS |
| 28 | `GET /routes` 回傳 200 | PASS | PASS |

### 4.3 行為差異觀察

| 行為 | v1.79.0 | v1.80.11 | 影響 |
|------|---------|----------|------|
| 無效 API 金鑰錯誤碼 | 400（BadRequestError） | 400（BadRequestError） | 一致，無影響 |
| Tool call ID 格式 | `call_<hex28>` | `call_<hex28>__thought__<sig>` | v1.80.11 在啟用 preview features 時嵌入 thought signature |
| Thought signature 保留 | 不保留（靜默丟棄） | 保留（via provider_specific_fields + ID 嵌入） | **核心修復項目** |

### 4.4 執行方式

```bash
# 啟動 proxy
cd testing/litellm-v1.79.0 && source .venv/bin/activate
source ../.env && litellm --config ../config.yaml --port 4000

# 執行迴歸測試（另一個終端機）
cd testing/litellm-v1.79.0 && source .venv/bin/activate
python testing/test_regression.py --port 4000
```

---

## 5. thought_signature 修復驗證（額外完成）

雖然屬於第三階段第 4 項任務，但在第一階段已提前完成驗證。

### 5.1 原始問題

Gemini thinking mode 下，LiteLLM v1.79.0 在將 Gemini API 回應轉換為 OpenAI 格式時，未保留 `thoughtSignature` 欄位。在長對話（307+ content blocks）中，Gemini API 因缺少 thought_signature 而拒絕請求，回傳 HTTP 400/503 錯誤。

### 5.2 修復內容

兩個 PR 共同修復此問題：

- **PR #16895**（2025-11-21 合併）：將 thought signature 儲存在 tool call ID 中
- **PR #18374**（2025-12-23 合併）：提升為正式功能，新增 pre-call hook

### 5.3 驗證結果

#### 程式碼存在性檢查

| 檢查項目 | v1.79.0 | v1.80.11 |
|----------|---------|----------|
| `__thought__` 模式 | 不存在 | 存在（factory.py） |
| `thought_signature` 引用 | 0 個檔案 | 4 個檔案 |
| 測試檔案 | 不存在 | 11 個測試案例 |
| `THOUGHT_SIGNATURE_SEPARATOR` 可匯入 | ImportError | OK |

#### 單元測試（v1.80.11）

11/11 全數通過（0.46 秒）：

- 編碼／解碼 tool call ID
- 啟用／停用 preview features 的 ID 嵌入行為
- `provider_specific_fields` 向後相容性
- 優先順序（provider_specific_fields > ID 嵌入）
- OpenAI 客戶端端對端流程
- 平行工具呼叫

#### 即時 API 整合測試

| 測試 | 模型 | v1.79.0 | v1.80.11 |
|------|------|---------|----------|
| 基本工具呼叫往返 | gemini-2.5-flash | 通過（無簽章） | 通過（含簽章） |
| 多城市擴展測試 | gemini-2.5-flash | 通過（無簽章） | 通過（含簽章） |
| 基本工具呼叫往返 | gemini-3-pro-preview | 通過（無簽章） | 通過（含簽章） |
| 多城市擴展測試 | gemini-3-pro-preview | 通過（無簽章） | 通過（含簽章） |
| ID 中含 `__thought__` | 所有模型 | **否** | **是** |

### 5.4 結論

v1.80.11-stable 包含完整且功能正常的 thought_signature 實作。升級後需確保 `enable_preview_features: true` 設定啟用，以確保 OpenAI SDK 客戶端（如 OpenClaw）能正確保留 thought signature。

---

## 6. 已產出檔案清單

| 檔案 | 用途 |
|------|------|
| `testing/litellm-v1.79.0/` | v1.79.0-stable 原始碼（含 venv） |
| `testing/litellm-v1.80.11/` | v1.80.11-stable 原始碼（含 venv） |
| `testing/config.yaml` | 共用 Proxy 設定（3 個 Gemini 模型） |
| `testing/.env` | 環境變數（API 金鑰） |
| `testing/test_regression.py` | 28 項迴歸測試腳本 |
| `testing/test_gemini_thought_signature.py` | thought_signature 整合測試腳本 |
| `testing/results/thought-signature-v1.79.0-code-check.md` | v1.79.0 thought_signature 程式碼審計 |
| `testing/results/thought-signature-v1.80.11-code-check.md` | v1.80.11 thought_signature 程式碼審計 |
| `testing/results/thought-signature-integration-test.md` | thought_signature 整合測試完整報告 |
| `phase1-report.md` | 本報告（第一階段繁體中文完整報告） |

---

## References

- LiteLLM v1.79.0-stable：<https://github.com/BerriAI/litellm/releases/tag/v1.79.0-stable>
- LiteLLM v1.80.11-stable：<https://github.com/BerriAI/litellm/releases/tag/v1.80.11-stable>
- PR #16895（thought_signature 初始實作）：<https://github.com/BerriAI/litellm/pull/16895>
- PR #18374（thought_signature 正式化）：<https://github.com/BerriAI/litellm/pull/18374>
- Gemini Thought Signatures 文件：<https://ai.google.dev/gemini-api/docs/thought-signatures>
- Schema 檔案：`testing/litellm-v1.79.0/litellm/proxy/schema.prisma`
- Docker Compose：`testing/litellm-v1.79.0/docker-compose.yml`
