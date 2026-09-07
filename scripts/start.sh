#!/usr/bin/env bash
set -Eeuo pipefail

: "${PORT:=8080}"
: "${HOST:=0.0.0.0}"
: "${API_KEY:=}"
: "${MODEL_ALIAS:=local-model}"
: "${MODEL_PATH:=/models/model.gguf}"
: "${MODEL_DIR:=/models}"
: "${MODEL_REPO:=}"
: "${MODEL_FILE:=}"
: "${MODEL_REVISION:=main}"
: "${HF_TOKEN:=}"
: "${DOWNLOAD_MODEL:=true}"
: "${CPU_THREADS:=2}"
: "${CPU_THREADS_BATCH:=${CPU_THREADS}}"
: "${CONTEXT_SIZE:=2048}"
: "${BATCH_SIZE:=256}"
: "${UBATCH_SIZE:=128}"
: "${PARALLEL:=1}"
: "${LOG_VERBOSITY:=3}"
: "${CORS_ORIGINS:=*}"
: "${LLAMA_SERVER_BIN:=llama-server}"
: "${LLAMA_SERVER_ARGS:=}"

if [[ -z "${MODEL_PATH}" ]]; then
  echo "MODEL_PATH must not be empty" >&2
  exit 2
fi

if [[ ! -f "${MODEL_PATH}" ]]; then
  if [[ "${DOWNLOAD_MODEL}" != "true" ]]; then
    echo "Model not found at ${MODEL_PATH} and DOWNLOAD_MODEL is not true." >&2
    exit 1
  fi
  if [[ -z "${MODEL_REPO}" || -z "${MODEL_FILE}" ]]; then
    echo "Model not found. Set MODEL_REPO and MODEL_FILE, or mount MODEL_PATH." >&2
    exit 1
  fi
  MODEL_DIR="${MODEL_DIR:-$(dirname "${MODEL_PATH}")}"
  export MODEL_DIR MODEL_REPO MODEL_FILE MODEL_REVISION HF_TOKEN MODEL_PATH
  "$(dirname "$0")/download-model.sh"
fi

if [[ ! -f "${MODEL_PATH}" ]]; then
  echo "Model file still not found at ${MODEL_PATH}." >&2
  exit 1
fi

args=(
  --model "${MODEL_PATH}"
  --alias "${MODEL_ALIAS}"
  --host "${HOST}"
  --port "${PORT}"
  --threads "${CPU_THREADS}"
  --threads-batch "${CPU_THREADS_BATCH}"
  --ctx-size "${CONTEXT_SIZE}"
  --batch-size "${BATCH_SIZE}"
  --ubatch-size "${UBATCH_SIZE}"
  --parallel "${PARALLEL}"
  --no-webui
  --log-verbosity "${LOG_VERBOSITY}"
  --cors-origins "${CORS_ORIGINS}"
)

if [[ -n "${API_KEY}" ]]; then
  args+=(--api-key "${API_KEY}")
fi

# Deliberately allow extra, operator-supplied flags without inventing defaults.
if [[ -n "${LLAMA_SERVER_ARGS}" ]]; then
  read -r -a extra_args <<< "${LLAMA_SERVER_ARGS}"
  args+=("${extra_args[@]}")
fi

exec "${LLAMA_SERVER_BIN}" "${args[@]}"
