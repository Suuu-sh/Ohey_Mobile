#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -f .env.local ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env.local
  set +a
fi

: "${SUPABASE_URL:?SUPABASE_URL is required. Put it in .env.local or export it.}"
: "${SUPABASE_PUBLISHABLE_KEY:?SUPABASE_PUBLISHABLE_KEY is required. Put it in .env.local or export it.}"
SUPABASE_AUTH_REDIRECT_URL="${SUPABASE_AUTH_REDIRECT_URL:-app.ohey.ohey://login-callback/}"
OHEY_ADMIN_EMAILS="${OHEY_ADMIN_EMAILS:-}"

# Run Ohey locally against dev-ohey Supabase and a local Go backend on :8080.
flutter run \
  --dart-define=OHEY_ENV=local \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL="$SUPABASE_AUTH_REDIRECT_URL" \
  --dart-define=OHEY_BACKEND_URL="${OHEY_BACKEND_URL:-http://localhost:8080}" \
  --dart-define=OHEY_ADMIN_EMAILS="$OHEY_ADMIN_EMAILS" \
  "$@"
