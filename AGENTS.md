# AGENTS.md

iPhone client for Infinitary (a paired view of the user's Mac). `README.md` covers install, pairing and what was verified; this file covers how to change the code.

## Gate

`./scripts/test.sh` is the gate: fake-Mac contract tests, `fm-checks`, then an end-to-end run. Keep it green; it needs no phone and no real Mac.

- Add a check to `Sources/fm-checks/main.swift` (pure logic) or a step to `Sources/fm-probe/main.swift` (talks to the fake Mac); there is no XCTest.
- Show a UI change in the simulator before committing: build with `xcodebuild … -destination "platform=iOS Simulator,id=<udid>"` (see `scripts/run-simulator.sh`), then `xcrun simctl io <udid> screenshot <file>`.

## Layers

`FM3000Core` (wire, models, TLS, pairing) → `FM3000Model` (`AppModel`, every request) → `FM3000UI` (SwiftUI). `FM3000CardWeb` (WebKit only) sets up the card body's web view and reports its content height, so a check can load a real page. `App/` and `project.yml` are a thin shell; `FM3000.xcodeproj` is generated and gitignored.

## Contract

- The Mac's `docs/contract.json` (inside `/Applications/Infinitary.app/Contents/Resources/self-source/docs`) is the source of truth; `fake-mac/fixtures/contract.json` is the committed copy the gate reads. Refresh it from the app when the contract changes, or run with `FM3000_CONTRACT=<path>` for channels and shapes. Read it before adding a request; never guess a field.
- `fake-mac/` validates every request and answer against that file. Teach it the new channel in the same commit as the client code.
- `Wire.protocolVersion` must match the Mac's major; the Mac drops a stale major to read-only.
- `/pair` needs `system: "ios"`.
- A feature the contract cannot express (voice notes, card pictures) is listed as a gap, never faked.

## Card bodies

Card bodies are HTML. `CardBody` draws them in a script-free web view with `CardStyle.css`, generated from the desktop's token and frame stylesheets (dark only). Regenerate it from `src/renderer/src/design/tokens/*.css` and `plugins/frames/frameStylesheet.ts` when the desktop look changes. `HTMLText.plain` stays for one-line previews.

## Simulator launch flags (Debug only)

`-pairLink <link>`, `-startTab <n>`, `-openDetails` (opens a card body's expandable sections), `-askClose` (shows the Close question), `-openCard`, `-openThread`, `-openTask`, `-layout board`. Reset a stale pairing with `xcrun simctl keychain <udid> reset`.

## Hard limits

- Run tests and probes under a scratch `HOME`; the real keychains stay untouched.
- Ask the captain before any Apple sign-in, upload, archive or release; the repo is public at `origin` (github.com/marcellovictorino/fm3000-ios), and pushing to `main` is standing direction. Leave `origin/design/refresh` alone.
- Commit atomically, one concern per commit, as `type(scope): summary`.
- `xcodegen` is not installed on this Mac, so `generate-project.sh`, `run-simulator.sh` and `install-device.sh` cannot run until `brew install xcodegen`. The generated `FM3000.xcodeproj` is gitignored, so a fresh clone has to run `generate-project.sh` before building the app.
