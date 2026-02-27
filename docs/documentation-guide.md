# Documentation Writing Guide

Guidelines for creating and organizing documents in this project.

## Document Locations

When you find important information, create new documents in `docs/`:

| Document Type | Location | When to Create |
|---------------|----------|----------------|
| Research notes | `docs/research/` | When investigating specific PRs, issues, or features |
| Implementation plans | `docs/plans/` | When planning phased implementation or verification steps |
| Version analysis | `docs/research/` | When analyzing version changes, breaking changes |
| Findings/Reports | `reports/` | When delivering conclusions or recommendations |
| How-to guides | `docs/` | When explaining how to accomplish specific tasks |

## Naming Conventions

- Use lowercase with hyphens: `pr-12345.md`
- Use descriptive names: `upgrade-changelog-v1.79-to-v1.81.md` not `notes.md`
- Use phase numbering for plans: `3-local-upgrade-verification.md`
- Use prefixes for research: `pr-`, `issue-`, `version-`, `db-schema-migration-`
- Reports use numbered prefix: `1-upgrade-report.md`, `2-upgrade-plan.md`

## Document Templates

### Research Document Template

```markdown
# PR #[Number]: [Title]

## Overview

| Field | Value |
|-------|-------|
| **PR Number** | #[Number] |
| **Title** | [Full PR title] |
| **Author** | [GitHub username] |
| **Status** | Merged/Open/Draft |
| **Created** | YYYY-MM-DD |
| **Merged** | YYYY-MM-DD (if applicable) |
| **URL** | <https://github.com/BerriAI/litellm/pull/[Number]> |

## Summary

[Brief overview of what this PR does - 2-3 sentences]

### The Problem

[Describe the issue being solved]

### The Solution

[Describe the approach taken]

## Changes

| File | Additions | Deletions | Description |
|------|-----------|-----------|-------------|
| `path/to/file.py` | 100 | 50 | What changed |

**Total:** +X lines, -Y lines

## References

- [Link 1]
- [Link 2]
```

### Version Analysis Template

```markdown
# 版本差異分析：LiteLLM v[X.Y] → v[X.Y]

- **Date**: YYYY-MM-DD
- **Status**: Complete/In Progress
- **Purpose**: [What this analysis captures]

## Summary

[Brief overview in Chinese - 2-3 sentences]

### 版本總覽

| 版本 | 發佈日期 | 主要變更重點 |
|------|----------|-------------|
| vX.Y.Z | YYYY-MM-DD | Change description |

### 變更類別統計

| 類別 | 數量 | 說明 |
|------|------|------|
| 破壞性變更 | N | Description |
| 新功能 | N | Description |

---

## 1. 破壞性變更

[Detailed breaking changes]

## References

- [Link 1]
- [Link 2]
```

### Report Template

```markdown
# [Report Title in Chinese]

- **Date**: YYYY-MM-DD
- **Purpose**: [What this report captures]

## Summary

[Overview in Chinese - what was accomplished]

| # | 任務 | 狀態 | 成果物 |
|---|------|------|--------|
| 1 | Task 1 | 完成 | Deliverable 1 |
| 2 | Task 2 | 完成 | Deliverable 2 |

---

## 1. [Section Title]

### [Subsection]

[Content with tables for data]

| 項目 | 值 |
|------|---|
| Key | Value |

## 2. [Next Section]

[Content]

## Findings

- Finding 1
- Finding 2

## Next Steps

1. Step 1
2. Step 2

## References

- [Link 1]
- [Link 2]
```

### Phase Plan Template

```markdown
# [Phase Title]

- **Date**: YYYY-MM-DD
- **Phase**: [Phase Number] - [Phase Name]
- **Target Version**: vX.Y.Z-stable
- **Environment**: [Development/Remote Docker/Production]
- **Status**: Planning/In Progress/Complete

## Summary

[Brief description in Chinese - 2-3 sentences]

| 任務 | 預估時間 | 相依項目 |
|------|----------|----------|
| 1. Task 1 | 30 分鐘 | - |
| 2. Task 2 | 1 小時 | 任務 1 |

---

## 1. [Section Title]

### 1.1 [Subsection]

[Content with detailed steps]

### 目錄結構

```
project/
├── file1.yaml
├── file2.yaml
└── config/
    └── config.yaml
```

## 2. [Next Section]

[Content]

## Testing

- [ ] Test case 1
- [ ] Test case 2

## Rollback Plan

[Steps to rollback if needed]
```

## Writing Style

### Language

- Use **English** for technical terms, code references, and PR titles
- Use **Traditional Chinese** for summaries, descriptions, and internal documentation
- When in doubt, default to English for broader accessibility

### Tone

- Be concise and direct
- Use active voice ("The proxy starts" not "The proxy is started")
- Include code examples where helpful
- Explain *why*, not just *what*

### Formatting

- Use tables for structured data (metadata, comparisons, task lists)
- Use code blocks for terminal commands and configuration
- Use bullet points for lists
- Use headers (##, ###) to organize content
- Use horizontal rules (`---`) to separate major sections

## Code Examples

### Terminal Commands

```bash
# Good: Include context
# Start LiteLLM proxy with config
litellm --config config.yaml --port 4000

# Bad: No context
litellm
```

### Configuration

```yaml
# Good: Include comments
model_list:
  - model_name: gemini-2.5-flash
    litellm_params:
      model: gemini/gemini-2.5-flash
      api_key: os.environ/VERTEX_API_KEY  # Load from environment
```

## Version Documentation

When documenting versions, include:

1. Release date
2. Key changes (features, fixes, breaking changes)
3. Compatibility notes
4. Migration steps if needed

For multi-version analysis (e.g., upgrade paths), use the pattern:
- `upgrade-changelog-v1.79-to-v1.81.md` for changelog analysis
- `db-schema-migration-v1.79-to-v1.81.md` for database schema changes

## Review Checklist

Before finalizing a document, verify:

- [ ] Title clearly describes the content
- [ ] Date is included
- [ ] All links are valid
- [ ] Code examples are tested
- [ ] Technical terms are consistent
- [ ] Sections flow logically
