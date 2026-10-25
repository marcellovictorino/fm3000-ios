#!/usr/bin/env bash
# Starts the Mac-side Machine load feed: a launchd agent that samples every few seconds, and `tailscale serve` publishing it
# to your tailnet only (https, port 8443). Does not touch Remote Login or the Infinitary app. Undo with ./uninstall.sh.
set -euo pipefail
cd "$(dirname "$0")"
LABEL=com.marcellovictorino.fm3000.machine-load
DIR="$HOME/Library/Application Support/fm3000-machine-load"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
PYTHON="$(command -v python3)"
mkdir -p "$DIR" "$HOME/Library/LaunchAgents"
cp machine_load_feed.py "$DIR/machine_load_feed.py"
cat > "$PLIST" <<PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$PYTHON</string><string>$DIR/machine_load_feed.py</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardErrorPath</key><string>$DIR/feed.log</string>
</dict></plist>
PLIST_EOF
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
tailscale serve --bg --https=8443 http://127.0.0.1:8787
NAME="$(tailscale status --json | python3 -c 'import json,sys;print(json.load(sys.stdin)["Self"]["DNSName"].rstrip("."))')"
echo "Published on your tailnet at https://$NAME:8443/machine-load.json"
