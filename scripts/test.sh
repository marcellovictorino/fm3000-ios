#!/usr/bin/env bash
# Everything that runs without a phone: the fake Mac's contract tests, the Swift checks, the end-to-end run.
set -euo pipefail
cd "$(dirname "$0")/.."
# Use the command line tools' toolchain when Xcode's license has not been accepted yet.
if ! swift build --show-bin-path >/dev/null 2>&1; then export DEVELOPER_DIR=/Library/Developer/CommandLineTools; fi
[ -d fake-mac/node_modules ] || (cd fake-mac && npm ci --silent)
echo "== fake Mac vs contract"; (cd fake-mac && npm test 2>&1 | grep -E "^ℹ (pass|fail)|✖")
echo "== Swift checks"; swift build --product fm-checks 2>&1 | grep -E "error|Build complete"
HOME="$(mktemp -d)" "$(swift build --show-bin-path)/fm-checks"
echo "== end to end (fake Mac, real TLS 1.3 and WebSocket)"; ./scripts/e2e.sh
