# 版本差異分析：LiteLLM v1.79.0 → v1.81.12-stable.1

- **Date**: 2026-02-27
- **Status**: Complete
- **Purpose**: 記錄 LiteLLM v1.79.0-stable 至 v1.81.12-stable.1 之間的所有變更，並評估對 Zeabur AI Hub 的影響。

## Summary

本文件涵蓋 11 個穩定版本的完整變更分析，從 2025 年 10 月（v1.79.0）至 2026 年 2 月（v1.81.12-stable.1），時間跨度約 4 個月。

### 版本總覽

| 版本 | 發佈日期 | 主要變更重點 |
|------|----------|-------------|
| v1.79.1-stable | 2025-11-08 | Azure 修復、FAL AI 整合、效能改善 |
| v1.79.3-stable | 2025-11-15 | Videos API、內容過濾防護、Node.js runtime 修復 |
| v1.80.0-stable.1 | 2025-11-24 | GPT-5.1 支援、A2A agent 協定、Prometheus OSS 化 |
| v1.80.5-stable | 2025-12-03 | **PR #16895 thought_signature 初始修復**、Gemini 3 Pro Image、MCP Hub |
| v1.80.8-stable | 2025-12-14 | Guardrails API 工具呼叫檢查、Cursor BYOK、health check DB 記錄 |
| v1.80.11-stable | 2026-01-10 | **PR #18374 thought_signature 正式化**、Skills API、RAG Search API |
| v1.80.15-stable | 2026-01-17 | Prisma 遷移鎖、Prometheus 快取指標、92.7% 效能加速 |
| v1.81.0-stable | 2026-01-24 | OOM 修復（image URL）、Deleted Keys/Teams UI、Web Search |
| v1.81.3-stable | 2026-02-08 | Policy Engine、21% 延遲降低、MCP 工具回應整合至 chat |
| v1.81.9-stable | 2026-02-15 | Claude Opus 4.6 支援、Access Groups、soft budget |
| v1.81.12-stable.1 | 2026-02-24 | Guardrail pipeline、Scaleway 支援、MCP StreamableHTTP 修復 |

### 變更類別統計

| 類別 | 數量 | 說明 |
|------|------|------|
| 破壞性變更（Breaking Changes） | 7 | Docker 映像遷移、Python 版本、OpenAI SDK v2、依賴項 |
| 新功能（New Features） | 50+ | A2A agents、Policy Engine、Access Groups、Skills API 等 |
| 錯誤修復（Bug Fixes） | 100+ | 記憶體洩漏、tool calling、streaming、cost tracking 等 |
| 效能改善（Performance） | 15+ | 21% 延遲降低、LRU 快取、provider config O(1) 查詢 |
| 資料庫變更（DB Schema） | 15 張新表 + 多張修改表 | 詳見 `docs/db-schema-migration-v1.79-to-v1.81.md` |
| 安全修復（Security） | 10+ | key 過期洩漏、SSRF 防護、CVE 修補 |

---

## 1. 破壞性變更（Breaking Changes）

### 1.1 Docker 映像倉庫遷移

| 項目 | v1.79.0 | v1.81.12 | 影響 |
|------|---------|----------|------|
| **映像倉庫** | `ghcr.io/berriai/litellm` | `docker.litellm.ai/berriai/litellm` | **HIGH** — CI/CD pipeline 必須更新 |
| **基礎映像** | `cgr.dev/chainguard/python:latest-dev` | `cgr.dev/chainguard/wolfi-base` | MEDIUM — 不影響使用者 |
| **Health Check** | `wget --no-verbose` | `python3 urllib` | MEDIUM — 自訂 health check 需更新 |

**影響評估**：Zeabur 部署需更新 Docker image pull source。Health check 使用 Python 內建模組，更可靠但需確認自訂腳本相容性。

### 1.2 Python 版本要求提升

| 項目 | v1.79.0 | v1.81.12 |
|------|---------|----------|
| 最低版本 | `>=3.8.1` | `>=3.9` |

