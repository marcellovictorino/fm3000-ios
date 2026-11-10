# Changes from upstream

Based on Infinitary **0.7.0-alpha.473** (installed app commit `a49d327bcc2a9adc0280d8b883d990a894b62ec4`, upstream branch commit `6ac0c81`), `ios/Infinitary`, Apache 2.0.
Before that the base was 0.6.5-alpha.403 (commit `ddbb0143092fc2824c32444daf72dccdd8259e62`), 0.6.4-alpha.337, 0.6.3-alpha.191 (commit `9687d5ac4e25e3daf4302386b79ce67827ad1fe7`) and 0.6.2-alpha.115 (commit `8421eddf0010a80709febc5ad5d8fbfd661878a1`).

Each entry says the PR, what changes for you, why, and whether the original app has the same problem at the version the entry was written against (0.6.3-alpha.191 unless it says otherwise). The upstream checks read the original app's source at that version. None of them was run on a phone.

## Identity and build

- **PR #3.** Bundle identifier `com.getinfinitary.infinitary` → `com.marcellovictorino.infinitary`, with `.tests`, `.uitests`, the `.join` URL name, the camera queue label and the Keychain labels (including the service of `ApprovalKey.swift`, added upstream in 0.7.0). Files: `Infinitary.xcodeproj/project.pbxproj`, `Info.plist`, `Simulator.entitlements`, `InfinitaryApp/CodeScanner.swift`, `InfinitaryKit/Sources/InfinitaryKit/PhoneIdentity.swift`, `InfinitaryKit/Sources/InfinitaryKit/PhoneSSHKey.swift`, `InfinitaryKit/Sources/InfinitaryKit/ApprovalKey.swift`.
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

## Tasks

- **PR #4.** A Board/List switch (opens on Board, remembers the last view) and project pills that filter both views. The board is read only, with the desktop's columns, and works in landscape. Files: new `InfinitaryApp/PhoneTaskBoard.swift`, edits to `InfinitaryApp/PhoneTasks.swift` and `InfinitaryKit/Sources/InfinitaryKit/PhoneTaskList.swift` (a `filtered(keep:aside:)` method that narrows the list to one project).
  - **Changes for you:** see where every task stands at a glance, as on the desktop, and narrow either view to one project.
  - **Why:** see where every task stands at a glance, as on the desktop, and narrow it to one project.
  - **In the original app:** the phone Tasks screen is a list grouped by state, with the project name on each row and no board and no project filter.
- **PR #6.** Kept upstream's new line saying why a brought-back card was put aside again, and show it above the board as well as the list.
  - **In the original app:** the line exists there, on the list.

## Cards

- **PR #11.** One message box at Home's foot for both the open card and the first mate. While a card that takes replies is on screen, a label above the box names the card, and the box says "anything to add?" and replies to that card's thread. Pressing the label switches the box to the first mate ("Give your first mate a task") and back. Each target keeps its own draft and photos; the first mate message still carries the open card as its hint (`visibleCardId`). With no card, or one that takes no reply, the box is the first mate's, as before. The card no longer draws its own reply field, on its face or its back; its choice buttons still send the words in the box with the choice. A new card opens with the box on the card. Files: `InfinitaryApp/MessageComposer.swift`, `InfinitaryApp/PhoneCards.swift`, `InfinitaryApp/PhoneWorkspace.swift` (the card's reply drafts and photos, and the card's send, move into `PhoneMessageContext`). The keyboard's Done now sits on the box, and a swipe down or a tap on the card closes whichever keyboard is up.
  - **Changes for you:** type once, at the foot, where the thumb already is, and choose where the words go with one press on the label.
  - **Why:** with the card's own field mid-screen and the first mate's box at the foot, I kept typing a card reply in the wrong place and pressing the wrong send arrow. I would rarely message the first mate while reading a card.
  - **In the original app:** the same layout at 0.6.3-alpha.191: the card's "anything to add?" field sits inside the card, and the box under it always goes to the first mate. For the official app's developer: two inputs on one screen with one thumb zone invite sending to the wrong one; one box with a visible target label removes the ambiguity. A suggestion, not a defect report.
  - **Not tested on a phone.** Checked in a simulator only: the box in card, first-mate and empty states with the label. The send path to a real card, choice buttons with words, and the keyboard Done were not run, as the journeys need a Mac test home.
