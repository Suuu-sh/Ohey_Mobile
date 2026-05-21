#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

cat >&2 <<'MSG'
Refusing to run the iOS Simulator against production.

Nomo policy: Simulator must always connect to dev-nomo DB.
Use one of these instead:
  ./scripts/run_dev_render.sh -d <simulator-id>
  ./scripts/run_dev_local.sh -d <simulator-id>
  flutter run --dart-define-from-file=config/firebase/dev.json -d <simulator-id>
MSG
exit 1
