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
SUPABASE_AUTH_REDIRECT_URL="${SUPABASE_AUTH_REDIRECT_URL:-app.tomo.tomo://login-callback/}"
TOMO_ADMIN_EMAILS="${TOMO_ADMIN_EMAILS:-}"

# Run Tomo locally against dev-nomo Supabase and a local Go backend on :8080.
flutter run \
  --dart-define=TOMO_ENV=local \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL="$SUPABASE_AUTH_REDIRECT_URL" \
  --dart-define=TOMO_BACKEND_URL="${TOMO_BACKEND_URL:-http://localhost:8080}" \
  --dart-define=TOMO_ADMIN_EMAILS="$TOMO_ADMIN_EMAILS" \
  "$@"