**影響評估**：Zeabur 使用 Python 3.12，無影響。

### 1.3 OpenAI SDK 重大版本升級

| 項目 | v1.79.0 | v1.81.12 | 風險 |
|------|---------|----------|------|
| openai SDK | `>=1.99.5` | `>=2.8.0` | **HIGH** |

**影響評估**：OpenAI SDK v2.x 變更了 response 物件結構、streaming API、error 類別。LiteLLM 內部已處理這些變更，但任何直接匯入 `openai` 套件的自訂程式碼需要檢查。Zeabur AI Hub 透過 LiteLLM proxy 使用 OpenAI API 格式，**不直接依賴 openai SDK**，因此影響低。

### 1.4 WebSocket 重大版本升級

| 項目 | v1.79.0 | v1.81.12 |
|------|---------|----------|
| websockets | `^13.1.0` | `^15.0.1` |

**影響評估**：影響 Realtime API 功能。Zeabur 目前未使用 Realtime API，影響低。

### 1.5 資料庫連線池預設值變更

| 設定 | v1.79.0 | v1.81.12 |
|------|---------|----------|
| `database_connection_pool_limit` | 100 | **10** |

**影響評估**：大幅降低。高併發資料庫環境需手動設定回 100。Zeabur 測試環境無資料庫，無影響；生產環境需注意。

### 1.6 記憶體佇列預設值變更

| 設定 | v1.79.0 | v1.81.12 |
|------|---------|----------|
| `MAX_SIZE_IN_MEMORY_QUEUE` | 10000 | **2000** |
| asyncio Queue | 無上限 | **1000**（`LITELLM_ASYNCIO_QUEUE_MAXSIZE`）|

**影響評估**：防止記憶體無限增長，但極高負載下可能丟棄 spend update 事件。建議監控佇列使用率。

### 1.7 `google-generativeai` 套件移除

| 項目 | v1.79.0 | v1.81.12 |
|------|---------|----------|
| `google-generativeai` | `0.5.0` | **已移除** |
| `google-genai` | `1.22.0` | `1.37.0` |

**影響評估**：已由 `google-genai` 取代，LiteLLM 內部已完成遷移，對使用者透明。

---

## 2. 新功能（依版本）

### v1.79.1-stable（2025-11-08）

- FAL AI 圖片生成支援
- Codestral Embed 模型支援
- Azure ContextWindowExceededError 正確映射
- Batch API 速率限制
- UI: 測試金鑰嵌入功能、快取設定介面
- OpenTelemetry 外部 tracer context 傳播

### v1.79.3-stable（2025-11-15）

- Vertex/Gemini Videos API + 成本追蹤
- Azure 內容政策錯誤資訊回傳
- Content Filter Guard 防護功能
- gpt-4o-transcribe 成本追蹤
- Node.js runtime 修復（Prisma 所需）

### v1.80.0-stable.1（2025-11-24）

- **GPT-5.1 / GPT-5.1-codex 家族支援**
- A2A（Agent-to-Agent）agent 註冊與探索
- VertexAI BGE Embeddings 支援
- Prometheus **OSS 化**（原企業功能）
- 向量儲存檔案管理穩定版
- RunwayML TTS 支援
- Model Access Group API
- MCP OAuth2 動態 metadata 探索

### v1.80.5-stable（2025-12-03）

- **PR #16895：Gemini 3 thought signature 嵌入 tool call ID**（核心修復）
- Gemini 3 Pro Image 模型支援
- MCP Hub：公司內部 MCP Server 發佈/探索
- Prompt Management 版本控制
- Docker Model Runner 新 LLM Provider
- Anthropic Structured Output（`output_format`）
- Claude 4.5 US Gov Cloud 支援
- 動態速率限制器 token 計數修復

### v1.80.8-stable（2025-12-14）

