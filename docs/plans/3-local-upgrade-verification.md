# 第三階段：遠端環境升級驗證計劃

**Date**: 2026-02-27
**Phase**: Phase 3 - Remote Environment Upgrade Verification
**Target Version**: v1.81.12-stable.1
**Environment**: Remote Docker (10.0.1.9)
**Status**: Planning

## Summary

本計劃詳細說明如何在遠端 Docker 環境中執行 LiteLLM 升級驗證（v1.79.0-stable → v1.81.12-stable.1），包含環境建置、資料庫遷移、功能測試及效能比對。

| 任務 | 預估時間 | 相依項目 |
|------|----------|----------|
| 1. Docker 環境建置 | 30 分鐘 | - |
| 2. v1.79.0 基準線建立 | 30 分鐘 | 任務 1 |
| 3. 資料庫遷移測試 | 1 小時 | 任務 2 |
| 4. v1.81.12 升級部署 | 30 分鐘 | 任務 3 |
| 5. 功能迴歸測試 | 1 小時 | 任務 4 |
| 6. thought_signature 驗證 | 30 分鐘 | 任務 4 |
| 7. 效能比對測試 | 30 分鐘 | 任務 4 |
| 8. 回滾測試 | 30 分鐘 | 任務 5, 6, 7 |

---

## 1. Docker 環境建置

### 1.1 目標環境規格

| 項目 | 規格 |
|------|------|
| 伺服器 | 10.0.1.9 (CT108) |
| Docker 版本 | 29.2.1 |
| Docker Compose | v5.1.0 |
| 網路 | 可連線 docker.litellm.ai（新映像倉庫）|
| 磁碟空間 | 40GB (4% used) |
| 記憶體 | 4GB+ |
| SSH | root@10.0.1.9:22 |

詳見 [docs/remote-docker-server.md](../remote-docker-server.md)

### 1.2 目錄結構

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

### 1.3 部署步驟

```bash
# 1. SSH 到遠端伺服器
ssh root@10.0.1.9

# 2. 建立工作目錄
mkdir -p ~/litellm-upgrade-test && cd ~/litellm-upgrade-test

# 3. 建立必要子目錄
mkdir -p config migrations scripts data reports

# 4. 驗證 Docker 環境（本機執行）
ssh root@10.0.1.9 "docker --version"
ssh root@10.0.1.9 "docker-compose --version"

# 5. 預先拉取 Docker 映像
ssh root@10.0.1.9 "docker pull docker.litellm.ai/berriai/litellm:v1.81.12-stable.1"
ssh root@10.0.1.9 "docker pull ghcr.io/berriai/litellm:v1.79.0-stable"
ssh root@10.0.1.9 "docker pull postgres:16"
ssh root@10.0.1.9 "docker pull redis:7-alpine"
```

### 1.4 部署配置到遠端伺服器

```bash
# 從本機複製配置檔案到遠端伺服器
scp -r docs/plans/config root@10.0.1.9:~/litellm-upgrade-test/
scp docker-compose.*.yml root@10.0.1.9:~/litellm-upgrade-test/
scp config.yaml root@10.0.1.9:~/litellm-upgrade-test/config/
```

### 1.5 本地端連線測試

由於測試腳本在本地端執行，需要透過 SSH 通道連線到遠端 LiteLLM 服務：

```bash
# 方法 1：使用 SSH 端口轉發（本機執行）
ssh -L 4000:localhost:4000 root@10.0.1.9

# 方法 2：在背景執行 SSH 通道
ssh -N -L 4000:localhost:4000 root@10.0.1.9 &

# 之後即可使用 localhost:4000 測試
curl http://localhost:4000/health/liveliness
```

---

## 2. 設定檔準備

### 2.1 Base Docker Compose（共用服務）

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

### 2.2 v1.79.0 Docker Compose

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

### 2.3 v1.81.12 Docker Compose

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

### 2.4 LiteLLM 設定檔

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

---

## 3. 資料庫遷移計劃

### 3.1 遷移策略

