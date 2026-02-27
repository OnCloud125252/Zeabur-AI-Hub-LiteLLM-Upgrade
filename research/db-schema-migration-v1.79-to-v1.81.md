# 資料庫 Schema 遷移分析：v1.79.0 → v1.81.12

> 資料庫 schema 遷移分析與 SQL 腳本

← [返回研究文件](README.md)

---

- **日期**: 2026-02-27
- **狀態**: 已完成
- **目的**: 記錄 LiteLLM v1.79.0 至 v1.81.12 之間的所有 Prisma schema 變更，提供手動 SQL 遷移腳本作為 `prisma db push` 的安全替代方案。

## 摘要

| 指標 | 數值 |
|------|------|
| Schema 行數（v1.79.0） | 582 行 |
| Schema 行數（v1.80.11） | 747 行 |
| Schema 行數（v1.81.12） | ~900 行（估計） |
| 新增資料表 | **15 張** |
| 修改資料表 | **12 張** |
| 刪除資料表 | **0 張** |
| 破壞性變更 | 7 處（唯一約束修改） |
| 完全可加性變更 | 95%+ |

---

## 1. Schema 遷移機制說明

LiteLLM 使用 Prisma ORM 管理資料庫 schema。在 `litellm/proxy/db/prisma_client.py` 中，`PrismaManager.setup_database()` 有兩種模式：

### 1.1 預設模式（`prisma db push`）

```python
# litellm/proxy/db/prisma_client.py (v1.81.12, lines 362-411)
prisma db push --accept-data-loss  # 60 秒 timeout，最多 4 次重試
```

- `--accept-data-loss` 旗標表示 Prisma 會自動處理 schema 差異
- 重試間隔為隨機 5-15 秒
- 可透過 `DISABLE_SCHEMA_UPDATE=true` 環境變數停用

### 1.2 遷移模式（`prisma migrate`）

```python
# use_migrate=True 時
litellm_proxy_extras.utils.ProxyExtrasDBManager.setup_database()
```

使用 Prisma Migrations（正式遷移檔案），提供更安全的生產環境遷移方式。

### 1.3 建議做法

對於生產環境升級，建議：

1. 先使用下方手動 SQL 腳本執行遷移
2. 設定 `DISABLE_SCHEMA_UPDATE=true` 防止 LiteLLM 啟動時自動執行 `prisma db push`
3. 驗證 schema 正確性後再啟動新版本

---

## 2. 三向比較總覽

### 2.1 v1.79.0 → v1.80.11 變更

#### 新增資料表（9 張）

| # | 資料表名稱 | 用途 | 安全性 |
|---|-----------|------|--------|
| 1 | `LiteLLM_AgentsTable` | A2A agent 註冊管理 | 可加性 ✅ |
| 2 | `LiteLLM_DailyOrganizationSpend` | 每日組織花費彙總 | 可加性 ✅ |
| 3 | `LiteLLM_DailyEndUserSpend` | 每日終端使用者花費彙總 | 可加性 ✅ |
| 4 | `LiteLLM_DailyAgentSpend` | 每日 agent 花費彙總 | 可加性 ✅ |
| 5 | `LiteLLM_SSOConfig` | SSO 設定儲存 | 可加性 ✅ |
| 6 | `LiteLLM_ManagedVectorStoreIndexTable` | 向量儲存索引管理 | 可加性 ✅ |
| 7 | `LiteLLM_CacheConfig` | 快取設定儲存 | 可加性 ✅ |
| 8 | `LiteLLM_UISettings` | UI 設定儲存 | 可加性 ✅ |
| 9 | `LiteLLM_SkillsTable` | Skills（技能）管理 | 可加性 ✅ |

#### 修改資料表（6 張）

| 資料表 | 變更 | 安全性 |
|--------|------|--------|
| `LiteLLM_ObjectPermissionTable` | 新增 `agents`、`agent_access_groups` 欄位 | 可加性 ✅ |
| `LiteLLM_MCPServerTable` | 新增 `credentials`、`static_headers` 欄位 | 可加性 ✅ |
| `LiteLLM_SpendLogs` | 新增 `organization_id`、`agent_id` 欄位 | 可加性 ✅ |
| `LiteLLM_ManagedFileTable` | 新增 `storage_backend`、`storage_url` 欄位 | 可加性 ✅ |
| `LiteLLM_DailyTagSpend` | 新增 `request_id` 欄位 | 可加性 ✅ |
| `LiteLLM_PromptTable` | unique constraint 變更 | ⚠️ 破壞性 |

**`LiteLLM_PromptTable` 破壞性變更詳細資訊：**

```
v1.79.0: prompt_id String @unique
v1.80.11: prompt_id String (不再 @unique)
          + version Int @default(1)
          + @@unique([prompt_id, version])  -- 複合唯一約束
          + @@index([prompt_id])
```

原本的單欄唯一約束被移除，改為 `(prompt_id, version)` 複合唯一約束，支援 prompt 版本控制。

---

