# 改善建議：LiteLLM 升級方案審查報告

> DevOps 視角的文件改善建議

← [返回報告索引](README.md)

---

- **日期**：2026-02-28
- **審查者**：DevOps 顧問
- **審查範圍**：Phase 1-4 全部文件
- **狀態**：待處理

---

## 執行摘要

本次審查針對 LiteLLM v1.79.0 → v1.81.12-stable.1 升級方案進行 DevOps 專業評估。整體而言，文件結構清晰、內容完整，符合企業級升級計劃標準。以下為需要改善的項目，依優先級分類。

| 優先級 | 項目數 | 狀態 |
|--------|--------|------|
| 🔴 高 | 3 | 待處理 |
| 🟡 中 | 3 | 待處理 |
| 🟢 低 | 3 | 待處理 |

---

## 🔴 高優先級（必須處理）

### 1. 監控與告警策略缺失

**問題描述**：所有文件中幾乎沒有提到升級過程中的監控和告警策略。這在生產環境升級中是關鍵缺口。

**建議補充內容**：

```markdown
## 升級監控檢查清單

### 前置準備
- [ ] 確認 Grafana Dashboard 可正常訪問
- [ ] 暫停非關鍵告警（避免升級期間誤報）
- [ ] 設定升級專用 Slack/Discord 頻道通知

### 關鍵監控指標
| 指標 | 正常範圍 | 警告閾值 | 嚴重閾值 |
|------|----------|----------|----------|
| 錯誤率 | < 1% | > 3% | > 5% |
| P95 延遲 | < 2s | > 3s | > 5s |
| 資料庫連線數 | < 80% | > 85% | > 95% |
| CPU 使用率 | < 70% | > 80% | > 90% |

### 自動回滾條件（可選）
- 錯誤率持續 > 5% 超過 2 分鐘
- P95 延遲 > 10 秒持續 3 分鐘
- Health check 失敗連續 5 次
```

**應更新文件**：`4d-upgrade-steps.md`（新增「升級監控」章節）

---

### 2. 缺乏 Canary 部署選項

**問題描述**：Blue-Green 部署雖然好，但對於 LLM 這種有狀態的服務，Canary（金絲雀）部署通常更安全，可以在發現問題時限制影響範圍。

**建議補充內容**：

在 `4f-downtime-strategy.md` 中增加「選項 C：Canary 部署」：

```markdown
### 選項 C：Canary 部署（最安全）

**預估停機時間**：0 秒（無縫漸進）
**適用條件**：有 Kubernetes + Service Mesh（Istio/Linkerd）或具備流量分割能力的 LB

#### 實施步驟

1. **初始階段（5% 流量）**
   - 部署新版本 replica: 1
   - 設定流量權重: 舊版 95%, 新版 5%
   - 監控 10-15 分鐘

2. **驗證階段（20% 流量）**
   - 檢查錯誤率、延遲指標
   - 如正常，擴大至 20% 流量
   - 監控 10 分鐘

3. **擴大階段（50% 流量）**
   - 繼續監控關鍵指標
   - 觀察是否有邊緣案例錯誤
   - 監控 10 分鐘

4. **全面切換（100% 流量）**
   - 確認所有指標正常
   - 切換 100% 流量至新版本
   - 保留舊版本 30 分鐘後銷毀

#### 快速回滾
任一階段發現問題，可立即將流量權重調回 0%，無需重啟服務。
```

---

### 3. 資料庫連線池設定未明確

**問題描述**：`4c-config-comparison.md` 提到 `database_connection_pool_limit` 預設從 100 降至 10，但缺乏具體建議。

**建議補充內容**：

```markdown
## 資料庫連線池設定建議

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

```

**應更新文件**：`4c-config-comparison.md`

---

## 🟡 中優先級（建議處理）

### 4. 資料庫遷移時間估算不足

**問題描述**：SQL 腳本雖然完整，但缺乏執行時間估算，對於大型資料庫 ALTER TABLE 可能需要數分鐘到數小時。

**建議補充內容**：

在 `4b-db-migration-guide.md` 的 SQL 腳本頂部加入：

```sql
-- =====================================================
-- Phase A: v1.79.0 → v1.80.11
-- 預估執行時間：
--   - 小型資料庫 (< 1GB): 30-60 秒
--   - 中型資料庫 (1-10GB): 2-5 分鐘
--   - 大型資料庫 (> 10GB): 10-30 分鐘
--
-- 執行前請先備份資料庫！
-- 建議在低流量時段執行
-- =====================================================

-- 進度查詢（在另一個終端執行）
-- SELECT now(), query, state, wait_event_type
-- FROM pg_stat_activity
-- WHERE datname = 'litellm';
```

---

### 5. ConfigMap/Secret 管理未提及

**問題描述**：如果 Zeabur 使用 Kubernetes，文件應說明 ConfigMap 和 Secret 的版本管理策略。

**建議新增文件**：`4h-kubernetes-deployment.md`

```markdown
# Kubernetes 部署指南

## ConfigMap 管理

### 版本化 ConfigMap
建議使用帶版本號的 ConfigMap 名稱，避免新舊版本衝突：

```yaml
# configmap-v1.79.0.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: litellm-config-v1-79-0
data:
  config.yaml: |
    # v1.79.0 設定內容

