# 遠端環境升級驗證報告

- **日期**：2026-02-27
- **階段**：Phase 3 - Remote Environment Upgrade Verification
- **升級路徑**：v1.79.0-stable → v1.81.12-stable.1
- **環境**：遠端 Docker（10.0.1.9, CT108）
- **狀態**：通過

---

## 執行摘要

LiteLLM 從 v1.79.0-stable 升級到 v1.81.12-stable.1 已成功在遠端 Docker 環境中完成驗證。所有測試皆通過，thought_signature 修復已確認有效，且回滾功能安全。

**建議：可進行正式環境升級。**

---

## 驗證計劃概述

| 任務 | 預估時間 | 相依項目 | 實際結果 |
|------|----------|----------|----------|
| 1. Docker 環境建置 | 30 分鐘 | - | 2 分鐘完成 |
| 2. v1.79.0 基準線建立 | 30 分鐘 | 任務 1 | 4 分鐘完成 |
| 3. 資料庫遷移測試 | 1 小時 | 任務 2 | 2 分鐘完成 |
| 4. v1.81.12 升級部署 | 30 分鐘 | 任務 3 | 2 分鐘完成 |
| 5. 功能迴歸測試 | 1 小時 | 任務 4 | 2 分鐘完成 |
| 6. thought_signature 驗證 | 30 分鐘 | 任務 4 | 含於任務 5 |
| 7. 效能比對測試 | 30 分鐘 | 任務 4 | 8 分鐘完成 |
| 8. 回滾測試 | 30 分鐘 | 任務 5, 6, 7 | 2 分鐘完成 |

**總預估時間**: 4 小時 → **實際耗時**: 約 23 分鐘

---

## 環境詳情

| 項目 | 規格 |
|------|------|
| 伺服器 | 10.0.1.9（CT108） |
| Docker | 29.2.1 |
| Docker Compose | v5.1.0 |
| PostgreSQL | 16 |
| Redis | 7-alpine |
| 網路 | 可連線 docker.litellm.ai（新映像倉庫） |
| 磁碟空間 | 40GB (4% used) |
| 記憶體 | 4GB+ |
| SSH | root@10.0.1.9:22 |
| LiteLLM（舊版） | ghcr.io/berriai/litellm:v1.79.0-stable |
| LiteLLM（新版） | docker.litellm.ai/berriai/litellm:v1.81.12-stable.1 |

---

## 部署配置

### 目錄結構

```
~/litellm-upgrade-test/
├── docker-compose.base.yml      # 共用服務定義
├── docker-compose.v1.79.0.yml   # v1.79.0 配置
├── docker-compose.v1.81.12.yml  # v1.81.12 配置
├── config/
│   └── config.yaml              # LiteLLM 設定
├── migrations/
│   ├── migration_phase_a.sql    # v1.79.0 → v1.80.11
│   └── migration_phase_b.sql    # v1.80.11 → v1.81.12
├── scripts/
│   ├── setup.sh                 # 環境初始化
│   ├── migrate.sh               # 資料庫遷移
│   ├── test.sh                  # 測試執行
│   └── rollback.sh              # 回滾腳本
├── data/                        # 資料庫資料（掛載）
└── reports/                     # 測試報告輸出
```

### Base Docker Compose（共用服務）

```yaml
# docker-compose.base.yml
version: "3.8"

services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: litellm
      POSTGRES_USER: llmproxy
      POSTGRES_PASSWORD: dbpassword9090
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U llmproxy -d litellm"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - ./data/redis:/data
```

### v1.79.0 Docker Compose

```yaml
# docker-compose.v1.79.0.yml
version: "3.8"

services:
  litellm:
    image: ghcr.io/berriai/litellm:v1.79.0-stable
    ports:
      - "4000:4000"
    environment:
      DATABASE_URL: "postgresql://llmproxy:dbpassword9090@db:5432/litellm"
      STORE_MODEL_IN_DB: "True"
      VERTEX_API_KEY: ${VERTEX_API_KEY}
    volumes:
      - ./config/config.yaml:/app/config.yaml
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
```

### v1.81.12 Docker Compose

