#!/usr/bin/env bash
set -Eeuo pipefail

: "${MODEL_DIR:=/models}"
: "${MODEL_REPO:=}"
: "${MODEL_FILE:=}"
: "${MODEL_REVISION:=main}"
: "${HF_TOKEN:=}"
: "${MODEL_PATH:=}"

if [[ -z "${MODEL_REPO}" || -z "${MODEL_FILE}" ]]; then
  echo "MODEL_REPO and MODEL_FILE are required." >&2
  exit 2
fi

target="${MODEL_PATH:-${MODEL_DIR}/${MODEL_FILE}}"
mkdir -p "$(dirname "${target}")"
url="https://huggingface.co/${MODEL_REPO}/resolve/${MODEL_REVISION}/${MODEL_FILE}?download=true"

if [[ -f "${target}" ]]; then
  echo "Model already exists: ${target}"
  exit 0
fi

auth_args=()
if [[ -n "${HF_TOKEN}" ]]; then
  auth_args=(-H "Authorization: Bearer ${HF_TOKEN}")
fi

tmp="${target}.part"
echo "Downloading ${MODEL_REPO}/${MODEL_FILE} to ${target}"
curl --fail --location --retry 3 --retry-delay 2 --continue-at - --output "${tmp}" "${auth_args[@]}" "${url}"
mv -f "${tmp}" "${target}"
echo "Downloaded ${target}"
