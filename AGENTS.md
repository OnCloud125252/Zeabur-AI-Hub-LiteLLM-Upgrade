# AGENTS.md - Zeabur AI Hub LiteLLM Upgrade

> Minimal instructions for AI agents

## Project

Research and plan the LiteLLM upgrade from v1.79.0-stable → v1.81.12-stable.1 to fix the Gemini thought_signature 503 error.

## Key Files

| File | Purpose |
|------|---------|
| `requirements.md` | Project requirements and dependencies |
| `reports/phase1-upgrade-report.md` | Phase 1 upgrade report |
| `reports/upgrade-plan-2026-02.md` | Upgrade plan with rollback strategy |
| `docs/research/upgrade-changelog-v1.79-to-v1.81.md` | Version-by-version changelog (11 releases) |
| `docs/research/db-schema-migration-v1.79-to-v1.81.md` | Database schema migration analysis + SQL |
| `docs/research/pr-16895.md` | PR #16895 analysis (thought signatures) |
| `docs/research/pr-18374.md` | PR #18374 analysis (thought signature fix) |
| `docs/research/pr-compatibility.md` | PR compatibility matrix |
| `testing/test_regression.py` | 28-test regression suite |
| `testing/test_gemini_signature.py` | thought_signature integration test |
| `testing/config.yaml` | Shared LiteLLM proxy config |

## Directory Structure

```
.
├── AGENTS.md                           # This file
├── CLAUDE.md                           # Inherits from ~/CLAUDE.md
├── requirements.md                     # Project requirements
├── reports/
│   ├── phase1-upgrade-report.md       # Phase 1 complete report
│   └── upgrade-plan-2026-02.md        # Upgrade plan with rollback
├── docs/
│   ├── documentation-guide.md          # Documentation conventions
│   ├── python-setup.md                 # UV usage guide
│   └── research/
│       ├── upgrade-changelog-v1.79-to-v1.81.md  # Version changelog
│       ├── db-schema-migration-v1.79-to-v1.81.md # DB schema diff
│       ├── pr-16895.md                 # PR #16895 analysis
│       ├── pr-18374.md                 # PR #18374 analysis
│       └── pr-compatibility.md         # PR compatibility
└── testing/
    ├── config.yaml                     # Shared proxy config
    ├── .env                            # API keys (gitignored)
    ├── test_regression.py              # Core regression tests
    ├── test_gemini_signature.py        # thought_signature test
    ├── results/                        # Test reports
    │   ├── v1.79.0-code-check.md
    │   ├── v1.80.11-code-check.md
    │   └── integration-test.md
    ├── litellm-v1.79.0/               # Cloned repo (gitignored)
    ├── litellm-v1.80.11/              # Cloned repo (gitignored)
    └── litellm-v1.81.12/              # Cloned repo (gitignored)
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
3. Follow `reports/upgrade-plan-2026-02.md` for the upgrade procedure
