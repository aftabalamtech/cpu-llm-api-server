# API

The service exposes the OpenAI-compatible HTTP API provided by upstream `llama-server`.

## Health

`GET /health`

Returns a successful response when the model is ready. It is intentionally unauthenticated so Railway, Render and Docker health checks can reach it.

## Models

`GET /v1/models`

Returns the loaded model. If `MODEL_ALIAS` is set, use that value as the API model name.

## Chat completions

`POST /v1/chat/completions`

Example:

```bash
curl -N http://localhost:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_API_KEY' \
  -d '{
    "model": "YOUR_MODEL_ALIAS",
    "messages": [{"role":"user","content":"Hello"}],
    "stream": true,
    "max_tokens": 64
  }'
```

Streaming uses server-sent events as implemented by upstream `llama-server`.

## Authentication

When `API_KEY` is non-empty, send:

```text
Authorization: Bearer YOUR_API_KEY
```

The `/health` endpoint remains public for deployment health checks.
