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
DEV_DART_DEFINE_FILE="${OHEY_DART_DEFINE_FILE:-config/firebase/dev.json}"
json_define_value() {
  local key="$1"
  if [[ ! -f "$DEV_DART_DEFINE_FILE" ]]; then
    return 0
  fi
  python3 - "$DEV_DART_DEFINE_FILE" "$key" <<'PY'
import json
import sys

path, key = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8") as handle:
        value = json.load(handle).get(key, "")
except Exception:
    value = ""
if value is not None:
    print(str(value))
PY
}

OHEY_AUTH_REDIRECT_URL="${OHEY_AUTH_REDIRECT_URL:-$OHEY_DEV_AUTH_REDIRECT_URL}"
DEV_OHEY_BACKEND_URL="${DEV_OHEY_BACKEND_URL:-$OHEY_DEV_BACKEND_URL}"
CLERK_PUBLISHABLE_KEY="${CLERK_PUBLISHABLE_KEY:-$(json_define_value CLERK_PUBLISHABLE_KEY)}"
if [[ -z "$CLERK_PUBLISHABLE_KEY" ]]; then
  echo "CLERK_PUBLISHABLE_KEY is required for Ohey Clerk auth" >&2
  exit 1
fi
GOOGLE_WEB_CLIENT_ID="${GOOGLE_WEB_CLIENT_ID:-$(json_define_value GOOGLE_WEB_CLIENT_ID)}"
GOOGLE_IOS_CLIENT_ID="${GOOGLE_IOS_CLIENT_ID:-$(json_define_value GOOGLE_IOS_CLIENT_ID)}"
GOOGLE_IOS_REVERSED_CLIENT_ID="${GOOGLE_IOS_REVERSED_CLIENT_ID:-$(json_define_value GOOGLE_IOS_REVERSED_CLIENT_ID)}"
OHEY_ENABLE_APPLE_OAUTH="${OHEY_ENABLE_APPLE_OAUTH:-$(json_define_value OHEY_ENABLE_APPLE_OAUTH)}"
OHEY_ENABLE_APPLE_OAUTH="${OHEY_ENABLE_APPLE_OAUTH:-true}"

dart_define_file_args=()
if [[ -f "$DEV_DART_DEFINE_FILE" ]]; then
  dart_define_file_args+=(--dart-define-from-file="$DEV_DART_DEFINE_FILE")
fi

if [[ -n "$GOOGLE_IOS_REVERSED_CLIENT_ID" ]]; then
  cat > ios/Flutter/OheyLocalOverrides.xcconfig <<EOF
GOOGLE_IOS_REVERSED_CLIENT_ID=$GOOGLE_IOS_REVERSED_CLIENT_ID
EOF
fi

flutter run \
  "${dart_define_file_args[@]}" \
  --dart-define=OHEY_ENV="$OHEY_DEV_ENV" \
  --dart-define=OHEY_AUTH_REDIRECT_URL="$OHEY_AUTH_REDIRECT_URL" \
  --dart-define=OHEY_BACKEND_URL="$DEV_OHEY_BACKEND_URL" \
  --dart-define=CLERK_PUBLISHABLE_KEY="$CLERK_PUBLISHABLE_KEY" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID" \
  --dart-define=GOOGLE_IOS_CLIENT_ID="$GOOGLE_IOS_CLIENT_ID" \
  --dart-define=GOOGLE_IOS_REVERSED_CLIENT_ID="$GOOGLE_IOS_REVERSED_CLIENT_ID" \
  --dart-define=OHEY_ENABLE_APPLE_OAUTH="$OHEY_ENABLE_APPLE_OAUTH" \
  "$@"
