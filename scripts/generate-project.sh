#!/usr/bin/env bash
# Writes FM3000.xcodeproj from project.yml. Signing values come from the environment:
#   FM3000_BUNDLE_ID  must be unique to you on Apple's servers (default: com.$USER.fm3000)
#   FM3000_TEAM_ID    your Apple team id; leave empty and pick the team in Xcode instead
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodegen >/dev/null || { echo "Install xcodegen first: brew install xcodegen"; exit 1; }
export FM3000_BUNDLE_ID="${FM3000_BUNDLE_ID:-com.$(whoami | tr -cd 'a-z0-9').fm3000}"
export FM3000_TEAM_ID="${FM3000_TEAM_ID:-}"
echo "Bundle id: $FM3000_BUNDLE_ID   Team: ${FM3000_TEAM_ID:-(choose in Xcode)}"
xcodegen generate
