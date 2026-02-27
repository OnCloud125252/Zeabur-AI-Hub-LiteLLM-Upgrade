# AGENTS.md - Zeabur AI Hub LiteLLM Upgrade

> Minimal instructions for AI agents

## Project

Research and plan the LiteLLM upgrade from v1.79.0-stable → v1.81.12-stable.1 to fix the Gemini thought_signature 503 error.

## Key Files

| File | Purpose |
|------|---------|
| `requirements.md` | Project requirements and dependencies |
| `reports/1-environment-report.md` | Phase 1 environment report |
| `reports/2-upgrade-plan.md` | Upgrade plan with rollback strategy |
| `reports/3-verification-report.md` | Phase 3 verification plan + results |
| `research/upgrade-changelog-v1.79-to-v1.81.md` | Version-by-version changelog (11 releases) |
| `research/db-schema-migration-v1.79-to-v1.81.md` | Database schema migration analysis + SQL |
| `research/pr-16895.md` | PR #16895 analysis (thought signatures) |
| `research/pr-18374.md` | PR #18374 analysis (thought signature fix) |
| `research/pr-compatibility.md` | PR compatibility matrix |
| `testing/local/test_regression.py` | 28-test regression suite |
| `testing/local/test_gemini_signature.py` | thought_signature integration test |
| `testing/local/test_performance.py` | Performance benchmark test |
| `testing/local/config.yaml` | Shared LiteLLM proxy config |

## Directory Structure

```
.
├── AGENTS.md                              # AI agent instructions
├── .gitignore
├── requirements.md                        # Project requirements
│
├── guides/                                # How-to guides
│   ├── README.md
│   ├── documentation-guide.md
│   ├── python-setup.md
│   └── remote-docker-server.md
│
├── research/                              # Investigation & analysis
│   ├── README.md
│   ├── upgrade-changelog-v1.79-to-v1.81.md
│   ├── db-schema-migration-v1.79-to-v1.81.md
│   ├── pr-16895.md
│   ├── pr-18374.md
│   └── pr-compatibility.md
│
├── reports/                               # Phase deliverables
│   ├── README.md                          # Reports index
│   ├── 1-environment-report.md            # Phase 1
│   ├── 2-upgrade-plan.md                  # Phase 2
│   ├── 3-verification-report.md           # Phase 3
│   ├── 4-delivery-report.md               # Phase 4
│   └── 4a-4g-*.md                         # Delivery sub-documents
│
├── test-outputs/                          # Machine-generated results
│   ├── README.md
│   ├── baseline-v1.79.0.txt
│   ├── regression-v1.81.12.txt
│   ├── rollback-v1.79.0.txt
│   ├── signature-v1.79.0.txt
│   ├── signature-v1.81.12.txt
│   ├── perf-v1.79.0.json
│   └── perf-v1.81.12.json
│
└── testing/
    ├── local/                             # Local test environment
    │   ├── config.yaml
    │   ├── .env                           # (gitignored)
    │   ├── .venv/                         # (gitignored)
    │   ├── README.md
    │   ├── test_regression.py
    │   ├── test_gemini_signature.py
    │   ├── test_performance.py
    │   ├── results/
    │   ├── litellm-v1.79.0/
    │   ├── litellm-v1.80.11/
    │   └── litellm-v1.81.12/
    └── remote/                            # Remote Docker deployment
        ├── docker-compose.base.yml
        ├── docker-compose.v1.79.0.yml
        ├── docker-compose.v1.81.12.yml
        ├── config/
        │   └── config.yaml
        ├── migrations/
        │   ├── migration_phase_a.sql
        │   └── migration_phase_b.sql
        └── scripts/
            ├── setup.sh
            ├── migrate.sh
            ├── test.sh
            └── rollback.sh
```

## Quick Reference

- **Target**: v1.81.12-stable.1 (latest stable with both PR #16895 and #18374 fixes)
- **Problem**: "function call read in the N. content block is missing a thought_signature"
- **Resource**: <https://github.com/BerriAI/litellm/releases>
- **Writing Guide**: See [guides/documentation-guide.md](guides/documentation-guide.md) for patterns

## Python Development

- **Always use UV** for Python package management (see [guides/python-setup.md](guides/python-setup.md) for details)
- Never use pip, pipenv, or poetry

## What to Do

1. Read `requirements.md` for full requirements
2. Check existing research in `research/`

## Remote Docker Server

See [guides/remote-docker-server.md](guides/remote-docker-server.md) for usage examples.
