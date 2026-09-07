# Deployment

## Docker

1. Copy `.env.example` to `.env`.
2. Set `MODEL_REPO` and `MODEL_FILE`, or set `MODEL_PATH` for an existing GGUF file.
3. Run `docker compose up -d --build`.
4. Check `/health`.

## Railway

`railway.toml` selects the Dockerfile and `/health` health check. Railway supplies `PORT` at runtime. Set the model variables in the service environment.

Required for startup when downloading:

```text
MODEL_REPO
MODEL_FILE
```

Recommended:

```text
API_KEY
```

A persistent volume mounted at `/models` can avoid repeated model downloads.

## Render

`render.yaml` defines a Docker web service and `/health` health check. Render environment variables with `sync: false` are intentionally not given values in Git.

Set `MODEL_REPO` and `MODEL_FILE` to the exact model you want. Select a compute plan with enough RAM for that model and its context/KV cache. The repository does not claim that every model can run on Render Free.

## VPS

Run Docker Compose on a Linux VPS. Put the API behind TLS before exposing it publicly and set `API_KEY`.

## Native Linux/macOS

Install a compatible upstream `llama-server` executable, export the model configuration, then run `scripts/start.sh`.

## Windows

Install a compatible `llama-server.exe`, configure the model environment variables and run `scripts/start.ps1` from PowerShell.
