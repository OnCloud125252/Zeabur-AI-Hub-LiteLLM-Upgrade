# Writing Guide

Guidelines for creating and organizing documents in this project.

## Document Locations

When you find important information, create new documents in `docs/`:

| Document Type | Location | When to Create |
|---------------|----------|----------------|
| Research notes | `docs/research/` | When investigating specific PRs, issues, or features |
| Version analysis | Root or `docs/` | When analyzing version changes, breaking changes |
| Findings/Reports | Root | When delivering conclusions or recommendations |

## Naming Conventions

- Use lowercase with hyphens: `pr-12345-analysis.md`
- Use descriptive names: `upgrade-changelog-v1.80.md` not `notes.md`
- Include date for reports: `upgrade-plan-2026-02.md`

## Document Template

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
