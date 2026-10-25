#!/usr/bin/env bash
# Stops the feed, unpublishes it from the tailnet and deletes only the files install.sh created.
set -euo pipefail
LABEL=com.marcellovictorino.fm3000.machine-load
tailscale serve --https=8443 off || true
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
rm -f "$HOME/Library/Application Support/fm3000-machine-load/machine_load_feed.py" "$HOME/Library/Application Support/fm3000-machine-load/feed.log"
rmdir "$HOME/Library/Application Support/fm3000-machine-load" 2>/dev/null || true
