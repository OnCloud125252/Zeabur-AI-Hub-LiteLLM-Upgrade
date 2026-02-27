# 資料庫遷移指南：v1.79.0 → v1.81.12

> Phase 4b - Database migration operations guide with SQL scripts

← [Back to Reports](README.md)

---

- **日期**：2026-02-27
- **階段**：Phase 4 Delivery
- **用途**：DBA / 運維人員可直接操作的資料庫遷移指南
- **升級路徑**：v1.79.0-stable → v1.81.12-stable.1
- **狀態**：完成
- **資料來源**：[research/db-schema-migration-v1.79-to-v1.81.md](/research/db-schema-migration-v1.79-to-v1.81.md)、[testing/remote/migrations/](/testing/remote/migrations/)

---

## 執行摘要

| 指標 | 數值 |
|------|------|
| 升級前資料表數 | 28（v1.79.0）→ 40（含 Prisma 自動建立） |
| 升級後資料表數 | **55** |
| 新增資料表 | **15 張** |
| 修改資料表 | **12 張** |
| 刪除資料表 | **0 張** |
| 破壞性變更 | 7 處（unique constraint 修改） |
| 可加性（additive）變更 | 95%+ |
| 遷移階段 | **兩階段**（Phase A + Phase B） |
| 向後相容 | **是** — v1.79.0 可在已遷移的 schema 上正常運行 |

> **已驗證**：Phase 3 遠端測試中，v1.79.0 在已套用全部遷移的資料庫上成功啟動並通過 28/28 回歸測試。

---

## 1. 遷移策略選擇

有兩種遷移方式可選：

| 方式 | 適用情境 | 優點 | 缺點 |
|------|----------|------|------|
| **手動 SQL 遷移**（推薦） | 生產環境 | 完全可控、可審計、可在舊版運行中執行 | 需手動操作 |
| **Prisma 自動遷移** | 測試環境、快速驗證 | 零操作 | `--accept-data-loss` 有風險 |

### 1.1 生產環境建議

1. 使用手動 SQL 腳本執行遷移
2. 設定 `DISABLE_SCHEMA_UPDATE=true` 防止 LiteLLM 啟動時自動執行 `prisma db push`
3. 驗證 schema 正確性後再啟動新版本

---

## 2. Phase A 遷移：v1.79.0 → v1.80.11

### 2.1 新增資料表（9 張）

| # | 資料表 | 用途 | 安全性 |
|---|--------|------|--------|
| 1 | `LiteLLM_AgentsTable` | A2A agent 註冊管理 | 可加性 |
| 2 | `LiteLLM_DailyOrganizationSpend` | 每日組織花費彙總 | 可加性 |
| 3 | `LiteLLM_DailyEndUserSpend` | 每日終端使用者花費彙總 | 可加性 |
| 4 | `LiteLLM_DailyAgentSpend` | 每日 agent 花費彙總 | 可加性 |
| 5 | `LiteLLM_SSOConfig` | SSO 設定儲存 | 可加性 |
| 6 | `LiteLLM_ManagedVectorStoreIndexTable` | 向量儲存索引管理 | 可加性 |
| 7 | `LiteLLM_CacheConfig` | 快取設定儲存 | 可加性 |
| 8 | `LiteLLM_UISettings` | UI 設定儲存 | 可加性 |
| 9 | `LiteLLM_SkillsTable` | Skills 管理 | 可加性 |

### 2.2 修改資料表（6 張）

| 資料表 | 變更 | 安全性 |
|--------|------|--------|
| `LiteLLM_ObjectPermissionTable` | 新增 `agents`、`agent_access_groups` 欄位 | 可加性 |
| `LiteLLM_MCPServerTable` | 新增 `credentials`、`static_headers` 欄位 | 可加性 |
| `LiteLLM_SpendLogs` | 新增 `organization_id`、`agent_id` 欄位 | 可加性 |
| `LiteLLM_ManagedFileTable` | 新增 `storage_backend`、`storage_url` 欄位 | 可加性 |
| `LiteLLM_DailyTagSpend` | 新增 `request_id` 欄位 | 可加性 |
| `LiteLLM_PromptTable` | unique constraint 變更 | **破壞性** |

