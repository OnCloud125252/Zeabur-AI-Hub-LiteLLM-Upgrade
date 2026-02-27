# 升級計劃：LiteLLM v1.79.0-stable → v1.81.12-stable.1

**Date**: 2026-02-27  
**Target Version**: v1.81.12-stable.1  
**Status**: Complete

## Overview

本升級計劃詳細說明從 LiteLLM v1.79.0-stable 升級至 v1.81.12-stable.1 的完整流程。升級的主要驅動因素是修復 Gemini `thought_signature` 503 錯誤（PR #16895 + #18374），同時獲得 4 個月的效能改善、安全修補及新功能。

### 升級策略

**直接跳躍**：v1.79.0 → v1.81.12-stable.1（跳過中間版本）

理由：

- Prisma schema 變更是累積性的，中間版本不需逐步遷移
- 所有 schema 變更都是可加性的（新表 + 新欄位 + 預設值）
- v1.81.12-stable.1 已包含所有 v1.80.x / v1.81.x 的修復

---

## 1. 前置檢查清單

### 1.1 環境確認

- [ ] Python 版本 >= 3.9（v1.81.12 要求）
- [ ] Docker daemon 可連線至 `docker.litellm.ai`（新映像倉庫）
- [ ] 確認 `enable_preview_features: true` 在 config.yaml 中
- [ ] 記錄當前 Docker image tag：`ghcr.io/berriai/litellm:v1.79.0-stable`
- [ ] 確認現有 28 項迴歸測試在 v1.79.0 上全數通過

### 1.2 資料備份

- [ ] **資料庫完整備份**（最關鍵步驟）

  ```bash
  pg_dump -Fc -d litellm -f litellm_backup_$(date +%Y%m%d_%H%M%S).dump
  ```

- [ ] 記錄備份檔案位置及大小
- [ ] 驗證備份可還原（在測試環境嘗試）

### 1.3 設定快照

- [ ] 備份 `config.yaml`
- [ ] 備份 `.env`（環境變數）
- [ ] 備份 `docker-compose.yml`
- [ ] 記錄 Kubernetes/Docker 部署參數

### 1.4 健康基線

- [ ] 記錄目前系統指標（延遲、錯誤率、記憶體使用量）
- [ ] 執行 health check：`GET /health/liveliness` → `"I'm alive!"`
- [ ] 記錄目前已連線的模型狀態

---

## 2. 升級步驟

### 方案 A：Blue-Green 部署（推薦）

**預估停機時間**：< 30 秒
**適用條件**：有 load balancer 或 Kubernetes 環境

#### Step 1：執行資料庫遷移（可在舊版本運行中執行）

所有 schema 變更都是可加性的（新表、新欄位帶預設值），因此可以**安全地在 v1.79.0 仍在運行時執行**。

```bash
# 連接至 PostgreSQL
psql -h <db-host> -U llmproxy -d litellm

# 執行 Phase A 遷移（v1.79.0 → v1.80.11）
\i migration_phase_a.sql

# 執行 Phase B 遷移（v1.80.11 → v1.81.12）
\i migration_phase_b.sql
```

SQL 腳本詳見 `docs/db-schema-migration-v1.79-to-v1.81.md`。

> **重要**：如果選擇讓 v1.81.12 自動執行 `prisma db push`（而非手動 SQL），可跳過此步驟。但建議設定 `DISABLE_SCHEMA_UPDATE=true` 搭配手動遷移，以獲得更好的控制。

#### Step 2：部署新版本實例

```yaml
# docker-compose.yml (v1.81.12)
services:
  litellm-new:
    image: docker.litellm.ai/berriai/litellm:v1.81.12-stable.1
    ports: ["4001:4000"]  # 暫時使用不同 port
    environment:
      DATABASE_URL: "postgresql://llmproxy:dbpassword9090@db:5432/litellm"
      STORE_MODEL_IN_DB: "True"
      DISABLE_SCHEMA_UPDATE: "true"  # 已手動遷移，停用自動遷移
    volumes:
      - ./config.yaml:/app/config.yaml
    healthcheck:
      test:
        - CMD-SHELL
        - python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness')"
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

#### Step 3：驗證新實例

```bash
# 健康檢查
curl http://localhost:4001/health/liveliness
# 期望回傳: "I'm alive!"

