# LiteLLM PR Compatibility Report

**Date**: 2026-02-26
**Repository**: [BerriAI/litellm](https://github.com/BerriAI/litellm)

---

## Summary

This document tracks the availability of two Gemini thought signature-related PRs in LiteLLM stable releases.

| PR | Title | Merged Date | Commit |
|----|-------|-------------|--------|
| [#16895](https://github.com/BerriAI/litellm/pull/16895) | [stripe] gemini 3 thought signatures in tool call id | 2025-11-21 | `f9d8eeaf8e38173973b149d50acba10f102a2be6` |
| [#18374](https://github.com/BerriAI/litellm/pull/18374) | Add gemini thought signature support via tool call id | 2025-12-23 | `a57c4d0aa1926e802375f02ece1e873376cc4eb8` |

---

## Version Compatibility Matrix

### Not Included (Released Before Merge)

| Version | Release Date | PR #16895 | PR #18374 |
|---------|--------------|-----------|-----------|
| v1.79.1-stable | 2025-11-08 | ❌ | ❌ |
| v1.80.5-stable | 2025-12-03 | ❌ | ❌ |
| v1.80.8-stable | 2025-12-14 | ✅ | ❌ |

### Included (Released After Both PRs Merged)

| Version | Release Date | PR #16895 | PR #18374 | Notes |
|---------|--------------|-----------|-----------|-------|
| **v1.80.11-stable** | 2026-01-10 | ✅ | ✅ | **Earliest stable with both** |
| v1.80.15-stable | 2026-01-17 | ✅ | ✅ | |
| v1.81.0-stable | 2026-01-24 | ✅ | ✅ | |
| v1.81.3-stable | 2026-02-08 | ✅ | ✅ | |
| v1.81.9-stable | 2026-02-15 | ✅ | ✅ | |
| **v1.81.12-stable.1** | 2026-02-24 | ✅ | ✅ | **Latest stable** |

---

## Recommendation

### Minimum Required Version

To use features from **both** PRs, upgrade to at least:

```
v1.80.11-stable
```

### Suggested Upgrade Path

- **Conservative**: `v1.80.11-stable` - Earliest stable with both fixes
- **Recommended**: `v1.81.12-stable.1` - Latest stable with additional improvements

---

## Feature Details

### Gemini Thought Signatures

Both PRs implement support for Gemini's "thinking" or "thought" signatures via tool call ID:

- **PR #16895**: Initial implementation with Stripe integration considerations
- **PR #18374**: Extended Gemini thought signature support

These features allow LiteLLM to properly handle Gemini's reasoning/thinking tokens that are exposed through tool call identifiers.

---

## Timeline

```
2025-11-08  v1.79.1-stable released
2025-11-21  PR #16895 merged ─────────┐
2025-12-03  v1.80.5-stable released   │ (doesn't include #16895)
2025-12-14  v1.80.8-stable released   │ (includes #16895, not #18374)
2025-12-23  PR #18374 merged ─────────┤
                                        │
2026-01-10  v1.80.11-stable released ◄──┘ (first stable with both)
```

---

## References

- [LiteLLM Releases](https://github.com/BerriAI/litellm/releases)
- [PR #16895 - View on GitHub](https://github.com/BerriAI/litellm/pull/16895)
- [PR #18374 - View on GitHub](https://github.com/BerriAI/litellm/pull/18374)
