# Learning this repo

A guided read for someone new to iOS and Swift. Each step says what to run and what you should see.

## 1. See it work (no phone needed)

```
./scripts/test.sh
```

You should see three sections, ending in `pass 16` for the fake Mac, `ALL 48 CHECKS PASSED` for the Swift checks, then `passed 12, failed 0`. This proves the pairing, the secure connection and every request work against a stand-in Mac.

## 2. Meet the pieces

The app talks to your Mac over a pinned, encrypted WebSocket. Read in this order:

1. `Sources/FM3000Core/Wire.swift`: the message frames and the protocol version.
2. `Sources/FM3000Core/PairClient.swift`: how a one-time link turns into a trusted device.
3. `Sources/FM3000Model/AppModel.swift`: one object that holds everything the screens show. SwiftUI redraws when it changes.
4. `Sources/FM3000UI/RootView` (in `OtherViews.swift`): the tab bar. Follow a tab into its screen: Cards, Message, Tasks, Feed, Mac.

## 3. Run it in the simulator

```
./scripts/run-simulator.sh
```

It builds the app, boots an iPhone simulator, starts the fake Mac and pairs the two. This needs `xcodegen` (`brew install xcodegen`). Without it, open `FM3000.xcodeproj` in Xcode, pick an iPhone simulator and press Run, then pair with a link from `node fake-mac/server.mjs --state /tmp/fake --invites 1`.

## 4. Change something

1. Pick a small screen, such as `ProjectPills` in `TasksView.swift`.
2. Edit it, rebuild, and look at the simulator.
3. Run `./scripts/test.sh`, then commit one change with a `type(scope): summary` message.

## 5. Put it on your iPhone

Follow "Install on your iPhone" in `README.md`. A free Apple ID app expires after 7 days; press Run again to renew it.

## Words you will meet

- **Contract**: the Mac's list of every request and answer (`contract.json`). The app and the fake Mac both obey it.
- **Pin**: the Mac's key fingerprint in the pairing link. The app refuses a Mac that does not match.
- **Fake Mac**: `fake-mac/`, a stand-in server so tests never touch your real Mac.
- **Debug launch flags**: simulator-only switches that open a given screen so a script can photograph it.
