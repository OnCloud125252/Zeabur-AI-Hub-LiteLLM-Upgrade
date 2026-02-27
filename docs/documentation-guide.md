# Documentation Writing Guide

Guidelines for creating and organizing documents in this project.

## Document Locations

When you find important information, create new documents in `docs/`:

| Document Type | Location | When to Create |
|---------------|----------|----------------|
| Research notes | `docs/research/` | When investigating specific PRs, issues, or features |
| Version analysis | Root or `docs/` | When analyzing version changes, breaking changes |
| Findings/Reports | Root | When delivering conclusions or recommendations |
| How-to guides | `docs/` | When explaining how to accomplish specific tasks |

## Naming Conventions

- Use lowercase with hyphens: `pr-12345-analysis.md`
- Use descriptive names: `upgrade-changelog-v1.80.md` not `notes.md`
- Include date for reports: `upgrade-plan-2026-02.md`
- Use prefixes for research: `pr-`, `issue-`, `version-`

## Document Templates

### Research Document Template

```markdown
# [Title]

**Date**: YYYY-MM-DD
**Purpose**: [What this document captures]

## Summary

[Brief overview - 2-3 sentences]

## Details

[Content]

## References

- [Link 1]
- [Link 2]
```

### Report Template

```markdown
# [Report Title]

**Date**: YYYY-MM-DD
**Status**: [In Progress / Complete / Blocked]

## Summary

| Item | Status |
|------|--------|
| Task 1 | Complete |
| Task 2 | Complete |

## Section 1: [Title]

[Content]

## Section 2: [Title]

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

### Upgrade Plan Template

```markdown
# Upgrade Plan: [From Version] → [To Version]

**Date**: YYYY-MM-DD
**Target Version**: vX.Y.Z-stable

## Overview

[Brief description of why this upgrade is needed]

## Changes

### Breaking Changes

| Change | Impact | Mitigation |
|--------|--------|------------|
| Item 1 | High/Medium/Low | Description |

### New Features

- Feature 1
- Feature 2

### Bug Fixes

- Fix 1
- Fix 2

## Testing

- [ ] Test case 1
- [ ] Test case 2

## Rollback Plan

[Steps to rollback if needed]

## Timeline

| Phase | Duration | Status |
|-------|----------|--------|
| Analysis | 1 week | Complete |
| Testing | 1 week | Pending |
| Deployment | 1 day | Pending |
```

## Writing Style

### Language

- Use **English** for technical documentation and code references
- Use **Traditional Chinese** for internal team communication if needed
- When in doubt, default to English for broader accessibility

### Tone

- Be concise and direct
- Use active voice ("The proxy starts" not "The proxy is started")
- Include code examples where helpful
- Explain *why*, not just *what*

### Formatting

- Use tables for structured data
- Use code blocks for terminal commands and configuration
- Use bullet points for lists
- Use headers (##, ###) to organize content

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

## Review Checklist

Before finalizing a document, verify:

- [ ] Title clearly describes the content
- [ ] Date is included
- [ ] All links are valid
- [ ] Code examples are tested
- [ ] Technical terms are consistent
- [ ] Sections flow logically
