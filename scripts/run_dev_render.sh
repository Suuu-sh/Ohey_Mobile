#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/ohey_env.sh"
cd "$SCRIPT_DIR/.."

if [[ -f .env.local ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env.local
  set +a
fi

# Run Ohey against dev-ohey Supabase and the dev Render backend.
# Public defaults are shared with lib/core/config/ohey_environment.dart.
SUPABASE_URL="${SUPABASE_URL:-$OHEY_DEV_SUPABASE_URL}"
SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY:-$OHEY_DEV_SUPABASE_PUBLISHABLE_KEY}"
SUPABASE_AUTH_REDIRECT_URL="${SUPABASE_AUTH_REDIRECT_URL:-$OHEY_DEV_AUTH_REDIRECT_URL}"
DEV_OHEY_BACKEND_URL="${DEV_OHEY_BACKEND_URL:-$OHEY_DEV_BACKEND_URL}"
OHEY_ADMIN_EMAILS="${OHEY_ADMIN_EMAILS:-}"

flutter run \
  --dart-define=OHEY_ENV="$OHEY_DEV_ENV" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL="$SUPABASE_AUTH_REDIRECT_URL" \
  --dart-define=OHEY_BACKEND_URL="$DEV_OHEY_BACKEND_URL" \
  --dart-define=OHEY_ADMIN_EMAILS="$OHEY_ADMIN_EMAILS" \
  "$@"