```yaml
# docker-compose.v1.81.12.yml
version: "3.8"

services:
  litellm:
    image: docker.litellm.ai/berriai/litellm:v1.81.12-stable.1
    ports:
      - "4000:4000"
    environment:
      DATABASE_URL: "postgresql://llmproxy:dbpassword9090@db:5432/litellm"
      STORE_MODEL_IN_DB: "True"
      VERTEX_API_KEY: ${VERTEX_API_KEY}
      # DISABLE_SCHEMA_UPDATE: "true"  # 若手動遷移則啟用
    volumes:
      - ./config/config.yaml:/app/config.yaml
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test:
        - CMD-SHELL
        - python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness')" || exit 1
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### LiteLLM 設定檔

```yaml
# config/config.yaml
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

### 配置說明

驗證過程中發現並修復了兩個配置問題：

1. **配置文件路徑**：Docker 映像的預設 CMD（`--port 4000`）不包含 `--config /app/config.yaml`。必須在 docker-compose 中新增 `command` 指令：

   ```yaml
   command: ["--config", "/app/config.yaml", "--port", "4000"]
   ```

2. **主金鑰環境變數**：使用 `STORE_MODEL_IN_DB: "True"` 時，主金鑰除了在 config.yaml 中設定外，還必須設定 `LITELLM_MASTER_KEY` 環境變數，以避免啟動競爭條件。

---

## 資料庫遷移

### 遷移策略

**選項 A：自動遷移（簡易）**

- 讓 v1.81.12 自動執行 `prisma db push`
- 適合：快速驗證、非生產環境

**選項 B：手動遷移（推薦）**

- 執行 SQL 遷移腳本，保留完整控制
- 適合：生產環境模擬、需要審核每個變更

### 手動遷移步驟

```bash
# Step 1: 啟動基礎服務（僅 PostgreSQL）
ssh root@10.0.1.9 "cd ~/litellm-upgrade-test && docker compose -f docker-compose.base.yml up -d"

# Step 2: 等待資料庫就緒
ssh root@10.0.1.9 "docker exec litellm-upgrade-test-db-1 pg_isready -U llmproxy -d litellm"

# Step 3: 執行 Phase A 遷移（v1.79.0 → v1.80.11）
ssh root@10.0.1.9 "docker exec -i litellm-upgrade-test-db-1 psql -U llmproxy -d litellm" < migrations/migration_phase_a.sql

# Step 4: 執行 Phase B 遷移（v1.80.11 → v1.81.12）
ssh root@10.0.1.9 "docker exec -i litellm-upgrade-test-db-1 psql -U llmproxy -d litellm" < migrations/migration_phase_b.sql

# Step 5: 驗證遷移結果
ssh root@10.0.1.9 "docker exec litellm-upgrade-test-db-1 psql -U llmproxy -d litellm -c '\dt'"
```

### 遷移結果

| 指標 | 升級前（v1.79.0） | 升級後（v1.81.12） |
|--------|-------------------|-------------------|
| 資料表數量 | 40 | 55 |
| 遷移方式 | Prisma 自動遷移 | Prisma 自動遷移 |
| 遷移狀態 | 不適用 | 所有遷移已套用 |
| 遷移後檢查 | 不適用 | 通過 |
| 向後相容 | 不適用 | 是（v1.79.0 可在 v1.81.12 結構上執行） |

### 遷移驗證檢查表

| 檢查項目 | 驗證指令 | 預期結果 |
|----------|----------|----------|
| 所有表存在 | `\dt` | 32+ 張表 |
| 新增表 | `SELECT * FROM "LiteLLM_ManagedFileTable" LIMIT 1;` | 無錯誤 |
| 新增欄位 | `SELECT "publicModelName" FROM "LiteLLM_ProxyModelTable" LIMIT 1;` | 無錯誤 |
| 預設值 | `\d "LiteLLM_ProxyModelTable"` | 欄位顯示預設值 |

---

## 測試結果

### 測試執行步驟

