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
SUPABASE_AUTH_REDIRECT_URL="${SUPABASE_AUTH_REDIRECT_URL:-app.nomo.nomo://login-callback/}"

# Run Nomo against dev-nomo Supabase and the dev Render backend.
DEV_NOMO_BACKEND_URL="${DEV_NOMO_BACKEND_URL:-https://dev-nomo-backend.onrender.com}"

flutter run \
  --dart-define=NOMO_ENV=dev \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL="$SUPABASE_AUTH_REDIRECT_URL" \
  --dart-define=NOMO_BACKEND_URL="$DEV_NOMO_BACKEND_URL" \
  "$@"
