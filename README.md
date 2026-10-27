# Infinitary for iPhone

> **Status: prototype.** A personal project, not an Anthropic or Infinitary release. It needs a running Infinitary Mac app to pair with, and is built against its protocol 12.0.0. Expect rough edges.

A single-user iPhone app that attaches to your running Infinitary over Tailscale. It shows the open cards, lets you choose a card's action (with words from the "anything to add?" field), reply under it, put a card aside for later (swipe right, or the button in the card; the same fact the Mac keeps, so it leaves the Mac's stack too and returns when its crewmate changes it), send Firstmate a message, and read the task board (a program is one tile) and feed. It learns the Mac's updated private-network addresses on each connection. It is a paired device of your Mac, as another Mac's window is: no relay, no account, no hosted service.

Built against Infinitary (the renamed Firstmate 3000), protocol 12.0.0 (`docs/contract.json` inside the app bundle; a copy is committed as `fake-mac/fixtures/contract.json`). The Mac now gives full access only to its own protocol major (`majorsBehind` is 0): after a major Infinitary update the app drops to read-only until it is updated to the new contract.

## What is here

| Path | What |
| --- | --- |
| `Sources/FM3000Core` | Pairing link, SPKI pin, the phone's own ECDSA P-256 key and self-signed certificate, TLS 1.3 dial with pin check, `/pair`, the `/connection` WebSocket, wire models |
| `Sources/FM3000Model` | `AppModel`: pairing, connect and reconnect with cursor, every request the screens make |
| `Sources/FM3000UI` | SwiftUI screens: Pair, Cards (detail, actions, reply), Message, Tasks, Feed, Mac |
| `Sources/FM3000WatchLink` | What the phone and the Apple Watch say to each other: the cards waiting on you as plain text, and three requests (list, choose, put aside) |
| `WatchApp/` | The Apple Watch app: lists the cards waiting on you, shows each body as text to scroll, one button per choice and Put aside. It asks the phone over WatchConnectivity, never the Mac; no words, alerts or complication |
| `App/`, `project.yml` | The app shell; XcodeGen writes `FM3000.xcodeproj` from `project.yml` |
| `mac-feed/` | The Mac-side Machine load job: a launchd agent samples CPU, GPU and memory every 3 seconds and `tailscale serve` publishes the latest JSON to your tailnet only. `./mac-feed/install.sh` starts it, `./mac-feed/uninstall.sh` removes it. Others > Panels > Machine load reads it (fresh within 15 s), and falls back to Infinitary's own readings with a visible note when it is unreachable or stale. The phone finds the feed by itself: it asks MagicDNS for the name of the paired Mac's Tailscale address and reads `https://<that name>:8443/machine-load.json`. An address typed under Others > Panels > Machine load > Live feed address overrides it (it is the `machineFeedURL` default, so the launch argument `-machineFeedURL <url>` also works) |
| `fake-mac/` | A fake Mac that follows the contract (every request and answer is checked against the committed `fake-mac/fixtures/contract.json`; set `FM3000_CONTRACT` to check against another copy, such as the one inside the installed app) |
| `scripts/` | `test.sh`, `e2e.sh`, `doctor.sh`, `run-simulator.sh`, `install-device.sh`, `archive-testflight.sh` |

## Install on your iPhone with a free Apple ID (no paid program, no TestFlight)

A free Apple ID gives a "Personal Team". Xcode signs the app with it and installs it over a cable. Limits: the app stops opening after 7 days (run the install again to renew it), at most 3 such apps at once, no TestFlight. Nothing else about the app differs.

1. `./scripts/doctor.sh` lists what is missing. You need Xcode (license accepted, `sudo xcodebuild -license accept`), `brew install xcodegen`, Tailscale running.
2. Xcode > Settings > Accounts > + > Apple ID: sign in with your normal Apple ID. A "Personal Team" appears.
3. On the iPhone: Settings > Privacy & Security > Developer Mode > on (it restarts the phone). Connect the phone by cable, unlock it, tap Trust.
4. Install the Tailscale app on the iPhone, sign in to the same tailnet as the Mac, and switch it on.
5. Make the project: `FM3000_BUNDLE_ID=com.yourname.fm3000 ./scripts/generate-project.sh` (the bundle id must be one nobody else has used; the default is `com.<your user>.fm3000`).
6. Open `FM3000.xcodeproj`. Select the FM3000 target > Signing & Capabilities > Team: your Personal Team. Choose your iPhone at the top and press Run. (Or from a terminal: `FM3000_TEAM_ID=<id> ./scripts/install-device.sh`.)
7. First launch: on the phone open Settings > General > VPN & Device Management > your Apple ID > Trust, then open Infinitary.
8. Every 7 days press Run again before it expires. Your pairing survives a re-install over the old app; if iOS removes the app you pair again.

### Pair it with your Mac

