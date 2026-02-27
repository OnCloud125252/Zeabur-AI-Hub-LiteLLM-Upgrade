# Remote Testing

> Remote Docker deployment testing environment

← [Back to Testing](../README.md)

---

## Overview

This directory contains Docker Compose configurations and scripts for testing LiteLLM upgrades in a remote Linux x86_64 environment (matching production architecture).

## Environment Details

| Property | Value |
|----------|-------|
| Server IP | `10.0.1.9` |
| Hostname | CT108 |
| OS | Linux 6.8.12-17-pve (Proxmox VE) |
| Architecture | x86_64 |
| Docker | 29.2.1 |
| Docker Compose | v5.1.0 |

See [guides/remote-docker-server.md](../../guides/remote-docker-server.md) for connection details.

## Directory Structure

```
testing/remote/
├── docker-compose.base.yml       # Shared base configuration
├── docker-compose.v1.79.0.yml    # v1.79.0 deployment
├── docker-compose.v1.81.12.yml   # v1.81.12 deployment
├── config/
│   └── config.yaml               # LiteLLM proxy configuration
├── migrations/
│   ├── migration_phase_a.sql     # v1.79.0 → v1.80.11
│   └── migration_phase_b.sql     # v1.80.11 → v1.81.12
└── scripts/
    ├── setup.sh                  # Environment setup
    ├── migrate.sh                # Database migration
    ├── test.sh                   # Test execution
    └── rollback.sh               # Rollback procedures
```

## Quick Start

### Deploy v1.79.0 (Baseline)

```bash
# Copy files to remote
scp -r testing/remote/* root@10.0.1.9:/opt/litellm/

# Deploy baseline
ssh root@10.0.1.9 "cd /opt/litellm && docker compose -f docker-compose.v1.79.0.yml up -d"
```

### Run Database Migration

```bash
# Apply migrations
ssh root@10.0.1.9 "cd /opt/litellm && psql -h localhost -U llmproxy -d litellm -f migrations/migration_phase_a.sql"
ssh root@10.0.1.9 "cd /opt/litellm && psql -h localhost -U llmproxy -d litellm -f migrations/migration_phase_b.sql"
```

### Deploy v1.81.12 (Upgrade)

```bash
# Deploy new version
ssh root@10.0.1.9 "cd /opt/litellm && docker compose -f docker-compose.v1.81.12.yml up -d"

# Verify
ssh root@10.0.1.9 "docker ps -a"
ssh root@10.0.1.9 "docker logs litellm-proxy"
```

### Rollback

```bash
# Stop new version
ssh root@10.0.1.9 "cd /opt/litellm && docker compose -f docker-compose.v1.81.12.yml down"

# Start old version
ssh root@10.0.1.9 "cd /opt/litellm && docker compose -f docker-compose.v1.79.0.yml up -d"
```

## Docker Compose Files

### Base Configuration (`docker-compose.base.yml`)

Shared services:
- PostgreSQL 16 (`litellm-db`)
- Redis 7-alpine (`litellm-redis`)

### Version-Specific Configurations

Each version file extends the base:
- Defines the LiteLLM proxy image
- Sets environment variables
- Configures health checks
- Maps volumes

## Migrations

| File | Purpose |
|------|---------|
| `migration_phase_a.sql` | Schema changes from v1.79.0 to v1.80.11 |
| `migration_phase_b.sql` | Schema changes from v1.80.11 to v1.81.12 |

See [reports/4b-db-migration-guide.md](../../reports/4b-db-migration-guide.md) for detailed instructions.

## Verification

After deployment, verify the installation:

```bash
# Health check
curl http://10.0.1.9:4000/health/liveliness

# Model list
curl http://10.0.1.9:4000/v1/models

# Chat completion (requires API key)
curl -X POST http://10.0.1.9:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-test-key-1234" \
  -d '{"model": "gemini-2.5-flash", "messages": [{"role": "user", "content": "Hello"}]}'
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Containers won't start | Check `docker logs litellm-proxy` |
| Database connection failed | Verify `DATABASE_URL` and PostgreSQL container |
| Migration errors | Review SQL scripts in migrations/ |
| Image pull errors | Verify connectivity to `docker.litellm.ai` |

---

*See [reports/3-verification-report.md](../../reports/3-verification-report.md) for Phase 3 verification results.*
