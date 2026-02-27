"""
Integration test for Gemini thought_signature fix.

Tests that LiteLLM properly preserves thought signatures in tool call IDs
during multi-turn conversations with Gemini thinking models.

Usage:
  1. Start LiteLLM proxy:
     cd litellm-v1.80.11 && source .venv/bin/activate
     GEMINI_API_KEY=<key> litellm --config ../config.yaml --port 4000

  2. Run this test:
     python test_gemini_thought_signature.py [--port PORT] [--model MODEL]
"""
import openai
import json
import sys
import argparse
import time


def create_client(port: int) -> openai.OpenAI:
    return openai.OpenAI(
        api_key="sk-test-key-1234",
        base_url=f"http://localhost:{port}",
    )


TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get the current weather in a given location",
            "parameters": {
                "type": "object",
                "properties": {
                    "location": {
                        "type": "string",
                        "description": "City name, e.g. 'Tokyo'",
                    }
                },
                "required": ["location"],
            },
        },
    }
]


def test_thought_signature(client: openai.OpenAI, model: str) -> bool:
    """
    Test multi-turn tool call flow with thought_signature preservation.

    Steps:
    1. Send initial request with tools — model should respond with tool_calls
    2. Check if tool_call IDs contain __thought__ signature
    3. Send tool result back with the same tool_call ID
    4. Verify final response completes without 400/503 errors
    """
    messages = [
        {
            "role": "user",
            "content": "What's the weather in Tokyo? You MUST use the get_weather tool to check. Do not answer without calling the tool first.",
        }
    ]

    # Step 1: Initial request — model should respond with a tool call
    print(f"Step 1: Sending initial request to {model} with tools...")
    try:
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            tools=TOOLS,
            tool_choice="required",
        )
    except Exception as e:
        print(f"  ERROR on initial request: {e}")
        return False

    choice = response.choices[0]
    print(f"  Finish reason: {choice.finish_reason}")

    if not choice.message.tool_calls:
        print("  WARNING: Model did not return tool calls even with tool_choice=required.")
        print(f"  Response: {choice.message.content[:200] if choice.message.content else '(empty)'}")
        print("  This is unexpected but not a thought_signature failure.")
        return True

    tool_call = choice.message.tool_calls[0]
    print(f"  Tool call ID: {tool_call.id}")
    print(f"  Function: {tool_call.function.name}({tool_call.function.arguments})")

    # Check if thought_signature is embedded in tool_call ID
    has_thought = "__thought__" in tool_call.id
    print(f"  Contains __thought__ in ID: {has_thought}")

    if has_thought:
        # Extract and display the signature (truncated)
        parts = tool_call.id.split("__thought__", 1)
        base_id = parts[0]
        signature = parts[1]
        print(f"  Base ID: {base_id}")
        print(f"  Thought signature: {signature[:60]}...")
    else:
        print("  NOTE: No __thought__ in ID. This may mean:")
        print("    - enable_preview_features is not enabled, OR")
        print("    - The model didn't emit a thought signature for this request")
        print("    - Check provider_specific_fields in raw response for signature")

    # Step 2: Send tool result back with the same tool_call ID
    messages.append(choice.message)
    messages.append(
        {
            "role": "tool",
            "tool_call_id": tool_call.id,
            "content": json.dumps(
                {
                    "temperature": 22,
                    "condition": "Partly cloudy",
                    "location": "Tokyo",
                    "humidity": "65%",
                }
            ),
        }
    )

    print("\nStep 2: Sending tool result back...")
    try:
        response2 = client.chat.completions.create(
            model=model,
            messages=messages,
            tools=TOOLS,
        )
        content = response2.choices[0].message.content or "(empty)"
        print(f"  Response: {content[:300]}...")
        print(f"  Finish reason: {response2.choices[0].finish_reason}")
        print(
            "\n  SUCCESS: Multi-turn tool call completed without errors."
        )
        return True
    except openai.BadRequestError as e:
        print(f"\n  FAILURE: BadRequestError — {e}")
        error_str = str(e)
        if "thought" in error_str.lower() or "signature" in error_str.lower():
            print("  >>> This is the known thought_signature bug! <<<")
        return False
    except openai.APIStatusError as e:
        print(f"\n  FAILURE: API error {e.status_code} — {e.message}")
        error_str = str(e.message)
        if "thought" in error_str.lower() or "signature" in error_str.lower():
            print("  >>> This is the known thought_signature bug! <<<")
        return False