### 2.2 v1.80.11 → v1.81.12 變更

#### 新增資料表（6 張）

| # | 資料表名稱 | 用途 | 安全性 |
|---|-----------|------|--------|
| 1 | `LiteLLM_DeletedTeamTable` | 已刪除團隊審計記錄 | 可加性 ✅ |
| 2 | `LiteLLM_DeletedVerificationToken` | 已刪除 API Key 審計記錄 | 可加性 ✅ |
| 3 | `LiteLLM_ManagedVectorStoreTable` | 統一向量儲存管理（不同於 `VectorStoresTable`） | 可加性 ✅ |
| 4 | `LiteLLM_PolicyTable` | Guardrail 政策定義 | 可加性 ✅ |
| 5 | `LiteLLM_PolicyAttachmentTable` | 政策附加（關聯 team/key/model） | 可加性 ✅ |
| 6 | `LiteLLM_AccessGroupTable` | 存取群組管理 | 可加性 ✅ |

#### 修改資料表（6+ 張）

| 資料表 | 變更 | 安全性 |
|--------|------|--------|
| `LiteLLM_TeamTable` | 新增 `soft_budget`、`router_settings`、`access_group_ids`、`policies`、`allow_team_guardrail_config` | 可加性 ✅ |
| `LiteLLM_UserTable` | 新增 `policies` | 可加性 ✅ |
| `LiteLLM_MCPServerTable` | 新增 `authorization_url`、`token_url`、`registration_url`、`allow_all_keys`、`available_on_public_internet` | 可加性 ✅ |
| `LiteLLM_VerificationToken` | 新增 `router_settings`、`policies`、`access_group_ids` + 3 個索引 | 可加性 ✅ |
| `LiteLLM_ManagedVectorStoresTable` | 新增 `team_id`、`user_id` + 索引 | 可加性 ✅ |
| `LiteLLM_GuardrailsTable` | 新增 `team_id` | 可加性 ✅ |
| **6 張 Daily Spend 資料表** | 新增 `endpoint` 欄位 + 唯一約束變更 | ⚠️ 破壞性 |

**Daily Spend 資料表唯一約束變更：**

所有 6 張 Daily Spend 資料表（User、Organization、EndUser、Agent、Team、Tag）的唯一約束都新增了 `endpoint` 欄位：

```
v1.80.11: @@unique([user_id, date, api_key, model, custom_llm_provider, mcp_namespaced_tool_name])
v1.81.12: @@unique([user_id, date, api_key, model, custom_llm_provider, mcp_namespaced_tool_name, endpoint])
```

**風險評估**：由於新增的 `endpoint` 欄位為 nullable，現有資料的 `endpoint` 值為 `NULL`。PostgreSQL 中 `NULL` 在唯一約束中被視為不同值，因此不會產生資料衝突。但必須先丟棄舊的唯一約束再建立新的。

#### Generator 變更

```
v1.80.11: provider = "prisma-client-py" (無 binaryTargets)
v1.81.12: + binaryTargets = ["native", "debian-openssl-1.1.x", "debian-openssl-3.0.x",
                             "linux-musl", "linux-musl-openssl-3.0.x"]
```

此變更不影響資料庫 schema，僅影響 Prisma client 二進位檔案產生。

---

### 2.3 Extras Schema 比較

`litellm-proxy-extras` 的 schema 檔案在每個版本中都與主要 schema **完全一致**。使用 `prisma db push` 或 `prisma migrate` 都會產生相同的目標 schema。

---

## 3. 手動 SQL 遷移腳本

### 3.1 Phase A：v1.79.0 → v1.80.11

