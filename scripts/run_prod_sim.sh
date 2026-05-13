#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Run Nomo on the iOS Simulator against the deployed Render backend.
# The Supabase project must match the backend's SUPABASE_URL, otherwise
# PostgREST returns PGRST301 (JWT key mismatch).
flutter run \
  --dart-define=NOMO_ENV=production \
  --dart-define=SUPABASE_URL=https://pwifgddolctqghygwxwj.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_pezjPt7pYRECNFdydlon8A_RpSjNulk \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL=app.nomo.nomo://login-callback/ \
  --dart-define=NOMO_BACKEND_URL=https://nomo-backend-nezf.onrender.com \
  "$@"
