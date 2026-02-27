# LiteLLM Testing Guide

**Date**: 2026-02-27
**Purpose**: Testing suite for LiteLLM proxy regression and integration tests

## Overview

This directory contains automated tests for validating LiteLLM proxy behavior across versions. Use these tests to establish a baseline before upgrades and verify fixes.

## Quick Start

```bash
# 1. Set up environment
cp .env.example .env  # Add your VERTEX_API_KEY

# 2. Start LiteLLM proxy
cd litellm-v1.80.11 && source .venv/bin/activate
GEMINI_API_KEY=$VERTEX_API_KEY litellm --config ../config.yaml --port 4000

# 3. Run tests (in another terminal)
uv run python test_regression.py --model gemini-2.5-flash
```

## Test Suites

### 1. Regression Tests (`test_regression.py`)

Comprehensive test suite covering core proxy features.

**Test Coverage**:

| Category | Tests |
|----------|-------|
| Health & Monitoring | `/health`, `/health/liveliness`, `/health/readiness` |
| Model Listing | `GET /v1/models`, `GET /v1/model/info` |
| Chat Completions | Non-streaming, streaming, usage stats |
| Tool Calling | Single tool, multi-turn conversation |
| Error Handling | Invalid model, invalid auth |
| Utilities | Token counter, routes listing |

**Usage**:

```bash
# Default (port 4000, gemini-2.5-flash)
uv run python test_regression.py

# Custom port and model
uv run python test_regression.py --port 4001 --model gemini-2.5-pro
```

**Expected Output**:

```
============================================================
  LiteLLM Regression Test Baseline
  Proxy: http://localhost:4000
  Model: gemini-2.5-flash
============================================================

============================================================
  Health & Monitoring
============================================================
    GET /health returns 200
    Health check reports healthy models
    ...

============================================================
  RESULTS SUMMARY
============================================================
  Passed: 28/28
  Failed: 0/28

  Overall: ALL TESTS PASSED
```

### 2. Gemini Thought Signature Test (`test_gemini_signature.py`)

Integration test for verifying the thought_signature fix in multi-turn tool conversations.

**Background**: Earlier versions (v1.79.0) had a bug where Gemini's thinking models would return 400/503 errors on multi-turn tool calls. This test verifies the fix preserves thought signatures correctly.

**Test Flow**:

1. Send initial request with tools
2. Verify tool_call IDs contain `__thought__` signature (if applicable)
3. Send tool result with same ID
4. Verify final response completes without errors

**Usage**:

```bash
# Requires proxy with Gemini models configured
uv run python test_gemini_signature.py --model gemini-2.5-flash
```

**What to Look For**:

- **PASS**: Multi-turn conversation completes successfully
- **FAIL with thought_signature error**: The bug is present
- **No __thought__ in ID**: Model may not be emitting signatures (check `enable_preview_features`)

## Configuration

### Environment Variables (`.env`)

```bash
VERTEX_API_KEY=your-vertex-api-key-here
```

### Proxy Configuration (`config.yaml`)

```yaml
model_list:
  - model_name: gemini-2.5-flash
    litellm_params:
      model: gemini/gemini-2.5-flash
      api_key: os.environ/VERTEX_API_KEY

general_settings:
  master_key: sk-test-key-1234  # Matches MASTER_KEY in test scripts

litellm_settings:
  enable_preview_features: true  # Required for thought signatures
```

## Directory Structure

```
testing/
├── README.md                    # This file
├── config.yaml                  # Shared LiteLLM proxy configuration
├── .env                         # API keys (gitignored)
├── test_regression.py           # Core regression test suite
├── test_gemini_signature.py     # Thought signature integration test
├── results/                     # Test result reports
│   ├── integration-test.md
│   ├── v1.79.0-code-check.md
│   └── v1.80.11-code-check.md
├── litellm-v1.79.0/            # v1.79.0 source for comparison
├── litellm-v1.80.11/           # v1.80.11 source for comparison
└── litellm-v1.81.12/           # v1.81.12 source for comparison
```

## Testing Workflows

### Pre-Upgrade Baseline

```bash
# 1. Start current version (e.g., v1.79.0)
cd litellm-v1.79.0 && source .venv/bin/activate
litellm --config ../config.yaml --port 4000

# 2. Run regression tests
uv run python test_regression.py > results/baseline-v1.79.0.txt

# 3. Stop proxy, switch to new version
# 4. Run same tests, compare results
```

### Feature-Specific Testing

```bash
# Test tool calling specifically
uv run python test_regression.py --model gemini-2.5-flash 2>&1 | grep -A2 "Tool\|Multi-turn"

# Test only thought signature fix
uv run python test_gemini_signature.py --model gemini-2.5-flash
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `ERROR: Cannot reach proxy` | Start LiteLLM proxy first on correct port |
| Model not in list | Check `VERTEX_API_KEY` and config.yaml |
| Tool calling fails | Verify model supports function calling |
| thought_signature errors | Ensure `enable_preview_features: true` in config |
| Auth errors | Verify `MASTER_KEY` matches between config and tests |

## References

- [Database Migration Guide](../docs/research/db-schema-migration-v1.79-to-v1.81.md)
- [Upgrade Plan](../reports/upgrade-plan-2026-02.md)
- [Python Setup with UV](../docs/python-setup.md)