# 模型列表
curl -H "Authorization: Bearer sk-test-key-1234" http://localhost:4001/v1/models
# 期望回傳: 包含 gemini-2.5-flash, gemini-2.5-pro, gemini-3-pro

# 快速功能測試
curl -X POST http://localhost:4001/v1/chat/completions \
  -H "Authorization: Bearer sk-test-key-1234" \
  -H "Content-Type: application/json" \
  -d '{"model": "gemini-2.5-flash", "messages": [{"role": "user", "content": "Say hello"}]}'
```

#### Step 4：切換流量

```bash
# 在 load balancer 將流量從 :4000 切換至 :4001
# 或在 Kubernetes 中更新 Deployment image tag

# 確認新實例接收流量正常
# 監控錯誤率至少 5 分鐘
```

#### Step 5：停用舊實例

```bash
# 確認無問題後，停止舊版本
docker stop litellm-old
```

---

### 方案 B：停機升級（簡易）

**預估停機時間**：5-10 分鐘
**適用條件**：可接受短暫停機

#### Step 1：停止 Proxy

```bash
docker-compose down
```

#### Step 2：備份資料庫

```bash
pg_dump -Fc -d litellm -f litellm_backup_$(date +%Y%m%d_%H%M%S).dump
```

#### Step 3：更新設定

```yaml
# docker-compose.yml 修改
services:
  litellm:
    # 更新映像來源
    image: docker.litellm.ai/berriai/litellm:v1.81.12-stable.1
    # 更新 health check
    healthcheck:
      test:
        - CMD-SHELL
        - python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness')"
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

#### Step 4：啟動新版本

```bash
# 選項 A：讓 LiteLLM 自動遷移 schema（較簡易但控制較少）
docker-compose up -d

# 選項 B：手動遷移 schema（較安全）
# 先執行 SQL 遷移腳本
psql -h <db-host> -U llmproxy -d litellm -f migration_phase_a.sql
psql -h <db-host> -U llmproxy -d litellm -f migration_phase_b.sql
# 再設定 DISABLE_SCHEMA_UPDATE=true 啟動
DISABLE_SCHEMA_UPDATE=true docker-compose up -d
```

#### Step 5：驗證

```bash
# 等待 health check 通過（start_period: 40s）
curl http://localhost:4000/health/liveliness
curl -H "Authorization: Bearer sk-test-key-1234" http://localhost:4000/v1/models
```

---

## 3. 設定變更

### 3.1 必須變更

| 項目 | 變更 | 說明 |
|------|------|------|
| Docker image | `ghcr.io/...` → `docker.litellm.ai/...` | 映像倉庫遷移 |
| Health check | `wget` → `python3 urllib` | 基礎映像不再包含 wget |

### 3.2 建議變更

| 項目 | 變更 | 說明 |
|------|------|------|
| `database_connection_pool_limit` | 視需要設為 `100` | 預設值從 100 降至 10 |
| `MAX_SIZE_IN_MEMORY_QUEUE` | 視需要設為 `10000` | 預設值從 10000 降至 2000 |

### 3.3 無需變更

| 項目 | 說明 |
|------|------|
| `config.yaml` | 已驗證完全相容 |
| `enable_preview_features: true` | 行為不變，繼續保留 |
| 模型定義（`gemini/` 前綴） | 語法不變 |
| `os.environ/` API key 語法 | 解析方式不變 |

---

## 4. 回滾計劃

### 4.1 回滾觸發條件

- Health check 持續失敗超過 5 分鐘
- 核心 API（`/v1/chat/completions`）錯誤率 > 5%
- 資料庫連線錯誤
- 已知 regression 影響業務

### 4.2 回滾步驟

#### 快速回滾（方案 A：Blue-Green 部署）

```bash
# 只需切換 load balancer 回舊實例
# 停機時間: < 30 秒
```

#### 完整回滾（方案 B：停機升級）

```bash
# Step 1: 停止新版本
docker-compose down

# Step 2: 還原 docker-compose.yml
# 將 image 改回 ghcr.io/berriai/litellm:v1.79.0-stable
# 將 health check 改回 wget

# Step 3: 還原資料庫（如果執行了手動 SQL 遷移）
pg_restore -d litellm -c litellm_backup_YYYYMMDD_HHMMSS.dump

# Step 4: 啟動舊版本
docker-compose up -d
```

### 4.3 資料庫回滾注意事項

