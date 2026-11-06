# Changes from upstream

Based on Infinitary **0.6.3-alpha.191** (installed app commit `9687d5ac4e25e3daf4302386b79ce67827ad1fe7`, upstream branch commit `3e5ea9d`), `ios/Infinitary`, Apache 2.0.
Before that the base was 0.6.2-alpha.115 (commit `8421eddf0010a80709febc5ad5d8fbfd661878a1`).

Each entry says the PR, what changes for you, why, and whether the original app has the same problem at 0.6.3-alpha.191. The upstream checks read the original app's source at that version. None of them was run on a phone.

## Identity and build

- **PR #3.** Bundle identifier `com.getinfinitary.infinitary` → `com.marcellovictorino.infinitary`, with `.tests`, `.uitests`, the `.join` URL name, the camera queue label and the Keychain labels. Files: `Infinitary.xcodeproj/project.pbxproj`, `Info.plist`, `Simulator.entitlements`, `InfinitaryApp/CodeScanner.swift`, `InfinitaryKit/Sources/InfinitaryKit/PhoneIdentity.swift`, `InfinitaryKit/Sources/InfinitaryKit/PhoneSSHKey.swift`.
  - **Changes for you:** your build installs beside the official app, with its own identity and Keychain items.
  - **Why:** run my own build on my phone under my own Apple account, next to the official app.
  - **In the original app:** not a defect. The official app keeps its own identifier.
- **PR #3.** Removed the official development team from `Infinitary.xcodeproj/project.pbxproj`; `Simulator.entitlements` uses the placeholder prefix `TEAMID`.
  - **Why:** keep signing details out of the repository, so anyone can sign with their own team.
  - **In the original app:** not applicable. `docs/ios.md` is the upstream file and still names the official bundle id and team.
- **PR #3.** Added `README.md`, `AGENTS.md`, `CHANGES.md`, `.gitignore` and `scripts/sync-upstream.sh`.
  - **Why:** keep this copy easy to rebuild and to bring up to date with each official version.
  - **In the original app:** not applicable, these are this repository's own files.
- **PR #3.** Not changed: the `infinitary://` URL scheme, so installing the official app too lets either open join links.
  - **In the original app:** the same scheme, so the same overlap.
- **PR #6.** Home-screen name `Infinitary` → `InfinitaryMV` (`CFBundleDisplayName` in `Info.plist`). Titles inside the app are unchanged.
  - **Why:** tell my build apart from the official app when both are on the phone.
  - **In the original app:** not applicable.

## Appearance

- **PR #4.** A Dark/Light choice in Settings, kept on the phone and starting on Dark, in place of "Follows this device's setting". Files: new `InfinitaryApp/PhoneAppearance.swift`, edits to `InfinitaryApp/InfinitaryApp.swift` and `InfinitaryApp/PhoneSettingsSheet.swift`.
  - **Changes for you:** the app keeps the look you pick, whatever the phone's own setting is.
  - **Why:** read the app in the look I prefer.
  - **In the original app:** no choice; its Settings still says "Follows this device's setting."
- **PR #4.** Added `InfinitaryTests/PhoneAppearanceTests.swift` (the appearance choice's default and persistence).

## Tasks

- **PR #4.** A Board/List switch (opens on Board, remembers the last view) and project pills that filter both views. The board is read only, with the desktop's columns, and works in landscape. Files: new `InfinitaryApp/PhoneTaskBoard.swift`, edits to `InfinitaryApp/PhoneTasks.swift`.
  - **Changes for you:** see where every task stands at a glance, as on the desktop, and narrow either view to one project.
  - **Why:** see where every task stands at a glance, as on the desktop, and narrow it to one project.
  - **In the original app:** the phone Tasks screen is a list grouped by state, with the project name on each row and no board and no project filter.
- **PR #6.** Kept upstream's new line saying why a brought-back card was put aside again, and show it above the board as well as the list.
  - **In the original app:** the line exists there, on the list.

## Cards

- **PR #5.** Swiping a card left or right turns to the next or previous card, as the pager arrows do (the arrows stay). Files: new `InfinitaryApp/PhoneSwipePaging.swift`, one line in `InfinitaryApp/PhoneCards.swift`.
  - **Changes for you:** get through a stack of cards with one hand, without reaching for the small arrows.
  - **Why:** get through a stack of cards quickly with one hand.
  - **In the original app:** not there. Its card has pager arrows only. A new feature, not a defect.
- **PR #7.** The card follows the finger with a slight tilt, springs back on a short drag, and on a full swipe slides off while the next slides in from the other side. With Reduce Motion it fades instead. Files: `InfinitaryApp/PhoneSwipePaging.swift`.
  - **Changes for you:** see the card move as you push it.
  - **In the original app:** not there. A new feature, not a defect.
- **PR #8.** While typing a card's reply, a swipe down on the card, a tap on its head or body, or Done above the keyboard closes the keyboard and keeps the draft. Files: edits to `InfinitaryApp/PhoneCards.swift`.
  - **Changes for you:** put the keyboard away mid-reply to read the card again, without losing what you typed.
  - **Why:** with the keyboard up, the card's body had no room to scroll, so nothing closed the keyboard.
  - **In the original app:** the same problem at 0.6.2-alpha.115, as you reported. At 0.6.3-alpha.191 upstream changes the card's scroll bounce for the same case (INF-2737, in the same file). That change is in this build beside these gestures. Not confirmed on a phone whether it alone closes the keyboard.
- **PR #9.** Tapping a diagram (an inline SVG drawing) opens it in the card picture viewer. The viewer pinches from 1x to 8x, pans when zoomed, and a double tap zooms in at the tap or back out. Files: new `InfinitaryApp/CardDiagramZoom.swift` (a script in its own content world inside the card body's frame, answering real taps only), edits to `InfinitaryApp/CardWebView.swift` and `InfinitaryApp/CardMediaView.swift`.
  - **Changes for you:** read the small print of a diagram or picture on a card by enlarging it.
  - **Why:** a phone screen is too small to show a diagram whole.
  - **In the original app:** the same gap at 0.6.3-alpha.191. A diagram on a card cannot be tapped open. The card body keeps zoom off (`maximum-scale=1`, pinch disabled in `CardWebView.swift`), and the picture viewer in `CardMediaView.swift` has no zoom.

## Earlier client, not in this tree

These came before the rebuild in PR #3 and are not in this tree. The rebuild replaced the hand-written client with the official app's code.

- **PR #1.** Bumped the iOS contract to 12.
- **PR #2.** Built no Mac address into the app.
- **Branch `fm/remove-watch-app`** (commit `94014ee`, no PR). Removed the Apple Watch app.

## Upstream merges

- **0.6.2-alpha.115.** Imported by hand in `d858c43`. Recorded as a merge in `880f01c` (tree kept as it was), so the upstream branch is an ancestor of this branch.
- **0.6.3-alpha.191.** Merged in `c78aceb`; one conflict, in `InfinitaryApp/PhoneTasks.swift`, resolved as the Tasks entries above describe.