```bash
# v1.79.0 基準線測試
ssh root@10.0.1.9 "cd ~/litellm-upgrade-test && docker compose -f docker-compose.base.yml -f docker-compose.v1.79.0.yml up -d"
python testing/local/test_regression.py --host 10.0.1.9 --port 4000 --output reports/test-outputs/baseline-v1.79.0.json
python testing/local/test_gemini_signature.py --host 10.0.1.9 --port 4000 --output reports/test-outputs/signature-v1.79.0.json
python testing/local/test_performance.py --host 10.0.1.9 --port 4000 --output reports/test-outputs/perf-v1.79.0.json

# v1.81.12 升級後測試
ssh root@10.0.1.9 "cd ~/litellm-upgrade-test && docker compose -f docker-compose.v1.79.0.yml stop litellm"
ssh root@10.0.1.9 "cd ~/litellm-upgrade-test && docker compose -f docker-compose.base.yml -f docker-compose.v1.81.12.yml up -d"
python testing/local/test_regression.py --host 10.0.1.9 --port 4000 --output reports/test-outputs/regression-v1.81.12.json
python testing/local/test_gemini_signature.py --host 10.0.1.9 --port 4000 --output reports/test-outputs/signature-v1.81.12.json
python testing/local/test_performance.py --host 10.0.1.9 --port 4000 --output reports/test-outputs/perf-v1.81.12.json
```

### 回歸測試（28 項測試）

| 版本 | 通過 | 失敗 | 結果 |
|---------|--------|--------|--------|
| v1.79.0（基準線） | 28/28 | 0 | 全部通過 |
| v1.81.12（升級後） | 28/28 | 0 | 全部通過 |
| v1.79.0（回滾） | 28/28 | 0 | 全部通過 |

### 測試細項（28 項回歸測試）

| # | 類別 | 測試項目 | v1.79.0 | v1.81.12 | 回滾 |
|---|----------|------|---------|----------|----------|
| 1 | 健康檢查 | GET /health 返回 200 | 通過 | 通過 | 通過 |
| 2 | 健康檢查 | 健康檢查報告模型正常 | 通過 | 通過 | 通過 |
| 3 | 健康檢查 | GET /health/liveliness 返回 200 | 通過 | 通過 | 通過 |
| 4 | 健康檢查 | GET /health/readiness 返回 200 | 通過 | 通過 | 通過 |
| 5 | 模型 | GET /v1/models 返回模型列表 | 通過 | 通過 | 通過 |
| 6 | 模型 | 模型列表包含 'gemini-2.5-flash' | 通過 | 通過 | 通過 |
| 7 | 模型 | 模型列表包含 'gemini-2.5-pro' | 通過 | 通過 | 通過 |
| 8 | 模型 | 模型列表包含 'gemini-3-pro' | 通過 | 通過 | 通過 |
| 9 | 對話 | POST /v1/chat/completions | 通過 | 通過 | 通過 |
| 10 | 對話 | 回應包含 usage 資訊 | 通過 | 通過 | 通過 |
| 11 | 對話 | 回應包含 model 欄位 | 通過 | 通過 | 通過 |
| 12 | 對話 | finish reason 為 'stop' | 通過 | 通過 | 通過 |
| 13 | 串流 | 串流返回多個區塊 | 通過 | 通過 | 通過 |
| 14 | 串流 | 第一個區塊有 role='assistant' | 通過 | 通過 | 通過 |
| 15 | 串流 | 最後一個區塊有 finish_reason='stop' | 通過 | 通過 | 通過 |
| 16 | 串流 | 串流內容非空 | 通過 | 通過 | 通過 |
| 17 | 工具 | 工具呼叫返回 tool_calls | 通過 | 通過 | 通過 |
| 18 | 工具 | 工具呼叫包含 function name | 通過 | 通過 | 通過 |
| 19 | 工具 | 工具呼叫包含有效 arguments | 通過 | 通過 | 通過 |
| 20 | 工具 | 工具呼叫包含 ID | 通過 | 通過 | 通過 |
| 21 | 工具 | 多輪：初始工具呼叫已接收 | 通過 | 通過 | 通過 |
| 22 | 工具 | 多輪：工具結果後的最終回應 | 通過 | 通過 | 通過 |
| 23 | 錯誤 | 無效模型返回錯誤 | 通過 | 通過 | 通過 |
| 24 | 錯誤 | 無效金鑰返回錯誤 | 通過 | 通過 | 通過 |
| 25 | 工具 | POST /utils/token_counter 返回 200 | 通過 | 通過 | 通過 |
| 26 | 工具 | GET /v1/model/info 返回 200 | 通過 | 通過 | 通過 |
| 27 | 工具 | 模型資訊包含已配置的模型 | 通過 | 通過 | 通過 |
| 28 | 工具 | GET /routes 返回 200 | 通過 | 通過 | 通過 |

