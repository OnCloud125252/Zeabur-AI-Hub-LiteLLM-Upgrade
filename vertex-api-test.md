# Vertex API Test

```sh
VERTEX_API_KEY=<API_KEY_HERE> && curl "https://aiplatform.googleapis.com/v1/publishers/google/models/gemini-3-pro-preview:streamGenerateContent?key=$VERTEX_API_KEY" \
-X POST \
-H "Content-Type: application/json" \
-d '{
  "contents": [
    {
      "role": "user",
      "parts": [
        {
          "text": "How many \"r\"s are in the word strawberry? Think step-by-step."
        }
      ]
    }
  ],
  "generationConfig": {
    "thinkingConfig": {
      "thinkingLevel": "HIGH"
    }
  }
}' | jq -r '[.[].candidates[].content.parts[].text] | join("")'
```
