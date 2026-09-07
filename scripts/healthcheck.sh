#!/usr/bin/env bash
set -Eeuo pipefail

: "${PORT:=8080}"
: "${HEALTHCHECK_HOST:=127.0.0.1}"
: "${HEALTHCHECK_TIMEOUT:=5}"

curl --fail --silent --show-error --max-time "${HEALTHCHECK_TIMEOUT}" \
  "http://${HEALTHCHECK_HOST}:${PORT}/health" >/dev/null
