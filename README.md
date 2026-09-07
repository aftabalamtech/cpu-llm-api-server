# CPU-only GGUF LLM API Server

A lightweight, cross-platform API server for running a local or hosted **GGUF** model with the upstream `llama-server` executable from [llama.cpp](https://github.com/ggml-org/llama.cpp). The project exposes an OpenAI-compatible API, keeps the default runtime CPU-only, downloads no model during image build, and supports Docker, Linux, macOS, Windows PowerShell, Railway, Render, and a generic Docker-based VPS deployment.

> The container image uses the upstream `ghcr.io/ggml-org/llama.cpp:server` image. The launcher passes only documented `llama-server` options: `--model`, `--alias`, `--host`, `--port`, `--threads`, `--threads-batch`, `--ctx-size`, `--batch-size`, `--ubatch-size`, `--parallel`, `--no-webui`, `--log-verbosity`, `--cors-origins`, and optional `--api-key`.

## Supported platforms

| Platform | Supported path | What is required |
|---|---|---|
| Linux | Native executable or Docker | A CPU build of `llama-server`, or Docker Engine |
| macOS | Native executable through a POSIX shell | A compatible `llama-server` binary and `curl`; Apple Silicon is supported only in CPU mode by this repository's defaults |
| Windows | PowerShell script | A compatible `llama-server.exe`, PowerShell, and a GGUF file or Hugging Face download settings |
| Docker | Docker Compose or `docker run` | Docker Engine with enough disk and RAM for the selected model |
| Railway | Docker deployment via `railway.toml` | Set model and secret environment variables in the Railway project; use a persistent volume if avoiding re-downloads |
| Render | Docker web service via `render.yaml` | Set model and secret environment variables; use persistent storage or accept a model download on each replacement |
| Generic VPS | Docker Compose or Docker CLI | A Linux VPS with Docker, a mounted model directory or download settings, and an exposed reverse-proxy/TLS layer for public use |

The repository does **not** claim native Windows batch-file support, GPU acceleration, model conversion, multi-model routing, or durable hosted model storage on providers that do not offer a persistent disk.

## API

The upstream server provides the following required routes.

| Route | Purpose | Authentication |
|---|---|---|
| `GET /health` | Returns `200` with `{"status":"ok"}` after the model is ready; returns `503` while loading | Public by design, so deployment health checks work |
| `GET /v1/models` | Lists the loaded model using `MODEL_ALIAS` | API key when `API_KEY` is set |
| `POST /v1/chat/completions` | OpenAI-compatible chat completion endpoint | API key when `API_KEY` is set |

Set `stream: true` in a chat completion request to receive server-sent event streaming. The client should send `Authorization: Bearer $API_KEY` when authentication is enabled. The `/health` endpoint remains public because upstream documents it as a public health check.

Example:

```bash
curl -sS http://localhost:8080/v1/models \
  -H "Authorization: Bearer change-me"

curl -N http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer change-me" \
  -d '{
    "model": "local-model",
    "messages": [{"role": "user", "content": "Say hello in one sentence."}],
    "stream": true,
    "max_tokens": 64
  }'
```

## Model configuration

No GGUF model is committed. The launcher first checks `MODEL_PATH`. If that file is absent and `DOWNLOAD_MODEL=true`, it downloads `MODEL_FILE` from the Hugging Face repository `MODEL_REPO` at `MODEL_REVISION` directly to `MODEL_PATH` (creating its parent directory). A private or gated repository may use `HF_TOKEN`.

The default example is intentionally small and CPU-oriented:

| Variable | Default | Meaning |
|---|---:|---|
| `MODEL_REPO` | `ggml-org/gemma-3-1b-it-GGUF` | Hugging Face repository used only when downloading |
| `MODEL_FILE` | `gemma-3-1b-it-Q4_K_M.gguf` | Quantized GGUF filename used by the example |
| `MODEL_PATH` | `/models/model.gguf` | File passed to `llama-server`; set it to the downloaded file or mounted file |
| `MODEL_ALIAS` | `local-model` | Value returned by `/v1/models` and used in requests |

The example model is a configuration default, not a model artifact. Verify the model's license and suitability before deploying it.

## Resource guidance

The GGUF **file size is not total RAM usage**. Runtime memory also includes the mapped or resident model weights, KV cache, prompt and batch buffers, allocator overhead, and the operating system's file cache. KV-cache memory grows with context size, concurrent sequences, layers, and cache data types. A smaller quantized file can therefore still require materially more RAM at runtime than its file size suggests.

The defaults target small CPU machines rather than maximum throughput.

| Setting | Default | Resource rationale |
|---|---:|---|
| `CPU_THREADS` | `2` | Avoids saturating a small shared VM; increase after measuring throughput |
| `CPU_THREADS_BATCH` | `2` | Keeps prompt processing bounded on low-core hosts |
| `CONTEXT_SIZE` | `2048` | Limits KV-cache growth; increase only with available RAM |
| `BATCH_SIZE` | `256` | Reduces prompt-processing workspace versus upstream's larger default |
| `UBATCH_SIZE` | `128` | Keeps physical batch memory bounded |
| `PARALLEL` | `1` | Avoids multiplying KV-cache usage across concurrent sequences |
| Quantization | User-selected GGUF | Q4-class models usually reduce storage and weight memory compared with F16, with quality trade-offs |

For a first deployment, reserve more RAM than the GGUF file size and monitor resident memory during long contexts. If the process is killed, reduce `CONTEXT_SIZE`, `BATCH_SIZE`, `UBATCH_SIZE`, and `PARALLEL` before increasing CPU threads.

## Linux and macOS: native setup

Install a CPU-capable `llama-server` binary from a trusted llama.cpp release or build llama.cpp according to its upstream instructions. Do not use a binary built only for an incompatible architecture. Then copy `.env.example` to `.env`, edit the model variables, and run:

```bash
cp .env.example .env
# Edit .env. For a local file, set MODEL_PATH and DOWNLOAD_MODEL=false.
chmod +x scripts/*.sh
set -a; . ./.env; set +a
./scripts/start.sh
```

The script binds to `HOST` and `PORT`; it does not replace the platform-provided `PORT`. For macOS, run the same POSIX script from Terminal after installing a compatible `llama-server` executable and ensuring it is on `PATH`, or set `LLAMA_SERVER_BIN` to its full path.

## Windows PowerShell setup

Install a compatible `llama-server.exe`, place a GGUF model at the configured `MODEL_PATH`, or set `MODEL_REPO`, `MODEL_FILE`, and `DOWNLOAD_MODEL=true`. In PowerShell:

```powershell
Copy-Item .env.example .env
# Load the values you need into the current PowerShell session, for example:
$env:MODEL_PATH = "$PWD\models\model.gguf"
$env:DOWNLOAD_MODEL = "false"
$env:API_KEY = "change-me"
$env:LLAMA_SERVER_BIN = "C:\path\to\llama-server.exe"
.\scripts\start.ps1
```

If PowerShell execution policy blocks local scripts, use a user-approved policy appropriate for your environment; do not disable security controls globally. The script uses the same API and tuning variables as the POSIX launcher.

## Docker Compose

Create `.env`, edit it, and start the server:

```bash
cp .env.example .env
# For a mounted local model, set MODEL_PATH=/models/your-model.gguf and DOWNLOAD_MODEL=false.
docker compose up -d --build
curl -fsS http://localhost:${PORT:-8080}/health
```

The Compose file mounts `./models` at `/models` and uses `${PORT:-8080}` only as a local Compose fallback. Hosted deployments still receive their own `PORT` environment variable. The health check waits for the public `/health` route.

## Generic VPS Docker deployment

On a Linux VPS, install Docker, clone this repository, place a model in `models/` or configure the Hugging Face download variables, set a strong `API_KEY`, and run `docker compose up -d --build`. Put the service behind a TLS reverse proxy before exposing it publicly. Keep the API key out of Git, restrict firewall access, and use a persistent disk for `models/` if model downloads should survive container replacement.

## Railway

Create a Railway service from this repository. `railway.toml` selects the Dockerfile, starts `/app/scripts/start.sh`, and checks `/health`. Railway injects `PORT`; the launcher passes that value to llama-server and never hardcodes a Railway port. Configure `API_KEY`, `MODEL_REPO`, `MODEL_FILE`, and optionally `HF_TOKEN`, `MODEL_ALIAS`, and tuning variables in Railway's Variables UI. A Railway volume mounted at `/models` is recommended when supported by the selected plan; otherwise the model may be downloaded again after replacement.

## Render

Create a Render Blueprint from `render.yaml` or create a Docker web service from this repository. Render injects `PORT`; the launcher binds to it. Set the secret values marked `sync: false`, especially `API_KEY`, `MODEL_REPO`, and `MODEL_FILE`. The service uses `/health` for readiness. Configure a persistent disk mounted at `/models` if the service plan supports one and you want to avoid repeat downloads; without persistent storage, replacement instances should be expected to download the model again.

## Security and operations

Set `API_KEY` for every non-local deployment. The key is passed to the upstream server's documented `--api-key` option. Use HTTPS through a reverse proxy for public traffic, do not place secrets in `.env.example`, and do not commit GGUF files. The server's built-in web UI is disabled with `--no-webui`; the API remains available.

This project intentionally avoids a custom proxy layer, database, telemetry service, or model manager. As a result, upstream llama-server behavior and model chat-template compatibility remain the primary operational dependencies.

## Tests and verification

The repository includes static consistency tests that do not download a model or start inference. Run:

```bash
python3 -m unittest discover -s tests -v
bash -n scripts/start.sh scripts/download-model.sh scripts/healthcheck.sh
```

## References

[1]: https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md "llama.cpp HTTP Server documentation"
[2]: https://github.com/ggml-org/llama.cpp "llama.cpp upstream repository"