- **PR #13.** Fix: one tap on the send arrow sends. The Done that PR #11 put above the keyboard is removed from the message box: on iOS 27 it floats as a pill over the send arrow, so the first tap only closed the keyboard. Files: `InfinitaryApp/MessageComposer.swift`.
  - **Changes for you:** type, then press send once. To put the keyboard away without sending, use Done at the left of the top bar, swipe down on the card, or tap the card.
  - **Why:** you reported pressing twice to send, first Done, then send.
  - **In the original app:** not a defect there. The original app has no Done above the keyboard on its message box, only the top bar's Done, which this build keeps.
  - **Checked in a simulator only** (iOS 27.1, a stand-in screen with the real message box): the Done pill covered the send arrow before, and the send arrow is clear after. Not tried on a phone.

- **PR #8. Retired on 9 November 2026, see "Retired" below.** While typing a card's reply, a swipe down on the card, a tap on its head or body, or Done above the keyboard closes the keyboard and keeps the draft. Files: edits to `InfinitaryApp/PhoneCards.swift`.
  - **Changes for you:** put the keyboard away mid-reply to read the card again, without losing what you typed.
  - **Why:** with the keyboard up, the card's body had no room to scroll, so nothing closed the keyboard.
  - **In the original app:** the same problem at 0.6.2-alpha.115, as you reported. At 0.6.3-alpha.191 upstream changes the card's scroll bounce for the same case (INF-2737, in the same file). That change is in this build beside these gestures. Not confirmed on a phone whether it alone closes the keyboard.
- **PR #9. Retired on 9 November 2026, see "Retired" below.** Tapping a diagram (an inline SVG drawing) opens it in the card picture viewer. The viewer pinches from 1x to 8x, pans when zoomed, and a double tap zooms in at the tap or back out. Files: new `InfinitaryApp/CardDiagramZoom.swift` (a script in its own content world inside the card body's frame, answering real taps only), edits to `InfinitaryApp/CardWebView.swift` and `InfinitaryApp/CardMediaView.swift`.
  - **Changes for you:** read the small print of a diagram or picture on a card by enlarging it.
  - **Why:** a phone screen is too small to show a diagram whole.
  - **In the original app:** the same gap at 0.6.3-alpha.191. A diagram on a card cannot be tapped open. The card body keeps zoom off (`maximum-scale=1`, pinch disabled in `CardWebView.swift`), and the picture viewer in `CardMediaView.swift` has no zoom.

## Retired

Dropped on 9 November 2026 when the base moved to 0.6.5-alpha.403 (installed app commit `ddbb014`). Both were asked for by the captain, who found upstream now does the same.

- **PR #9 (tap a diagram to zoom).** Replaced by upstream's INF-3107. At 0.6.5-alpha.403 a tapped inline diagram arrives from the card runtime as a picture of its own (`CardRuntime/cardHost.ts`), and the picture viewer (`InfinitaryApp/CardMediaView.swift`) fits it, pinches to 8x, pans, double-taps to its own size and closes on a swipe down. Removed: `InfinitaryApp/CardDiagramZoom.swift`, the fork's edits to `CardWebView.swift` and `CardMediaView.swift` (both now identical to upstream). Left out on purpose: keeping both would open the viewer twice per tap. Difference: the fork's script copied the drawing with its computed colours; upstream sends the card's own drawing source. Not run on a phone.
- **PR #8 (swipe, tap or Done closes the reply's keyboard).** Replaced by upstream's INF-3106. At 0.6.5-alpha.403 a pull down that starts anywhere on the card, a tap on the card's head or on the thread's head, and a keyboard-down circle beside send (`InfinitaryApp/PhoneHideKeyboard.swift`, `MessageComposer.swift`) put the keyboard away, and the top bar's Done stays. Removed: the fork's swipe-down gesture, body tap, head tap and the Done above the keyboard in `InfinitaryApp/PhoneCards.swift`. Not covered: a tap on the card's body no longer closes the keyboard (upstream scrolling and the pull down remain). The circle is untested against PR #13's send-arrow overlap on iOS 27; not run on a phone.

