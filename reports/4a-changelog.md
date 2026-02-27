# 版本變更 Changelog：LiteLLM v1.79.0 → v1.81.12-stable.1

- **日期**：2026-02-27
- **用途**：完整記錄 11 個穩定版本的變更，供升級評估與上線審查使用
- **資料來源**：[docs/research/upgrade-changelog-v1.79-to-v1.81.md](../docs/research/upgrade-changelog-v1.79-to-v1.81.md)

---

## 執行摘要

從 v1.79.0-stable（2025-10-26）到 v1.81.12-stable.1（2026-02-24），共跨越 **11 個穩定版本**、約 4 個月的開發週期。

| 類別 | 數量 |
|------|------|
| 破壞性變更（Breaking Changes） | 7 |
| 新功能（New Features） | 50+ |
| 錯誤修復（Bug Fixes） | 100+ |
| 效能改善（Performance） | 15+ |
| 資料庫變更（DB Schema） | 15 張新表 + 12 張修改表 |
| 安全修復（Security） | 10+ |

---

## 1. 版本總覽

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

---

## 2. 破壞性變更（Breaking Changes）

共 7 項破壞性變更，以下依影響程度排序：

### 2.1 Docker 映像倉庫遷移

| 項目 | v1.79.0 | v1.81.12 | 影響 |
|------|---------|----------|------|
| 映像倉庫 | `ghcr.io/berriai/litellm` | `docker.litellm.ai/berriai/litellm` | **HIGH** — CI/CD 必須更新 |
| 基礎映像 | `cgr.dev/chainguard/python:latest-dev` | `cgr.dev/chainguard/wolfi-base` | MEDIUM |
| Health Check | `wget --no-verbose` | `python3 urllib` | MEDIUM — 自訂 health check 需更新 |

### 2.2 OpenAI SDK 重大版本升級

| 項目 | v1.79.0 | v1.81.12 | 影響 |
|------|---------|----------|------|
| openai SDK | `>=1.99.5` | `>=2.8.0` | **HIGH**（LiteLLM 內部已處理） |

Zeabur AI Hub 透過 LiteLLM proxy 使用 OpenAI API 格式，不直接依賴 openai SDK，因此實際影響低。

### 2.3 Python 版本要求提升

| 項目 | v1.79.0 | v1.81.12 |
|------|---------|----------|
| 最低版本 | `>=3.8.1` | `>=3.9` |

Zeabur 使用 Python 3.12，無影響。

### 2.4 資料庫連線池預設值變更

| 設定 | v1.79.0 | v1.81.12 | 說明 |
|------|---------|----------|------|
| `database_connection_pool_limit` | 100 | **10** | 高併發環境需手動設回 100 |

### 2.5 記憶體佇列預設值變更

| 設定 | v1.79.0 | v1.81.12 | 說明 |
|------|---------|----------|------|
| `MAX_SIZE_IN_MEMORY_QUEUE` | 10000 | **2000** | 防止記憶體無限增長 |
| `LITELLM_ASYNCIO_QUEUE_MAXSIZE` | 無上限 | **1000** | 新增佇列上限 |

### 2.6 WebSocket 重大版本升級

| 項目 | v1.79.0 | v1.81.12 |
|------|---------|----------|
| websockets | `^13.1.0` | `^15.0.1` |

影響 Realtime API 功能。Zeabur 目前未使用 Realtime API，影響低。

### 2.7 `google-generativeai` 套件移除

| 項目 | v1.79.0 | v1.81.12 |
|------|---------|----------|
| `google-generativeai` | `0.5.0` | **已移除** |
| `google-genai` | `1.22.0` | `1.37.0` |

已由 `google-genai` 取代，LiteLLM 內部已完成遷移，對使用者透明。

---

## 3. 新功能亮點

### 核心平台功能

