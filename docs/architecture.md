# Architecture

The repository is a thin deployment wrapper around upstream `llama-server`; it does not implement a second inference engine or an API translation proxy.

```text
Client
  |
  | HTTP /health, /v1/models, /v1/chat/completions
  v
llama-server (CPU-only defaults, OpenAI-compatible API)
  |
  v
GGUF model file at MODEL_PATH
```

At startup, `scripts/start.sh` or `scripts/start.ps1` checks `MODEL_PATH`. If the file is absent and downloading is enabled, the launcher downloads `MODEL_FILE` from the Hugging Face `MODEL_REPO` into `MODEL_DIR`. It then starts the upstream executable with the configured host, platform-provided port, CPU threads, context size, logical and physical batch sizes, one parallel sequence, model alias, API key, and disabled web UI.

`GET /health` is intentionally public because upstream documents it as a readiness endpoint. It returns an unavailable response while the model is loading and an OK response after the server is ready. The OpenAI-compatible routes are authenticated when `API_KEY` is non-empty.

The repository does not claim that RAM equals the GGUF file size. Memory usage includes model weights, memory-map residency or loaded pages, KV cache, prompt and batch buffers, allocator overhead, and concurrent sequence state. The default context, batch, physical batch, and parallel values are therefore conservative.
