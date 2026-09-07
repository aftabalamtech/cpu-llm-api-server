# CPU-only GGUF LLM API Server

A lightweight cross-platform API server for running any user-selected **GGUF** model with the upstream `llama-server` executable from [llama.cpp](https://github.com/ggml-org/llama.cpp).

## Important: no default model

This repository intentionally has **no default model**.

The server never assumes or downloads a bundled model. You must choose the model through environment variables:

```text
MODEL_REPO=owner/model-repository
MODEL_FILE=exact-model-file.gguf
MODEL_REVISION=main
```

Only the model specified by those variables is downloaded. Alternatively, set `MODEL_PATH` to an existing local/mounted GGUF file and set `DOWNLOAD_MODEL=false`.

If neither a usable `MODEL_PATH` nor both `MODEL_REPO` and `MODEL_FILE` are provided, startup fails instead of silently selecting a model.

## Recommended alternative model

If you want to test a model other than the previously used SmolLM2 model, **Qwen2.5-0.5B-Instruct** is a good lightweight alternative. The official GGUF repository provides multiple quantizations, including Q4_K_M. The Q4_K_M file is about 491 MB in the official repository. citeturn0search0

Official Hugging Face model page:

https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF

Render environment values:

```dotenv
MODEL_REPO=Qwen/Qwen2.5-0.5B-Instruct-GGUF
MODEL_FILE=qwen2.5-0.5b-instruct-q4_k_m.gguf
MODEL_REVISION=main
MODEL_PATH=
DOWNLOAD_MODEL=true
MODEL_ALIAS=Qwen2.5-0.5B-Instruct
```

Note: the exact filename should be confirmed from the repository's Files tab before deployment because Hugging Face filenames are case-sensitive. The official model page documents Q4_K_M and its size. citeturn0search0

## Features

- CPU-first llama.cpp inference
- GGUF model support
- OpenAI-compatible API
- Streaming chat completions
- `/health`
- `/v1/models`
- `/v1/chat/completions`
- Environment-only model selection
- Hugging Face model download at startup
- Local/mounted model support
- Linux, macOS, Windows PowerShell and Docker
- Railway and Render deployment configuration
- Low-resource CPU defaults
- Optional API-key authentication
- No GGUF model committed to Git

## Repository layout

```text
.
├── README.md
├── LICENSE
├── .env.example
├── .gitignore
├── .dockerignore
├── Dockerfile
├── docker-compose.yml
├── railway.toml
├── render.yaml
├── docs/
│   ├── api.md
│   ├── configuration.md
│   ├── deployment.md
│   └── troubleshooting.md
├── models/
│   └── .gitkeep
├── scripts/
│   ├── download-model.sh
│   ├── healthcheck.sh
│   ├── start.ps1
│   └── start.sh
└── tests/
    ├── test_config.py
    └── test_scripts.sh
```

## Environment variables

| Variable | Required | Purpose |
|---|---|---|
| `MODEL_REPO` | Yes for download | Exact Hugging Face repository, e.g. `org/model-GGUF` |
| `MODEL_FILE` | Yes for download | Exact GGUF filename to download |
| `MODEL_REVISION` | No | Hugging Face branch/tag/commit; default `main` |
| `MODEL_PATH` | Optional | Existing GGUF file path; if present and valid, it is used first |
| `MODEL_DIR` | No | Directory used when `MODEL_PATH` is empty; default `/models` in Docker |
| `DOWNLOAD_MODEL` | No | `true` to download when no existing model is available; default `true` |
| `MODEL_ALIAS` | No | API model name; if empty, llama-server's normal behavior is used |
| `HF_TOKEN` | Optional | Token for private/gated Hugging Face repositories |
| `PORT` | No | Listening port; provider-supplied `PORT` is respected |
| `HOST` | No | Bind address; Docker/provider deployments should use `0.0.0.0` |
| `API_KEY` | Optional | Protects API endpoints when set |
| `CPU_THREADS` | No | Generation CPU threads; default `2` |
| `CPU_THREADS_BATCH` | No | Prompt-processing threads; default `2` |
| `CONTEXT_SIZE` | No | Context window; default `2048` |
| `BATCH_SIZE` | No | Logical batch size; default `256` |
| `UBATCH_SIZE` | No | Physical micro-batch size; default `128` |
| `PARALLEL` | No | Concurrent sequences; default `1` |
| `CORS_ORIGINS` | Optional | Explicit CORS origins; empty means do not add a CORS override |
| `LLAMA_SERVER_BIN` | No | Local executable name/path; default `llama-server` |
| `LLAMA_SERVER_ARGS` | Optional | Additional llama-server arguments |
| `LOG_VERBOSITY` | No | llama-server log verbosity; default `3` |
| `ENABLE_WEBUI` | No | Enables the llama.cpp Web UI; default `true` |

## Quick start: model from Hugging Face

Copy the example environment file and set the exact model you want:

```bash
cp .env.example .env
```

Edit `.env`:

```dotenv
MODEL_REPO=YOUR_ORG/YOUR_MODEL_GGUF_REPO
MODEL_FILE=YOUR_EXACT_MODEL.gguf
MODEL_REVISION=main
DOWNLOAD_MODEL=true
MODEL_ALIAS=
```

Then start the server using Docker Compose:

```bash
docker compose up -d --build
curl -fsS http://localhost:${PORT:-8080}/health
```

The container downloads **only** `MODEL_REPO/MODEL_FILE` if the selected model is not already present.

## Quick start: existing local model

Set:

```dotenv
MODEL_PATH=/models/your-model.gguf
DOWNLOAD_MODEL=false
```

Place the model in `./models/your-model.gguf`, then run:

```bash
docker compose up -d --build
```

No model is downloaded in this mode.

## API

### Health

```bash
curl -fsS http://localhost:8080/health
```

### Models

```bash
curl http://localhost:8080/v1/models \
  -H "Authorization: Bearer $API_KEY"
```

### Chat completion

```bash
curl -N http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d '{
    "model": "YOUR_MODEL_ALIAS",
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": true,
    "max_tokens": 64
  }'
```

The API is provided by upstream `llama-server`; this repository does not implement a custom inference engine.

## Resource usage

GGUF file size is **not** the same as total RAM usage. Runtime memory also includes model residency, KV cache, batch buffers, allocator overhead and operating-system cache.

The conservative defaults are:

```text
CPU_THREADS=2
CPU_THREADS_BATCH=2
CONTEXT_SIZE=2048
BATCH_SIZE=256
UBATCH_SIZE=128
PARALLEL=1
```

For a small CPU machine, reduce `CONTEXT_SIZE`, `BATCH_SIZE`, `UBATCH_SIZE` and `PARALLEL` first if RAM is insufficient.

## Linux and macOS

Install a compatible CPU `llama-server` binary from upstream llama.cpp releases or build it from source. Then:

```bash
cp .env.example .env
# Edit .env with your model variables.
chmod +x scripts/*.sh
set -a; . ./.env; set +a
./scripts/start.sh
```

The shell launcher uses the exact model selected by the environment. It does not contain a fallback model.

## Windows PowerShell

Install a compatible `llama-server.exe`, then configure the same environment variables and run:

```powershell
$env:MODEL_REPO = "YOUR_ORG/YOUR_MODEL_GGUF_REPO"
$env:MODEL_FILE = "YOUR_EXACT_MODEL.gguf"
$env:DOWNLOAD_MODEL = "true"
$env:LLAMA_SERVER_BIN = "C:\path\to\llama-server.exe"
.\scripts\start.ps1
```

## Docker

The Docker image is based on the upstream llama.cpp server image. No model is copied into the image. The `/models` directory is a volume.

```bash
docker compose up -d --build
```

## Railway

The repository includes `railway.toml` using the Dockerfile and `/health` health check. Railway supplies `PORT`; the launcher passes it to llama-server.

Set these variables in the Railway service:

```text
MODEL_REPO
MODEL_FILE
MODEL_REVISION (optional)
MODEL_PATH (optional)
MODEL_ALIAS (optional)
API_KEY (recommended)
HF_TOKEN (only for private/gated models)
```

For a hosted download, leave `MODEL_PATH` unset and set `MODEL_REPO` plus `MODEL_FILE`. The selected model is then the only model downloaded.

Use persistent storage if you want the downloaded model to survive service replacement. Without persistent storage, the model may need to be downloaded again.

## Render

The repository includes a Render Blueprint using Docker and `/health`.

The Blueprint deliberately does **not** choose a model. `MODEL_REPO`, `MODEL_FILE`, and other model-related values are supplied as environment variables during deployment. Render's `sync: false` variables are intentionally used so the repository does not contain model or secret values.

Do not assume Render Free can run an arbitrary GGUF model. Select a compute plan with enough RAM for the specific model and context configuration you choose.

## Generic VPS

Use Docker Compose on a Linux VPS:

```bash
git clone https://github.com/aftabalamtech/cpu-llm-api-server.git
cd cpu-llm-api-server
cp .env.example .env
# Set MODEL_REPO and MODEL_FILE, or MODEL_PATH for an existing file.
docker compose up -d --build
```

For public access, put the service behind HTTPS and set a strong `API_KEY`.

## Security

- Do not commit `.env` or `HF_TOKEN`.
- Set `API_KEY` for public deployments.
- Do not expose the API without TLS on an untrusted network.
- Keep `CORS_ORIGINS` restricted when browser clients are used.
- GGUF files are intentionally excluded from Git.

## Testing

Static tests do not download a model or perform inference:

```bash
python3 -m unittest discover -s tests -v
bash tests/test_scripts.sh
```

## Support boundary

This repository supports the deployment paths that have actual configuration and matching documentation in the repository. It does not claim GPU acceleration, model conversion, model routing, or provider-specific persistent storage where the provider/plan does not supply it.

## Upstream

- [llama.cpp](https://github.com/ggml-org/llama.cpp)
- [llama-server documentation](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md)