---

## thought_signature 專項驗證

### 測試情境

```bash
# 情境 1：基本工具呼叫
curl -X POST http://10.0.1.9:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-test-key-1234" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-2.5-flash",
    "messages": [{"role": "user", "content": "What is the weather in Tokyo?"}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "get_weather",
        "parameters": {"type": "object", "properties": {"city": {"type": "string"}}}
      }
    }]
  }'

# 檢查回應中 tool_calls[0].id 是否包含 "__thought__"
```

### 驗證結果

| 檢查項目 | v1.79.0 | v1.81.12 |
|-------|---------|----------|
| 工具呼叫 ID 包含 `__thought__` | 否 | **是** |
| Provider specific fields 保留 | 否 | **是** |
| 基本工具呼叫來回測試 | 通過 | 通過 |
| 多輪多工具對話 | 通過 | 通過 |
| 多輪含工具結果 | 通過 | 通過 |

**v1.79.0 工具呼叫 ID**（簽章已移除）：

```
call_70c754b500124dd59dc5bac483f7
```

**v1.81.12 工具呼叫 ID**（簽章已保留）：

```
call_9d5001a4996649f9b2da20855b39__thought__Co8CAb4+9vtqDGoRj3RPv/40SN2X...
```

---

## 效能比對測試

測試模型：gemini-2.5-flash，每項基準測試 10 輪。

| 基準測試 | v1.79.0 中位數 | v1.81.12 中位數 | 差異 |
|----------|---------------|----------------|------|
| 對話完成 | 0.732s | 0.736s | +0.5% |
| 串流完成 | 1.025s | 0.979s | -4.5% |
| 首位元組時間 (TTFB) | 0.905s | 0.926s | +2.3% |
| 工具呼叫 | 1.254s | 1.272s | +1.4% |
| 多輪工具 | 2.304s | 2.394s | +3.9% |

### 詳細統計

| 基準測試 | 版本 | 平均 | 中位數 | P95 | 最小 | 最大 | 標準差 |
|----------|------|------|--------|-----|------|------|--------|
| 對話完成 | v1.79.0 | 0.777s | 0.732s | 0.979s | 0.683s | 0.979s | 0.104s |
| | v1.81.12 | 0.776s | 0.736s | 1.211s | 0.664s | 1.211s | 0.155s |
| 串流完成 | v1.79.0 | 1.029s | 1.025s | 1.275s | 0.812s | 1.275s | 0.128s |
| | v1.81.12 | 0.968s | 0.979s | 1.093s | 0.846s | 1.093s | 0.087s |
| TTFB | v1.79.0 | 0.900s | 0.905s | 0.962s | 0.842s | 0.962s | 0.038s |
| | v1.81.12 | 0.980s | 0.926s | 1.378s | 0.813s | 1.378s | 0.169s |
| 工具呼叫 | v1.79.0 | 1.364s | 1.254s | 2.160s | 1.000s | 2.160s | 0.359s |
| | v1.81.12 | 1.307s | 1.272s | 1.687s | 0.996s | 1.687s | 0.213s |
| 多輪工具 | v1.79.0 | 2.390s | 2.304s | 3.279s | 1.848s | 3.279s | 0.394s |
| | v1.81.12 | 2.381s | 2.394s | 2.807s | 1.946s | 2.807s | 0.236s |

> **分析**：10 輪測試結果顯示兩版本效能差異均在 5% 以內，屬於正常網路波動範圍。v1.81.12 的工具呼叫標準差較低（0.213s vs 0.359s），表示延遲更穩定。整體而言，升級不會造成效能退步。

