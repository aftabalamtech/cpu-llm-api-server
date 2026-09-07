# Configuration

## Model selection

There is no default model. Configure either:

```dotenv
MODEL_REPO=owner/model-GGUF
MODEL_FILE=exact-file.gguf
MODEL_REVISION=main
DOWNLOAD_MODEL=true
```

or an existing model:

```dotenv
MODEL_PATH=/models/model.gguf
DOWNLOAD_MODEL=false
```

When downloading, `MODEL_REPO` and `MODEL_FILE` are required. The launcher downloads exactly that file and does not discover or substitute another model.

## Resource tuning

Start with:

```text
CPU_THREADS=2
CPU_THREADS_BATCH=2
CONTEXT_SIZE=2048
BATCH_SIZE=256
UBATCH_SIZE=128
PARALLEL=1
```

If RAM is constrained, lower context, batch and parallelism before increasing CPU threads.

## Authentication

Set `API_KEY` for non-local deployments. The value is passed to llama-server's API-key option and is never stored in the repository.

## CORS

Leave `CORS_ORIGINS` empty unless a CORS override is needed. For browser access, configure only the origins that should be allowed.
