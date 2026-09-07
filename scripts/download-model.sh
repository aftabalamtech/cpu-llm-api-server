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

# Railway Free/Trial volumes are small. Give a useful diagnostic before curl
# starts instead of repeatedly restarting after a disk-full write failure.
avail_kb="$(df -Pk "$(dirname "${target}")" | awk 'NR==2 {print $4}')"
if [[ -n "${avail_kb}" && "${avail_kb}" -lt 50000 ]]; then
  echo "ERROR: insufficient free disk space in $(dirname "${target}")." >&2
  echo "Available: ${avail_kb} KB. Remove old .part/model files or use a larger Railway volume." >&2
  echo "For Railway Free/Trial, prefer a smaller GGUF such as SmolLM2 360M (~271 MB)." >&2
  exit 1
fi

# Resume only when a partial download exists. curl may return exit 23 when the
# volume fills; keep the partial file so a larger volume can resume it.
curl --fail --location --retry 3 --retry-delay 2 --continue-at - --output "${tmp}" "${auth_args[@]}" "${url}"
mv -f "${tmp}" "${target}"
echo "Downloaded ${target}"
