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
# Do not reuse NOMO_BACKEND_URL from .env.local here: run_dev_local.sh owns
# localhost, while this script must stay pinned to the dev Render backend.
: "${DEV_NOMO_BACKEND_URL:?DEV_NOMO_BACKEND_URL is required because the old dev Render hostname is not resolvable. Use run_dev_local.sh for local dev backend.}"

flutter run \
  --dart-define=NOMO_ENV=dev \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL="$SUPABASE_AUTH_REDIRECT_URL" \
  --dart-define=NOMO_BACKEND_URL="$DEV_NOMO_BACKEND_URL" \
  "$@"
