-- =====================================================
-- Phase B: v1.80.11 -> v1.81.12
-- Execute a database backup before running this!
-- =====================================================

BEGIN;

-- --- New Tables -----------------------------------------------

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

-- --- Alter Existing Tables ------------------------------------

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

-- --- Daily Spend Tables: unique constraint changes (breaking) --

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