---
# configmap-v1.81.12.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: litellm-config-v1-81-12
data:
  config.yaml: |
    # v1.81.12 設定內容
```

### Deployment 參考

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: litellm
spec:
  template:
    spec:
      containers:
      - name: litellm
        image: docker.litellm.ai/berriai/litellm:v1.81.12-stable.1
        volumeMounts:
        - name: config
          mountPath: /app/config.yaml
          subPath: config.yaml
      volumes:
      - name: config
        configMap:
          name: litellm-config-v1-81-12  # 升級時修改此行
```

## Secret 管理

### 環境變數來源

```yaml
env:
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: litellm-secrets
      key: database-url
- name: LITELLM_MASTER_KEY
  valueFrom:
    secretKeyRef:
      name: litellm-secrets
      key: master-key
```

### 使用 Helm 管理

如有使用 Helm，建議使用 values.yaml 區分環境：

```yaml
# values-production.yaml
image:
  repository: docker.litellm.ai/berriai/litellm
  tag: v1.81.12-stable.1

config:
  enable_preview_features: true
  database_connection_pool_limit: 50
```

---

### 6. 測試覆蓋率可以擴展

**問題描述**：目前的 28 項回歸測試很好，但缺少負載測試和壓力測試。

**建議補充內容**：

新增 `testing/local/test_load.py`：

```python
"""
負載測試：模擬高併發場景

Usage:
    python test_load.py --host <host> --port 4000 --users 50 --duration 60
"""
import asyncio
import time
import statistics
from typing import List
import httpx
import argparse


async def make_request(client: httpx.AsyncClient, base_url: str, api_key: str):
    """Make a single chat completion request."""
    start = time.time()
    try:
        r = await client.post(
            f"{base_url}/v1/chat/completions",
            headers={"Authorization": f"Bearer {api_key}"},
            json={
                "model": "gemini-2.5-flash",
                "messages": [{"role": "user", "content": "Hello"}]
            },
            timeout=30
        )
        latency = time.time() - start
        return r.status_code == 200, latency
    except Exception as e:
        return False, time.time() - start


async def run_load_test(base_url: str, api_key: str, users: int, duration: int):
    """Run load test with specified concurrent users."""
    print(f"Starting load test: {users} users for {duration}s")

    results: List[bool] = []
    latencies: List[float] = []

    async with httpx.AsyncClient() as client:
        start_time = time.time()

        while time.time() - start_time < duration:
            tasks = [
                make_request(client, base_url, api_key)
                for _ in range(users)
            ]
            batch_results = await asyncio.gather(*tasks)

            for success, latency in batch_results:
                results.append(success)
                latencies.append(latency)

            # Small delay to prevent overwhelming
            await asyncio.sleep(0.1)

    # Report results
    success_rate = sum(results) / len(results) * 100
    print(f"\nResults:")
    print(f"  Total requests: {len(results)}")
    print(f"  Success rate: {success_rate:.1f}%")
    print(f"  Avg latency: {statistics.mean(latencies):.3f}s")
    print(f"  P95 latency: {statistics.quantiles(latencies, n=20)[18]:.3f}s")
    print(f"  P99 latency: {statistics.quantiles(latencies, n=100)[98]:.3f}s")

    return success_rate >= 95  # Pass if > 95% success


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--port", type=int, default=4000)
    parser.add_argument("--users", type=int, default=50)
    parser.add_argument("--duration", type=int, default=60)
    args = parser.parse_args()

    base_url = f"http://{args.host}:{args.port}"
    api_key = "sk-test-key-1234"

    passed = asyncio.run(run_load_test(base_url, api_key, args.users, args.duration))
    exit(0 if passed else 1)
```

---

## 🟢 低優先級（可選處理）

### 7. 文件交叉引用可以優化

**問題描述**：部分文件之間的引用使用相對路徑，建議統一格式。

**建議**：

- 在 `CLAUDE.md` 中統一定義文件路徑常數
- 使用絕對路徑格式：`[文件名](/reports/filename.md)`

---

### 8. 時間戳記格式不統一

**問題描述**：部分文件使用不同日期格式。

**建議統一為**：`YYYY-MM-DD`（ISO 8601）

需檢查的文件：

- `reports/1-environment-report.md`
- `reports/2-upgrade-plan.md`
- `reports/3-verification-report.md`
- `reports/4-delivery-report.md`

---

## 結論與建議行動

### 立即行動（升級前必須完成）

1. **補充監控策略**（🔴 高）
   - 負責人：SRE/運維
   - 預估時間：2-4 小時

2. **確認資料庫連線池設定**（🔴 高）
   - 負責人：DBA
   - 預估時間：30 分鐘

### 後續優化（升級後處理）

1. **增加負載測試**（🟡 中）
   - 負責人：QA/DevOps
   - 預估時間：4-8 小時

2. **建立 Kubernetes 部署指南**（🟡 中）
   - 負責人：DevOps
   - 預估時間：4 小時

---

## References

- [4d-upgrade-steps.md](4d-upgrade-steps.md) - 升級步驟
- [4f-downtime-strategy.md](4f-downtime-strategy.md) - 停機策略
- [4b-db-migration-guide.md](4b-db-migration-guide.md) - 資料庫遷移
- [4c-config-comparison.md](4c-config-comparison.md) - 設定對照
