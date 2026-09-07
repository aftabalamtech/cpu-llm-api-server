# CPU-only GGUF LLM API Server

A lightweight cross-platform API server for running any user-selected **GGUF** model with the upstream `llama-server` executable from [llama.cpp](https://github.com/ggml-org/llama.cpp).

## Important: no default model

This repository intentionally has **no default model**. Choose the model through environment variables.

## Recommended example models

### 1. SmolLM2 360M Instruct — lightweight

Good choice for low-RAM CPU deployments such as small Render instances.

```dotenv
MODEL_REPO=unsloth/SmolLM2-360M-Instruct-GGUF
MODEL_FILE=SmolLM2-360M-Instruct-Q4_K_M.gguf
MODEL_REVISION=main
MODEL_ALIAS=SmolLM2-360M-Instruct
```

Model repository: https://huggingface.co/unsloth/SmolLM2-360M-Instruct-GGUF

### 2. Qwen2.5 0.5B Instruct — alternative

A different, somewhat larger instruction model. Its Q4_K_M file is approximately 491 MB, so allow enough RAM for model runtime overhead and KV cache.

```dotenv
MODEL_REPO=Qwen/Qwen2.5-0.5B-Instruct-GGUF
MODEL_FILE=qwen2.5-0.5b-instruct-q4_k_m.gguf
MODEL_REVISION=main
MODEL_ALIAS=Qwen2.5-0.5B-Instruct
```

Model repository: https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF

> Only configure **one model at a time**. The server downloads only the exact `MODEL_REPO` + `MODEL_FILE` selected in the environment.

## Features

- CPU-first llama.cpp inference
- GGUF model support
- OpenAI-compatible API
- Streaming chat completions
- llama.cpp Web UI
- `/health`
- `/v1/models`
- `/v1/chat/completions`
- Environment-only model selection
- Hugging Face model download at startup
- Local/mounted model support
- Linux, macOS, Windows PowerShell and Docker
- Railway and Render deployment configuration
- Low-resource CPU defaults
- API-key authentication
- No GGUF model committed to Git

## Environment variables

| Variable | Required | Purpose |
|---|---|---|
| `MODEL_REPO` | Yes for download | Exact Hugging Face repository |
| `MODEL_FILE` | Yes for download | Exact GGUF filename |
| `MODEL_REVISION` | No | Hugging Face branch/tag/commit; default `main` |
| `MODEL_PATH` | Optional | Existing GGUF file path; used first if valid |
| `MODEL_DIR` | No | Model directory; default `/models` in Docker |
| `DOWNLOAD_MODEL` | No | Download when no existing model is available; default `true` |
| `MODEL_ALIAS` | No | API model name |
| `HF_TOKEN` | Optional | Token for private/gated Hugging Face repositories |
| `PORT` | No | Listening port; provider-supplied `PORT` is respected |
| `HOST` | No | Bind address; use `0.0.0.0` for hosted deployments |
| `API_KEY` | Optional | Protects API endpoints when set |
| `ENABLE_WEBUI` | No | `true` enables the llama.cpp Web UI; `false` disables it |
| `CPU_THREADS` | No | Generation CPU threads; default `2` |
| `CPU_THREADS_BATCH` | No | Prompt-processing threads; default `2` |
| `CONTEXT_SIZE` | No | Context window; default `2048` |
| `BATCH_SIZE` | No | Logical batch size; default `256` |
| `UBATCH_SIZE` | No | Physical micro-batch size; default `128` |
| `PARALLEL` | No | Concurrent sequences; default `1` |
| `CORS_ORIGINS` | Optional | Explicit CORS origins |
| `LLAMA_SERVER_BIN` | No | llama-server executable path |
| `LLAMA_SERVER_ARGS` | Optional | Additional llama-server arguments |
| `LOG_VERBOSITY` | No | llama-server log verbosity; default `3` |

## API

### Health

```bash
curl -fsS https://YOUR-SERVICE.onrender.com/health \
  -H "Authorization: Bearer $API_KEY"
```

### Models

```bash
curl https://YOUR-SERVICE.onrender.com/v1/models \
  -H "Authorization: Bearer $API_KEY"
```

### Chat completion

```bash
curl -N https://YOUR-SERVICE.onrender.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "YOUR_MODEL_ALIAS",
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": true,
    "max_tokens": 64
  }'
```

The API and Web UI are provided by upstream `llama-server`; this repository does not implement a custom inference engine.

## Resource usage

GGUF file size is not the same as total RAM usage. Runtime memory also includes model residency, KV cache, batch buffers, allocator overhead and operating-system cache.

Conservative defaults:

```text
CPU_THREADS=2
CPU_THREADS_BATCH=2
CONTEXT_SIZE=2048
BATCH_SIZE=256
UBATCH_SIZE=128
PARALLEL=1
```

For a small CPU machine, reduce `CONTEXT_SIZE`, `BATCH_SIZE`, `UBATCH_SIZE` and `PARALLEL` first if RAM is insufficient.

## Quick start

```bash
cp .env.example .env
# Set MODEL_REPO and MODEL_FILE to one supported model or another GGUF model.
chmod +x scripts/*.sh
set -a; . ./.env; set +a
./scripts/start.sh
```

For Docker:

```bash
docker compose up -d --build
```

The container downloads only the selected model if it is not already present.

## Render

The repository includes a Render Blueprint using Docker and `/health`. Render supplies `PORT`; the launcher passes it to llama-server.

Set `MODEL_REPO` and `MODEL_FILE` to exactly one model. For public API access, set a strong `API_KEY`. Keep `ENABLE_WEBUI=true` if you want the browser UI at `/`.

Do not assume Render Free can run an arbitrary GGUF model. Select a compute plan with enough RAM for the specific model and context configuration.

## Security

- Do not commit `.env` or `HF_TOKEN`.
- Set a strong `API_KEY` for public deployments.
- Do not expose the API without TLS on an untrusted network.
- Keep `CORS_ORIGINS` restricted when browser clients are used.
- GGUF files are intentionally excluded from Git.

## Testing

```bash
python3 -m unittest discover -s tests -v
bash tests/test_scripts.sh
```

## Upstream

- [llama.cpp](https://github.com/ggml-org/llama.cpp)
- [llama-server documentation](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md)