- **新增的表和欄位不會影響舊版本運作**。v1.79.0 會忽略它不認識的表和欄位。
- 因此在多數情況下，**不需要還原資料庫**即可回滾——只需切換回舊版 Docker image。
- 唯一例外：如果 `prisma db push --accept-data-loss` 修改了現有表結構（如 unique constraint），且舊版本依賴原始結構，才需要還原資料庫。

---

## 5. 風險矩陣

| 風險 | 機率 | 影響 | 緩解措施 |
|------|------|------|----------|
| DB schema 遷移失敗 | 低 | 高 | 使用手動 SQL 遷移 + 事先備份 |
| `prisma db push --accept-data-loss` 丟失資料 | 低 | 高 | 設定 `DISABLE_SCHEMA_UPDATE=true` |
| Docker image pull 失敗（新倉庫） | 低 | 中 | 事先 `docker pull` 確認可存取 |
| OpenAI SDK v2 不相容 | 極低 | 中 | 我們透過 proxy 使用，不直接依賴 |
| Health check 失敗 | 低 | 低 | 已更新為 python3 urllib |
| 記憶體佇列大小變更導致花費遺失 | 低 | 低 | 監控佇列使用率，必要時調高 |
| Gemini thought_signature 仍有問題 | 極低 | 高 | v1.80.11 已驗證修復，v1.81.12 包含額外修正 |

### 已知問題（v1.81.x 系列）

| 問題 | 狀態 | 影響 |
|------|------|------|
| MCP StreamableHTTP stateless bug | 已在 v1.81.12-stable.1 修復 | 使用 MCP 時可能影響 |
| Daily Spend unique constraint 重複 | 已在 v1.81.9 修復（#20394） | 花費追蹤準確性 |
| JSON logs 重複 | 已在 v1.81.3 修復（#19705） | 日誌量翻倍 |

所有已知問題都已在 v1.81.12-stable.1 中修復。

---

## 6. 升級後驗證

### 6.1 自動化測試

```bash
# 執行 28 項迴歸測試
cd testing && python test_regression.py --port 4000

# 執行 thought_signature 整合測試
cd testing && python test_gemini_thought_signature.py --port 4000
```

### 6.2 手動驗證清單

- [ ] `GET /health/liveliness` → `"I'm alive!"`
- [ ] `GET /health/readiness` → 200
- [ ] `GET /v1/models` → 包含 3 個 Gemini 模型
- [ ] `POST /v1/chat/completions`（非串流）→ 正常回應
- [ ] `POST /v1/chat/completions`（串流）→ SSE chunks 正常
- [ ] Tool calling → tool_calls 包含 `__thought__` 簽章（v1.81.12 核心驗證）
- [ ] 多輪工具呼叫 → 完整對話流程正常
- [ ] 無效模型/金鑰 → 正確錯誤回應

### 6.3 效能驗證

| 指標 | v1.79.0 基線 | v1.81.12 預期 |
|------|-------------|--------------|
| chat completion 延遲 | 基線 | 降低 ~21% |
| 記憶體使用量 | 基線 | 降低（多項 OOM 修復） |
| Provider config 查詢 | 基線 | 加速 92.7% |

### 6.4 thought_signature 專項驗證

```bash
# 驗證 tool call ID 包含 thought_signature
curl -X POST http://localhost:4000/v1/chat/completions \
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

# 檢查回應中的 tool_calls[0].id 是否包含 "__thought__"
# 例如: "call_abc123__thought__xyz789"
```

---

## 7. 時間線

| 階段 | 預估時間 | 狀態 |
|------|----------|------|
| Phase 1：環境準備與基準線 | - | ✅ 完成 |
| Phase 2：版本差異分析與升級計劃 | - | ✅ 完成（本文件） |
| Phase 3：測試環境升級與驗證 | 1-2 天 | [待執行](docs/plans/3-local-upgrade-verification.md) |
| Phase 4：生產環境升級 | 半天 | 待排程 |

---

## References

- 版本差異分析：`reports/upgrade-changelog-v1.79-to-v1.81.md`
- DB Schema 遷移分析：`docs/db-schema-migration-v1.79-to-v1.81.md`
- Phase 1 報告：`reports/phase1-report.md`
- 迴歸測試：`testing/test_regression.py`
- thought_signature 測試：`testing/test_gemini_thought_signature.py`
- LiteLLM Releases：<https://github.com/BerriAI/litellm/releases>
