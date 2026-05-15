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

# Run Nomo on the iOS Simulator against the production Supabase/Render backend.
flutter run \
  --dart-define=NOMO_ENV=production \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL="$SUPABASE_AUTH_REDIRECT_URL" \
  --dart-define=NOMO_BACKEND_URL="${NOMO_BACKEND_URL:-https://nomo-backend-nezf.onrender.com}" \
  "$@"