**選項 A：自動遷移（簡易）**
- 讓 v1.81.12 自動執行 `prisma db push`
- 適合：快速驗證、非生產環境

**選項 B：手動遷移（推薦）**
- 執行 SQL 遷移腳本，保留完整控制
- 適合：生產環境模擬、需要審核每個變更

### 3.2 手動遷移步驟

```bash
# 遠端伺服器上執行：

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

### 3.3 遷移驗證檢查表

| 檢查項目 | 驗證指令 | 預期結果 |
|----------|----------|----------|
| 所有表存在 | `\dt` | 32+ 張表 |
| 新增表 | `SELECT * FROM "LiteLLM_ManagedFileTable" LIMIT 1;` | 無錯誤 |
| 新增欄位 | `SELECT "publicModelName" FROM "LiteLLM_ProxyModelTable" LIMIT 1;` | 無錯誤 |
| 預設值 | `\d "LiteLLM_ProxyModelTable"` | 欄位顯示預設值 |

---

## 4. 測試執行計劃

### 4.1 v1.79.0 基準線測試

```bash
# 遠端伺服器上執行：

# 1. 啟動 v1.79.0
ssh root@10.0.1.9 "cd ~/litellm-upgrade-test && docker compose -f docker-compose.base.yml -f docker-compose.v1.79.0.yml up -d"

# 2. 等待健康檢查通過
sleep 60
ssh root@10.0.1.9 "curl http://localhost:4000/health/liveliness"

# 3. 執行迴歸測試（本地端執行測試，連線遠端 API）
python testing/test_regression.py --host 10.0.1.9 --port 4000 --output reports/baseline-v1.79.0.json

# 4. 執行 thought_signature 測試（預期會顯示無簽章）
python testing/test_gemini_signature.py --host 10.0.1.9 --port 4000 --output reports/signature-v1.79.0.json

# 5. 記錄效能基準
python testing/test_performance.py --host 10.0.1.9 --port 4000 --output reports/perf-v1.79.0.json
```

### 4.2 v1.81.12 升級後測試

```bash
# 遠端伺服器上執行：

# 1. 停止 v1.79.0（保留資料庫）
ssh root@10.0.1.9 "cd ~/litellm-upgrade-test && docker compose -f docker-compose.v1.79.0.yml stop litellm"

# 2. 執行資料庫遷移（若選擇手動遷移）
ssh root@10.0.1.9 "cd ~/litellm-upgrade-test && ./scripts/migrate.sh"

# 3. 啟動 v1.81.12
ssh root@10.0.1.9 "cd ~/litellm-upgrade-test && docker compose -f docker-compose.base.yml -f docker-compose.v1.81.12.yml up -d"

# 4. 等待健康檢查通過
sleep 60
ssh root@10.0.1.9 "curl http://localhost:4000/health/liveliness"

# 5. 執行迴歸測試（本地端執行測試，連線遠端 API）
python testing/test_regression.py --host 10.0.1.9 --port 4000 --output reports/regression-v1.81.12.json

# 6. 執行 thought_signature 測試（預期顯示簽章存在）
python testing/test_gemini_signature.py --host 10.0.1.9 --port 4000 --output reports/signature-v1.81.12.json

# 7. 記錄效能數據
python testing/test_performance.py --host 10.0.1.9 --port 4000 --output reports/perf-v1.81.12.json
```

### 4.3 測試檢查清單

| # | 測試項目 | v1.79.0 預期 | v1.81.12 預期 |
|---|----------|-------------|--------------|
| 1 | Health check | Pass | Pass |
| 2 | 28 項迴歸測試 | 28/28 Pass | 28/28 Pass |
| 3 | Tool call ID 格式 | `call_<hex28>` | `call_<hex28>__thought__<sig>` |
| 4 | thought_signature 保留 | No | Yes |
| 5 | 多輪工具對話 | Pass | Pass |
| 6 | 效能（延遲）| 基準 | 降低 ~21% |

---

## 5. thought_signature 專項驗證

### 5.1 測試情境

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

### 5.2 驗證標準

| 檢查項目 | v1.79.0 | v1.81.12 |
|----------|---------|----------|
| Tool call ID 含 `__thought__` | ❌ No | ✅ Yes |
| Provider specific fields 保留 | ❌ No | ✅ Yes |
| 多輪對話正常 | ✅ Yes | ✅ Yes |

---

## 6. 回滾測試

### 6.1 回滾步驟

```bash
# 遠端伺服器上執行：

