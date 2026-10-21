#!/usr/bin/env bash
# OPTIONAL, needs the paid Apple Developer Program. Archives the app and exports an App Store build for
# TestFlight. It stops before any sign-in or upload: send the build yourself (README, "TestFlight").
set -euo pipefail
cd "$(dirname "$0")/.."
: "${FM3000_TEAM_ID:?Set FM3000_TEAM_ID to your paid team id}"
./scripts/generate-project.sh
OUT="build/testflight"; rm -rf "$OUT"; mkdir -p "$OUT"
xcodebuild -project FM3000.xcodeproj -scheme FM3000 -configuration Release -destination "generic/platform=iOS" \
  -archivePath "$OUT/FM3000.xcarchive" -allowProvisioningUpdates archive | tail -3
cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>$FM3000_TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
  <key>destination</key><string>export</string>
</dict></plist>
PLIST
xcodebuild -exportArchive -archivePath "$OUT/FM3000.xcarchive" -exportPath "$OUT/export" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" -allowProvisioningUpdates | tail -3
echo "Built: $OUT/export/FM3000.ipa. Upload it with the Transporter app (drag the .ipa in), then follow README > TestFlight."