```sql
-- =====================================================
-- Phase A: v1.79.0 → v1.80.11
-- 執行前請先備份資料庫！
-- =====================================================

BEGIN;

-- ─── 新增資料表 ───────────────────────────────────

-- 1. LiteLLM_AgentsTable
CREATE TABLE IF NOT EXISTS "LiteLLM_AgentsTable" (
    "agent_id" TEXT NOT NULL DEFAULT gen_random_uuid(),
    "agent_name" TEXT NOT NULL,
    "litellm_params" JSONB,
    "agent_card_params" JSONB NOT NULL,
    "agent_access_groups" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" TEXT NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_by" TEXT NOT NULL,
    CONSTRAINT "LiteLLM_AgentsTable_pkey" PRIMARY KEY ("agent_id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "LiteLLM_AgentsTable_agent_name_key"
    ON "LiteLLM_AgentsTable"("agent_name");

-- 2. LiteLLM_DailyOrganizationSpend
CREATE TABLE IF NOT EXISTS "LiteLLM_DailyOrganizationSpend" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid(),
    "organization_id" TEXT,
    "date" TEXT NOT NULL,
    "api_key" TEXT NOT NULL,
    "model" TEXT,
    "model_group" TEXT,
    "custom_llm_provider" TEXT,
    "mcp_namespaced_tool_name" TEXT,
    "prompt_tokens" BIGINT NOT NULL DEFAULT 0,
    "completion_tokens" BIGINT NOT NULL DEFAULT 0,
    "cache_read_input_tokens" BIGINT NOT NULL DEFAULT 0,
    "cache_creation_input_tokens" BIGINT NOT NULL DEFAULT 0,
    "spend" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "api_requests" BIGINT NOT NULL DEFAULT 0,
    "successful_requests" BIGINT NOT NULL DEFAULT 0,
    "failed_requests" BIGINT NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "LiteLLM_DailyOrganizationSpend_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS
    "LiteLLM_DailyOrganizationSpend_org_date_key_model_provider_mcp_key"
    ON "LiteLLM_DailyOrganizationSpend"(
        "organization_id", "date", "api_key", "model",
        "custom_llm_provider", "mcp_namespaced_tool_name"
    );
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyOrganizationSpend_date_idx"
    ON "LiteLLM_DailyOrganizationSpend"("date");
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyOrganizationSpend_organization_id_idx"
    ON "LiteLLM_DailyOrganizationSpend"("organization_id");
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyOrganizationSpend_api_key_idx"
    ON "LiteLLM_DailyOrganizationSpend"("api_key");
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyOrganizationSpend_model_idx"
    ON "LiteLLM_DailyOrganizationSpend"("model");
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyOrganizationSpend_mcp_tool_idx"
    ON "LiteLLM_DailyOrganizationSpend"("mcp_namespaced_tool_name");

-- 3. LiteLLM_DailyEndUserSpend
CREATE TABLE IF NOT EXISTS "LiteLLM_DailyEndUserSpend" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid(),
    "end_user_id" TEXT,
    "date" TEXT NOT NULL,
    "api_key" TEXT NOT NULL,
    "model" TEXT,
    "model_group" TEXT,
    "custom_llm_provider" TEXT,
    "mcp_namespaced_tool_name" TEXT,
    "prompt_tokens" BIGINT NOT NULL DEFAULT 0,
    "completion_tokens" BIGINT NOT NULL DEFAULT 0,
    "cache_read_input_tokens" BIGINT NOT NULL DEFAULT 0,
    "cache_creation_input_tokens" BIGINT NOT NULL DEFAULT 0,
    "spend" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "api_requests" BIGINT NOT NULL DEFAULT 0,
    "successful_requests" BIGINT NOT NULL DEFAULT 0,
    "failed_requests" BIGINT NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "LiteLLM_DailyEndUserSpend_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS
    "LiteLLM_DailyEndUserSpend_enduser_date_key_model_provider_mcp_key"
    ON "LiteLLM_DailyEndUserSpend"(
        "end_user_id", "date", "api_key", "model",
        "custom_llm_provider", "mcp_namespaced_tool_name"
    );
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyEndUserSpend_date_idx"
    ON "LiteLLM_DailyEndUserSpend"("date");
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyEndUserSpend_end_user_id_idx"
    ON "LiteLLM_DailyEndUserSpend"("end_user_id");
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyEndUserSpend_api_key_idx"
    ON "LiteLLM_DailyEndUserSpend"("api_key");
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyEndUserSpend_model_idx"
    ON "LiteLLM_DailyEndUserSpend"("model");
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyEndUserSpend_mcp_tool_idx"
    ON "LiteLLM_DailyEndUserSpend"("mcp_namespaced_tool_name");

-- 4. LiteLLM_DailyAgentSpend
CREATE TABLE IF NOT EXISTS "LiteLLM_DailyAgentSpend" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid(),
    "agent_id" TEXT,
    "date" TEXT NOT NULL,
    "api_key" TEXT NOT NULL,
    "model" TEXT,
    "model_group" TEXT,
    "custom_llm_provider" TEXT,
    "mcp_namespaced_tool_name" TEXT,
    "prompt_tokens" BIGINT NOT NULL DEFAULT 0,
    "completion_tokens" BIGINT NOT NULL DEFAULT 0,
    "cache_read_input_tokens" BIGINT NOT NULL DEFAULT 0,
    "cache_creation_input_tokens" BIGINT NOT NULL DEFAULT 0,
    "spend" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "api_requests" BIGINT NOT NULL DEFAULT 0,
    "successful_requests" BIGINT NOT NULL DEFAULT 0,
    "failed_requests" BIGINT NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "LiteLLM_DailyAgentSpend_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS
    "LiteLLM_DailyAgentSpend_agent_date_key_model_provider_mcp_key"
    ON "LiteLLM_DailyAgentSpend"(
        "agent_id", "date", "api_key", "model",
        "custom_llm_provider", "mcp_namespaced_tool_name"
    );
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyAgentSpend_date_idx"
    ON "LiteLLM_DailyAgentSpend"("date");
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyAgentSpend_agent_id_idx"
    ON "LiteLLM_DailyAgentSpend"("agent_id");
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyAgentSpend_api_key_idx"
    ON "LiteLLM_DailyAgentSpend"("api_key");
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyAgentSpend_model_idx"
    ON "LiteLLM_DailyAgentSpend"("model");
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyAgentSpend_mcp_tool_idx"
    ON "LiteLLM_DailyAgentSpend"("mcp_namespaced_tool_name");

-- 5. LiteLLM_SSOConfig
CREATE TABLE IF NOT EXISTS "LiteLLM_SSOConfig" (
    "id" TEXT NOT NULL DEFAULT 'sso_config',
    "sso_settings" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "LiteLLM_SSOConfig_pkey" PRIMARY KEY ("id")
);

-- 6. LiteLLM_ManagedVectorStoreIndexTable
CREATE TABLE IF NOT EXISTS "LiteLLM_ManagedVectorStoreIndexTable" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid(),
    "index_name" TEXT NOT NULL,
    "litellm_params" JSONB NOT NULL,
    "index_info" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_by" TEXT,
    CONSTRAINT "LiteLLM_ManagedVectorStoreIndexTable_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "LiteLLM_ManagedVectorStoreIndexTable_index_name_key"
    ON "LiteLLM_ManagedVectorStoreIndexTable"("index_name");

-- 7. LiteLLM_CacheConfig
CREATE TABLE IF NOT EXISTS "LiteLLM_CacheConfig" (
    "id" TEXT NOT NULL DEFAULT 'cache_config',
    "cache_settings" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "LiteLLM_CacheConfig_pkey" PRIMARY KEY ("id")
);

-- 8. LiteLLM_UISettings
CREATE TABLE IF NOT EXISTS "LiteLLM_UISettings" (
    "id" TEXT NOT NULL DEFAULT 'ui_settings',
    "ui_settings" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "LiteLLM_UISettings_pkey" PRIMARY KEY ("id")
);

-- 9. LiteLLM_SkillsTable
CREATE TABLE IF NOT EXISTS "LiteLLM_SkillsTable" (
    "skill_id" TEXT NOT NULL DEFAULT gen_random_uuid(),
    "display_title" TEXT,
    "description" TEXT,
    "instructions" TEXT,
    "source" TEXT NOT NULL DEFAULT 'custom',
    "latest_version" TEXT,
    "file_content" BYTEA,
    "file_name" TEXT,
    "file_type" TEXT,
    "metadata" JSONB DEFAULT '{}',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_by" TEXT,
    CONSTRAINT "LiteLLM_SkillsTable_pkey" PRIMARY KEY ("skill_id")
);

-- ─── 修改現有資料表 ─────────────────────────────────

-- ObjectPermissionTable
ALTER TABLE "LiteLLM_ObjectPermissionTable"
    ADD COLUMN IF NOT EXISTS "agents" TEXT[] DEFAULT ARRAY[]::TEXT[];
ALTER TABLE "LiteLLM_ObjectPermissionTable"
    ADD COLUMN IF NOT EXISTS "agent_access_groups" TEXT[] DEFAULT ARRAY[]::TEXT[];

-- MCPServerTable
ALTER TABLE "LiteLLM_MCPServerTable"
    ADD COLUMN IF NOT EXISTS "credentials" JSONB DEFAULT '{}';
ALTER TABLE "LiteLLM_MCPServerTable"
    ADD COLUMN IF NOT EXISTS "static_headers" JSONB DEFAULT '{}';

-- SpendLogs
ALTER TABLE "LiteLLM_SpendLogs"
    ADD COLUMN IF NOT EXISTS "organization_id" TEXT;
ALTER TABLE "LiteLLM_SpendLogs"
    ADD COLUMN IF NOT EXISTS "agent_id" TEXT;

-- ManagedFileTable
ALTER TABLE "LiteLLM_ManagedFileTable"
    ADD COLUMN IF NOT EXISTS "storage_backend" TEXT;
ALTER TABLE "LiteLLM_ManagedFileTable"
    ADD COLUMN IF NOT EXISTS "storage_url" TEXT;

-- DailyTagSpend
ALTER TABLE "LiteLLM_DailyTagSpend"
    ADD COLUMN IF NOT EXISTS "request_id" TEXT;

-- PromptTable: 唯一約束變更（破壞性）
ALTER TABLE "LiteLLM_PromptTable"
    ADD COLUMN IF NOT EXISTS "version" INTEGER NOT NULL DEFAULT 1;
-- 移除舊的唯一約束（如果存在）
ALTER TABLE "LiteLLM_PromptTable"
    DROP CONSTRAINT IF EXISTS "LiteLLM_PromptTable_prompt_id_key";
-- 建立新的複合唯一約束
CREATE UNIQUE INDEX IF NOT EXISTS "LiteLLM_PromptTable_prompt_id_version_key"
    ON "LiteLLM_PromptTable"("prompt_id", "version");
CREATE INDEX IF NOT EXISTS "LiteLLM_PromptTable_prompt_id_idx"
    ON "LiteLLM_PromptTable"("prompt_id");

COMMIT;
```

