"""
Regression test baseline for LiteLLM proxy.

Tests core proxy features to establish expected behavior before upgrade.
Designed to run against both v1.79.0 and v1.80.11+ for comparison.

Usage:
  1. Start LiteLLM proxy on port 4000
  2. python test_regression.py [--port PORT] [--model MODEL]
"""
import argparse
import json
import sys
import time
import traceback
from typing import Optional

import httpx
import openai


# ─── Test infrastructure ─────────────────────────────────────────────────────

MASTER_KEY = "sk-test-key-1234"
RESULTS: list[dict] = []


def record(name: str, passed: bool, detail: str = ""):
    status = "PASS" if passed else "FAIL"
    RESULTS.append({"name": name, "passed": passed, "detail": detail})
    icon = "  " if passed else "  "
    print(f"  {icon} {name}")
    if detail and not passed:
        for line in detail.strip().split("\n"):
            print(f"      {line}")


def section(title: str):
    print(f"\n{'=' * 60}")
    print(f"  {title}")
    print(f"{'=' * 60}")


# ─── Test cases ──────────────────────────────────────────────────────────────

def test_health(base_url: str):
    """Test /health endpoint returns healthy status."""
    section("Health & Monitoring")
    try:
        r = httpx.get(
            f"{base_url}/health",
            headers={"Authorization": f"Bearer {MASTER_KEY}"},
            timeout=15,
        )
        data = r.json()
        healthy = data.get("healthy_count", 0)
        record(
            "GET /health returns 200",
            r.status_code == 200,
            f"status={r.status_code}",
        )
        record(
            "Health check reports healthy models",
            healthy > 0,
            f"healthy={healthy}, unhealthy={data.get('unhealthy_count', 0)}",
        )
    except Exception as e:
        record("GET /health", False, str(e))


def test_liveness(base_url: str):
    """Test /health/liveliness probe."""
    try:
        r = httpx.get(f"{base_url}/health/liveliness", timeout=10)
        record(
            "GET /health/liveliness returns 200",
            r.status_code == 200,
            f"status={r.status_code}, body={r.text[:100]}",
        )
    except Exception as e:
        record("GET /health/liveliness", False, str(e))


def test_readiness(base_url: str):
    """Test /health/readiness probe."""
    try:
        r = httpx.get(
            f"{base_url}/health/readiness",
            headers={"Authorization": f"Bearer {MASTER_KEY}"},
            timeout=10,
        )
        record(
            "GET /health/readiness returns 200",
            r.status_code == 200,
            f"status={r.status_code}, body={r.text[:100]}",
        )
    except Exception as e:
        record("GET /health/readiness", False, str(e))


def test_model_listing(client: openai.OpenAI):
    """Test model listing via OpenAI SDK."""
    section("Model Listing")
    try:
        models = client.models.list()
        model_ids = [m.id for m in models.data]
        record(
            "GET /v1/models returns model list",
            len(model_ids) > 0,
            f"models={model_ids}",
        )
        # Check that our configured models appear
        for expected in ["gemini-2.5-flash", "gemini-2.5-pro", "gemini-3-pro"]:
            record(
                f"Model '{expected}' in list",
                expected in model_ids,
                f"found={expected in model_ids}",
            )
    except Exception as e:
        record("GET /v1/models", False, str(e))


def test_chat_completion(client: openai.OpenAI, model: str):
    """Test basic non-streaming chat completion."""
    section("Chat Completions")
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Reply with exactly: HELLO"}],
            max_tokens=50,
        )
        content = response.choices[0].message.content or ""
        record(
            f"POST /v1/chat/completions ({model})",
            len(content) > 0,
            f"content={content[:100]}",
        )
        record(
            "Response has usage info",
            response.usage is not None and response.usage.total_tokens > 0,
            f"usage={response.usage}",
        )
        record(
            "Response has model field",
            response.model is not None and len(response.model) > 0,
            f"model={response.model}",
        )
        record(
            "Finish reason is 'stop'",
            response.choices[0].finish_reason == "stop",
            f"finish_reason={response.choices[0].finish_reason}",
        )
    except Exception as e:
        record(f"Chat completion ({model})", False, str(e))


