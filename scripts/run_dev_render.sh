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

# Run Ohey against Clerk auth and the dev Render backend.
# Public defaults are shared with lib/core/config/ohey_environment.dart.
OHEY_AUTH_REDIRECT_URL="${OHEY_AUTH_REDIRECT_URL:-$OHEY_DEV_AUTH_REDIRECT_URL}"
DEV_OHEY_BACKEND_URL="${DEV_OHEY_BACKEND_URL:-$OHEY_DEV_BACKEND_URL}"
OHEY_ADMIN_EMAILS="${OHEY_ADMIN_EMAILS:-}"
CLERK_PUBLISHABLE_KEY="${CLERK_PUBLISHABLE_KEY:-}"
if [[ -z "$CLERK_PUBLISHABLE_KEY" ]]; then
  echo "CLERK_PUBLISHABLE_KEY is required for Ohey Clerk auth" >&2
  exit 1
fi

flutter run \
  --dart-define=OHEY_ENV="$OHEY_DEV_ENV" \
  --dart-define=OHEY_AUTH_REDIRECT_URL="$OHEY_AUTH_REDIRECT_URL" \
  --dart-define=OHEY_BACKEND_URL="$DEV_OHEY_BACKEND_URL" \
  --dart-define=OHEY_ADMIN_EMAILS="$OHEY_ADMIN_EMAILS" \
  --dart-define=CLERK_PUBLISHABLE_KEY="$CLERK_PUBLISHABLE_KEY" \
  "$@"
