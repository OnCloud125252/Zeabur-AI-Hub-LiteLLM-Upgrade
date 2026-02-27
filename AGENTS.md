# AGENTS.md - Zeabur AI Hub LiteLLM Upgrade

> Minimal instructions for AI agents

## Project

Research and plan the LiteLLM upgrade from v1.79.0-stable → v1.81.12-stable.1 to fix the Gemini thought_signature 503 error.

## Key Files

| File | Purpose |
|------|---------|
| `upgrade-requirements.md` | Full requirements and task breakdown (Chinese) |
| `reports/phase1-report.md` | Phase 1 report (Traditional Chinese) |
| `docs/research/liteLLM-version-matrix.md` | Version compatibility matrix |
| `testing/test_regression.py` | 28-test regression suite (runs against both versions) |
| `testing/test_gemini_thought_signature.py` | thought_signature integration test |
| `testing/config.yaml` | Shared LiteLLM proxy config |

## Directory Structure

```
.
├── AGENTS.md                           # This file
├── upgrade-requirements.md              # Full requirements (ZH-TW)
├── reports/
│   └── phase1-report.md                # Phase 1 complete report (ZH-TW)
├── docs/
│   ├── documentation-guide.md           # Documentation conventions
│   ├── python-setup-uv.md              # UV usage guide
│   └── research/                       # PR analysis and research
│       ├── liteLLM-version-matrix.md
│       ├── gemini-pr16895-thought-signatures.md
│       ├── gemini-pr18374-thought-signature.md
│       └── vertex-api-test.md
├── testing/
│   ├── config.yaml                     # Shared proxy config
│   ├── .env                            # API keys (gitignored)
│   ├── test_regression.py              # Core regression tests
│   ├── test_gemini_thought_signature.py # thought_signature integration test
│   ├── results/                        # Test reports
│   │   ├── thought-signature-v1.79.0-code-check.md
│   │   ├── thought-signature-v1.80.11-code-check.md
│   │   └── thought-signature-integration-test.md
│   ├── litellm-v1.79.0/               # Cloned repo (gitignored)
│   └── litellm-v1.80.11/              # Cloned repo (gitignored)
```

## Quick Reference

- **Target**: v1.81.12-stable.1 (latest stable with both PR #16895 and #18374 fixes)
- **Problem**: "function call read in the N. content block is missing a thought_signature"
- **Resource**: <https://github.com/BerriAI/litellm/releases>
- **Writing Guide**: See [docs/documentation-guide.md](docs/documentation-guide.md) for documentation patterns
- **Phase 1**: Complete (see `reports/phase1-report.md`)

## Python Development

- **Always use UV** for Python package management (see [docs/python-setup-uv.md](docs/python-setup-uv.md) for details)
- Never use pip, pipenv, or poetry

## What to Do

1. Read `upgrade-requirements.md` for full requirements
2. Check existing research in `docs/research/`
3. Phase 1 is complete — proceed to Phase 2 (version diff analysis)
4. Document findings in the project
