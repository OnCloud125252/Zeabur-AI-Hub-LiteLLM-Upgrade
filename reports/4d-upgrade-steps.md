# 升級步驟：Step-by-Step 操作手冊

- **日期**：2026-02-27
- **用途**：運維人員可直接依循的升級操作手冊
- **資料來源**：[reports/2-upgrade-plan.md](2-upgrade-plan.md)

---

## 前置檢查清單

在開始升級前，請逐項確認：

### 環境確認

- [ ] Python 版本 >= 3.9（v1.81.12 要求）
- [ ] Docker daemon 可連線至 `docker.litellm.ai`（新映像倉庫）
- [ ] 確認 `enable_preview_features: true` 在 config.yaml 中
- [ ] 記錄當前 Docker image tag：`ghcr.io/berriai/litellm:v1.79.0-stable`
- [ ] 事先拉取新映像：`docker pull docker.litellm.ai/berriai/litellm:v1.81.12-stable.1`

### 資料備份

- [ ] **資料庫完整備份**（最關鍵步驟）

  ```bash
  pg_dump -Fc -d litellm -f litellm_backup_$(date +%Y%m%d_%H%M%S).dump
  ```

- [ ] 記錄備份檔案位置及大小
- [ ] 驗證備份可還原（在測試環境嘗試）

### 設定快照

- [ ] 備份 `config.yaml`
- [ ] 備份 `.env`（環境變數）
- [ ] 備份 `docker-compose.yml`

### 健康基線

- [ ] 記錄目前系統指標（延遲、錯誤率、記憶體使用量）
- [ ] 執行 health check：`GET /health/liveliness` → `"I'm alive!"`
- [ ] 記錄目前已連線的模型狀態

---

## 方案 A：Blue-Green 部署（推薦）

**預估停機時間**：< 30 秒
**適用條件**：有 load balancer 或 Kubernetes 環境

### Step 1：執行資料庫遷移

> 所有 schema 變更都是可加性的（新表、新欄位帶預設值），可以**安全地在 v1.79.0 仍在運行時執行**。

```bash
# 連接至 PostgreSQL
psql -h <db-host> -U llmproxy -d litellm

# 執行 Phase A 遷移（v1.79.0 → v1.80.11）
\i migration_phase_a.sql
# 預期輸出: BEGIN → 多個 CREATE TABLE/ALTER TABLE → COMMIT

# 執行 Phase B 遷移（v1.80.11 → v1.81.12）
\i migration_phase_b.sql
# 預期輸出: BEGIN → 多個 CREATE TABLE/ALTER TABLE → COMMIT
```

**驗證遷移**：

```bash
# 確認表數量
psql -h <db-host> -U llmproxy -d litellm -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';"
# 預期結果: 55
```

> **替代方案**：如果選擇讓 v1.81.12 自動執行 `prisma db push`，可跳過此步驟。但建議設定 `DISABLE_SCHEMA_UPDATE=true` 搭配手動遷移。

### Step 2：部署新版本實例

```yaml
# docker-compose.new.yml
services:
  litellm-new:
    image: docker.litellm.ai/berriai/litellm:v1.81.12-stable.1
    ports: ["4001:4000"]  # 暫時使用不同 port
    environment:
      DATABASE_URL: "postgresql://llmproxy:dbpassword9090@db:5432/litellm"
      STORE_MODEL_IN_DB: "True"
      LITELLM_MASTER_KEY: "sk-your-master-key"
      DISABLE_SCHEMA_UPDATE: "true"  # 已手動遷移
    volumes:
      - ./config.yaml:/app/config.yaml
    command: ["--config", "/app/config.yaml", "--port", "4000"]
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

啟動新實例：

```bash
docker compose -f docker-compose.new.yml up -d
```

### Step 3：驗證新實例

```bash
# 健康檢查
curl http://localhost:4001/health/liveliness
# 預期回傳: "I'm alive!"

# 模型列表
curl -H "Authorization: Bearer sk-your-master-key" http://localhost:4001/v1/models
# 預期回傳: 包含已設定的模型

# 快速功能測試
curl -X POST http://localhost:4001/v1/chat/completions \
  -H "Authorization: Bearer sk-your-master-key" \
  -H "Content-Type: application/json" \
  -d '{"model": "gemini-2.5-flash", "messages": [{"role": "user", "content": "Say hello"}]}'