### 3.2 Phase B：v1.80.11 → v1.81.12

```sql
-- =====================================================
-- Phase B: v1.80.11 → v1.81.12
-- 執行前請先備份資料庫！
-- =====================================================

BEGIN;

-- ─── 新增資料表 ───────────────────────────────────

-- 1. LiteLLM_DeletedTeamTable
CREATE TABLE IF NOT EXISTS "LiteLLM_DeletedTeamTable" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid(),
    "team_id" TEXT NOT NULL,
    "team_alias" TEXT,
    "organization_id" TEXT,
    "object_permission_id" TEXT,
    "admins" TEXT[],
    "members" TEXT[],
    "members_with_roles" JSONB NOT NULL DEFAULT '{}',
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "max_budget" DOUBLE PRECISION,
    "soft_budget" DOUBLE PRECISION,
    "spend" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "models" TEXT[],
    "max_parallel_requests" INTEGER,
    "tpm_limit" BIGINT,
    "rpm_limit" BIGINT,
    "budget_duration" TEXT,
    "budget_reset_at" TIMESTAMP(3),
    "blocked" BOOLEAN NOT NULL DEFAULT false,
    "model_spend" JSONB NOT NULL DEFAULT '{}',
    "model_max_budget" JSONB NOT NULL DEFAULT '{}',
    "router_settings" JSONB DEFAULT '{}',
    "team_member_permissions" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "access_group_ids" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "policies" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "model_id" INTEGER,
    "allow_team_guardrail_config" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3),
    "updated_at" TIMESTAMP(3),
    "deleted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_by" TEXT,
    "deleted_by_api_key" TEXT,
    "litellm_changed_by" TEXT,
    CONSTRAINT "LiteLLM_DeletedTeamTable_pkey" PRIMARY KEY ("id")
);
CREATE INDEX IF NOT EXISTS "LiteLLM_DeletedTeamTable_team_id_idx"
    ON "LiteLLM_DeletedTeamTable"("team_id");
CREATE INDEX IF NOT EXISTS "LiteLLM_DeletedTeamTable_deleted_at_idx"
    ON "LiteLLM_DeletedTeamTable"("deleted_at");
CREATE INDEX IF NOT EXISTS "LiteLLM_DeletedTeamTable_organization_id_idx"
    ON "LiteLLM_DeletedTeamTable"("organization_id");
CREATE INDEX IF NOT EXISTS "LiteLLM_DeletedTeamTable_team_alias_idx"
    ON "LiteLLM_DeletedTeamTable"("team_alias");
CREATE INDEX IF NOT EXISTS "LiteLLM_DeletedTeamTable_created_at_idx"
    ON "LiteLLM_DeletedTeamTable"("created_at");

-- 2. LiteLLM_DeletedVerificationToken
CREATE TABLE IF NOT EXISTS "LiteLLM_DeletedVerificationToken" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid(),
    "token" TEXT NOT NULL,
    "key_name" TEXT,
    "key_alias" TEXT,
    "soft_budget_cooldown" BOOLEAN NOT NULL DEFAULT false,
    "spend" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "expires" TIMESTAMP(3),
    "models" TEXT[],
    "aliases" JSONB NOT NULL DEFAULT '{}',
    "config" JSONB NOT NULL DEFAULT '{}',
    "user_id" TEXT,
    "team_id" TEXT,
    "permissions" JSONB NOT NULL DEFAULT '{}',
    "max_parallel_requests" INTEGER,
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "blocked" BOOLEAN,
    "tpm_limit" BIGINT,
    "rpm_limit" BIGINT,
    "max_budget" DOUBLE PRECISION,
    "budget_duration" TEXT,
    "budget_reset_at" TIMESTAMP(3),
    "allowed_cache_controls" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "allowed_routes" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "policies" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "access_group_ids" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "model_spend" JSONB NOT NULL DEFAULT '{}',
    "model_max_budget" JSONB NOT NULL DEFAULT '{}',
    "router_settings" JSONB DEFAULT '{}',
    "budget_id" TEXT,
    "organization_id" TEXT,
    "object_permission_id" TEXT,
    "created_at" TIMESTAMP(3),
    "created_by" TEXT,
    "updated_at" TIMESTAMP(3),
    "updated_by" TEXT,
    "rotation_count" INTEGER DEFAULT 0,
    "auto_rotate" BOOLEAN DEFAULT false,
    "rotation_interval" TEXT,
    "last_rotation_at" TIMESTAMP(3),
    "key_rotation_at" TIMESTAMP(3),
    "deleted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deleted_by" TEXT,
    "deleted_by_api_key" TEXT,
    "litellm_changed_by" TEXT,
    CONSTRAINT "LiteLLM_DeletedVerificationToken_pkey" PRIMARY KEY ("id")
);
CREATE INDEX IF NOT EXISTS "LiteLLM_DeletedVerificationToken_token_idx"
    ON "LiteLLM_DeletedVerificationToken"("token");
CREATE INDEX IF NOT EXISTS "LiteLLM_DeletedVerificationToken_deleted_at_idx"
    ON "LiteLLM_DeletedVerificationToken"("deleted_at");
CREATE INDEX IF NOT EXISTS "LiteLLM_DeletedVerificationToken_user_id_idx"
    ON "LiteLLM_DeletedVerificationToken"("user_id");
CREATE INDEX IF NOT EXISTS "LiteLLM_DeletedVerificationToken_team_id_idx"
    ON "LiteLLM_DeletedVerificationToken"("team_id");
CREATE INDEX IF NOT EXISTS "LiteLLM_DeletedVerificationToken_organization_id_idx"
    ON "LiteLLM_DeletedVerificationToken"("organization_id");
CREATE INDEX IF NOT EXISTS "LiteLLM_DeletedVerificationToken_key_alias_idx"
    ON "LiteLLM_DeletedVerificationToken"("key_alias");
CREATE INDEX IF NOT EXISTS "LiteLLM_DeletedVerificationToken_created_at_idx"
    ON "LiteLLM_DeletedVerificationToken"("created_at");

-- 3. LiteLLM_ManagedVectorStoreTable
CREATE TABLE IF NOT EXISTS "LiteLLM_ManagedVectorStoreTable" (
    "id" TEXT NOT NULL DEFAULT gen_random_uuid(),
    "unified_resource_id" TEXT NOT NULL,
    "resource_object" JSONB,
    "model_mappings" JSONB NOT NULL,
    "flat_model_resource_ids" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "storage_backend" TEXT,
    "storage_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_by" TEXT,
    CONSTRAINT "LiteLLM_ManagedVectorStoreTable_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "LiteLLM_ManagedVectorStoreTable_unified_resource_id_key"
    ON "LiteLLM_ManagedVectorStoreTable"("unified_resource_id");
CREATE INDEX IF NOT EXISTS "LiteLLM_ManagedVectorStoreTable_unified_resource_id_idx"
    ON "LiteLLM_ManagedVectorStoreTable"("unified_resource_id");

-- 4. LiteLLM_PolicyTable
CREATE TABLE IF NOT EXISTS "LiteLLM_PolicyTable" (
    "policy_id" TEXT NOT NULL DEFAULT gen_random_uuid(),
    "policy_name" TEXT NOT NULL,
    "inherit" TEXT,
    "description" TEXT,
    "guardrails_add" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "guardrails_remove" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "condition" JSONB DEFAULT '{}',
    "pipeline" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_by" TEXT,
    CONSTRAINT "LiteLLM_PolicyTable_pkey" PRIMARY KEY ("policy_id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "LiteLLM_PolicyTable_policy_name_key"
    ON "LiteLLM_PolicyTable"("policy_name");

-- 5. LiteLLM_PolicyAttachmentTable
CREATE TABLE IF NOT EXISTS "LiteLLM_PolicyAttachmentTable" (
    "attachment_id" TEXT NOT NULL DEFAULT gen_random_uuid(),
    "policy_name" TEXT NOT NULL,
    "scope" TEXT,
    "teams" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "keys" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "models" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_by" TEXT,
    CONSTRAINT "LiteLLM_PolicyAttachmentTable_pkey" PRIMARY KEY ("attachment_id")
);

-- 6. LiteLLM_AccessGroupTable
CREATE TABLE IF NOT EXISTS "LiteLLM_AccessGroupTable" (
    "access_group_id" TEXT NOT NULL DEFAULT gen_random_uuid(),
    "access_group_name" TEXT NOT NULL,
    "description" TEXT,
    "access_model_names" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "access_mcp_server_ids" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "access_agent_ids" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "assigned_team_ids" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "assigned_key_ids" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_by" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_by" TEXT,
    CONSTRAINT "LiteLLM_AccessGroupTable_pkey" PRIMARY KEY ("access_group_id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "LiteLLM_AccessGroupTable_access_group_name_key"
    ON "LiteLLM_AccessGroupTable"("access_group_name");

-- ─── 修改現有資料表 ─────────────────────────────────

-- TeamTable
ALTER TABLE "LiteLLM_TeamTable"
    ADD COLUMN IF NOT EXISTS "soft_budget" DOUBLE PRECISION;
ALTER TABLE "LiteLLM_TeamTable"
    ADD COLUMN IF NOT EXISTS "router_settings" JSONB DEFAULT '{}';
ALTER TABLE "LiteLLM_TeamTable"
    ADD COLUMN IF NOT EXISTS "access_group_ids" TEXT[] DEFAULT ARRAY[]::TEXT[];
ALTER TABLE "LiteLLM_TeamTable"
    ADD COLUMN IF NOT EXISTS "policies" TEXT[] DEFAULT ARRAY[]::TEXT[];
ALTER TABLE "LiteLLM_TeamTable"
    ADD COLUMN IF NOT EXISTS "allow_team_guardrail_config" BOOLEAN NOT NULL DEFAULT false;

-- UserTable
ALTER TABLE "LiteLLM_UserTable"
    ADD COLUMN IF NOT EXISTS "policies" TEXT[] DEFAULT ARRAY[]::TEXT[];

-- MCPServerTable
ALTER TABLE "LiteLLM_MCPServerTable"
    ADD COLUMN IF NOT EXISTS "authorization_url" TEXT;
ALTER TABLE "LiteLLM_MCPServerTable"
    ADD COLUMN IF NOT EXISTS "token_url" TEXT;
ALTER TABLE "LiteLLM_MCPServerTable"
    ADD COLUMN IF NOT EXISTS "registration_url" TEXT;
ALTER TABLE "LiteLLM_MCPServerTable"
    ADD COLUMN IF NOT EXISTS "allow_all_keys" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "LiteLLM_MCPServerTable"
    ADD COLUMN IF NOT EXISTS "available_on_public_internet" BOOLEAN NOT NULL DEFAULT false;

-- VerificationToken
ALTER TABLE "LiteLLM_VerificationToken"
    ADD COLUMN IF NOT EXISTS "router_settings" JSONB DEFAULT '{}';
ALTER TABLE "LiteLLM_VerificationToken"
    ADD COLUMN IF NOT EXISTS "policies" TEXT[] DEFAULT ARRAY[]::TEXT[];
ALTER TABLE "LiteLLM_VerificationToken"
    ADD COLUMN IF NOT EXISTS "access_group_ids" TEXT[] DEFAULT ARRAY[]::TEXT[];
CREATE INDEX IF NOT EXISTS "LiteLLM_VerificationToken_user_id_team_id_idx"
    ON "LiteLLM_VerificationToken"("user_id", "team_id");
CREATE INDEX IF NOT EXISTS "LiteLLM_VerificationToken_team_id_idx"
    ON "LiteLLM_VerificationToken"("team_id");
CREATE INDEX IF NOT EXISTS "LiteLLM_VerificationToken_budget_reset_expires_idx"
    ON "LiteLLM_VerificationToken"("budget_reset_at", "expires");

-- ManagedVectorStoresTable
ALTER TABLE "LiteLLM_ManagedVectorStoresTable"
    ADD COLUMN IF NOT EXISTS "team_id" TEXT;
ALTER TABLE "LiteLLM_ManagedVectorStoresTable"
    ADD COLUMN IF NOT EXISTS "user_id" TEXT;
CREATE INDEX IF NOT EXISTS "LiteLLM_ManagedVectorStoresTable_team_id_idx"
    ON "LiteLLM_ManagedVectorStoresTable"("team_id");
CREATE INDEX IF NOT EXISTS "LiteLLM_ManagedVectorStoresTable_user_id_idx"
    ON "LiteLLM_ManagedVectorStoresTable"("user_id");

-- GuardrailsTable
ALTER TABLE "LiteLLM_GuardrailsTable"
    ADD COLUMN IF NOT EXISTS "team_id" TEXT;

-- ─── Daily Spend 資料表唯一約束變更（破壞性）──

-- DailyUserSpend
ALTER TABLE "LiteLLM_DailyUserSpend"
    ADD COLUMN IF NOT EXISTS "endpoint" TEXT;
ALTER TABLE "LiteLLM_DailyUserSpend"
    DROP CONSTRAINT IF EXISTS "LiteLLM_DailyUserSpend_user_id_date_api_key_model_custom_llm_provider_mcp_namespaced_tool_name_key";
CREATE UNIQUE INDEX IF NOT EXISTS
    "LiteLLM_DailyUserSpend_user_date_key_model_provider_mcp_ep_key"
    ON "LiteLLM_DailyUserSpend"(
        "user_id", "date", "api_key", "model",
        "custom_llm_provider", "mcp_namespaced_tool_name", "endpoint"
    );
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyUserSpend_endpoint_idx"
    ON "LiteLLM_DailyUserSpend"("endpoint");

-- DailyOrganizationSpend
ALTER TABLE "LiteLLM_DailyOrganizationSpend"
    ADD COLUMN IF NOT EXISTS "endpoint" TEXT;
ALTER TABLE "LiteLLM_DailyOrganizationSpend"
    DROP CONSTRAINT IF EXISTS "LiteLLM_DailyOrganizationSpend_org_date_key_model_provider_mcp_key";
CREATE UNIQUE INDEX IF NOT EXISTS
    "LiteLLM_DailyOrgSpend_org_date_key_model_provider_mcp_ep_key"
    ON "LiteLLM_DailyOrganizationSpend"(
        "organization_id", "date", "api_key", "model",
        "custom_llm_provider", "mcp_namespaced_tool_name", "endpoint"
    );
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyOrganizationSpend_endpoint_idx"
    ON "LiteLLM_DailyOrganizationSpend"("endpoint");

-- DailyEndUserSpend
ALTER TABLE "LiteLLM_DailyEndUserSpend"
    ADD COLUMN IF NOT EXISTS "endpoint" TEXT;
ALTER TABLE "LiteLLM_DailyEndUserSpend"
    DROP CONSTRAINT IF EXISTS "LiteLLM_DailyEndUserSpend_enduser_date_key_model_provider_mcp_key";
CREATE UNIQUE INDEX IF NOT EXISTS
    "LiteLLM_DailyEndUserSpend_eu_date_key_model_provider_mcp_ep_key"
    ON "LiteLLM_DailyEndUserSpend"(
        "end_user_id", "date", "api_key", "model",
        "custom_llm_provider", "mcp_namespaced_tool_name", "endpoint"
    );
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyEndUserSpend_endpoint_idx"
    ON "LiteLLM_DailyEndUserSpend"("endpoint");

-- DailyAgentSpend
ALTER TABLE "LiteLLM_DailyAgentSpend"
    ADD COLUMN IF NOT EXISTS "endpoint" TEXT;
ALTER TABLE "LiteLLM_DailyAgentSpend"
    DROP CONSTRAINT IF EXISTS "LiteLLM_DailyAgentSpend_agent_date_key_model_provider_mcp_key";
CREATE UNIQUE INDEX IF NOT EXISTS
    "LiteLLM_DailyAgentSpend_agent_date_key_model_provider_mcp_ep_key"
    ON "LiteLLM_DailyAgentSpend"(
        "agent_id", "date", "api_key", "model",
        "custom_llm_provider", "mcp_namespaced_tool_name", "endpoint"
    );
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyAgentSpend_endpoint_idx"
    ON "LiteLLM_DailyAgentSpend"("endpoint");

-- DailyTeamSpend
ALTER TABLE "LiteLLM_DailyTeamSpend"
    ADD COLUMN IF NOT EXISTS "endpoint" TEXT;
ALTER TABLE "LiteLLM_DailyTeamSpend"
    DROP CONSTRAINT IF EXISTS "LiteLLM_DailyTeamSpend_team_id_date_api_key_model_custom_llm_provider_mcp_namespaced_tool_name_key";
CREATE UNIQUE INDEX IF NOT EXISTS
    "LiteLLM_DailyTeamSpend_team_date_key_model_provider_mcp_ep_key"
    ON "LiteLLM_DailyTeamSpend"(
        "team_id", "date", "api_key", "model",
        "custom_llm_provider", "mcp_namespaced_tool_name", "endpoint"
    );
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyTeamSpend_endpoint_idx"
    ON "LiteLLM_DailyTeamSpend"("endpoint");

-- DailyTagSpend
ALTER TABLE "LiteLLM_DailyTagSpend"
    ADD COLUMN IF NOT EXISTS "endpoint" TEXT;
ALTER TABLE "LiteLLM_DailyTagSpend"
    DROP CONSTRAINT IF EXISTS "LiteLLM_DailyTagSpend_tag_date_api_key_model_custom_llm_provider_mcp_namespaced_tool_name_key";
CREATE UNIQUE INDEX IF NOT EXISTS
    "LiteLLM_DailyTagSpend_tag_date_key_model_provider_mcp_ep_key"
    ON "LiteLLM_DailyTagSpend"(
        "tag", "date", "api_key", "model",
        "custom_llm_provider", "mcp_namespaced_tool_name", "endpoint"
    );
CREATE INDEX IF NOT EXISTS "LiteLLM_DailyTagSpend_endpoint_idx"
    ON "LiteLLM_DailyTagSpend"("endpoint");

COMMIT;
```

