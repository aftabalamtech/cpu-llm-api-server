#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$ROOT/scripts/start.sh"
bash -n "$ROOT/scripts/download-model.sh"
bash -n "$ROOT/scripts/healthcheck.sh"

# Verify the runtime does not contain a hardcoded model identity.
! grep -Eq 'MODEL_REPO=ggml-org/|MODEL_FILE=gemma' "$ROOT/scripts/start.sh" "$ROOT/.env.example" "$ROOT/Dockerfile" "$ROOT/docker-compose.yml" "$ROOT/render.yaml"

echo "Static script and no-default-model checks passed."