def test_streaming(client: openai.OpenAI, model: str):
    """Test streaming chat completion."""
    section("Streaming")
    try:
        stream = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Count from 1 to 5."}],
            max_tokens=100,
            stream=True,
        )
        chunks = []
        for chunk in stream:
            chunks.append(chunk)

        record(
            f"Streaming returns multiple chunks ({model})",
            len(chunks) > 1,
            f"chunk_count={len(chunks)}",
        )
        # Check first chunk has role
        first_delta = chunks[0].choices[0].delta if chunks else None
        record(
            "First chunk has role='assistant'",
            first_delta is not None and first_delta.role == "assistant",
            f"first_delta_role={getattr(first_delta, 'role', None)}",
        )
        # Check last chunk has finish_reason
        last_choice = chunks[-1].choices[0] if chunks else None
        record(
            "Last chunk has finish_reason='stop'",
            last_choice is not None and last_choice.finish_reason == "stop",
            f"last_finish_reason={getattr(last_choice, 'finish_reason', None)}",
        )
        # Reconstruct content
        full_content = ""
        for c in chunks:
            if c.choices and c.choices[0].delta and c.choices[0].delta.content:
                full_content += c.choices[0].delta.content
        record(
            "Streamed content is non-empty",
            len(full_content) > 0,
            f"content_length={len(full_content)}",
        )
    except Exception as e:
        record(f"Streaming ({model})", False, str(e))


def test_tool_calling(client: openai.OpenAI, model: str):
    """Test function/tool calling."""
    section("Tool Calling")
    tools = [
        {
            "type": "function",
            "function": {
                "name": "get_weather",
                "description": "Get weather for a city",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "location": {"type": "string", "description": "City name"}
                    },
                    "required": ["location"],
                },
            },
        }
    ]
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "user", "content": "What's the weather in Paris? Use the tool."}
            ],
            tools=tools,
            tool_choice="required",
        )
        choice = response.choices[0]
        has_tool_calls = choice.message.tool_calls is not None and len(choice.message.tool_calls) > 0
        record(
            f"Tool calling returns tool_calls ({model})",
            has_tool_calls,
            f"finish_reason={choice.finish_reason}",
        )
        if has_tool_calls:
            tc = choice.message.tool_calls[0]
            record(
                "Tool call has function name",
                tc.function.name == "get_weather",
                f"function={tc.function.name}",
            )
            args = json.loads(tc.function.arguments)
            record(
                "Tool call has valid arguments",
                "location" in args,
                f"args={args}",
            )
            record(
                "Tool call has ID",
                tc.id is not None and len(tc.id) > 0,
                f"id={tc.id}",
            )
    except Exception as e:
        record(f"Tool calling ({model})", False, str(e))


def test_multi_turn_tool(client: openai.OpenAI, model: str):
    """Test multi-turn conversation with tool result."""
    section("Multi-turn Tool Conversation")
    tools = [
        {
            "type": "function",
            "function": {
                "name": "calculate",
                "description": "Calculate a math expression",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "expression": {"type": "string", "description": "Math expression"}
                    },
                    "required": ["expression"],
                },
            },
        }
    ]
    try:
        # Turn 1: Get tool call
        r1 = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "What is 42 * 17? Use the calculate tool."}],
            tools=tools,
            tool_choice="required",
        )
        choice1 = r1.choices[0]
        if not choice1.message.tool_calls:
            record("Multi-turn: get tool call", False, "No tool calls returned")
            return

        tc = choice1.message.tool_calls[0]
        record("Multi-turn: initial tool call received", True, f"id={tc.id}")

        # Turn 2: Send tool result
        messages = [
            {"role": "user", "content": "What is 42 * 17? Use the calculate tool."},
            choice1.message,
            {
                "role": "tool",
                "tool_call_id": tc.id,
                "content": json.dumps({"result": 714}),
            },
        ]
        r2 = client.chat.completions.create(
            model=model,
            messages=messages,
            tools=tools,
        )
        content = r2.choices[0].message.content or ""
        record(
            "Multi-turn: final response after tool result",
            len(content) > 0 and "714" in content,
            f"content={content[:150]}",
        )
    except openai.BadRequestError as e:
        record("Multi-turn tool conversation", False, f"BadRequestError: {e}")
    except Exception as e:
        record("Multi-turn tool conversation", False, str(e))


