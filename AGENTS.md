# AGENTS.md - Zeabur AI Hub LiteLLM Upgrade

> Minimal instructions for AI agents

## Project

Research and plan the LiteLLM upgrade from v1.79.0-stable → v1.81.12-stable to fix the Gemini thought_signature 503 error.

## Key Files

| File | Purpose |
|------|---------|
| `docs/brief.md` | Full requirements and task breakdown |
| `litellm-pr-compatibility.md` | Version compatibility matrix |

## Quick Reference

- **Target**: v1.81.12-stable (latest stable with both PR #16895 and #18374 fixes)
- **Problem**: "function call read in the N. content block is missing a thought_signature"
- **Resource**: https://github.com/BerriAI/litellm/releases

## What to Do

1. Read `docs/brief.md` for full requirements
2. Check existing research in `docs/research/`
3. Document findings in the project

## Not Needed Here

- No code to write or test
- No build commands
- No package installations
