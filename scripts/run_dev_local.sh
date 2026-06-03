#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cat >&2 <<'MSG'
run_dev_local.sh is deprecated.

Ohey dev / iOS Simulator checks must use dev-ohey Supabase and the dev Render
backend, not a local backend on localhost:8080. Delegating to run_dev_render.sh.
MSG

exec "$SCRIPT_DIR/run_dev_render.sh" "$@"
