# 設定變更對照表：v1.79.0 → v1.81.12

> Phase 4c - Configuration changes reference for operations

← [Back to Reports](README.md)

---

- **日期**：2026-02-27
- **階段**：Phase 4 Delivery
- **用途**：運維人員升級前後的設定檢查清單
- **升級路徑**：v1.79.0-stable → v1.81.12-stable.1
- **狀態**：完成
- **資料來源**：[reports/2-upgrade-plan.md](/reports/2-upgrade-plan.md)、[research/upgrade-changelog-v1.79-to-v1.81.md](/research/upgrade-changelog-v1.79-to-v1.81.md)

---

## 執行摘要

本文件提供 v1.79.0 至 v1.81.12 版本間的設定變更對照，包含必須變更、建議變更、無需變更及新增設定項，協助運維人員在升級前進行必要的設定調整。

---

## 1. 必須變更

升級時**必須修改**的設定項目，否則服務無法正常運作：

| # | 項目 | v1.79.0（舊） | v1.81.12（新） | 原因 |
|---|------|-------------|--------------|------|
| 1 | Docker image | `ghcr.io/berriai/litellm:v1.79.0-stable` | `docker.litellm.ai/berriai/litellm:v1.81.12-stable.1` | 映像倉庫遷移 |
| 2 | Health check | `wget --no-verbose --tries=1 ...` | `python3 -c "import urllib.request; ..."` | 新映像不含 wget |

### 1.1 Docker Compose Health Check 對照

**v1.79.0（舊）：**

```yaml
healthcheck:
  test:
    - CMD-SHELL
    - wget --no-verbose --tries=1 http://localhost:4000/health/liveliness || exit 1
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

**v1.81.12（新）：**

```yaml
healthcheck:
  test:
    - CMD-SHELL
    - python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness')" || exit 1
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

---

## 2. 建議變更

預設值已變更，建議根據實際需求**評估是否調整**：

| # | 設定項 | v1.79.0 預設 | v1.81.12 預設 | 建議 |
|---|--------|-------------|--------------|------|
| 1 | `database_connection_pool_limit` | 100 | **10** | 高併發環境設回 100 |
| 2 | `MAX_SIZE_IN_MEMORY_QUEUE` | 10000 | **2000** | 高負載環境視需要調高 |
| 3 | `LITELLM_ASYNCIO_QUEUE_MAXSIZE` | 無上限 | **1000** | 監控佇列使用率 |

### 2.1 如何調整

在 `docker-compose.yml` 的 `environment` 區塊新增：

```yaml
environment:
  # 恢復舊的連線池大小（如需要）
  DATABASE_CONNECTION_POOL_LIMIT: "100"
  # 恢復舊的佇列大小（如需要）
  MAX_SIZE_IN_MEMORY_QUEUE: "10000"
  LITELLM_ASYNCIO_QUEUE_MAXSIZE: "5000"
```

或在 `config.yaml` 的 `general_settings` 中設定：

```yaml
general_settings:
  database_connection_pool_limit: 100
```

---

## 2.5 資料庫連線池設定建議

### 預設值變更影響

| 版本 | 預設值 | 可能影響 |
|------|--------|----------|
| v1.79.0 | 100 | 高併發下有較多連線可用 |
| v1.81.12 | 10 | 可能導致連線等待，增加延遲 |

### 建議設定公式

```
連線池大小 = (CPU 核心數 × 2) + 有效磁碟數
```

對於典型的 4 核心 PostgreSQL：

- **開發/測試環境**：保持 10（預設）
- **生產環境（< 1000 QPS）**：設為 20-30
- **生產環境（> 1000 QPS）**：設為 50-100

### 設定方式

在 `config.yaml` 的 `general_settings` 中：

```yaml
general_settings:
  database_connection_pool_limit: 50  # 根據負載調整
```

或在環境變數中：

```bash
DATABASE_CONNECTION_POOL_LIMIT=50
```

### 驗證方式

```sql
-- 監控當前連線數
SELECT count(*) FROM pg_stat_activity
WHERE datname = 'litellm' AND state = 'active';

-- 監控等待中的連線
SELECT count(*) FROM pg_stat_activity
WHERE datname = 'litellm' AND wait_event_type = 'Client';
```

---

## 3. 無需變更

以下項目已驗證**完全相容**，不需任何修改：

| # | 項目 | 說明 |
|---|------|------|
| 1 | `config.yaml` 整體結構 | 格式與語法不變 |
| 2 | `model_list` 定義 | `gemini/` 前綴語法不變 |
| 3 | `os.environ/` API key 語法 | 環境變數引用方式不變 |
| 4 | `general_settings.master_key` | 解析方式不變 |
| 5 | `litellm_settings.enable_preview_features: true` | **關鍵設定，行為一致，繼續保留** |
| 6 | `DATABASE_URL` 格式 | 連線字串格式不變 |
| 7 | `STORE_MODEL_IN_DB` | 行為不變 |

> **驗證依據**：Phase 1 本機測試及 Phase 3 遠端測試均使用相同的 `config.yaml`，在 v1.79.0 和 v1.81.12 上均正常運作。

---

## 4. 新增設定項

v1.81.12 新增的設定項，可選擇性啟用：

