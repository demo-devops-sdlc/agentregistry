#!/usr/bin/env bash
set -euo pipefail

# For test deployments (e.g., Render), load baked runtime settings from /app/.env.
if [[ -f /app/.env ]]; then
  set -a
  # shellcheck disable=SC1091
  source /app/.env
  set +a
fi

exec /app/bin/arctl-server
