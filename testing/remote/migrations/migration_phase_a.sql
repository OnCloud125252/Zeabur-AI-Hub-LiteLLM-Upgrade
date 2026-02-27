-- =====================================================
-- Phase A: v1.79.0 -> v1.80.11
-- Execute a database backup before running this!
-- =====================================================

BEGIN;

-- --- New Tables -----------------------------------------------

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

-- --- Alter Existing Tables ------------------------------------

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

-- PromptTable: unique constraint change (breaking)
ALTER TABLE "LiteLLM_PromptTable"
    ADD COLUMN IF NOT EXISTS "version" INTEGER NOT NULL DEFAULT 1;
-- Drop old unique constraint (if exists)
ALTER TABLE "LiteLLM_PromptTable"
    DROP CONSTRAINT IF EXISTS "LiteLLM_PromptTable_prompt_id_key";
-- Create new composite unique constraint
CREATE UNIQUE INDEX IF NOT EXISTS "LiteLLM_PromptTable_prompt_id_version_key"
    ON "LiteLLM_PromptTable"("prompt_id", "version");
CREATE INDEX IF NOT EXISTS "LiteLLM_PromptTable_prompt_id_idx"
    ON "LiteLLM_PromptTable"("prompt_id");

COMMIT;
