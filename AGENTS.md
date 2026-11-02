# AGENTS.md

iPhone app for Infinitary: the official app, lightly customised. `README.md` covers building and syncing.

## Branches

- `upstream`: pristine copy of the installed app's `ios/Infinitary`, `LICENSE`, `NOTICE` and `docs/ios.md`, one commit per Infinitary version, made only by `scripts/sync-upstream.sh`. Never edit it by hand.
- `main`: `upstream` plus my changes (listed in `CHANGES.md`). Bring a version in with `git merge upstream` (merge commit, never squash or rebase). Resolve conflicts in favour of upstream unless the change is listed in `CHANGES.md`.
- `archive/fm3000`, tag `fm3000-final`: the earlier hand-written client. Leave alone.

## Rules

- Every file I change from upstream is added to `CHANGES.md` (Apache 2.0 requires marking changes). Keep `LICENSE` and `NOTICE`.
- Never commit an Apple team id or a Mac's address. Pairing supplies the address.
- Upstream docs are in `docs/ios.md`; read them before changing behaviour. The wire contract is the Mac's `docs/contract.json`.
- Ask the captain before any Apple sign-in, upload, archive or release.
- Commit atomically as `type(scope): summary`.

## Checks

- `swift test` in `InfinitaryKit` (23 tests, no phone needed).
- `xcodebuild build -project Infinitary.xcodeproj -scheme Infinitary -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO`
- Upstream's own test targets: `InfinitaryTests`, `InfinitaryUITests` (need an iOS simulator runtime).