# 1. 停止 v1.81.12
ssh root@10.0.1.9 "cd ~/litellm-upgrade-test && docker compose -f docker-compose.v1.81.12.yml stop litellm"

# 2. 啟動 v1.79.0（資料庫已遷移，測試向後相容）
ssh root@10.0.1.9 "cd ~/litellm-upgrade-test && docker compose -f docker-compose.base.yml -f docker-compose.v1.79.0.yml up -d litellm"

# 3. 驗證功能正常
ssh root@10.0.1.9 "curl http://localhost:4000/health/liveliness"
python testing/test_regression.py --host 10.0.1.9 --port 4000

# 4. 確認新增欄位不影響舊版本
```

### 6.2 回滾驗證標準

- v1.79.0 能正常啟動並連線已遷移的資料庫
- 28 項迴歸測試仍全數通過
- 新增的表和欄位不會造成錯誤

---

## 7. 預期產出

### 7.1 測試報告

| 報告檔案 | 內容 |
|----------|------|
| `reports/baseline-v1.79.0.json` | v1.79.0 基準線測試結果 |
| `reports/regression-v1.81.12.json` | v1.81.12 迴歸測試結果 |
| `reports/signature-v1.79.0.json` | thought_signature 基準線 |
| `reports/signature-v1.81.12.json` | thought_signature 修復驗證 |
| `reports/perf-v1.79.0.json` | 效能基準線 |
| `reports/perf-v1.81.12.json` | 升級後效能數據 |
| `reports/phase3-summary.md` | 第三階段總結報告 |

### 7.2 交付物檢查清單

- [ ] Docker 環境建置完成
- [ ] v1.79.0 基準線測試通過
- [ ] 資料庫遷移成功執行
- [ ] v1.81.12 升級部署成功
- [ ] 28 項迴歸測試通過
- [ ] thought_signature 修復驗證通過
- [ ] 回滾測試通過
- [ ] 效能比對報告產出
- [ ] 執行過程問題與解決方案記錄

---

## 8. 風險與因應

| 風險 | 機率 | 影響 | 因應措施 |
|------|------|------|----------|
| Docker 環境網路限制 | 中 | 高 | 事先確認可連線 docker.litellm.ai |
| 資料庫遷移失敗 | 低 | 高 | 使用手動 SQL + 備份 |
| 遠端環境資源不足 | 低 | 中 | 確認 4GB+ 記憶體可用 |
| API 金鑰過期 | 低 | 高 | 準備備用金鑰 |

---

## 9. 執行時程

| 階段 | 時間 | 活動 |
|------|------|------|
| 第 1 小時 | 0:00-0:30 | Docker 環境建置 |
| | 0:30-1:00 | v1.79.0 部署與基準線測試 |
| 第 2 小時 | 1:00-2:00 | 資料庫遷移與驗證 |
| 第 3 小時 | 2:00-3:00 | v1.81.12 升級與功能測試 |
| 第 4 小時 | 3:00-4:00 | thought_signature 驗證與回滾測試 |

**總預估時間**: 4 小時

---

## References

- Phase 1 Report: `reports/1-upgrade-report.md`
- Phase 2 Upgrade Plan: `reports/2-upgrade-plan.md`
- Database Migration SQL: `docs/research/db-schema-migration-v1.79-to-v1.81.md`
- Regression Tests: `testing/test_regression.py`
- thought_signature Tests: `testing/test_gemini_signature.py`
- Remote Docker Server: `docs/remote-docker-server.md`