---

## 4. 風險評估

### 4.1 安全的可加性變更（95%）

- 所有 15 張新資料表都是 `CREATE TABLE IF NOT EXISTS`
- 所有新欄位都是 nullable 或有預設值
- 新索引不影響現有資料

### 4.2 需要注意的破壞性變更（5%）

| 變更 | 風險 | 說明 |
|------|------|------|
| PromptTable 唯一約束 | MEDIUM | 先加 `version` 欄位，再替換唯一約束 |
| 6x Daily Spend 唯一約束 | MEDIUM | 先加 `endpoint` 欄位，再替換唯一約束 |

**關鍵風險點**：

- `DROP CONSTRAINT` 操作需要取得資料表鎖定，在高負載下可能導致短暫阻塞
- 建議在低流量時段執行
- PostgreSQL 的 `NULL` 在唯一約束中被視為不同值，所以新增 nullable 欄位後不會違反約束

### 4.3 `prisma db push --accept-data-loss` 的風險

`--accept-data-loss` 旗標意味著 Prisma 可能：

- 自動丟棄不相容的欄位資料
- 重建有結構性變更的資料表

**建議**：生產環境使用手動 SQL 遷移，設定 `DISABLE_SCHEMA_UPDATE=true`。

---

## References

- Prisma Schema: `testing/litellm-v1.81.12/litellm/proxy/schema.prisma`
- PrismaManager: `testing/litellm-v1.81.12/litellm/proxy/db/prisma_client.py`
- Extras Schema: `testing/litellm-v1.81.12/litellm-proxy-extras/litellm_proxy_extras/schema.prisma`
- 完整變更日誌: `reports/upgrade-changelog-v1.79-to-v1.81.md`
- 升級計劃: `reports/upgrade-plan-2026-02.md`
