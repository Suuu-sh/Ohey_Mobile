#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Run Nomo locally against dev-nomo Supabase and a local Go backend on :8080.
flutter run \
  --dart-define=NOMO_ENV=local \
  --dart-define=SUPABASE_URL=https://wwyaftonswgxnjcceyfb.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_pPvKPrOvVmkKQIXKVWj2Rw_DlYkm0Ty \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=app.nomo.nomo://login-callback/ \
  --dart-define=NOMO_BACKEND_URL=http://localhost:8080 \
  "$@"
