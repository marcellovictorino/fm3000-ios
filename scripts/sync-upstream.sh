#!/bin/bash
# Copy the installed Infinitary app's iPhone source onto the upstream branch as one commit.
# Run from a clean checkout of the `upstream` branch. Then merge `upstream` into `main`.
set -euo pipefail
SRC="${INFINITARY_SOURCE:-/Applications/Infinitary.app/Contents/Resources/self-source}"
MAP="$SRC/self-map.json"
[ -f "$MAP" ] || { echo "No self-map.json in $SRC" >&2; exit 1; }
[ "$(git rev-parse --abbrev-ref HEAD)" = "upstream" ] || { echo "Check out the upstream branch first." >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "Working tree is not clean." >&2; exit 1; }
VERSION=$(/usr/bin/python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["version"])' "$MAP")
COMMIT=$(/usr/bin/python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["commit"])' "$MAP")
# Keep only this script; everything else mirrors the upstream folder.
find . -mindepth 1 -maxdepth 1 ! -name .git ! -name scripts -exec rm -rf {} +
mkdir -p docs
cp "$SRC/LICENSE" "$SRC/NOTICE" .
cp "$SRC/docs/ios.md" docs/ios.md
cp -R "$SRC/ios/Infinitary/." .
git add -A
if git diff --cached --quiet; then echo "Already at $VERSION."; exit 0; fi
git commit -q -m "chore(upstream): import Infinitary $VERSION" -m "Source: ios/Infinitary of the installed app, commit $COMMIT."
echo "Imported $VERSION. Next: git checkout main && git merge upstream"