### 4.1 新增 `general_settings` 欄位

| 欄位 | 類型 | 說明 | 預設值 |
|------|------|------|--------|
| `reject_clientside_metadata_tags` | `bool` | 防止使用者透過 tag 影響預算 | `false` |
| `user_mcp_management_mode` | `enum` | 非管理者 MCP server 可見性 | - |
| `store_prompts_in_spend_logs` | `bool` | 在 spend logs 中儲存請求/回應 | `false` |
| `maximum_spend_logs_retention_period` | `str` | Spend logs 保留期限 | - |
| `mcp_internal_ip_ranges` | `List[str]` | MCP 內部網路存取 CIDR | `[]` |
| `mcp_trusted_proxy_ranges` | `List[str]` | MCP 信任反向代理 CIDR | `[]` |

### 4.2 新增環境變數

| 變數 | 預設值 | 說明 |
|------|--------|------|
| `MAX_IMAGE_URL_DOWNLOAD_SIZE_MB` | `50` | 最大圖片下載大小（MB），設 `0` 停用 |
| `LITELLM_ASYNCIO_QUEUE_MAXSIZE` | `1000` | asyncio 佇列上限 |
| `LOGGING_WORKER_CONCURRENCY` | `100` | logging worker 並行任務數 |
| `DEFAULT_FAILURE_THRESHOLD_MINIMUM_REQUESTS` | `5` | 錯誤率 cooldown 前最低請求數 |
| `DISABLE_SCHEMA_UPDATE` | `false` | 停用自動 `prisma db push` |

---

## 5. Docker Compose 完整對照

### v1.79.0

```yaml
version: "3.8"
services:
  litellm:
    image: ghcr.io/berriai/litellm:v1.79.0-stable
    ports:
      - "4000:4000"
    environment:
      DATABASE_URL: "postgresql://llmproxy:dbpassword9090@db:5432/litellm"
      STORE_MODEL_IN_DB: "True"
      LITELLM_MASTER_KEY: "sk-test-key-1234"
    volumes:
      - ./config.yaml:/app/config.yaml
    command: ["--config", "/app/config.yaml", "--port", "4000"]
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test:
        - CMD-SHELL
        - wget --no-verbose --tries=1 http://localhost:4000/health/liveliness || exit 1
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
    volumes:
      - postgres_data:/var/lib/postgresql/data
```

### v1.81.12（變更處以註解標記）

```yaml
version: "3.8"
services:
  litellm:
    # [變更] Docker image 來源
    image: docker.litellm.ai/berriai/litellm:v1.81.12-stable.1
    ports:
      - "4000:4000"
    environment:
      DATABASE_URL: "postgresql://llmproxy:dbpassword9090@db:5432/litellm"
      STORE_MODEL_IN_DB: "True"
      LITELLM_MASTER_KEY: "sk-test-key-1234"
      # [新增/選用] 手動遷移時啟用
      # DISABLE_SCHEMA_UPDATE: "true"
      # [新增/選用] 恢復舊連線池大小
      # DATABASE_CONNECTION_POOL_LIMIT: "100"
    volumes:
      - ./config.yaml:/app/config.yaml
    command: ["--config", "/app/config.yaml", "--port", "4000"]
    depends_on:
      db:
        condition: service_healthy
    # [變更] Health check 方式
    healthcheck:
      test:
        - CMD-SHELL
        - python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness')" || exit 1
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
    volumes:
      - postgres_data:/var/lib/postgresql/data
```

### 5.1 變更摘要

| 行 | 變更類型 | 項目 |
|----|----------|------|
| `image:` | **必須變更** | Docker image 來源 |
| `healthcheck.test` | **必須變更** | wget → python3 urllib |
| `DISABLE_SCHEMA_UPDATE` | 選用新增 | 手動遷移時使用 |
| `DATABASE_CONNECTION_POOL_LIMIT` | 選用新增 | 高併發環境 |

---

## 6. config.yaml 相容性確認

以下是 Zeabur AI Hub 使用的 `config.yaml`，已在 v1.79.0 和 v1.81.12 上驗證相容：

```yaml
model_list:
  - model_name: gemini-2.5-flash
    litellm_params:
      model: gemini/gemini-2.5-flash          # ✅ 語法不變
      api_key: os.environ/VERTEX_API_KEY       # ✅ 語法不變
  - model_name: gemini-2.5-pro
    litellm_params:
      model: gemini/gemini-2.5-pro
      api_key: os.environ/VERTEX_API_KEY
  - model_name: gemini-3-pro
    litellm_params:
      model: gemini/gemini-3-pro-preview
      api_key: os.environ/VERTEX_API_KEY

general_settings:
  master_key: sk-test-key-1234                 # ✅ 解析方式不變

litellm_settings:
  enable_preview_features: true                # ✅ 關鍵設定，行為一致
```

---

## References

- 升級計劃設定章節：[reports/2-upgrade-plan.md](2-upgrade-plan.md) 第 3 章
- 版本變更分析：[research/upgrade-changelog-v1.79-to-v1.81.md](/research/upgrade-changelog-v1.79-to-v1.81.md) 第 6 章
- Phase 3 驗證報告：[reports/3-verification-report.md](3-verification-report.md)
