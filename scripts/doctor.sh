#!/usr/bin/env bash
# Says what is still missing on this Mac before the app can be built and installed. Changes nothing.
cd "$(dirname "$0")/.."
ok() { echo "  ok   $1"; }
no() { echo "  TODO $1"; todo=1; }
todo=0
echo "Mac"
[ -d /Applications/Xcode.app ] && ok "Xcode is installed" || no "Install Xcode from the Mac App Store"
if xcodebuild -license check >/dev/null 2>&1; then ok "Xcode license accepted"; else no "Accept the license: sudo xcodebuild -license accept"; fi
if xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then ok "Xcode first-launch tasks done"; else no "Run: xcodebuild -runFirstLaunch"; fi
if xcrun simctl list runtimes 2>/dev/null | grep -q "iOS"; then ok "an iOS simulator runtime is installed"; else no "Xcode > Settings > Components: download the iOS platform"; fi
if command -v xcodegen >/dev/null 2>&1; then ok "xcodegen is installed"; else no "brew install xcodegen"; fi
command -v node >/dev/null 2>&1 && ok "node is installed (for the fake Mac)" || no "Install node (the fake Mac and its tests need it)"
echo "Phone"
if xcrun devicectl list devices 2>/dev/null | grep -qi "connected\|available"; then ok "an iPhone is connected"; else no "Connect your iPhone by cable, unlock it and tap Trust (Developer Mode: Settings > Privacy & Security)"; fi
echo "Tailscale"
if command -v tailscale >/dev/null 2>&1 && tailscale status >/dev/null 2>&1; then ok "Tailscale is running on this Mac: $(tailscale ip -4 2>/dev/null | head -1)"; else no "Start Tailscale on this Mac"; fi
exit $todo
