# Changes from upstream

Based on Infinitary 0.6.2-alpha.47 (commit c1e941529438207bf1cca34c437df3c2e9d80477), `ios/Infinitary`, Apache 2.0.

- Bundle identifier `com.getinfinitary.infinitary` → `com.marcellovictorino.infinitary` (and `.tests`, `.uitests`, the `.join` URL name, the camera queue label, the Keychain labels): `Infinitary.xcodeproj/project.pbxproj`, `Info.plist`, `Simulator.entitlements`, `InfinitaryApp/CodeScanner.swift`, `InfinitaryKit/Sources/InfinitaryKit/PhoneIdentity.swift`, `InfinitaryKit/Sources/InfinitaryKit/PhoneSSHKey.swift`.
- Removed the official development team from `Infinitary.xcodeproj/project.pbxproj`; `Simulator.entitlements` uses the placeholder prefix `TEAMID`.
- Added `README.md`, `AGENTS.md`, `CHANGES.md`, `.gitignore` and `scripts/sync-upstream.sh`.
- `docs/ios.md` is unchanged and still names the official bundle id and team.
- Not changed: the `infinitary://` URL scheme, so installing the official app too lets either open join links.
- Appearance: a Dark/Light choice in Settings, kept on the phone and starting on Dark, in place of "Follows this device's setting": new `InfinitaryApp/PhoneAppearance.swift`, edits to `InfinitaryApp/InfinitaryApp.swift` and `InfinitaryApp/PhoneSettingsSheet.swift`.
- Tasks: a Board/List switch (opens on Board, remembers the last view) and project pills that filter both views; the board is read only, with the desktop's columns, and works in landscape: new `InfinitaryApp/PhoneTaskBoard.swift`, edits to `InfinitaryApp/PhoneTasks.swift`.
- Added `InfinitaryTests/PhoneAppearanceTests.swift` (the appearance choice's default and persistence).
