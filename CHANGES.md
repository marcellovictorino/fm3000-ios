# Changes from upstream

Based on Infinitary 0.6.2-alpha.115 (commit 8421eddf0010a80709febc5ad5d8fbfd661878a1), `ios/Infinitary`, Apache 2.0.

Each line says what changed, then **Job:** the job to be done, for feedback to the developer.

- Bundle identifier `com.getinfinitary.infinitary` → `com.marcellovictorino.infinitary` (and `.tests`, `.uitests`, the `.join` URL name, the camera queue label, the Keychain labels): `Infinitary.xcodeproj/project.pbxproj`, `Info.plist`, `Simulator.entitlements`, `InfinitaryApp/CodeScanner.swift`, `InfinitaryKit/Sources/InfinitaryKit/PhoneIdentity.swift`, `InfinitaryKit/Sources/InfinitaryKit/PhoneSSHKey.swift`.
  **Job:** run my own build on my phone under my own Apple account, next to the official app, without the two sharing an identity or Keychain items.
- Home-screen name `Infinitary` → `InfinitaryMV` (`CFBundleDisplayName` in `Info.plist`); titles inside the app are unchanged.
  **Job:** tell my build apart from the official app when both are on the phone.
- Removed the official development team from `Infinitary.xcodeproj/project.pbxproj`; `Simulator.entitlements` uses the placeholder prefix `TEAMID`.
  **Job:** keep signing details out of the repository, so anyone can sign with their own team.
- Added `README.md`, `AGENTS.md`, `CHANGES.md`, `.gitignore` and `scripts/sync-upstream.sh`.
  **Job:** keep this copy easy to rebuild and to bring up to date with each official version.
- `docs/ios.md` is unchanged and still names the official bundle id and team.
- Not changed: the `infinitary://` URL scheme, so installing the official app too lets either open join links.
- Appearance: a Dark/Light choice in Settings, kept on the phone and starting on Dark, in place of "Follows this device's setting": new `InfinitaryApp/PhoneAppearance.swift`, edits to `InfinitaryApp/InfinitaryApp.swift` and `InfinitaryApp/PhoneSettingsSheet.swift`.
  **Job:** read the app in the look I prefer, whatever the phone's own setting is.
- Tasks: a Board/List switch (opens on Board, remembers the last view) and project pills that filter both views; the board is read only, with the desktop's columns, and works in landscape: new `InfinitaryApp/PhoneTaskBoard.swift`, edits to `InfinitaryApp/PhoneTasks.swift`. Since 0.6.2-alpha.115 the board also shows upstream's line saying why a brought-back card was put aside again.
  **Job:** see where every task stands at a glance, as on the desktop, and narrow it to one project.
- Cards: swiping the stage left or right turns to the next or previous card, as the pager arrows do (the arrows stay): new `InfinitaryApp/PhoneSwipePaging.swift`, one line added in `InfinitaryApp/PhoneCards.swift`.
  **Job:** get through a stack of cards quickly with one hand, without reaching for the small arrows.
- Added `InfinitaryTests/PhoneAppearanceTests.swift` (the appearance choice's default and persistence).
