# 回滾方案

> Phase 4e - Emergency rollback procedures

← [Back to Reports](README.md)

---

- **日期**：2026-02-27
- **階段**：Phase 4 Delivery
- **用途**：緊急回滾操作手冊
- **升級路徑**：v1.79.0-stable → v1.81.12-stable.1
- **狀態**：完成

---

## 執行摘要

本文件提供 LiteLLM 升級失敗時的緊急回滾操作手冊，包含快速回滾（Blue-Green）和完整回滾（停機升級）兩種方案，以及資料庫回滾注意事項。

| 指標 | 數值 |
|------|------|
| 快速回滾停機時間 | < 30 秒 |
| 完整回滾停機時間 | 5-10 分鐘 |
| 資料庫回滾需求 | 多數情況不需要 |

---

## 1. 回滾觸發條件

出現以下任一情況時，應啟動回滾：

| 條件 | 判斷標準 | 嚴重性 |
|------|----------|--------|
| Health check 持續失敗 | `/health/liveliness` 失敗超過 **5 分鐘** | 高 |
| API 錯誤率異常 | `/v1/chat/completions` 錯誤率 > **5%** | 高 |
| 資料庫連線錯誤 | DB connection refused / timeout | 高 |
| 已知 regression | 升級後出現影響業務的新 bug | 中 |
| 效能嚴重退步 | 延遲增加 > **50%** | 中 |

---

## 2. 快速回滾（Blue-Green 部署）

**適用情境**：使用方案 A（Blue-Green）升級，舊實例仍在運行
**停機時間**：< 30 秒

### 2.1 操作步驟

```bash
# Step 1: 切換 load balancer 流量回舊實例
# 將流量從 :4001（新）切回 :4000（舊）
# 具體操作依 LB 類型而異

# Step 2: 停止新實例
docker stop litellm-new

# Step 3: 確認舊實例正常
curl http://localhost:4000/health/liveliness
# 預期: "I'm alive!"

# Step 4: 執行回歸測試確認
python testing/local/test_regression.py --host <proxy-host> --port 4000
# 預期: 28/28 通過
```

---

## 3. 完整回滾（停機升級）

**適用情境**：使用方案 B（停機升級），舊實例已停止
**停機時間**：5-10 分鐘

### 3.1 操作步驟

```bash
# Step 1: 停止新版本
docker compose down

# Step 2: 還原 docker-compose.yml
# 將以下兩處改回舊值：
#   image: ghcr.io/berriai/litellm:v1.79.0-stable
#   healthcheck: wget --no-verbose --tries=1 ...
# 或直接從備份還原：
cp docker-compose.yml.backup docker-compose.yml

# Step 3: 啟動舊版本
docker compose up -d

# Step 4: 等待 health check 通過
sleep 45
curl http://localhost:4000/health/liveliness
# 預期: "I'm alive!"
```

---

## 4. 資料庫回滾注意事項

### 4.1 多數情況不需要還原資料庫

> **已驗證**：v1.79.0 可以在已遷移的 schema 上正常運行。新增的表和欄位對舊版本完全透明。

Phase 3 遠端測試結果：

| 檢查項目 | 結果 |
|----------|------|
| v1.79.0 在已遷移 DB 上啟動 | **通過** |
| 健康檢查通過 | **通過** |
| 28/28 回歸測試通過 | **通過** |
| 結構向後相容性 | **確認** |

**因此**：切回 v1.79.0 Docker image 即可，不需要還原資料庫。

### 4.2 需要還原資料庫的情況

以下情況例外，需從備份還原：

| 情況 | 說明 |
|------|------|
| `prisma db push` 破壞了現有表結構 | 如果未設定 `DISABLE_SCHEMA_UPDATE=true` 且 Prisma 自動修改了 unique constraint |
| 資料損壞 | 遷移過程中資料庫出現不一致 |
| 業務邏輯衝突 | 新版本寫入的資料導致舊版本行為異常 |

### 4.3 資料庫還原步驟

```bash
# 停止所有服務
docker compose down

# 啟動 PostgreSQL
docker compose up -d db
sleep 5

# 從備份還原
pg_restore -h localhost -U llmproxy -d litellm -c litellm_backup_YYYYMMDD_HHMMSS.dump
# -c: 先清除再還原

# 啟動舊版本
docker compose up -d
```

---

## 5. 風險矩陣

| 風險 | 機率 | 影響 | 緩解措施 |
|------|------|------|----------|
| DB schema 遷移失敗 | 低 | 高 | 手動 SQL + 事先備份 |
| `prisma db push` 丟失資料 | 低 | 高 | `DISABLE_SCHEMA_UPDATE=true` |
| Docker image pull 失敗 | 低 | 中 | 事先 `docker pull` |
| OpenAI SDK v2 不相容 | 極低 | 中 | 透過 proxy 使用，不直接依賴 |
| Health check 失敗 | 低 | 低 | 已更新為 python3 urllib |
| 記憶體佇列大小變更 | 低 | 低 | 監控佇列、必要時調高 |
| thought_signature 仍有問題 | 極低 | 高 | v1.80.11 已驗證修復，v1.81.12 包含額外修正 |

---

## 6. 已知問題狀態

以下已知問題在 v1.81.12-stable.1 中**全部已修復**：

| 問題 | 修復版本 | 影響 |
|------|----------|------|
| MCP StreamableHTTP stateless bug | v1.81.12-stable.1 | MCP 連線 |
| Daily Spend unique constraint 重複 | v1.81.9（#20394） | 花費追蹤 |
| JSON logs 重複 | v1.81.3（#19705） | 日誌量 |

---

## References

- 升級計劃回滾章節：[2-upgrade-plan.md](2-upgrade-plan.md)
- Phase 3 回滾測試結果：[3-verification-report.md](3-verification-report.md)
- 升級步驟：[4d-upgrade-steps.md](4d-upgrade-steps.md)