def test_error_handling(client: openai.OpenAI):
    """Test error handling for invalid requests."""
    section("Error Handling")
    # Invalid model
    try:
        client.chat.completions.create(
            model="nonexistent-model-xyz",
            messages=[{"role": "user", "content": "test"}],
        )
        record("Invalid model returns error", False, "No exception raised")
    except openai.NotFoundError:
        record("Invalid model returns NotFoundError", True)
    except openai.BadRequestError:
        record("Invalid model returns BadRequestError", True)
    except openai.APIStatusError as e:
        record(
            "Invalid model returns error",
            e.status_code in (400, 404),
            f"status={e.status_code}",
        )
    except Exception as e:
        record("Invalid model returns error", False, f"Unexpected: {type(e).__name__}: {e}")

    # Missing auth — LiteLLM may return 400 or 401 depending on version
    try:
        no_auth = openai.OpenAI(api_key="invalid-key", base_url=client.base_url)
        no_auth.chat.completions.create(
            model="gemini-2.5-flash",
            messages=[{"role": "user", "content": "test"}],
        )
        record("Invalid key returns error", False, "No exception raised")
    except openai.AuthenticationError:
        record("Invalid key returns error (401 AuthenticationError)", True)
    except openai.BadRequestError:
        record("Invalid key returns error (400 BadRequestError)", True, "v1.79.0 returns 400 for invalid keys")
    except openai.APIStatusError as e:
        record(
            "Invalid key returns error",
            e.status_code in (400, 401, 403),
            f"status={e.status_code}",
        )
    except Exception as e:
        record("Invalid key returns error", False, f"Unexpected: {type(e).__name__}: {e}")


def test_token_counter(base_url: str):
    """Test token counting utility."""
    section("Utilities")
    try:
        r = httpx.post(
            f"{base_url}/utils/token_counter",
            json={
                "model": "gemini-2.5-flash",
                "messages": [{"role": "user", "content": "Hello, world!"}],
            },
            headers={"Authorization": f"Bearer {MASTER_KEY}"},
            timeout=15,
        )
        record(
            "POST /utils/token_counter returns 200",
            r.status_code == 200,
            f"status={r.status_code}, body={r.text[:200]}",
        )
    except Exception as e:
        record("Token counter", False, str(e))


def test_model_info(base_url: str):
    """Test model info retrieval."""
    try:
        r = httpx.get(
            f"{base_url}/v1/model/info",
            headers={"Authorization": f"Bearer {MASTER_KEY}"},
            timeout=15,
        )
        record(
            "GET /v1/model/info returns 200",
            r.status_code == 200,
            f"status={r.status_code}",
        )
        if r.status_code == 200:
            data = r.json().get("data", [])
            record(
                "Model info contains configured models",
                len(data) > 0,
                f"model_count={len(data)}",
            )
    except Exception as e:
        record("Model info", False, str(e))


def test_routes(base_url: str):
    """Test route listing."""
    try:
        r = httpx.get(
            f"{base_url}/routes",
            headers={"Authorization": f"Bearer {MASTER_KEY}"},
            timeout=15,
        )
        record(
            "GET /routes returns 200",
            r.status_code == 200,
            f"status={r.status_code}, route_count={len(r.json()) if r.status_code == 200 else 'N/A'}",
        )
    except Exception as e:
        record("Routes listing", False, str(e))


# ─── Main ────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="LiteLLM regression test baseline")
    parser.add_argument("--host", type=str, default="localhost", help="Proxy host")
    parser.add_argument("--port", type=int, default=4000, help="Proxy port")
    parser.add_argument("--model", type=str, default="gemini-2.5-flash", help="Model to test")
    args = parser.parse_args()

    base_url = f"http://{args.host}:{args.port}"
    client = openai.OpenAI(api_key=MASTER_KEY, base_url=base_url)

    print("=" * 60)
    print("  LiteLLM Regression Test Baseline")
    print(f"  Proxy: {base_url}")
    print(f"  Model: {args.model}")
    print("=" * 60)

    # Check proxy is up
    try:
        httpx.get(f"{base_url}/health/liveliness", timeout=5)
    except Exception:
        print(f"\nERROR: Cannot reach proxy at {base_url}")
        print("Make sure LiteLLM proxy is running.")
        sys.exit(1)

    # Run all tests
    test_health(base_url)
    test_liveness(base_url)
    test_readiness(base_url)
    test_model_listing(client)
    test_chat_completion(client, args.model)
    test_streaming(client, args.model)
    test_tool_calling(client, args.model)
    test_multi_turn_tool(client, args.model)
    test_error_handling(client)
    test_token_counter(base_url)
    test_model_info(base_url)
    test_routes(base_url)

    # Summary
    passed = sum(1 for r in RESULTS if r["passed"])
    failed = sum(1 for r in RESULTS if not r["passed"])
    total = len(RESULTS)

    section("RESULTS SUMMARY")
    print(f"  Passed: {passed}/{total}")
    print(f"  Failed: {failed}/{total}")

    if failed > 0:
        print("\n  Failed tests:")
        for r in RESULTS:
            if not r["passed"]:
                print(f"    - {r['name']}: {r['detail']}")

    print(f"\n  Overall: {'ALL TESTS PASSED' if failed == 0 else 'SOME TESTS FAILED'}")
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