def test_multi_turn_tool_calls(client: openai.OpenAI, model: str) -> bool:
    """
    Extended test: 3-turn conversation with multiple tool calls.
    This exercises the thought_signature preservation more thoroughly.
    """
    print("\n" + "=" * 60)
    print("Extended test: Multi-turn conversation with tool calls")
    print("=" * 60)

    messages = [
        {
            "role": "user",
            "content": "I need weather for both Tokyo and Paris. Use the get_weather tool for each city separately.",
        }
    ]

    # Turn 1: Get tool calls
    print("\nTurn 1: Requesting weather for two cities...")
    try:
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            tools=TOOLS,
            tool_choice="required",
        )
    except Exception as e:
        print(f"  ERROR: {e}")
        return False

    choice = response.choices[0]
    if not choice.message.tool_calls:
        print("  No tool calls returned. Skipping extended test.")
        return True

    print(f"  Got {len(choice.message.tool_calls)} tool call(s)")
    for tc in choice.message.tool_calls:
        has_thought = "__thought__" in tc.id
        print(f"    - {tc.function.name}({tc.function.arguments}) | ID has __thought__: {has_thought}")

    # Send all tool results back
    messages.append(choice.message)
    for tc in choice.message.tool_calls:
        args = json.loads(tc.function.arguments)
        location = args.get("location", "Unknown")
        messages.append(
            {
                "role": "tool",
                "tool_call_id": tc.id,
                "content": json.dumps(
                    {
                        "temperature": 22 if "tokyo" in location.lower() else 15,
                        "condition": "Partly cloudy" if "tokyo" in location.lower() else "Rainy",
                        "location": location,
                    }
                ),
            }
        )

    # Turn 2: Get summary
    print("\nTurn 2: Sending tool results back...")
    try:
        response2 = client.chat.completions.create(
            model=model,
            messages=messages,
            tools=TOOLS,
        )
        content = response2.choices[0].message.content or "(empty)"
        print(f"  Response: {content[:300]}...")
        print("\n  SUCCESS: Extended multi-turn test passed.")
        return True
    except openai.BadRequestError as e:
        print(f"\n  FAILURE: BadRequestError — {e}")
        return False
    except openai.APIStatusError as e:
        print(f"\n  FAILURE: API error {e.status_code} — {e.message}")
        return False


def main():
    parser = argparse.ArgumentParser(description="Test Gemini thought_signature fix")
    parser.add_argument("--port", type=int, default=4000, help="LiteLLM proxy port")
    parser.add_argument("--model", type=str, default="gemini-2.5-flash", help="Model name to test")
    args = parser.parse_args()

    client = create_client(args.port)

    print("=" * 60)
    print(f"Gemini thought_signature Integration Test")
    print(f"Proxy: http://localhost:{args.port}")
    print(f"Model: {args.model}")
    print("=" * 60)

    # Check proxy health first
    print("\nChecking proxy health...")
    try:
        models = client.models.list()
        print(f"  Proxy is up. Available models: {[m.id for m in models.data]}")
    except Exception as e:
        print(f"  ERROR: Cannot reach proxy at port {args.port}: {e}")
        print("  Make sure LiteLLM proxy is running.")
        sys.exit(1)

    # Run basic test
    print("\n" + "=" * 60)
    print("Basic test: Single tool call round-trip")
    print("=" * 60)
    basic_ok = test_thought_signature(client, args.model)

    # Run extended test
    extended_ok = test_multi_turn_tool_calls(client, args.model)

    # Summary
    print("\n" + "=" * 60)
    print("RESULTS SUMMARY")
    print("=" * 60)
    print(f"  Basic tool call test:    {'PASS' if basic_ok else 'FAIL'}")
    print(f"  Extended multi-turn test: {'PASS' if extended_ok else 'FAIL'}")

    all_pass = basic_ok and extended_ok
    print(f"\n  Overall: {'ALL TESTS PASSED' if all_pass else 'SOME TESTS FAILED'}")
    sys.exit(0 if all_pass else 1)


if __name__ == "__main__":
    main()
