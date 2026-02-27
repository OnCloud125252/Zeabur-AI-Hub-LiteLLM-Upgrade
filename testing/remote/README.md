# 遠端測試

> 遠端 Docker 部署測試環境

← [返回測試](/testing/README.md)

---

## 概覽

此目錄包含 Docker Compose 設定檔和指令碼，用於在遠端 Linux x86_64 環境（符合生產環境架構）中測試 LiteLLM 升級。

## 環境詳細資訊

| 屬性 | 數值 |
|----------|-------|
| 伺服器 IP | `10.0.1.9` |
| 主機名稱 | CT108 |
| 作業系統 | Linux 6.8.12-17-pve (Proxmox VE) |
| 架構 | x86_64 |
| Docker | 29.2.1 |
| Docker Compose | v5.1.0 |

連線詳細資訊請參閱 [guides/remote-docker-server.md](/guides/remote-docker-server.md)。

## 目錄結構

```
testing/remote/
├── docker-compose.base.yml       # 共用基礎設定
├── docker-compose.v1.79.0.yml    # v1.79.0 部署
├── docker-compose.v1.81.12.yml   # v1.81.12 部署
├── config/
│   └── config.yaml               # LiteLLM proxy 設定
├── migrations/
│   ├── migration_phase_a.sql     # v1.79.0 → v1.80.11
│   └── migration_phase_b.sql     # v1.80.11 → v1.81.12
└── scripts/
    ├── setup.sh                  # 環境設定
    ├── migrate.sh                # 資料庫遷移
    ├── test.sh                   # 測試執行
    └── rollback.sh               # 回滾程序
```

## 快速開始

### 部署 v1.79.0（基準版本）

```bash
# 複製檔案到遠端
scp -r testing/remote/* root@10.0.1.9:/opt/litellm/

# 部署基準版本
ssh root@10.0.1.9 "cd /opt/litellm && docker compose -f docker-compose.v1.79.0.yml up -d"
```

### 執行資料庫遷移

```bash
# 套用遷移
ssh root@10.0.1.9 "cd /opt/litellm && psql -h localhost -U llmproxy -d litellm -f migrations/migration_phase_a.sql"
ssh root@10.0.1.9 "cd /opt/litellm && psql -h localhost -U llmproxy -d litellm -f migrations/migration_phase_b.sql"
```

### 部署 v1.81.12（升級版本）

```bash
# 部署新版本
ssh root@10.0.1.9 "cd /opt/litellm && docker compose -f docker-compose.v1.81.12.yml up -d"

# 驗證
ssh root@10.0.1.9 "docker ps -a"
ssh root@10.0.1.9 "docker logs litellm-proxy"
```

### 回滾

```bash
# 停止新版本
ssh root@10.0.1.9 "cd /opt/litellm && docker compose -f docker-compose.v1.81.12.yml down"

# 啟動舊版本
ssh root@10.0.1.9 "cd /opt/litellm && docker compose -f docker-compose.v1.79.0.yml up -d"
```

## Docker Compose 檔案

### 基礎設定（`docker-compose.base.yml`）

共用服務：
- PostgreSQL 16 (`litellm-db`)
- Redis 7-alpine (`litellm-redis`)

### 版本特定設定

每個版本檔案擴充基礎設定：
- 定義 LiteLLM proxy 映像檔
- 設定環境變數
- 設定健康檢查
- 對應磁碟區

## 遷移

| 檔案 | 用途 |
|------|---------|
| `migration_phase_a.sql` | 從 v1.79.0 到 v1.80.11 的結構變更 |
| `migration_phase_b.sql` | 從 v1.80.11 到 v1.81.12 的結構變更 |

詳細說明請參閱 [reports/4b-db-migration-guide.md](/reports/4b-db-migration-guide.md)。

## 驗證

部署後，驗證安裝：

```bash
# 健康檢查
curl http://10.0.1.9:4000/health/liveliness

# 模型列表
curl http://10.0.1.9:4000/v1/models

# 聊天完成（需要 API 金鑰）
curl -X POST http://10.0.1.9:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-test-key-1234" \
  -d '{"model": "gemini-2.5-flash", "messages": [{"role": "user", "content": "Hello"}]}'
```

## 疑難排解

| 問題 | 解決方案 |
|-------|----------|
| 容器無法啟動 | 檢查 `docker logs litellm-proxy` |
| 資料庫連線失敗 | 驗證 `DATABASE_URL` 和 PostgreSQL 容器 |
| 遷移錯誤 | 檢閱 migrations/ 中的 SQL 指令碼 |
| 映像檔拉取錯誤 | 驗證與 `docker.litellm.ai` 的連線 |

---

*Phase 3 驗證結果請參閱 [reports/3-verification-report.md](/reports/3-verification-report.md)。*