| 功能 | 版本 | 說明 |
|------|------|------|
| A2A Agent 協定 | v1.80.0 | Agent-to-Agent 註冊與探索 |
| Skills API | v1.80.11 | 跨 Anthropic/Vertex/Azure/Bedrock 的統一技能 API |
| Policy Engine | v1.81.3 | Guardrail 政策管理，支援條件/權限 per Key/Team |
| Access Groups | v1.81.9 | 模型/MCP server/agent 存取群組管理 |
| Guardrail Pipeline | v1.81.12 | 條件序列執行 guardrail |

### 模型支援

| 功能 | 版本 |
|------|------|
| GPT-5.1 / GPT-5.1-codex 家族 | v1.80.0 |
| Gemini 3 Pro Image | v1.80.5 |
| Claude Opus 4.6 全面支援 | v1.81.9 |
| Claude 4.5 US Gov Cloud | v1.80.5 |

### 監控與觀測

| 功能 | 版本 | 說明 |
|------|------|------|
| Prometheus OSS 化 | v1.80.0 | 原企業功能開放 |
| Prometheus 快取指標 | v1.80.15 | hits/misses/tokens |
| Pyroscope 觀測 | v1.81.12 | Profiling 支援 |

### MCP 生態

| 功能 | 版本 |
|------|------|
| MCP Hub | v1.80.5 |
| MCP Registry | v1.80.15 |
| MCP Semantic Filtering UI | v1.81.9 |
| MCP Gateway | v1.81.9 |
| MCP StreamableHTTP 修復 | v1.81.12 |

---

## 4. 重要錯誤修復

### 4.1 核心修復（直接影響 Zeabur）

| 修復 | 版本 | PR | 影響 |
|------|------|-----|------|
| **thought_signature 嵌入 tool call ID** | v1.80.5 | #16895 | **核心目標** — 解決 Gemini 503 錯誤 |
| **thought_signature pre-call hook 正式化** | v1.80.11 | #18374 | **核心目標** — 完整修復 |
| OOM 修復：image URL 下載大小限制 | v1.81.0 | #19257 | 防止大圖片導致記憶體耗盡 |
| Gemini 多輪 tool calling 訊息格式修復 | v1.81.12 | #20569 | 長對話穩定性 |
| 排程器佇列 orphan entries 記憶體洩漏 | v1.81.12 | #20866 | 長時間運行穩定性 |
| SpendUpdateQueue 原地修改漏洞 | v1.81.12 | #20876 | 花費追蹤準確性 |

### 4.2 效能相關修復

| 修復 | 版本 | 改善幅度 |
|------|------|----------|
| 92.7% provider config 查詢加速 | v1.80.15 | LLM provider 壓力提升 2.5x |
| 21% chat_completion 延遲降低 | v1.81.3 | pre-call 處理時間減少 |
| LRU caching for `get_model_info` | v1.81.3 | 成本查詢加速 |
| `pattern_router.route()` 跳過非 wildcard | v1.81.3 | 路由效能提升 |
| Prometheus budget 指標平行化 | v1.81.9 | CPU 使用降低 ~40% |
| 重複 provider parsing 移除 | v1.81.12 | budget limiter 熱路徑加速 |

### 4.3 安全修復

| 修復 | 版本 | 類型 |
|------|------|------|
| 過期 key plaintext 洩漏防護 | v1.80.15 | 資訊洩漏 |
| `/user/new` 權限提升修復 | v1.81.3 | 權限控制 |
| Streaming SSE 錯誤回應 traceback 洩漏防護 | v1.81.12 | 資訊洩漏 |
| 多項 CVE 依賴項更新 | v1.81.12 | urllib3、tornado、filelock |
| Extra header secrets 遮罩 | v1.80.15 | 資訊洩漏 |

---

## 5. 依賴項變更

### 5.1 高風險變更

| 依賴項 | v1.79.0 | v1.81.12 | 風險 | Zeabur 影響 |
|--------|---------|----------|------|------------|
| Python | `>=3.8.1` | `>=3.9` | HIGH | 無（使用 3.12） |
| openai | `>=1.99.5` | `>=2.8.0` | HIGH | 低（透過 proxy） |
| websockets | `^13.1.0` | `^15.0.1` | HIGH | 無（未使用 Realtime API） |
| google-cloud-aiplatform | `1.47.0` | `1.133.0` | HIGH | 低（86 版本跳躍，內部處理） |

