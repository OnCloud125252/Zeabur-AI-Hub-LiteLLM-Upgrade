"""
Performance benchmark for LiteLLM proxy.

Measures latency for chat completions, streaming, and tool calls
across multiple iterations to compare versions.

Usage:
  python test_performance.py [--host HOST] [--port PORT] [--rounds N]
"""
import argparse
import json
import statistics
import sys
import time
from typing import Optional

import httpx
import openai

MASTER_KEY = "sk-test-key-1234"

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get weather for a city",
            "parameters": {
                "type": "object",
                "properties": {
                    "location": {"type": "string", "description": "City name"},
                },
                "required": ["location"],
            },
        },
    }
]


def measure(fn, label: str) -> Optional[float]:
    """Run fn, return elapsed seconds or None on error."""
    try:
        start = time.perf_counter()
        fn()
        elapsed = time.perf_counter() - start
        return elapsed
    except Exception as e:
        print(f"    ERROR ({label}): {e}")
        return None


def bench_chat(client: openai.OpenAI, model: str) -> Optional[float]:
    """Measure non-streaming chat completion latency."""
    def run():
        client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Reply with exactly: OK"}],
            max_tokens=10,
        )
    return measure(run, "chat")


def bench_streaming(client: openai.OpenAI, model: str) -> Optional[float]:
    """Measure streaming chat completion latency (full stream)."""
    def run():
        stream = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Count 1 to 3."}],
            max_tokens=30,
            stream=True,
        )
        for _ in stream:
            pass
    return measure(run, "streaming")


def bench_ttfb(client: openai.OpenAI, model: str) -> Optional[float]:
    """Measure time to first byte (first streamed chunk)."""
    try:
        start = time.perf_counter()
        stream = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Say hello."}],
            max_tokens=10,
            stream=True,
        )
        for _ in stream:
            elapsed = time.perf_counter() - start
            # Drain the rest
            for _ in stream:
                pass
            return elapsed
        return None
    except Exception as e:
        print(f"    ERROR (ttfb): {e}")
        return None


def bench_tool_call(client: openai.OpenAI, model: str) -> Optional[float]:
    """Measure tool call response latency."""
    def run():
        client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Weather in Tokyo? Use tool."}],
            tools=TOOLS,
            tool_choice="required",
            max_tokens=100,
        )
    return measure(run, "tool_call")


def bench_multi_turn(client: openai.OpenAI, model: str) -> Optional[float]:
    """Measure full multi-turn tool call round-trip (2 API calls)."""
    try:
        start = time.perf_counter()
        # Turn 1: get tool call
        r1 = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": "Weather in Tokyo? Use tool."}],
            tools=TOOLS,
            tool_choice="required",
        )
        if not r1.choices[0].message.tool_calls:
            return None
        tc = r1.choices[0].message.tool_calls[0]
        # Turn 2: send result
        client.chat.completions.create(
            model=model,
            messages=[
                {"role": "user", "content": "Weather in Tokyo? Use tool."},
                r1.choices[0].message,
                {"role": "tool", "tool_call_id": tc.id, "content": '{"temp": 22}'},
            ],
            tools=TOOLS,
        )
        return time.perf_counter() - start
    except Exception as e:
        print(f"    ERROR (multi_turn): {e}")
        return None


def summarize(values: list[float]) -> dict:
    """Compute stats from a list of latency measurements."""
    clean = [v for v in values if v is not None]
    if not clean:
        return {"samples": 0, "errors": len(values)}
    return {
        "samples": len(clean),
        "errors": len(values) - len(clean),
        "min": round(min(clean), 3),
        "max": round(max(clean), 3),
        "mean": round(statistics.mean(clean), 3),
        "median": round(statistics.median(clean), 3),
        "stdev": round(statistics.stdev(clean), 3) if len(clean) > 1 else 0,
        "p95": round(sorted(clean)[int(len(clean) * 0.95)], 3) if len(clean) >= 2 else round(clean[0], 3),
    }


def main():
    parser = argparse.ArgumentParser(description="LiteLLM performance benchmark")
    parser.add_argument("--host", default="localhost", help="Proxy host")
    parser.add_argument("--port", type=int, default=4000, help="Proxy port")
    parser.add_argument("--model", default="gemini-2.5-flash", help="Model to test")
    parser.add_argument("--rounds", type=int, default=5, help="Iterations per benchmark")
    parser.add_argument("--output", help="JSON output file path")
    args = parser.parse_args()

    base_url = f"http://{args.host}:{args.port}"
    client = openai.OpenAI(api_key=MASTER_KEY, base_url=base_url)

    print("=" * 60)
    print("  LiteLLM Performance Benchmark")
    print(f"  Proxy: {base_url}")
    print(f"  Model: {args.model}")
    print(f"  Rounds: {args.rounds}")
    print("=" * 60)

    # Verify proxy is up
    try:
        httpx.get(f"{base_url}/health/liveliness", timeout=5)
    except Exception:
        print(f"\nERROR: Cannot reach proxy at {base_url}")
        sys.exit(1)

    # Warm up (1 request to prime model loading)
    print("\n  Warming up...")
    bench_chat(client, args.model)

    benchmarks = {
        "chat_completion": bench_chat,
        "streaming_full": bench_streaming,
        "time_to_first_byte": bench_ttfb,
        "tool_call": bench_tool_call,
        "multi_turn_tool": bench_multi_turn,
    }

    results = {}
    for name, fn in benchmarks.items():
        print(f"\n  Benchmarking: {name} ({args.rounds} rounds)")
        values = []
        for i in range(args.rounds):
            val = fn(client, args.model)
            marker = f"{val:.3f}s" if val is not None else "ERROR"
            print(f"    Round {i + 1}/{args.rounds}: {marker}")
            values.append(val)
        results[name] = summarize(values)

    # Summary
    print("\n" + "=" * 60)
    print("  RESULTS")
    print("=" * 60)
    print(f"  {'Benchmark':<22} {'Mean':>8} {'Median':>8} {'P95':>8} {'Min':>8} {'Max':>8}")
    print(f"  {'-' * 22} {'-' * 8} {'-' * 8} {'-' * 8} {'-' * 8} {'-' * 8}")
    for name, stats in results.items():
        if stats["samples"] == 0:
            print(f"  {name:<22} {'N/A':>8}")
            continue
        print(
            f"  {name:<22} {stats['mean']:>7.3f}s {stats['median']:>7.3f}s "
            f"{stats['p95']:>7.3f}s {stats['min']:>7.3f}s {stats['max']:>7.3f}s"
        )

    # Output JSON
    output_data = {
        "host": args.host,
        "port": args.port,
        "model": args.model,
        "rounds": args.rounds,
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "benchmarks": results,
    }

    if args.output:
        with open(args.output, "w") as f:
            json.dump(output_data, f, indent=2)
        print(f"\n  Results saved to: {args.output}")
    else:
        print(f"\n  (Use --output <path> to save JSON results)")


if __name__ == "__main__":
    main()
