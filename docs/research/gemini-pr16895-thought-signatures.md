# PR #16895: Gemini 3 Thought Signatures in Tool Call ID

## Overview

| Field | Value |
|-------|-------|
| **PR Number** | #16895 |
| **Title** | [stripe] gemini 3 thought signatures in tool call id |
| **Author** | colinlin-stripe |
| **Status** | ✅ Merged |
| **Created** | 2025-11-20 |
| **Merged** | 2025-11-21 |
| **URL** | <https://github.com/BerriAI/litellm/pull/16895> |

## Summary

This PR addresses a compatibility issue between **Gemini 3** and chat completion clients (like LangChain's ChatOpenAI) that don't natively support Gemini's "thought signatures" in tool calls.

### The Problem

Gemini 3 returns thought signatures in tool calls within its responses and expects the client to send back the thought signature in subsequent requests. If the thought signature is not provided, Gemini returns a 400 error. Many chat completion clients (e.g., LangChain's ChatOpenAI) do not handle this out-of-the-box.

**Reference:** [Gemini Thought Signatures Documentation](https://ai.google.dev/gemini-api/docs/thought-signatures)

### The Solution

Store Gemini thought signatures within the **tool call ID**. This ensures that chat completion clients will always pass back the tool call ID in chat history. LiteLLM then extracts the thought signature from the tool call ID and sends it to Gemini.

**Note:** This only works for chat completions, not the Responses API.

## Changes

| File | Additions | Deletions | Description |
|------|-----------|-----------|-------------|
| `docs/my-website/docs/providers/gemini.md` | 2 | 0 | Documentation update for Gemini provider |
| `litellm/litellm_core_utils/prompt_templates/factory.py` | 95 | 34 | Core logic for embedding/extracting thought signatures in tool call IDs |
| `litellm/llms/vertex_ai/gemini/vertex_and_google_ai_studio_gemini.py` | 13 | 1 | Integration with Vertex AI Gemini handler |
| `tests/test_litellm/llms/vertex_ai/gemini/test_thought_signature_in_tool_call_id.py` | 264 | 0 | Comprehensive test suite |

**Total:** +374 lines, -35 lines

## Technical Details

### Thought Signature Format

The tool call ID is modified to include the thought signature in a specific format:

```
call_<uuid>__thought__<signature>
```

Example:

```
call_00d09e4f03654b668abe3e361f1e__thought__CsoDAePx/140cmKGChx3tcqSw7eWw+UgW8B...
```

### Example Response

```json
{
  "id": "gpUfacGnCPiZ4_UP3qjZkQs",
  "created": 1763677569,
  "model": "gemini-3-pro",
  "object": "chat.completion",
  "choices": [
    {
      "finish_reason": "tool_calls",
      "index": 0,
      "message": {
        "role": "assistant",
        "tool_calls": [
          {
            "index": 0,
            "provider_specific_fields": {
              "thought_signature": "CsoDAePx/140cmKGChx3tcqSw7eWw+UgW8B..."
            },
            "function": {
              "arguments": "{\"num1\": 2, \"operation\": \"add\", \"num2\": 2}",
              "name": "calculator"
            },
            "id": "call_00d09e4f03654b668abe3e361f1e__thought__CsoDAePx/140cmKGChx3tcqSw7eWw+UgW8B...",
            "type": "function"
          }
        ],
        "thinking_blocks": [
          {
            "type": "thinking",
            "thinking": "{\"functionCall\": {\"name\": \"calculator\", \"args\": {\"num1\": 2, \"operation\": \"add\", \"num2\": 2}}}",
            "signature": "CsoDAePx/140cmKGChx3tcqSw7eWw+UgW8B..."
          }
        ]
      }
    }
  ]
}
```

## Testing

### Test Command

```bash
poetry run pytest tests/test_litellm/llms/vertex_ai/gemini/test_thought_signature_in_tool_call_id.py -v
```

### cURL Test Example

```bash
curl --verbose -X POST http://0.0.0.0:4000/chat/completions \
  -H 'Authorization: Bearer sk-123' \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "gemini-3-pro",
    "messages": [
      {
        "role": "user",
        "content": "What is 2 + 2?"
      }
    ],
    "tools": [
      {
        "type": "function",
        "function": {
          "name": "calculator",
          "description": "A basic calculator that can add, subtract, multiply, or divide two numbers",
          "parameters": {
            "type": "object",
            "properties": {
              "operation": {
                "type": "string",
                "enum": ["add", "subtract", "multiply", "divide"],
                "description": "The mathematical operation to perform"
              },
              "num1": {
                "type": "number",
                "description": "The first number"
              },
              "num2": {
                "type": "number",
                "description": "The second number"
              }
            },
            "required": ["operation", "num1", "num2"]
          }
        }
      }
    ]
}'
```

## Impact

This change enables proper tool calling with Gemini 3 models through LiteLLM's proxy, even when using clients that don't natively support Gemini's thought signature protocol. This improves compatibility with:

- LangChain's ChatOpenAI
- OpenAI-compatible clients
- Any chat completion client that follows standard tool call ID patterns

## Related PRs

- **PR #18374**: Subsequent refinement that moves the feature out of beta and adds a pre-call hook for checking tool calls for thought signatures