Dropped on 10 November 2026 when the base moved to 0.7.0-alpha.473 (installed app commit `a49d327`). Upstream now covers all of these.

- **PR #4, the Dark/Light choice.** Replaced by upstream's `PhoneAppearance` and `PhoneLook` (Device, Dark, Light). It starts on Device and saves under a different setting, so pick Dark once in Settings. Removed: the fork's `PhoneAppearance.swift`, `InfinitaryApp.swift` and `PhoneSettingsSheet.swift` edits (all three now identical to upstream) and `InfinitaryTests/PhoneAppearanceTests.swift`.
- **PR #5, #7 and #12, card swipe, tilt and one swipe per page.** Replaced by upstream's INF-3110, where the whole card swipes with a lean and the head's own swipe is gone. Removed: `InfinitaryApp/PhoneSwipePaging.swift` and the fork's swipe lines in `PhoneCards.swift`. Difference: upstream's swipe waits while the keyboard is up.

## Earlier client, not in this tree

These came before the rebuild in PR #3 and are not in this tree. The rebuild replaced the hand-written client with the official app's code.

- **PR #1.** Bumped the iOS contract to 12.
- **PR #2.** Built no Mac address into the app.
- **Branch `fm/remove-watch-app`** (commit `94014ee`, no PR). Removed the Apple Watch app.

## Upstream merges

- **0.6.2-alpha.115.** Imported by hand in `d858c43`. Recorded as a merge in `880f01c` (tree kept as it was), so the upstream branch is an ancestor of this branch.
- **0.6.3-alpha.191.** Merged in `c78aceb`; one conflict, in `InfinitaryApp/PhoneTasks.swift`, resolved as the Tasks entries above describe.
- **0.6.4-alpha.337.** Imported with `scripts/sync-upstream.sh`, linked with `git merge -s ours` on the 0.6.3-alpha.191 import, then merged; one conflict, in `InfinitaryApp/PhoneTasks.swift`. Upstream's rewritten Tasks list (groups, row moves, task record) is taken whole, and the Board/List switch, project pills and board are re-attached around it. Pairing with a Mac on contract 14 is not tested.
- **0.6.5-alpha.403.** Imported with `scripts/sync-upstream.sh`, linked with `git merge -s ours` on the 0.6.4-alpha.337 import, then merged; conflicts in `InfinitaryApp/CardMediaView.swift` (taken whole from upstream, PR #9 retired) and `InfinitaryApp/PhoneCards.swift` (the card's footer keeps the fork's message-box rule and drops upstream's reply field; the head keeps upstream's tap and the fork's no-swipe, PR #12). Ended cards and the card departure animation are taken as upstream has them. `swift test` and the simulator build pass.
- **0.7.0-alpha.473.** Imported with `scripts/sync-upstream.sh`, linked with `git merge -s ours` on the 0.6.5-alpha.403 import, then merged; conflicts in `InfinitaryApp/InfinitaryApp.swift`, `PhoneAppearance.swift`, `PhoneSettingsSheet.swift` (all taken whole from upstream, theme retired) and `PhoneCards.swift` (taken whole from upstream, then the message box of PR #11 re-applied: the reply draft and photos in the message context, no reply field on the face or back, the card publishes itself as the box's target only while it is the shown card). The Keychain service of the new `ApprovalKey.swift` is renamed. `swift test` (88 tests), the simulator build and `build-for-testing` pass; the iOS test targets were not run, as no iPhone simulator was available.
