# Test Outputs

> Machine-generated test results archive

← [Back to Documentation Home](../README.md)

---

## Test Results

This directory contains machine-generated test outputs from the LiteLLM upgrade verification process.

### Regression Tests

| File | Version | Description |
|------|---------|-------------|
| `baseline-v1.79.0.txt` | v1.79.0 | Baseline regression results (28/28 passed) |
| `regression-v1.81.12.txt` | v1.81.12 | Post-upgrade regression (28/28 passed) |
| `rollback-v1.79.0.txt` | v1.79.0 | Rollback verification (28/28 passed) |

### Gemini Signature Tests

| File | Version | Description |
|------|---------|-------------|
| `signature-v1.79.0.txt` | v1.79.0 | Baseline (bug present) |
| `signature-v1.81.12.txt` | v1.81.12 | Fix verified (thought_signature working) |

### Performance Benchmarks

| File | Version | Description |
|------|---------|-------------|
| `perf-v1.79.0.json` | v1.79.0 | Performance baseline |
| `perf-v1.81.12.json` | v1.81.12 | Post-upgrade performance |

---

## Test Coverage

### Regression Tests (28 tests)

| Category | Tests |
|----------|-------|
| Health & Monitoring | `/health`, `/health/liveliness`, `/health/readiness` |
| Model Lists | `GET /v1/models`, `GET /v1/model/info` |
| Chat Completions | Non-streaming, streaming, usage stats |
| Tool Calling | Single tool, multi-turn conversations |
| Error Handling | Invalid model, invalid auth |
| Utility Functions | Token counting, route listing |

### Gemini Signature Tests

Verifies the `thought_signature` fix for multi-turn tool conversations:
1. Initial request with tool definitions
2. Verify tool call ID contains `__thought__` signature (when applicable)
3. Send tool result with same ID
4. Verify final response completes without errors

### Performance Benchmarks

5 benchmarks × 10 rounds each:
- Simple chat completion (non-streaming)
- Simple chat completion (streaming)
- Tool calling
- Multi-turn conversation
- Token counting

---

## How to Generate

### Regression Tests

```bash
cd testing/local
uv run python test_regression.py --model gemini-2.5-flash > ../../test-outputs/baseline-v1.79.0.txt
```

### Signature Tests

```bash
cd testing/local
uv run python test_gemini_signature.py --model gemini-2.5-flash > ../../test-outputs/signature-v1.81.12.txt
```

### Performance Tests

```bash
cd testing/local
uv run python test_performance.py --model gemini-2.5-flash
# Results saved to results/ directory, copy to test-outputs/
```

---

## Verification Summary

| Metric | Result |
|--------|--------|
| Regression Tests | 28/28 × 3 versions passed |
| thought_signature Fix | ✅ Verified in v1.81.12 |
| Performance Impact | Within ±5% (no regression) |

See [reports/4g-test-report.md](../reports/4g-test-report.md) for complete analysis.

---

*See [SUMMARY.md](../SUMMARY.md) for complete documentation navigation.*
