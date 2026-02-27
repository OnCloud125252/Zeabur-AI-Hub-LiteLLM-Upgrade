# AGENTS.md - Zeabur AI Hub LiteLLM Upgrade

> Minimal instructions for AI agents

## Project

Research and plan the LiteLLM upgrade from v1.79.0-stable → v1.81.12-stable.1 to fix the Gemini thought_signature 503 error.

## Key Files

| File | Purpose |
|------|---------|
| `requirements.md` | Project requirements and dependencies |
| `reports/1-upgrade-report.md` | Phase 1 upgrade report |
| `reports/2-upgrade-plan.md` | Upgrade plan with rollback strategy |
| `reports/3-phase3-verification-report.md` | Phase 3 verification results |
| `docs/plans/3-local-upgrade-verification.md` | Phase 3 local verification plan |
| `docs/research/upgrade-changelog-v1.79-to-v1.81.md` | Version-by-version changelog (11 releases) |
| `docs/research/db-schema-migration-v1.79-to-v1.81.md` | Database schema migration analysis + SQL |
| `docs/research/pr-16895.md` | PR #16895 analysis (thought signatures) |
| `docs/research/pr-18374.md` | PR #18374 analysis (thought signature fix) |
| `docs/research/pr-compatibility.md` | PR compatibility matrix |
| `testing/local/test_regression.py` | 28-test regression suite |
| `testing/local/test_gemini_signature.py` | thought_signature integration test |
| `testing/local/config.yaml` | Shared LiteLLM proxy config |

## Directory Structure

```
.
├── AGENTS.md                           # This file
├── CLAUDE.md                           # Inherits from ~/CLAUDE.md
├── requirements.md                     # Project requirements
├── reports/
│   ├── 1-upgrade-report.md            # Phase 1 upgrade report
│   ├── 2-upgrade-plan.md              # Phase 2 upgrade plan
│   ├── 3-phase3-verification-report.md # Phase 3 verification results
│   ├── baseline-v1.79.0.txt           # Baseline test output
│   ├── regression-v1.81.12.txt        # Regression test results
│   ├── rollback-v1.79.0.txt           # Rollback test results
│   ├── signature-v1.79.0.txt          # Signature test v1.79.0
│   └── signature-v1.81.12.txt         # Signature test v1.81.12
├── docs/
│   ├── documentation-guide.md          # Documentation conventions
│   ├── python-setup.md                 # UV usage guide
│   ├── remote-docker-server.md         # Remote Docker server docs
│   ├── plans/                          # Phase plans
│   │   └── 3-local-upgrade-verification.md
│   └── research/
│       ├── upgrade-changelog-v1.79-to-v1.81.md  # Version changelog
│       ├── db-schema-migration-v1.79-to-v1.81.md # DB schema diff
│       ├── pr-16895.md                 # PR #16895 analysis
│       ├── pr-18374.md                 # PR #18374 analysis
│       └── pr-compatibility.md         # PR compatibility
├── testing/
│   ├── local/                          # Local testing environment
│   │   ├── config.yaml                 # Shared proxy config
│   │   ├── .env                        # API keys (gitignored)
│   │   ├── .venv/                      # Python virtual env (gitignored)
│   │   ├── test_regression.py          # Core regression tests
│   │   ├── test_gemini_signature.py    # thought_signature test
│   │   ├── README.md                   # Local testing guide
│   │   ├── results/                    # Test reports
│   │   ├── litellm-v1.79.0/           # Cloned LiteLLM v1.79.0
│   │   ├── litellm-v1.80.11/          # Cloned LiteLLM v1.80.11
│   │   └── litellm-v1.81.12/          # Cloned LiteLLM v1.81.12
│   └── remote/                         # Remote Docker deployment
│       ├── docker-compose.base.yml    # Shared services (PostgreSQL, Redis)
│       ├── docker-compose.v1.79.0.yml  # v1.79.0 LiteLLM config
│       ├── docker-compose.v1.81.12.yml # v1.81.12 LiteLLM config
│       ├── config/
│       │   └── config.yaml            # LiteLLM proxy config
│       ├── migrations/
│       │   ├── migration_phase_a.sql  # v1.79.0 -> v1.80.11 SQL
│       │   └── migration_phase_b.sql  # v1.80.11 -> v1.81.12 SQL
│       └── scripts/
│           ├── setup.sh               # Remote environment init
│           ├── migrate.sh             # Database migration
│           ├── test.sh                # Test orchestration
│           └── rollback.sh            # Version rollback
```

## Quick Reference

- **Target**: v1.81.12-stable.1 (latest stable with both PR #16895 and #18374 fixes)
- **Problem**: "function call read in the N. content block is missing a thought_signature"
- **Resource**: <https://github.com/BerriAI/litellm/releases>
- **Writing Guide**: See [docs/documentation-guide.md](docs/documentation-guide.md) for patterns

## Python Development

- **Always use UV** for Python package management (see [docs/python-setup.md](docs/python-setup.md) for details)
- Never use pip, pipenv, or poetry

## What to Do

1. Read `requirements.md` for full requirements
2. Check existing research in `docs/research/`
3. Follow `reports/2-upgrade-plan.md` for the upgrade procedure

## Remote Docker Server

`root@10.0.1.9`

See [docs/remote-docker-server.md](docs/remote-docker-server.md) for usage examples.
