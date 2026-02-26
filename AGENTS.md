# AGENTS.md - Zeabur AI Hub LiteLLM Upgrade

> Minimal instructions for AI agents

## Project

Research and plan the LiteLLM upgrade from v1.79.0-stable → v1.81.12-stable to fix the Gemini thought_signature 503 error.

## Key Files

| File | Purpose |
|------|---------|
| `docs/requirements.md` | Full requirements and task breakdown |
| `specs/litellm-pr-compatibility.md` | Version compatibility matrix |

## Quick Reference

- **Target**: v1.81.12-stable (latest stable with both PR #16895 and #18374 fixes)
- **Problem**: "function call read in the N. content block is missing a thought_signature"
- **Resource**: https://github.com/BerriAI/litellm/releases

## Document Creation

When you find important information, create new documents in `docs/`:

| Document Type | Location | When to Create |
|---------------|----------|----------------|
| Research notes | `docs/research/` | When investigating specific PRs, issues, or features |
| Version analysis | Root or `docs/` | When analyzing version changes, breaking changes |
| Findings/Reports | Root | When delivering conclusions or recommendations |

### Document Naming

- Use lowercase with hyphens: `pr-12345-analysis.md`
- Use descriptive names: `upgrade-changelog-v1.80.md` not `notes.md`
- Include date for reports: `upgrade-plan-2026-02.md`

### Document Template

```markdown
# [Title]

**Date**: YYYY-MM-DD
**Purpose**: [What this document captures]

## Summary

[Brief overview]

## Details

[Content]

## References

- [Link 1]
- [Link 2]
```

## What to Do

1. Read `docs/requirements.md` for full requirements
2. Check existing research in `docs/research/`
3. Document findings in the project

## Not Needed Here

- No code to write or test
- No build commands
- No package installations
