# PR #18374: Add Gemini Thought Signature Support via Tool Call ID

## Overview

| Field | Value |
|-------|-------|
| **PR Number** | #18374 |
| **Title** | Add gemini thought signature support via tool call id |
| **Author** | Sameerlite |
| **Status** | ✅ Merged |
| **Created** | 2025-12-23 |
| **Merged** | 2025-12-23 |
| **URL** | https://github.com/BerriAI/litellm/pull/18374 |
| **Fixes** | #18160 |

## Summary

This PR refines the Gemini thought signature feature initially introduced in PR #16895. It moves the feature out of beta status and improves the implementation with a pre-call hook for checking tool calls for thought signatures.

### Key Improvements

1. **Removed beta status** - The thought signature feature is no longer considered experimental
2. **Added pre-call hook** - A dedicated hook checks tool calls for thought signatures before sending requests
3. **Enhanced compatibility** - Improved support for OpenAI Agents SDK

## Changes

| File | Additions | Deletions | Description |
|------|-----------|-----------|-------------|
| `litellm/llms/vertex_ai/gemini/vertex_and_google_ai_studio_gemini.py` | 5 | 7 | Cleanup and refinement of Gemini integration |
| `litellm/utils.py` | 157 | 0 | Added pre-call hook for thought signature detection |
| `tests/local_testing/test_function_setup.py` | 175 | 1 | Additional test coverage for function setup |
| `tests/test_litellm/llms/vertex_ai/gemini/test_thought_signature_in_tool_call_id.py` | 112 | 178 | Refactored and expanded tests |

**Total:** +449 lines, -186 lines

## Technical Details

### Pre-Call Hook

The new pre-call hook in `litellm/utils.py` provides:
- Detection of thought signatures embedded in tool call IDs
- Extraction and proper handling of signatures before API calls
- Validation of tool call formatting

### Code Changes

#### `litellm/utils.py` (+157 lines)

Added utility functions for:
- Parsing tool call IDs for thought signatures
- Extracting signatures when present
- Reconstructing proper tool call payloads for Gemini API

#### `litellm/llms/vertex_ai/gemini/vertex_and_google_ai_studio_gemini.py` (+5, -7)

- Removed beta feature flags
- Simplified logic now that the pre-call hook handles signature extraction
- Cleaner separation of concerns

## Testing

### 1. SDK Testing

Direct SDK usage with thought signature support verified.

### 2. Proxy Testing

LiteLLM proxy server tested with tool calls containing thought signatures.

### 3. OpenAI Agents SDK Testing

Verified compatibility with:
- Gemini models through LiteLLM
- OpenAI Agents SDK with Gemini backend

## Migration from Beta

Users previously using the beta feature should note:

1. The `__thought__` delimiter format remains the same
2. Tool call IDs continue to include signatures in the format: `call_<uuid>__thought__<signature>`
3. The feature is now automatically applied without beta configuration
4. The pre-call hook ensures better error handling and validation

## Example Usage

The tool call flow works seamlessly:

1. **First Request**: Client sends tool call request
2. **Gemini Response**: Returns tool call with signature embedded in ID
   ```json
   {
     "tool_calls": [{
       "id": "call_xxx__thought__CsoDAePx...",
       "function": { "name": "calculator", "arguments": "{...}" }
     }]
   }
   ```
3. **Follow-up Request**: Client returns tool result with the same tool call ID
4. **Pre-call Hook**: LiteLLM extracts the thought signature from the ID
5. **Gemini API**: Receives the proper signature for context continuity

## Impact

This PR solidifies the thought signature feature as a stable, production-ready component of LiteLLM's Gemini integration. The improvements enable:

- More reliable tool calling with Gemini 3 models
- Better compatibility with agent frameworks
- Cleaner code architecture with the pre-call hook pattern
- Reduced risk of 400 errors from missing thought signatures

## Related

- **PR #16895**: Original implementation of thought signatures in tool call IDs
- **Issue #18160**: Related issue that this PR fixes
