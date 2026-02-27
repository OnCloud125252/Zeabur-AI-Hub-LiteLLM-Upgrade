# Testing

> Testing documentation and environments for LiteLLM upgrade

← [Back to Documentation Home](../README.md)

---

## Testing Environments

| Environment | Purpose | Documentation |
|-------------|---------|---------------|
| [Local](local/) | Local development and testing | [local/README.md](local/README.md) |
| [Remote](remote/) | Remote Docker deployment testing | [remote/README.md](remote/README.md) |

---

## Test Types

### Regression Tests (`test_regression.py`)

- **Location**: `local/test_regression.py`
- **Purpose**: Verify core proxy functionality across versions
- **Coverage**: 28 tests covering health checks, model lists, chat completions, tool calling
- **Usage**: `uv run python test_regression.py --model gemini-2.5-flash`

### Gemini Signature Test (`test_gemini_signature.py`)

- **Location**: `local/test_gemini_signature.py`
- **Purpose**: Verify thought_signature fix in multi-turn tool conversations
- **Usage**: `uv run python test_gemini_signature.py --model gemini-2.5-flash`

### Performance Test (`test_performance.py`)

- **Location**: `local/test_performance.py`
- **Purpose**: Benchmark latency and throughput
- **Usage**: `uv run python test_performance.py --model gemini-2.5-flash`

---

## Test Results

Machine-generated test outputs are stored in [`../test-outputs/`](../test-outputs/):

| File | Description |
|------|-------------|
| `baseline-v1.79.0.txt` | v1.79.0 baseline regression results |
| `regression-v1.81.12.txt` | v1.81.12 post-upgrade regression |
| `rollback-v1.79.0.txt` | Rollback verification results |
| `signature-v1.79.0.txt` | v1.79.0 signature test (baseline) |
| `signature-v1.81.12.txt` | v1.81.12 signature test (verification) |
| `perf-v1.79.0.json` | v1.79.0 performance metrics |
| `perf-v1.81.12.json` | v1.81.12 performance metrics |

---

## Quick Start

### Local Testing

```bash
cd testing/local

# Setup
cp .env.example .env  # Add your VERTEX_API_KEY

# Start proxy
cd litellm-v1.79.0 && source .venv/bin/activate
GEMINI_API_KEY=$VERTEX_API_KEY litellm --config ../config.yaml --port 4000

# Run tests (in another terminal)
uv run python test_regression.py
```

### Remote Testing

```bash
cd testing/remote

# Deploy
docker compose -f docker-compose.v1.81.12.yml up -d

# Verify
docker compose ps
```

See [remote/README.md](remote/README.md) for complete instructions.

---

*See [SUMMARY.md](../SUMMARY.md) for complete documentation navigation.*