1. On the Mac: Infinitary > Settings > Devices > **A phone**. It shows a QR code and a Copy link button. Scan the code with the iPhone camera (it opens this app, which shows the address for you to confirm) or paste the copied link. The link works once and for ten minutes.
2. Copy it and get it to the phone (Universal Clipboard works: copy on the Mac, paste on the phone; or AirDrop or Notes).
3. In the app: paste the link, "Review and pair", read the address it names, Pair. The app checks the Mac's key against the link's pin before it sends anything, then joins.
4. The link names addresses the Mac listens on. Reaching the Mac over Tailscale needs one of them to be the Mac's Tailscale address (`tailscale ip -4`, a `100.x.y.z` address). If the pairing says it could not reach the Mac, edit the host part of `at=` in the pasted link to that address and try again with a fresh link.

### If the phone is lost

On the Mac: Infinitary > Settings > Devices > remove the phone. It is cut off at once; its key is useless after that. Words typed on the phone count as yours, so do this promptly. "Forget this Mac" in the app's Mac tab does the same from the phone.

## What was verified, and what was not

Run everything that needs no phone: `./scripts/test.sh`.

- **Fake Mac against the contract** (`fake-mac`, 16 tests): the pairing statuses, Origin refusal (403), 401 for an unpaired key, 404, hello and welcome, replay by cursor, read access for an older major, argument checks, all against `contract.json`.
- **Swift checks** (`fm-checks`, 48 checks): link parsing as the Mac builds it, the SPKI pin against openssl's, the phone's certificate verified by openssl, chunked `/pair` answers, wire frames, the client's request matching, push de-duplication, 4401 handling and the app forgetting the Mac.
- **End to end** (`scripts/e2e.sh`): the app's own model pairs with the fake Mac and runs cards, act, reply, converse, board, feed, a pushed card, reconnect with replay, unpair, over real TLS 1.3 and a real WebSocket through Network.framework. The fake confirms: TLS 1.3, client certificate pin, hello protocol `12.0.0 / view / ios / arm64`, and no Origin header on any request.
- **Apple Watch** (simulators, Xcode 27.1): an iPhone 17 and an Apple Watch Series 12 simulator, paired with `xcrun simctl pair`, against the fake Mac. The watch listed both waiting cards through the phone, showed a body as text, put a card aside and chose Merge; the fake Mac logged each. The phone's side of the service also runs in `fm-probe`. Debug builds take `-openCard <n>`, `-scrollEnd`, `-pressChoice <n>` and `-pressAside` on the watch, since a script cannot tap a simulated watch.
- **Simulator**: `./scripts/run-simulator.sh` builds the app for the iOS simulator, installs it and pairs it with the fake Mac. It paired and showed the cards.

Not verified, because it needs your real Mac or your phone:

- Pairing with the real Firstmate 3000. No link existed, so nothing was sent to it. Use the app, or `swift run fm-probe --state /tmp/p pair '<link>'` first (it uses the link up; make another for the phone).
- Whether the Mac raises a "Finish setting up" card for a phone paired as a computer. The app pairs as `kind: mac` and connects only as a view. If a card appears, choose "Not now"; it never runs work for the phone.
- iOS WebSocket Origin behaviour on a real iOS device. Network.framework sent no Origin on macOS and in the simulator; a real phone uses the same stack.
- Whether iOS reaches the Mac's `100.x` address without a local network prompt (it should not ask). The app declares a local network usage string in case it does.
- Card pictures, live forms and scripts. Card bodies are drawn as HTML with the desktop stylesheet (headings, colours, tables, SVG), without scripts or pictures. Actions that open a window on the Mac (settings, browser) answer "needs your Mac's window".
- A real Apple Watch (Series 9, watchOS 27.0.1): it needs Developer Mode on the watch (Settings > Privacy & Security) and Trust, then the iPhone install above also installs the watch app. Whether a watch message wakes the phone app in the background was not shown: in the simulator the phone app has to be running.
- The identity lookup on a real iPhone (the simulator exercises the same code).

## TestFlight (optional, needs the paid Apple Developer Program)

Only if you later want builds that do not expire after 7 days or want to share the app.

1. Enrol at developer.apple.com/programs and wait for approval; in App Store Connect create an app with your bundle id.
2. `FM3000_TEAM_ID=<paid team id> FM3000_BUNDLE_ID=<id> ./scripts/archive-testflight.sh` archives and exports `build/testflight/export/FM3000.ipa`, and stops before any sign-in or upload.
3. Upload the `.ipa` with the Transporter app (App Store Connect sign-in), or in Xcode's Organizer choose Distribute App.
4. In App Store Connect > TestFlight add yourself as an internal tester; install the TestFlight app on the phone, accept the invite, install. Builds last 90 days.

## Safety

- The phone's private key is made in, and never leaves, the iOS Keychain. The Mac keeps only its pin.
- Tests and the probe use a scratch keychain file in a temporary folder, never your keychains. No Apple sign-in, no upload, nothing pushed.
- The debug-only `-pairLink` launch argument (simulator runs) is compiled out of release builds.

## Licence

MIT, see `LICENSE`. `Sources/FM3000UI/CardStyle.swift` is generated from Infinitary's design styles.

## Usage counters

The app counts what you use, on the phone only: `usage.json` in the app's Application Support folder holds `{day: {event: count}}` (no text, titles, names or ids), kept 90 days. Others > Usage shows 7 or 30 days and exports the file as JSON. Events are recorded with `UsageLog.shared.record("name")`.
