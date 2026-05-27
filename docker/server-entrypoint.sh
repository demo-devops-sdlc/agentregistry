#!/bin/sh
set -eu

# For test deployments (e.g., Render), load baked runtime settings from /app/.env.
if [ -f /app/.env ]; then
  set -a
  # shellcheck disable=SC1091
  . /app/.env
  set +a
fi

exec /app/bin/arctl-server