- Guardrails API 支援 tool call 檢查（`/chat/completions`、`/responses`、`/v1/messages`）
- Cursor BYOK 自訂設定
- Background health checks 寫入資料庫
- Bedrock Qwen 2 imported model 支援
- 結構化 `structured_messages` 參數
- gpt-5.1-codex-max `xhigh` reasoning effort
- Amazon Nova 一方 provider
- Mistral Large 3 支援
- 動態團隊速率限制/優先權預留

### v1.80.11-stable（2026-01-10）

- **PR #18374：thought_signature 正式化為 pre-call hook**（核心修復完成）
- Unified Skills API（跨 Anthropic/Vertex/Azure/Bedrock）
- RAG Search API + Reranker
- Stability 模型支援（含 Bedrock）
- Vertex AI DeepSeek OCR
- UI: 回呼管理、向量儲存設定、wildcard health check
- Guardrails 負載平衡
- 41 個 configuration 類別 lazy loading（記憶體優化）

### v1.80.15-stable（2026-01-17）

- **Prisma 遷移內建鎖**（防止並行 migrate deploy）
- **92.7% provider config 查詢加速**
- Prometheus 快取指標（hits/misses/tokens）
- Tag routing: ANY/ALL 切換
- Vertex AI API Key 支援
- MCP Registry 功能
- Bedrock token counting 後端
- RDS IAM token 主動更新（防止 15 分鐘連線失敗）
- 記憶體洩漏偵測測試 + CI 整合

### v1.81.0-stable（2026-01-24）

- **OOM 修復**：`MAX_IMAGE_URL_DOWNLOAD_SIZE_MB`（預設 50MB）
- Deleted Keys/Teams 審計表 UI
- Claude Code Web Search 整合
- Public Model Hub health check 資訊

### v1.81.3-stable（2026-02-08）

- **Policy Engine**：建立 guardrail 政策管理，支援條件/權限 per Key/Team
- **21% chat_completion 延遲降低**
- MCP 工具回應整合至 chat completions
- Azure OpenAI v1 API 支援
- Gemini `responseJsonSchema`（2.0+ 模型）
- Claude Code Plugin Marketplace
- GMI Cloud provider 支援
- Volcengine Responses API
- SSO user roles 更新修復
- 多項 HTTP client 記憶體洩漏修復

### v1.81.9-stable（2026-02-15）

- **Claude Opus 4.6 全面支援**（Anthropic/Azure AI/Bedrock/Vertex AI）
- **Access Groups**：模型/MCP server/agent 存取群組管理
- Team soft budget + email 警報
- MCP Semantic Filtering UI
- MCP Gateway：私有/公開/IP 限制
- Agent guardrail 串流輸出支援
- Prometheus budget 指標 40% CPU 降低
- 多項效能優化（LRU cache、frozenset lookup、early-exit guards）

### v1.81.12-stable.1（2026-02-24）

- **Guardrail pipeline**：條件序列執行
- NSFW/Toxic/Child Safety 政策模板
- Scaleway provider 支援
- OpenAI Responses API `context_management` 壓縮
- Shell tool 支援
- Access Group 權限檢查
- Pyroscope 觀測能力
- MCP StreamableHTTP stateless 修復（hotfix）
- 多項 Anthropic beta header 管理改善

---

## 3. 重要錯誤修復

### 3.1 核心修復（直接影響 Zeabur）

| 修復 | 版本 | PR | 影響 |
|------|------|-----|------|
| **thought_signature 嵌入 tool call ID** | v1.80.5 | #16895 | **核心目標** — 解決 Gemini 503 錯誤 |
| **thought_signature pre-call hook 正式化** | v1.80.11 | #18374 | **核心目標** — 完整修復 |
| OOM 修復：image URL 下載大小限制 | v1.81.0 | #19257 | 防止大圖片導致記憶體耗盡 |
| Gemini 多輪 tool calling 訊息格式修復 | v1.81.12 | #20569 | 長對話穩定性 |
| 排程器佇列 orphan entries 記憶體洩漏 | v1.81.12 | #20866 | 長時間運行穩定性 |
| SpendUpdateQueue 原地修改漏洞 | v1.81.12 | #20876 | 花費追蹤準確性 |

