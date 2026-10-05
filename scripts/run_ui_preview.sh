#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

# Run Ohey in the debug-only UI preview mode: the app starts signed in as a
# fixture user and every backend call is answered in memory
# (lib/core/preview/). No Clerk account, backend, or network is needed, so it
# is meant for reviewing screens in the Simulator, not for testing the API.
exec flutter run --dart-define=OHEY_UI_PREVIEW=true "$@"