### 2.3 PromptTable 破壞性變更

```
v1.79.0: prompt_id String @unique
v1.80.11: prompt_id String (不再 @unique)
          + version Int @default(1)
          + @@unique([prompt_id, version])  -- 複合唯一約束
          + @@index([prompt_id])
```

原本的單欄 unique 約束被移除，改為 `(prompt_id, version)` 複合唯一約束，支援 prompt 版本控制。

### 2.4 執行指令

```bash
# 連接至 PostgreSQL
psql -h <db-host> -U llmproxy -d litellm

# 執行 Phase A 遷移
\i migration_phase_a.sql
```

SQL 腳本位於：`testing/remote/migrations/migration_phase_a.sql`

---

## 3. Phase B 遷移：v1.80.11 → v1.81.12

### 3.1 新增資料表（6 張）

| # | 資料表 | 用途 | 安全性 |
|---|--------|------|--------|
| 1 | `LiteLLM_DeletedTeamTable` | 已刪除團隊審計記錄 | 可加性 |
| 2 | `LiteLLM_DeletedVerificationToken` | 已刪除 API Key 審計記錄 | 可加性 |
| 3 | `LiteLLM_ManagedVectorStoreTable` | 統一向量儲存管理 | 可加性 |
| 4 | `LiteLLM_PolicyTable` | Guardrail 政策定義 | 可加性 |
| 5 | `LiteLLM_PolicyAttachmentTable` | 政策附加（關聯 team/key/model） | 可加性 |
| 6 | `LiteLLM_AccessGroupTable` | 存取群組管理 | 可加性 |

### 3.2 修改資料表（6+ 張）

| 資料表 | 變更 | 安全性 |
|--------|------|--------|
| `LiteLLM_TeamTable` | 新增 `soft_budget`、`router_settings`、`access_group_ids`、`policies`、`allow_team_guardrail_config` | 可加性 |
| `LiteLLM_UserTable` | 新增 `policies` | 可加性 |
| `LiteLLM_MCPServerTable` | 新增 `authorization_url`、`token_url`、`registration_url`、`allow_all_keys`、`available_on_public_internet` | 可加性 |
| `LiteLLM_VerificationToken` | 新增 `router_settings`、`policies`、`access_group_ids` + 3 個索引 | 可加性 |
| `LiteLLM_GuardrailsTable` | 新增 `team_id` | 可加性 |
| **6 張 Daily Spend 表** | 新增 `endpoint` 欄位 + unique constraint 變更 | **破壞性** |

### 3.3 Daily Spend 表 unique constraint 變更

所有 6 張 Daily Spend 表（User、Organization、EndUser、Agent、Team、Tag）的 unique constraint 都新增了 `endpoint` 欄位：

```
v1.80.11: @@unique([user_id, date, api_key, model, custom_llm_provider, mcp_namespaced_tool_name])
v1.81.12: @@unique([user_id, date, api_key, model, custom_llm_provider, mcp_namespaced_tool_name, endpoint])
```

**風險評估**：新增的 `endpoint` 欄位為 nullable，現有資料的 `endpoint` 值為 `NULL`。PostgreSQL 中 `NULL` 在 unique constraint 中被視為不同值，因此不會產生資料衝突。但必須先丟棄舊的 unique constraint 再建立新的。

### 3.4 執行指令

```bash
# 連接至 PostgreSQL
psql -h <db-host> -U llmproxy -d litellm

# 執行 Phase B 遷移
\i migration_phase_b.sql
```

SQL 腳本位於：`testing/remote/migrations/migration_phase_b.sql`

---

## 4. 破壞性 Schema 變更總覽

| # | 變更 | 影響表 | 風險 | 說明 |
|---|------|--------|------|------|
| 1 | PromptTable unique constraint | 1 張 | MEDIUM | 先加 `version` 欄位，再換 constraint |
| 2-7 | Daily Spend unique constraint | 6 張 | MEDIUM | 先加 `endpoint` 欄位，再換 constraint |

**關鍵風險點**：

