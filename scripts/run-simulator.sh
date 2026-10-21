#!/usr/bin/env bash
# Builds the app, runs it in an iPhone simulator, and pairs it with the fake Mac, so you can try every
# screen without your real Mac. Needs Xcode (license accepted). Pass a simulator UDID to pick another phone.
set -euo pipefail
cd "$(dirname "$0")/.."
# The simulator phone: the one you name (UDID), else the first iPhone simulator Xcode has installed.
UDID="${1:-$(xcrun simctl list devices available | awk '/iPhone/ {match($0, /[0-9A-F]{8}-[0-9A-F-]{27}/); print substr($0, RSTART, RLENGTH); exit}')}"
[ -n "$UDID" ] || { echo "No iPhone simulator found. In Xcode: Settings > Components, download an iOS platform."; exit 1; }
OUT="${FM3000_OUT:-$(mktemp -d)}"
./scripts/generate-project.sh >/dev/null
xcodebuild -project FM3000.xcodeproj -scheme FM3000 -configuration Debug -destination "platform=iOS Simulator,id=$UDID" \
  -derivedDataPath "$OUT/dd" CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO build | tail -3
APP="$(find "$OUT/dd/Build/Products" -name 'FM3000.app' -maxdepth 3 | head -1)"
xcrun simctl boot "$UDID" 2>/dev/null || true
# The window is optional: the simulator runs headless too (Xcode 27 shows it in DeviceHub).
open -a Simulator 2>/dev/null || open "$(xcode-select -p)/../Applications/DeviceHub.app" 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
[ -d fake-mac/node_modules ] || (cd fake-mac && npm ci --silent)
node fake-mac/server.mjs --state "$OUT/fake" --invites 1 >"$OUT/fake.log" &
FAKE=$!
trap 'kill $FAKE 2>/dev/null || true' EXIT
for _ in $(seq 1 50); do grep -q '"ev":"link"' "$OUT/fake.log" && break; sleep 0.1; done
LINK="$(grep '"ev":"link"' "$OUT/fake.log" | node -e 'process.stdin.on("data",d=>process.stdout.write(JSON.parse(d).link))')"
BUNDLE="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Info.plist")"
xcrun simctl launch "$UDID" "$BUNDLE" -pairLink "$LINK"
echo "The app is running in the simulator, paired with the fake Mac. Press Ctrl-C to stop the fake Mac."
wait $FAKE