---

## 回滾測試

### 回滾步驟

```bash
# 1. 停止 v1.81.12
ssh root@10.0.1.9 "cd ~/litellm-upgrade-test && docker compose -f docker-compose.v1.81.12.yml stop litellm"

# 2. 啟動 v1.79.0（資料庫已遷移，測試向後相容）
ssh root@10.0.1.9 "cd ~/litellm-upgrade-test && docker compose -f docker-compose.base.yml -f docker-compose.v1.79.0.yml up -d litellm"

# 3. 驗證功能正常
ssh root@10.0.1.9 "curl http://localhost:4000/health/liveliness"
python testing/local/test_regression.py --host 10.0.1.9 --port 4000
```

### 回滾結果

| 檢查項目 | 結果 |
|-------|--------|
| v1.79.0 在已遷移的資料庫上啟動 | 通過 |
| 健康檢查通過 | 通過 |
| 28/28 回歸測試通過 | 通過 |
| 結構向後相容性 | 確認 |

---

## 風險與因應

| 風險 | 機率 | 影響 | 因應措施 |
|------|------|------|----------|
| Docker 環境網路限制 | 中 | 高 | 事先確認可連線 docker.litellm.ai |
| 資料庫遷移失敗 | 低 | 高 | 使用手動 SQL + 備份 |
| 遠端環境資源不足 | 低 | 中 | 確認 4GB+ 記憶體可用 |
| API 金鑰過期 | 低 | 高 | 準備備用金鑰 |

---

## 交付項目清單

- [x] 遠端伺服器上建構 Docker 環境
- [x] v1.79.0 基準線測試通過（28/28）
- [x] 執行資料庫遷移（40 → 55 資料表）
- [x] 成功部署 v1.81.12 升級
- [x] v1.81.12 上 28/28 回歸測試通過
- [x] 驗證 thought_signature 修復（ID 包含 `__thought__`）
- [x] 回滾測試通過（已遷移資料庫上的 v1.79.0）
- [x] 效能比對報告產出
- [x] 記錄配置問題
- [x] 保存所有測試報告

---

## 報告檔案

| 檔案 | 說明 |
|------|-------------|
| `reports/test-outputs/baseline-v1.79.0.txt` | v1.79.0 回歸基準線 |
| `reports/test-outputs/signature-v1.79.0.txt` | v1.79.0 thought_signature 基準線 |
| `reports/test-outputs/regression-v1.81.12.txt` | v1.81.12 回歸測試結果 |
| `reports/test-outputs/signature-v1.81.12.txt` | v1.81.12 thought_signature 驗證 |
| `reports/test-outputs/rollback-v1.79.0.txt` | 回滾回歸測試結果 |
| `reports/test-outputs/perf-v1.79.0.json` | v1.79.0 效能基準線 |
| `reports/test-outputs/perf-v1.81.12.json` | v1.81.12 效能數據 |

---

## 時間表

| 時間 | 活動 | 耗時 |
|------|----------|----------|
| 10:26 | 環境設定 + 映像拉取 | 2 分鐘 |
| 10:28 | v1.79.0 部署（含配置修復） | 4 分鐘 |
| 10:32 | 基準線測試 | 2 分鐘 |
| 10:34 | v1.81.12 升級 + 遷移 | 2 分鐘 |
| 10:35 | v1.81.12 測試 | 2 分鐘 |
| 10:36 | 回滾測試 | 2 分鐘 |
| 10:37 | 清理 + 報告 | 1 分鐘 |
| 12:39 | v1.79.0 效能測試 | 3 分鐘 |
| 12:41 | v1.81.12 效能測試 | 5 分鐘 |
| **總計** | | **約 23 分鐘** |

---

## References

- Phase 1 Report: `reports/1-environment-report.md`
- Phase 2 Upgrade Plan: `reports/2-upgrade-plan.md`
- Database Migration SQL: `docs/research/db-schema-migration-v1.79-to-v1.81.md`
- Regression Tests: `testing/local/test_regression.py`
- thought_signature Tests: `testing/local/test_gemini_signature.py`
- Performance Tests: `testing/local/test_performance.py`