### 3.2 效能相關修復

| 修復 | 版本 | 改善幅度 |
|------|------|----------|
| 92.7% provider config 查詢加速 | v1.80.15 | LLM provider 壓力提升 2.5x |
| 21% chat_completion 延遲降低 | v1.81.3 | pre-call 處理時間減少 |
| LRU caching for `get_model_info` | v1.81.3 | 成本查詢加速 |
| `pattern_router.route()` 跳過非 wildcard | v1.81.3 | 路由效能提升 |
| Prometheus budget 指標平行化 | v1.81.9 | CPU 使用降低 ~40% |
| 重複 provider parsing 移除 | v1.81.12 | budget limiter 熱路徑加速 |

### 3.3 安全修復

| 修復 | 版本 | 類型 |
|------|------|------|
| 過期 key plaintext 洩漏防護 | v1.80.15 | 資訊洩漏 |
| `/user/new` 權限提升修復 | v1.81.3 | 權限控制 |
| Streaming SSE 錯誤回應 traceback 洩漏防護 | v1.81.12 | 資訊洩漏 |
| 多項 CVE 依賴項更新 | v1.81.12 | urllib3、tornado、filelock |
| Extra header secrets 遮罩 | v1.80.15 | 資訊洩漏 |

---

## 4. 依賴項變更總覽

### 4.1 高風險變更

| 依賴項 | v1.79.0 | v1.81.12 | 風險 | 影響 |
|--------|---------|----------|------|------|
| **Python** | `>=3.8.1` | `>=3.9` | HIGH | Zeabur 用 3.12，無影響 |
| **openai** | `>=1.99.5` | `>=2.8.0` | HIGH | LiteLLM 內部處理，使用者透明 |
| **websockets** | `^13.1.0` | `^15.0.1` | HIGH | Realtime API 相關，未使用 |
| **google-cloud-aiplatform** | `1.47.0` | `1.133.0` | HIGH | 86 版本跳躍，Vertex AI 使用者需測試 |

### 4.2 中風險變更

| 依賴項 | v1.79.0 | v1.81.12 | 風險 |
|--------|---------|----------|------|
| fastapi | `^0.115.5` | `>=0.120.1` | MEDIUM |
| starlette | `0.47.2` | `0.49.1` | MEDIUM |
| mcp | `^1.10.0` | `>=1.25.0,<2.0.0` | MEDIUM |
| litellm-proxy-extras | `0.2.29` | `0.4.39` | MEDIUM |
| boto3 | `1.36.0` | `1.40.76` | MEDIUM |
| pydantic | `2.10.2` | `>=2.11,<3` | MEDIUM |
| grpcio | 必要 | **選配** | MEDIUM |

### 4.3 新增依賴項

| 依賴項 | 版本 | 用途 | 類型 |
|--------|------|------|------|
| a2a-sdk | `^0.3.22` | Agent-to-Agent 協定 | 選配 |
| google-cloud-aiplatform | `>=1.38.0` | Google Cloud AI Platform | 選配 |
| pyroscope-io | `^0.8` | Profiling 觀測 | 選配 |
| soundfile | `^0.12.1` | 音訊處理 | 選配 |
| redisvl | `0.4.1` | Redis 語意快取 | 選配 |
| pypdf | `>=6.6.2` | PDF 文字擷取 | 必要 |

### 4.4 移除依賴項

| 依賴項 | 原因 |
|--------|------|
| google-generativeai | 已由 google-genai 取代（deprecated） |

---

## 5. Docker 變更

### 5.1 Dockerfile

| 變更 | 詳細 |
|------|------|
| 基礎映像 | `python:latest-dev` → `wolfi-base` |
| Runtime 安裝 | 新增 `bash`、`python3`、`py3-pip`、`nodejs`、`npm` |
| 音訊支援 | 新增 `libsndfile`（ARM64） |
| Prisma generate | 新增 `--schema=` 明確路徑指定 |
| Windows 相容 | 新增 CR/LF 轉換（`sed -i 's/\r$//'`） |
| 安全修復 | npm 依賴 CVE 修補、nodejs-wheel 修補 |

