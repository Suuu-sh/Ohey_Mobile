#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Run Nomo against dev-nomo Supabase and the dev Render backend.
# Do not use the production nomo Supabase for local/dev checks.
flutter run \
  --dart-define=NOMO_ENV=dev \
  --dart-define=SUPABASE_URL=https://wwyaftonswgxnjcceyfb.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_pPvKPrOvVmkKQIXKVWj2Rw_DlYkm0Ty \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=app.nomo.nomo://login-callback/ \
  --dart-define=NOMO_BACKEND_URL=https://dev-nomo-backend.onrender.com \
  "$@"
