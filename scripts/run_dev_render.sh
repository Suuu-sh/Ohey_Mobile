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
SUPABASE_AUTH_REDIRECT_URL="${SUPABASE_AUTH_REDIRECT_URL:-app.ohey.com://login-callback/}"
OHEY_ADMIN_EMAILS="${OHEY_ADMIN_EMAILS:-}"

# Run Ohey against dev-ohey Supabase and the dev Render backend.
DEV_OHEY_BACKEND_URL="${DEV_OHEY_BACKEND_URL:-https://dev-ohey-backend.onrender.com}"

flutter run \
  --dart-define=OHEY_ENV=dev \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL="$SUPABASE_AUTH_REDIRECT_URL" \
  --dart-define=OHEY_BACKEND_URL="$DEV_OHEY_BACKEND_URL" \
  --dart-define=OHEY_ADMIN_EMAILS="$OHEY_ADMIN_EMAILS" \
  "$@"