### 5.2 docker-compose.yml

| 變更 | v1.79.0 | v1.81.12 |
|------|---------|----------|
| 映像來源 | `ghcr.io/berriai/litellm:main-stable` | `docker.litellm.ai/berriai/litellm:main-stable` |
| Health check | `wget --no-verbose` | `python3 -c "import urllib.request; ..."` |
| 新增 | — | `docker-compose.hardened.yml`（non-root、read-only） |

---

## 6. 設定變更

### 6.1 新增 `general_settings` 欄位

| 欄位 | 類型 | 說明 |
|------|------|------|
| `reject_clientside_metadata_tags` | `bool` | 防止使用者透過 tag 影響預算 |
| `user_mcp_management_mode` | `enum` | 非管理者 MCP server 可見性 |
| `store_prompts_in_spend_logs` | `bool` | 在 spend logs 中儲存請求/回應 |
| `maximum_spend_logs_retention_period` | `str` | Spend logs 保留期限（如 '7d'） |
| `mcp_internal_ip_ranges` | `List[str]` | MCP 內部網路存取 CIDR |
| `mcp_trusted_proxy_ranges` | `List[str]` | MCP 信任反向代理 CIDR |

### 6.2 新增環境變數

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `MAX_IMAGE_URL_DOWNLOAD_SIZE_MB` | `50` | 最大圖片下載大小（MB），設 `0` 停用 |
| `LITELLM_ASYNCIO_QUEUE_MAXSIZE` | `1000` | asyncio 佇列上限，防止記憶體無限增長 |
| `LOGGING_WORKER_CONCURRENCY` | `100` | logging worker 並行任務數 |
| `DEFAULT_FAILURE_THRESHOLD_MINIMUM_REQUESTS` | `5` | 錯誤率 cooldown 前最低請求數 |

### 6.3 現有設定相容性

我們的 `testing/local/config.yaml` 已驗證 **完全相容** v1.81.12：

- `model_list`：`gemini/` 前綴、`os.environ/` 語法均支援
- `general_settings.master_key`：解析方式不變
- `litellm_settings.enable_preview_features: true`：**關鍵設定，兩版本行為一致**

---

## 7. Zeabur AI Hub 影響評估

### 7.1 直接影響（必須處理）

| 項目 | 影響 | 行動 |
|------|------|------|
| Docker image 來源 | 必須更新 pull source | 更新 CI/CD 設定 |
| Health check 方式 | 需更新自訂 health check | 改用 python3 urllib 或保持 `/health/liveliness` HTTP 端點 |
| `enable_preview_features: true` | 必須保留 | 已驗證相容 |

### 7.2 改善項目（升級後獲益）

| 項目 | 改善 |
|------|------|
| thought_signature 503 錯誤 | **根本修復** — 升級主要目標 |
| chat completion 延遲 | 降低 ~21% |
| provider config 查詢 | 加速 92.7% |
| 記憶體穩定性 | 多項 OOM/洩漏修復 |
| Prometheus 指標 | OSS 化 + 快取指標 + CPU 降低 40% |

### 7.3 無影響項目

| 項目 | 原因 |
|------|------|
| Python 版本提升 | 已使用 3.12 |
| OpenAI SDK v2 | 透過 proxy 使用，不直接依賴 |
| WebSocket 升級 | 未使用 Realtime API |
| 新功能（A2A、Policy Engine 等） | 可選啟用，不影響現有功能 |

---

## References

- LiteLLM Releases: <https://github.com/BerriAI/litellm/releases>
- PR #16895（thought_signature 初始修復）: <https://github.com/BerriAI/litellm/pull/16895>
- PR #18374（thought_signature 正式化）: <https://github.com/BerriAI/litellm/pull/18374>
- Schema 比較：見 `docs/db-schema-migration-v1.79-to-v1.81.md`
- 升級計劃：見 `reports/upgrade-plan-2026-02.md`
