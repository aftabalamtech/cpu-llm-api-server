# Troubleshooting

## Startup says no model is configured

Set both variables when using Hugging Face download:

```dotenv
MODEL_REPO=owner/model-GGUF
MODEL_FILE=exact-file.gguf
DOWNLOAD_MODEL=true
```

Or provide an existing file:

```dotenv
MODEL_PATH=/models/model.gguf
DOWNLOAD_MODEL=false
```

## Model download fails

Check the exact repository, filename and revision. For private or gated repositories, set `HF_TOKEN`. The downloader does not search for a different file.

## Out of memory

Lower, in order:

```text
CONTEXT_SIZE
BATCH_SIZE
UBATCH_SIZE
PARALLEL
```

The GGUF file size alone does not represent total runtime RAM.

## Health check fails

The health endpoint becomes successful only when llama-server is ready. Check container logs and verify that the selected GGUF file exists and is compatible with the installed llama.cpp build.

## Provider deploy loops

Confirm the provider supplies a `PORT` environment variable and enough RAM/disk for the exact model. A model download can consume substantial disk during startup.

## Authentication failures

If `API_KEY` is set, send `Authorization: Bearer <key>` to protected API routes. `/health` remains public.