- `DROP CONSTRAINT` 操作需要取得表鎖，在高負載下可能導致短暫阻塞
- 建議在低流量時段執行
- PostgreSQL 的 `NULL` 在 unique constraint 中被視為不同值，新增 nullable 欄位後不會違反約束

---

## 5. 向後相容性

### 已驗證結論

> v1.79.0 可以在已完成所有遷移的 schema 上正常運行。

驗證方式（Phase 3 遠端測試）：

1. 在 v1.79.0 上建立基準線（28/28 測試通過）
2. 執行 Phase A + Phase B 遷移（或讓 v1.81.12 自動遷移）
3. 將 Docker image 切回 v1.79.0-stable
4. v1.79.0 成功啟動，28/28 回歸測試全數通過

**原因**：v1.79.0 會忽略它不認識的表和欄位。所有新增的表、欄位和索引對舊版本完全透明。

---

## 6. 遷移驗證檢查表

遷移完成後，請執行以下 SQL 驗證：

### 6.1 確認表數量

```sql
SELECT COUNT(*) FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
-- 預期結果: 55（含所有新表）
```

### 6.2 確認 Phase A 新表存在

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name IN (
    'LiteLLM_AgentsTable',
    'LiteLLM_DailyOrganizationSpend',
    'LiteLLM_DailyEndUserSpend',
    'LiteLLM_DailyAgentSpend',
    'LiteLLM_SSOConfig',
    'LiteLLM_ManagedVectorStoreIndexTable',
    'LiteLLM_CacheConfig',
    'LiteLLM_UISettings',
    'LiteLLM_SkillsTable'
);
-- 預期結果: 9 rows
```

### 6.3 確認 Phase B 新表存在

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name IN (
    'LiteLLM_DeletedTeamTable',
    'LiteLLM_DeletedVerificationToken',
    'LiteLLM_ManagedVectorStoreTable',
    'LiteLLM_PolicyTable',
    'LiteLLM_PolicyAttachmentTable',
    'LiteLLM_AccessGroupTable'
);
-- 預期結果: 6 rows
```

### 6.4 確認新欄位存在

```sql
-- 確認 PromptTable 有 version 欄位
SELECT column_name FROM information_schema.columns
WHERE table_name = 'LiteLLM_PromptTable' AND column_name = 'version';
-- 預期結果: 1 row

-- 確認 DailyUserSpend 有 endpoint 欄位
SELECT column_name FROM information_schema.columns
WHERE table_name = 'LiteLLM_DailyUserSpend' AND column_name = 'endpoint';
-- 預期結果: 1 row

-- 確認 TeamTable 有 soft_budget 欄位
SELECT column_name FROM information_schema.columns
WHERE table_name = 'LiteLLM_TeamTable' AND column_name = 'soft_budget';
-- 預期結果: 1 row
```

### 6.5 確認 unique constraint 變更

```sql
-- 確認 PromptTable 複合唯一約束
SELECT indexname FROM pg_indexes
WHERE tablename = 'LiteLLM_PromptTable'
  AND indexname LIKE '%prompt_id_version%';
-- 預期結果: 1 row
```

---

## 7. `prisma db push --accept-data-loss` 風險

如果選擇讓 LiteLLM 自動遷移（不使用手動 SQL），需注意：

| 風險 | 說明 |
|------|------|
| `--accept-data-loss` | Prisma 可能自動丟棄不相容的欄位資料或重建表 |
| 並行遷移 | 多個實例同時啟動可能導致遷移衝突（v1.80.15 已加鎖） |
| 無審計軌跡 | 自動遷移不會產生可回溯的遷移記錄 |

**結論**：生產環境強烈建議使用手動 SQL 遷移 + `DISABLE_SCHEMA_UPDATE=true`。

---

## References

- Schema 遷移分析：[research/db-schema-migration-v1.79-to-v1.81.md](/research/db-schema-migration-v1.79-to-v1.81.md)
- Phase A SQL：[testing/remote/migrations/migration_phase_a.sql](/testing/remote/migrations/migration_phase_a.sql)
- Phase B SQL：[testing/remote/migrations/migration_phase_b.sql](/testing/remote/migrations/migration_phase_b.sql)
- Phase 3 驗證報告：[reports/3-verification-report.md](3-verification-report.md)