### 5.2 中風險變更

| 依賴項 | v1.79.0 | v1.81.12 |
|--------|---------|----------|
| fastapi | `^0.115.5` | `>=0.120.1` |
| starlette | `0.47.2` | `0.49.1` |
| mcp | `^1.10.0` | `>=1.25.0,<2.0.0` |
| litellm-proxy-extras | `0.2.29` | `0.4.39` |
| boto3 | `1.36.0` | `1.40.76` |
| pydantic | `2.10.2` | `>=2.11,<3` |

### 5.3 新增依賴項

| 依賴項 | 版本 | 用途 | 類型 |
|--------|------|------|------|
| a2a-sdk | `^0.3.22` | Agent-to-Agent 協定 | 選配 |
| pyroscope-io | `^0.8` | Profiling 觀測 | 選配 |
| pypdf | `>=6.6.2` | PDF 文字擷取 | 必要 |
| redisvl | `0.4.1` | Redis 語意快取 | 選配 |

### 5.4 移除依賴項

| 依賴項 | 原因 |
|--------|------|
| google-generativeai | 已由 google-genai 取代 |

---

## 6. 逐版本摘要

### v1.79.1-stable（2025-11-08）

- FAL AI 圖片生成支援
- Azure ContextWindowExceededError 正確映射
- OpenTelemetry 外部 tracer context 傳播

### v1.79.3-stable（2025-11-15）

- Vertex/Gemini Videos API + 成本追蹤
- Content Filter Guard 防護功能
- Node.js runtime 修復（Prisma 所需）

### v1.80.0-stable.1（2025-11-24）

- GPT-5.1 / GPT-5.1-codex 家族支援
- A2A agent 協定
- Prometheus OSS 化
- Model Access Group API

### v1.80.5-stable（2025-12-03）

- **PR #16895：thought_signature 嵌入 tool call ID**（核心修復）
- Gemini 3 Pro Image 模型支援
- MCP Hub
- Anthropic Structured Output

### v1.80.8-stable（2025-12-14）

- Guardrails API 支援 tool call 檢查
- Cursor BYOK 自訂設定
- Background health checks 寫入資料庫

### v1.80.11-stable（2026-01-10）

- **PR #18374：thought_signature pre-call hook 正式化**（核心修復完成）
- Unified Skills API
- RAG Search API + Reranker
- 41 個 configuration 類別 lazy loading

### v1.80.15-stable（2026-01-17）

- Prisma 遷移內建鎖
- 92.7% provider config 查詢加速
- Prometheus 快取指標
- RDS IAM token 主動更新

### v1.81.0-stable（2026-01-24）

- OOM 修復：`MAX_IMAGE_URL_DOWNLOAD_SIZE_MB`（預設 50MB）
- Deleted Keys/Teams 審計表 UI

### v1.81.3-stable（2026-02-08）

- Policy Engine
- 21% chat_completion 延遲降低
- MCP 工具回應整合至 chat completions
- 多項 HTTP client 記憶體洩漏修復

### v1.81.9-stable（2026-02-15）

- Claude Opus 4.6 全面支援
- Access Groups
- Team soft budget + email 警報
- Prometheus budget 指標 40% CPU 降低

### v1.81.12-stable.1（2026-02-24）

- Guardrail pipeline 條件序列執行
- Scaleway provider 支援
- MCP StreamableHTTP stateless 修復
- Shell tool 支援

---

## References

- LiteLLM Releases: <https://github.com/BerriAI/litellm/releases>
- PR #16895: <https://github.com/BerriAI/litellm/pull/16895>
- PR #18374: <https://github.com/BerriAI/litellm/pull/18374>
- 完整分析: [docs/research/upgrade-changelog-v1.79-to-v1.81.md](../docs/research/upgrade-changelog-v1.79-to-v1.81.md)