# 預期回傳: 正常的 chat completion 回應
```

### Step 4：切換流量

```bash
# 在 load balancer 將流量從 :4000 切換至 :4001
# 或在 Kubernetes 中更新 Deployment image tag

# 確認新實例接收流量正常
# 監控錯誤率至少 5 分鐘
```

### Step 5：停用舊實例

```bash
# 確認無問題後，停止舊版本
docker stop litellm-old

# 可選：將新實例 port 改回 4000
# 修改 docker-compose.yml 並重啟
```

---

## 方案 B：停機升級（簡易）

**預估停機時間**：5-10 分鐘
**適用條件**：可接受短暫停機，環境較簡單

### Step 1：停止 Proxy

```bash
docker compose down
# 預期: 所有服務停止（保留資料庫 volume）
```

### Step 2：備份資料庫

```bash
# 確保 PostgreSQL 仍在運行（或單獨啟動）
docker compose up -d db
sleep 5

pg_dump -Fc -h localhost -U llmproxy -d litellm -f litellm_backup_$(date +%Y%m%d_%H%M%S).dump
# 預期: 產生 .dump 備份檔案
```

### Step 3：更新設定

修改 `docker-compose.yml`：

```yaml
services:
  litellm:
    # 1. 更新映像來源
    image: docker.litellm.ai/berriai/litellm:v1.81.12-stable.1

    # 2. 更新 health check
    healthcheck:
      test:
        - CMD-SHELL
        - python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness')" || exit 1
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Step 4：啟動新版本

**選項 A：自動遷移（較簡易）**

```bash
docker compose up -d
# LiteLLM 啟動時自動執行 prisma db push
# 等待 health check 通過（約 40 秒 start_period）
```

**選項 B：手動遷移（較安全，推薦）**

```bash
# 先確保 DB 啟動
docker compose up -d db
sleep 5

# 執行 SQL 遷移腳本
psql -h localhost -U llmproxy -d litellm -f migration_phase_a.sql
psql -h localhost -U llmproxy -d litellm -f migration_phase_b.sql

# 設定 DISABLE_SCHEMA_UPDATE=true 並啟動
# 在 docker-compose.yml 中新增環境變數，或：
DISABLE_SCHEMA_UPDATE=true docker compose up -d
```

### Step 5：驗證

```bash
# 等待 health check 通過（start_period: 40s）
sleep 45

curl http://localhost:4000/health/liveliness
# 預期: "I'm alive!"

curl -H "Authorization: Bearer sk-your-master-key" http://localhost:4000/v1/models
# 預期: 包含已設定的模型
```

---

## 升級後驗證清單

### 自動化測試

```bash
# 執行 28 項迴歸測試
python testing/local/test_regression.py --host <proxy-host> --port 4000

# 執行 thought_signature 整合測試
python testing/local/test_gemini_signature.py --host <proxy-host> --port 4000
```

### 手動驗證

- [ ] `GET /health/liveliness` → `"I'm alive!"`
- [ ] `GET /health/readiness` → 200
- [ ] `GET /v1/models` → 包含所有已設定模型
- [ ] `POST /v1/chat/completions`（非串流）→ 正常回應
- [ ] `POST /v1/chat/completions`（串流）→ SSE chunks 正常
- [ ] Tool calling → tool_calls 回應正常
- [ ] 多輪工具呼叫 → 完整對話流程正常
- [ ] 無效模型/金鑰 → 正確錯誤回應

### thought_signature 專項驗證

```bash
curl -X POST http://<proxy-host>:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-your-master-key" \
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
```

**檢查重點**：回應中的 `tool_calls[0].id` 應包含 `__thought__` 字串，例如：

```
call_9d5001a4996649f9b2da20855b39__thought__Co8CAb4+9vtqDGoRj3RPv/...
```

如果 tool call ID 不包含 `__thought__`，請確認：

1. `config.yaml` 中 `enable_preview_features: true` 已設定
2. 使用的模型支援 thinking mode（如 gemini-2.5-flash、gemini-3-pro）

---

## References

- 升級計劃：[reports/2-upgrade-plan.md](2-upgrade-plan.md)
- 設定變更：[reports/4c-config-comparison.md](4c-config-comparison.md)
- 資料庫遷移：[reports/4b-db-migration-guide.md](4b-db-migration-guide.md)
- 回滾方案：[reports/4e-rollback-plan.md](4e-rollback-plan.md)
