#!/usr/bin/env bash
set -Eeuo pipefail

: "${PORT:=8080}"
: "${HOST:=0.0.0.0}"
: "${API_KEY:=}"
: "${MODEL_ALIAS:=}"
: "${MODEL_PATH:=}"
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
: "${CORS_ORIGINS:=}"
: "${LLAMA_SERVER_BIN:=llama-server}"
: "${LLAMA_SERVER_ARGS:=}"

if [[ -n "${MODEL_PATH}" && -f "${MODEL_PATH}" ]]; then
  echo "Using model from MODEL_PATH: ${MODEL_PATH}"
elif [[ "${DOWNLOAD_MODEL}" == "true" ]]; then
  if [[ -z "${MODEL_REPO}" || -z "${MODEL_FILE}" ]]; then
    echo "No model configured. Set MODEL_REPO and MODEL_FILE to the exact model to download, or set MODEL_PATH to an existing GGUF file." >&2
    exit 2
  fi
  MODEL_PATH="${MODEL_PATH:-${MODEL_DIR}/${MODEL_FILE}}"
  export MODEL_DIR MODEL_REPO MODEL_FILE MODEL_REVISION HF_TOKEN MODEL_PATH
  "$(dirname "$0")/download-model.sh"
else
  echo "No usable model configured. Set MODEL_PATH to an existing GGUF file or set MODEL_REPO and MODEL_FILE with DOWNLOAD_MODEL=true." >&2
  exit 2
fi

if [[ ! -f "${MODEL_PATH}" ]]; then
  echo "Model file not found at ${MODEL_PATH}." >&2
  exit 1
fi

args=(
  --model "${MODEL_PATH}"
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
)

if [[ -n "${MODEL_ALIAS}" ]]; then
  args+=(--alias "${MODEL_ALIAS}")
fi

if [[ -n "${CORS_ORIGINS}" ]]; then
  args+=(--cors-origins "${CORS_ORIGINS}")
fi

if [[ -n "${API_KEY}" ]]; then
  args+=(--api-key "${API_KEY}")
fi

if [[ -n "${LLAMA_SERVER_ARGS}" ]]; then
  read -r -a extra_args <<< "${LLAMA_SERVER_ARGS}"
  args+=("${extra_args[@]}")
fi

exec "${LLAMA_SERVER_BIN}" "${args[@]}"
