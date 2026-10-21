#!/usr/bin/env bash
# Builds the app and installs it on your connected iPhone with a FREE Apple ID (a "Personal Team").
# No paid Developer Program, no TestFlight. The app stops opening after 7 days; run this again to renew it.
#
# One-time, in Xcode (no command line for this part): Xcode > Settings > Accounts > + > Apple ID, sign in.
# Then: FM3000_TEAM_ID=<your personal team id> ./scripts/install-device.sh
#   (find the id in Xcode > Settings > Accounts > your Apple ID > Personal Team, or leave it empty and use
#    Xcode itself: open FM3000.xcodeproj, pick the team under Signing & Capabilities, press Run.)
set -euo pipefail
cd "$(dirname "$0")/.."
: "${FM3000_TEAM_ID:?Set FM3000_TEAM_ID to your Personal Team id, or open FM3000.xcodeproj and press Run in Xcode instead}"
./scripts/generate-project.sh
UDID="${1:-$(xcrun devicectl list devices 2>/dev/null | awk '/connected|available/ && /iPhone/ {for(i=1;i<=NF;i++) if ($i ~ /^[0-9A-F-]{25,}$/) {print $i; exit}}')}"
[ -n "$UDID" ] || { echo "No iPhone found. Connect it by cable, unlock it and tap Trust. Or pass its identifier: $0 <udid>"; exit 1; }
OUT="$(mktemp -d)"
xcodebuild -project FM3000.xcodeproj -scheme FM3000 -configuration Release -destination "id=$UDID" \
  -derivedDataPath "$OUT" -allowProvisioningUpdates build | tail -5
APP="$(find "$OUT/Build/Products" -name 'FM3000.app' -maxdepth 3 | head -1)"
xcrun devicectl device install app --device "$UDID" "$APP"
echo "Installed. First launch: on the phone open Settings > General > VPN & Device Management, trust your Apple ID, then open Firstmate."
