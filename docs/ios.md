# Infinitary on iPhone and iPad

The native SwiftUI app lives in `ios/Infinitary/`, supports iPhone and iPad from iOS 18, and reads a Mac through the published connection contract.
Its name is Infinitary, its bundle identifier is `com.getinfinitary.infinitary`, and its Xcode development team is `9T2J7MNUP9`.
The phone is a view of the Mac, not a separate first mate or a place that runs work.
It shows interactive cards on Home, with Tasks and Activity on their own tabs, sends the captain's messages and photos, and lets the captain start, continue, steer and interrupt work on the Mac.
The version-dispatched TestFlight workflow and the square app icon support internal delivery; App Store distribution and background notifications remain separate work.
The visual rules live in the design skill's `components/devices/PhoneView.prompt.md`.

## Joining and trust

Settings → Devices → **A phone** on the Mac opens a locally generated QR code, the same one-use computer link, Copy link and Stop it.
Every build of the Mac app offers **A phone**, installed and development alike (`docs/devices.md`, "Settings -> Devices").
The panel explains whether its link prefers a detected private-network address, with local fallbacks, or offers local addresses only.
Both devices need a permitted private-network route, and the computer must stay awake with Infinitary open; a detected address proves neither reachability nor the service that supplied it.
MagicDNS discovery and broader VPN or IPv6-only private-address discovery are not included.
The panel explains that the phone app comes from TestFlight for now, only to the people asked to test it, and is not in the App Store yet.
A phone can scan that code, paste its link or open an `infinitary://join` link, then confirms the address of the Mac it is joining.
On a computer with no screen at hand, `infinitary link --phone` prints the same code and link in its terminal, from the Infinitary running there (`docs/run.md`, "A link by command").
Its first screen welcomes the person in the Mac's first-launch words, “Welcome aboard Infinitary”, with the three ways in, Scan the code, Paste its link and Join by its address, as rows in one list and Nearby as one plain line under it.
Nearby browses `_infinitary._tcp` and opens the scanner; an announcement supplies a possible address, never a key or permission.
The computer, a Mac or a Linux home with Avahi, announces while a usable direct computer invitation is open as well as while a phone is on its list, so first-phone discovery works (`docs/devices.md`, "Announcing to a phone").
Camera and Local Network permissions have separate explanations; a camera refusal offers pasting rather than reading the clipboard automatically.

`InfinitaryKit` owns strict link parsing, the device identity, pinned transport and the view session (`ReadOnlySession`, the foundation’s original type).
`PhoneIdentity` creates a P-256 signing key and a self-signed certificate, with Apple's `swift-certificates` package supplying the certificate encoder.
The private key and certificate live in this app's iOS Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` and synchronization disabled, not in iCloud, a shared group or the Secure Enclave.
If the key exists without its certificate, the app issues a certificate for that same key rather than rotating or abandoning the identity.
The certificate's public key hashes to the same SHA-256 SPKI pin the Mac owns (`docs/devices.md`, "Keys").
The Mac's identity is that pin, not the self-signed certificate's name or dates.

`PinnedTransport` uses an ephemeral URLSession, TLS 1.3, the phone's client identity and the exact saved or scanned server pin, with no cookies, credential store, proxy configuration, cache or redirects.
The app turns off iOS's transport security (`NSAllowsArbitraryLoads`), because iOS counts a Tailscale address (`100.64.0.0/10`) as not local and fails the Mac's self-signed certificate there even after the pin matches (INF-1903); `NSAllowsLocalNetworking` would bring that failure back, and iOS ignores `NSAllowsArbitraryLoads` beside it.
`PinnedTransport` is the app's only URL session, and card web views load only local content.
An App Store submission or external TestFlight build must give Apple a written reason for that setting: the app trusts only the Mac's pinned key, over TLS 1.3 with the phone's own key, and no narrower setting can name a person's own Tailscale address.
`PhoneTransportSecurityTests` joins and reconnects at `127.1`, a loopback form iOS also counts as not local, under the app's own Info.plist.
Pairing has short request deadlines; the socket uses a separate configuration whose deadlines outlast its heartbeat, not the pairing POST's timeouts.
A join sends the invitation's kind and `system: "ios"`; the Mac returns HTTP 201 and kind `view` regardless of that invitation's computer kind.
Before spending the invitation, a pinned, non-mutating `GET /connection` must return 426 from a reachable candidate.
Private IPv4 candidates in `100.64.0.0/10` come first, followed by local names and addresses; an unavailable preflight, including a timeout, may try the next candidate.
A wrong pin ends the attempt without sending the invitation, and once a candidate answers preflight the pairing POST never moves to another candidate.
A timeout or missing reply never repeats a pairing request: the Mac may already have spent its code.
An explicit `paired` refusal leaves a fresh invitation unspent, so that one confirmed invitation may use `again` once to recover the same phone identity.
A wrong pin never sends the invitation to that address or replaces the saved pin.

The only saved app record is `JoinedMac.json`: public Mac addresses, pin, device identifier and name.
It has file protection and is excluded from backup; no invitation code, card, feed line or cursor is saved there.
The Keychain identity survives relaunch, Leave and local Forget; it is never replaced because the network is unavailable.
Protected identity and saved-Mac reads start on activation, not prewarm, and a failed read is retried on activation or joining with a visible explanation if it still fails.
A saved-Mac read suggests unlocking only for `CocoaError(.fileReadNoPermission)` or unavailable protected data; other temporary read failures retain the record and offer another attempt.
An undecodable record, invalid pin or invalid address discards only the saved Mac, retains the phone's identity, explains the local reset and allows a fresh confirmed link.

### Joining by its address

**Join by its address** opens one field for the account and the computer, such as `kun@studio`, and an optional port, 22 when empty (INF-1183).
Under them the sheet lists the computers on this network with Remote Login on (INF-1312): `NearbyComputers` browses `_ssh._tcp` while the sheet is typing and the app is in front, as the Mac's own By its address list does (`src/shared/nearbyMacs.ts`), and stops when the sheet closes, a join starts or the app leaves the front.
A row names the computer and the host it resolved to; with a Your account field filled above the list, a tap fills the whole address and the port, and Continue signs in as a typed address does.
An announcement says where to try, never who to trust: the first sign-in still asks for the fingerprint.
When iOS has not let the app use the local network the list says to allow Local Network in Settings, and when it cannot look it says an address can still be typed.
A plain line under the list offers to look at every address on this network; only after the yes in its alert does the phone try each other address of its own private IPv4 network on port 22, at most the 254 around it and a few at a time, and lists each one that answers with an SSH banner.
The app's `NSBonjourServices` names `_ssh._tcp` beside `_infinitary._tcp`, and its local network sentence says it lists those computers.
The phone signs in to that computer over SSH with SwiftNIO SSH (`SSHJoin`), runs one fixed command there and joins with the one-use phone link the open Infinitary answers, as with a scanned code; SSH carries only the joining, and every connection after it is the pinned connection above.
The commands are the home's own text, generated into `PhoneSSHCommand` from `src/shared/phoneLink.ts`, and the home's side is `docs/devices.md`, "A phone that joins by its address".
The first sign-in to an address shows the computer's SSH fingerprint, as `ssh-keygen -l` prints it, and asks once: **Not this one** sends nothing, and the yes is kept in `TrustedHomes.json` by address and port.
A different key at that address later stops the join before the phone signs in or sends anything.
The phone signs in with its own key first: a P-256 key in the Secure Enclave where the phone has one, otherwise (a simulator) in this app's Keychain, this device only, never synchronized (`PhoneSSHKey`).
When the computer refuses that key but takes a password, the phone asks for the account's password there once and signs in with it only to run the command that adds the phone's public key to that account's `~/.ssh/authorized_keys`; it then signs in again with the key.
The password is never saved, shown or sent anywhere else; SwiftNIO SSH holds it as a string, so the phone cannot zero its bytes after use.
Beside the password, **Copy this phone's key** copies the public key line, shown in full, for an account that takes no password; **Try again** signs in again once it is added.
The link is never shown: the phone joins with it at once, trying the typed address first at the link's port, then the link's own addresses, and keeps the typed address among the saved alternatives.
The join never repeats an uncertain pairing request, as above.
Each refusal is said in plain words: the computer not reached, Remote Login off (every connection refused), the key refused, a wrong password, Infinitary not open, Infinitary there too old, and the phone too old for the home's answer.
SwiftNIO SSH has no keyboard-interactive sign-in, so a computer that takes passwords only that way takes the copied key instead.

## Reading and returning

The session sends a view hello and its current in-memory epoch/sequence cursor, then reads cards, Activity, the task board and the last turn.
The generated `PhoneRequest` limits the additional requests to the published view channels and derives their read/change distinction and message limits from the contract.
Activity shows the newest line at the bottom, as on the Mac, and uses the Mac's feed wording, not a second event-to-words implementation.
Each line is one row: its dot, its task key, its words cut with an ellipsis and its age (INF-1845).
Tapping a row opens the line's summary with the whole words and its exact time; tapping a key on the board opens that task's record.
The list opens at the bottom and follows a new line while the reader is at the bottom, as a chat does; a reader scrolled up stays where they are.
The native contract constants are generated from `docs/contract.json` with `node scripts/generate-phone-contract.ts`.
`pnpm generate:contract` updates them together, and `pnpm check` refuses stale native constants, theme values or bundled card code and fonts.
Generation also verifies the required native fields in cards, Activity, task boards, records, search, last turns and crewmate transcripts, including the pushed card and task snapshots.
The shown card reads its thread once and follows numbered `inf:cards:thread` pushes; a newer push supersedes an older thread read.
Its card requests are a closed enum generated from the published contract, not a channel an HTML body chooses.

A return consumes numbered replay pushes, or reads fresh snapshots after a reload welcome.
All four initial snapshots must arrive before the app says **In reach**.
A card or task-board push supplies the new snapshot directly and supersedes any older initial read still in flight.
A task-board delta folds onto the board the app holds, as the Mac’s `applyTaskBoardDelta` does (`PhoneBoard.applying`), because a full read of a large board on every task change stalled the crew scene on the main thread (INF-1854).
Only a delta whose base is not the board held requests a coalesced full board, the published resynchronization path.
Only a closed list of non-streaming events that can change the feed requests a coalesced feed refresh; assistant and thinking deltas cause no reads.
The feed owner exports `FEED_EVENT_TYPES`, with its authoring switch checked exhaustively against that list, and the contract generator derives the Swift `FeedChange` enum from it.
A gap in numbering drops the cursor and reconnects rather than silently losing updates.
Successful frames and pongs update the last-heard time; bounded handshake, welcome, read, Leave and heartbeat waits cut a stalled connection.
The watchdog starts before sending hello and cancels the transport too, so a stalled TLS handshake does not inherit the socket's longer lifetime.
The app keeps only its in-memory view while out of reach and shows its last-heard time.
Out of reach is said once, by the reach line under the top bar with the time the computer was last heard; the message capsule and a card's reply row dim, and `changesOffLine` puts the Mac's own words (`changesOffWords`, `src/renderer/src/devices/viewWords.ts`) under the message box.
`ReadOnlySession.returns` counts the times the computer came back in reach after a failed attempt, so the app can mark a return without mistaking the ordinary reconnection when it opens for one.
A trip to the background keeps the connection for the background time iOS gives the app (INF-1528), so a short trip away comes back in reach on the same connection, with what changed meanwhile already read.
When iOS ends that time, the app cancels the connection generation before it is suspended, and activation starts it again; an inactive scene such as Control Center does not disconnect.
A late callback from an old connection cannot clear or overwrite a newer connection.
Nearby addresses may be tried with the original pin.
Each reconnect orders the saved and nearby alternatives with private IPv4 candidates first, without letting a successful local fallback permanently reverse that preference.
The authenticated welcome may carry `addresses`, which refreshes the saved alternatives without changing the phone identity or home pin, erasing local fallbacks or interrupting the working socket.
An older home that omits the field leaves the saved alternatives unchanged.
The computer sheet displays the last authenticated address actually reached, separately from the saved preference; before any successful connection it shows no reached address.

Leave is available in reach and asks for confirmation, sends the connection's Leave frame, waits for removal and forgets the saved Mac.
Out of reach, **Forget this computer** asks for confirmation and clears the saved Mac and pin locally without claiming the Mac removed the phone.
Both choices live in the computer's sheet, opened by the top bar's right-hand computer button or Command-I; neither is an always-visible destructive toolbar action.
That button is the computer glyph, with a dot in the warning color at its corner only while the computer is out of reach, and VoiceOver reads the reach as its value; the computer's name is in the sheet, not the bar.
A removal close or repeated authenticated refusal clears cards and feed, forgets the Mac, and offers joining with a new link on a screen shaped like the first one, with one prominent Join again.
A failed address with no HTTP response does not erase an earlier authenticated refusal; a welcome or a different HTTP response does.
Neither reconnection nor discovery queues or retries a mutation.

## Cards on the phone

`PhoneCards(session:)` is the card-stage integration point: it fills its available column without adding navigation, a toolbar or the app's message box.
It keeps one shown card with a next-card peek and a lower pager of two chevrons around the count, whose menu lists the current titles.
With no current card the stage shows the character alone, as the Mac does, and the pager hides.
Shift-Command-[ and Shift-Command-] turn one page per press, as `cards.previous` and `cards.next` do on the Mac, and a sheet keeps them from the stage behind it (INF-1753).
They are UIKit key commands on the window's root view controller with `repeatBehavior` `.nonRepeatable`, because a page turn builds the next card's web view and can hold the main thread past UIKit's key repeat delay, and SwiftUI's shortcuts repeat even with `buttonRepeatBehavior(.disabled)`.
Before iOS 26 UIKit offers no way to stop that repeat.
The stack follows the Mac's stage rule (`onStage` in `src/shared/cards.ts`): a new card awaiting its author's close-out stays out of the stage, pager and unread count until it is released.
A replied-under card carrying `sentBackAt` keeps its place while its author answers.
A card minimized on any Mac leaves the phone's stack and count, and waits in Tasks, as on the Mac (INF-1517).
A tap on its row there sends `inf:cards:minimize` with `false`, which brings it back on every Mac too, and shows it on Home.
A card is one framed surface that fits the stage: its head stays at the top, its choices stay at its foot, and the body, attachments and thread scroll between them in one native scroller.
The surface is the Mac's raised card (`PhoneCardSurface`): a solid fill, its thin edge, the light line inside its top and its drop shadows, read from the Mac's `--acrylic-shadow` by `scripts/generate-phone-theme.ts`; the next card's sliver is raised the same way.
The body's web view never scrolls, zooms or adds insets of its own; it takes its content's height inside that scroller, so there is only one scroll and nothing runs past the card's rounded frame.
Until the body reports drawn, its web view is a 48-point placeholder that clips the body, so native code keeps the web view one closed accessibility element that takes no taps until it has laid the view out at the body's height.
The page itself never hides the body: on iOS 27.0, a frame hidden from accessibility inside the page stays hidden after it is shown (INF-1651).
Native code reveals the body from the web view's own layout once its bounds hold the drawn height, never from the SwiftUI update that reads it, which runs before that layout; the footer choices enable at the same moment (INF-1574).
The page tells the body's bridge that its pictures can arrive late (`latePictures` on `initialize`), so the body reports drawn once the fonts its layout asked for are in.
WebKit's `document.fonts.ready`, which the bridge waits for otherwise, resolves only after the page's load event, and that waits for every picture; a picture waiting for its computer to come back in reach would keep the body's words clipped and out of accessibility (INF-1562).
On a short stage, such as an iPhone on its side, where the pinned head and choices would take more room than the body keeps, the whole card scrolls in that one scroller instead.
The session keeps which offers the stage drew while the person could see it, so the next chevron's dot marks an unread card ahead.
Swiping the native head pages cards without capturing the body's horizontal form and canvas gestures.
Ordinary arrivals keep the shown card in place; a new `holdsPlace` card comes forward, and a departure chooses an unread card before the first card.
On Home, unread cards besides the shown one are counted beside the pager ("1 new"), and a press shows the first of them; the new-card pill shows only on the other tabs, while a reply's pill shows on every tab.
Form and reply drafts live only in memory and survive paging.
Native controls own the head, footer choices and reply field; a body cannot draw over or press them.
The head draws the Mac's: the kind (Attention in the danger color), Review finding, the task's key in mono, where the task runs, the model chip and the risk, then the title and the revised line; it names no sender.
The task's key opens its record on Tasks, or in the sidebar beside the stage.
A merge card's risk, on a merge card, a past merge card or a self-merge note, is a row of seven dots in the levels' colors, and a press opens a sheet naming each dimension, its level's words and the crewmate's why.
Put aside (a minus before the close, ⇧⌘M from a keyboard) sends `inf:cards:minimize` with `true`; the core brings the card back when it changes.
On an iPad the head also maximizes the card to the stage's whole width.
The close asks first, in the Mac's words (`closeQuestionWords.ts`), while picks or typed words would be discarded, or while the captain's reply waits on its answer, which offers Put aside instead.
VoiceOver reads the close's and put aside's rest words as their hints.
The words a phone card shows come from the Mac's owners through `PhoneCardWords.generated.swift`, written by `scripts/generate-phone-contract.ts`.
The footer choices are the Mac's row (`PhoneChoiceStyle` in `PhoneChoiceRow`): rounded rectangles with 16-point words, drawn about 37 points tall inside a 44-point touch area, each keeping its own width at the trailing edge and wrapping onto another line when they do not fit.
As on the Mac (`footerGroups`), the default is drawn last, filled with the accent; a danger choice has a red outline and the rest a hairline outline.
The answers line (`answersLine.ts`) sits in mono at the start of the first line, and a hairline sits above the row while the body runs on beneath it.
While a required question has no answer the default choice is drawn muted, and a press of it asks for the missing answer; a pressed choice shows a pending mark until the computer answers.
Above the choices sit the host's fact strip, which the body's page splits off as the Mac does and a second read-only web view draws, then the actions to take after merging, one written out or more folded under their count, as the Mac shows them, then the reply field.
The reply field reads "anything to add?", takes photos from the library or the camera, and its words also go with a choice as the `anything_else` answer, as the Mac's field does.
A footer press collects a fresh form reading through the computer’s shared bridge, including question definitions and staged settings, and sends the mounted offer and lifecycle with its own interaction id.
If the body has already failed, a later deliberate press may use its last observed draft, marked `fallback` with `no-fresh-reading` rather than fresh question evidence.
A timeout on the current press still refuses it; a body that never supplied a reading keeps choices unavailable rather than inventing answers.
The default choice waits for every required question; other choices carry the current answers.
The core still owns refusals, effects and closing, and a refusal leaves the card and draft in place.
Body and footer choices share one native pending gate, and an accepted choice remains locked until its card leaves.
Reply admission counts UTF-16 units against `PhoneLimits.reply`, generated from the published request’s text limit.
A shown, drawn card reports seen only while the phone is active and the Mac is in reach.
A reply sends its words, photos and current settings to the card’s author and makes no closing choice.
The thread shows each message as the Mac's does: who wrote it (you, crew, mate or app) in its color, its time, its words as plain text and a captain's settings folded on one line, then a working line while its author is at work; it opens when a new message arrives.
The body's change bars mark the parts the revised line counts, and the body's task keys open their records.
A link in the body opens in the device's default browser, and a draft button puts its words at the start of the message box, unsent.
A crewmate's browser on its card is a strip naming Browser, the page's site and who is driving, read from its task's record; its button names the computer.
A lone or marked card stays; an ordinary reply with another card declares its departure to the core.
Settings and browser doors name the computer where they must be used and send no action.
The host’s saved-sign-in choice needs no local browser page and is sent like any other choice.
The phone keeps recently closed cards in memory through `inf:cards:past` and also opens a past card the Mac points to with `past_card_shown`.
A past card has its last-seen body, saved answers, inert choices with the chosen one at full contrast and an accent edge, the words sent with that choice, its thread and Hide; it has no reply or mutation path.
Its ending words are generated from `src/shared/pastCard.ts`, so the captain, first mate and crewmate keep their own attribution, alongside withdrawn, taken-down and duplicate endings.
An evidence actor of `frame` is projected to the card’s typed author for those words; the stored ending stays unchanged.
The same read accepts older past-card ids; the current Tasks record does not expose its cards.

`CardWebHost` gives the shown body a nonpersistent WKWebView containing an opaque `sandbox="allow-scripts"` frame.
The bundled parent uses the actual shared frame bridge, form readers, schemas, stylesheet and typefaces, generated by `node scripts/generate-phone-cards.ts`; no second form implementation exists in Swift.
Each inline body script runs by its hash under `default-src 'none'`, with only local font and picture sources; event handlers, external scripts, fetch, forms, popups and navigation gain no permission.
Native WebKit messages are admitted from the trusted main frame alone, never from the body’s child frame.
The parent checks source identity, document identity, shared message schemas and declared action ids; native code checks effect-free action ids again and stamps every such request as `frame`, never `chrome`.
The native footer is the only path to an effect-bearing action.
A native watchdog removes a body that stops answering without removing its native controls, and offers Retry.
The watchdog counts only while the body is on screen, loaded and in front, since WebKit pauses a card behind another tab or in the background, and any answer since its last look counts, however slow.
Its pings go to the body, which can answer only once its frame's bridge says ready; until then the card's page answers each ping for it (`CardWatchdog`).
So a body still loading on a busy device is never counted, while one whose script loops as it loads stops its page answering too, since the frame runs on its page's thread.
It also counts only once the page has run something, the card's mount or an answer, since a loaded page can still wait seconds for WebKit's own processes to start before it runs anything; the mount tells the host before it builds the body, so a body that loops from its first moment is still counted (INF-2076).
A native collection timeout also releases a waiting footer or reply when the web process cannot run its own timer.
`CardAssets` serves bundled fonts and minted picture, project-font and recording names through the pinned connection; it never opens an arbitrary URL or filesystem path.
It asks through `ReadOnlySession.read`, which waits until the computer is in reach and asks again after a reconnect, so a card drawn from the first cards read, before the other first reads answer, still gets its pictures.
A separate script-free, nonpersistent web view shows pictures and GIFs, with no native message handler.
Both web views disable system link previews as well as refusing navigation.
A body's link leaves only on the captain's own press, when the parent's `isSafeCardHref` admits it, and native code checks its scheme again before the system opens it.
MP4 recordings use the native player, whose resource loader serves only bounded bytes read through the pinned connection and writes nothing to disk.
The asset refuses all external references, and the player disables external playback and picture-in-picture.
Assets and drafts are memory-only and are cleared when their owner goes away.
An out-of-reach session refuses changes; a lost reply has an unknown result and is never retried or queued across reconnection.
The phone containment review is in `docs/live-prototype-security.md`, “Phone cards”.

## Native shell and component ownership

`PhoneWorkspace` supplies a stage, an optional Tasks view and an optional composer, with no draft or record state of its own.
The composition installs `PhoneCards(session:)`, `PhoneTasks(session:)` and `MessageComposer(session:)` together.
The composer stays mounted once, preserving its own text and photo state across tab and orientation changes; the shell never copies it into a tab or layout branch.
The card with its pager, the message box, Tasks and Activity share one centred reading column, `PhoneColumn`, 560 points with its gutters, so on an iPad the message box lines up with the card above it.
On an iPhone on its side (compact height) the card gets the height: the bar keeps its one row, and the last turn and the notice wait until it is upright.
There `AnyLayout` puts the removable photo strip beside the message capsule, retaining one field and its complete draft.
The field displays up to two lines there, the controls retain 44-point targets, and warnings remain full-length; portrait and iPad keep the stacked arrangement.
The native journey requires a completely visible card heading and scrolls real body text and an action into full view, not merely a retained draft under the card.
Card and task owners keep their selected records and replies.
`PhoneMessageContext` carries only the shown current or past card, Home's visibility and the open task record into the composer; hidden cards and dismissed records supply no hint.
The top bar is the one-row bar the captain chose (INF-1062): a Settings button at its left, the strip of Home, Tasks and Activity in its middle and the computer button at its right; there is no bottom tab bar.
The strip, `PhoneTabStrip`, is Apple's segmented control, which iOS 26 draws on glass (INF-1328): a house for Home, a checklist for Tasks and a pulse line for Activity (INF-1334), read by VoiceOver as a tab bar of the tabs' names.
It carries no unread dot; the notice under the bar and the next chevron's dot mark an unread card.
The strip keeps the bar's own size at every type setting, as the system's bars do, so the bar's buttons never move around it.
Where the bar has room, the strip is as wide as makes the lit tab a 40-point circle, 144 points for three tabs (INF-1517, the captain's Round); where it has not, a `ViewThatFits` gives it the control's own fitted width.
Settings and the computer are the system's 44-point circles for a one-icon button, with no wider frame of the app's.
Command-1, Command-2 and Command-3 switch tabs, Command-Comma opens Settings and Command-I the computer.
`PhoneWorkspace` holds the tabs in the system tab controller with its own bar hidden, so each tab keeps its draft, scroll position and search while another is shown, and a tab that is away leaves the view hierarchy: nothing in it is drawn, pressable or read, and a keyboard typing into the message box closes with the tab it leaves.
Home is one column: the stage, then the last turn and the message box under it, in the layout rather than floating over it; Tasks and Activity run to the foot with nothing over them, so the last row is whole and pressable after scrolling to the end.
No bar height is measured or guessed, and nothing recedes on scroll.
No panel sits behind the message box: the last turn is its rounds of lines over the capsule, which is native glass on iOS 26 and the field's fill and hairline on iOS 18.
The capsule is 48 points tall, with the photo glyph 16 points in, the words 52 points in and send a 32-point filled circle 8 points from its end, each control in a 44-point touch area (INF-1517, following ChatGPT's input).
Settings is this phone's own sheet, `PhoneSettingsSheet`: this device and what it can do, that appearance follows the device, and the app's version; the computer's sheet keeps the computer's name, reach, address and Leave or Forget.
Both open at half height on the system's glass and can be pulled up, with the same headings and spacing; Leave, or Forget while out of reach, is the computer sheet's second section under its own heading.
While the keyboard is open, Done takes Settings' place in the leading slot and the Hide keyboard command (Shift-Command-K) dismisses it without sending or clearing the draft.
The dismissal command does not belong to the keyboard’s transient accessory view.
The tabs read Home, Tasks and Activity, in that order.
The iPad's wide landscape workspace places a sidebar beside the stage, with Tasks and Activity as a segmented pair at its top, opening on Tasks, each scrolling alone, keeps the composer at the stage's foot and shows no strip in the bar.
Portrait or narrow multitasking returns to the strip; layout measurement excludes the keyboard.
A rotation moves the sidebar and the stage with its animation, and nothing else enters or leaves the window inside it (INF-1590): views that did at times left one of its animations started and never stopped, and XCTest's wait for the app to settle then never ended.
So a turn into landscape brings Home in just before its animation starts, laid out at once and unanimated, because Home put back after that animation came back short by a keyboard inset it took while out of the window.
Home brought in that way is already laid out at the new size while the window is still upright, so the workspace's fill reaches past its foot and the system's white never shows.
The bar's strip, and on the way back upright the tab Home gives way to, follow the new layout once the animation has ended, or on the main queue's next turn when no rotation runs.
`PhoneActivity` reads the computer's wording and optional task key, shows its kind dot and relative mono age, and orders newest first on both devices.
The task key sits inline before the words at micro size, as on the Mac's feed line.
It exposes the full local timestamp to accessibility.
`PhoneSymbol` supplies native outline template images for the system's tinted chrome.
`PhoneStyle` holds the shared looks: `phoneTitle` draws a sheet's title inline in Space Grotesk, the `.phone` field style is the app's field, and `phoneSheetSurface` leaves a sheet on the system's glass on iOS 26 and puts it on the panel color with a hairline at its edge on iOS 18.
The message capsule's glass takes corners concentric with the screen's.
It also holds `SensoryFeedback.phone`, the one soft tap played when the computer accepts a message, a card's answer or reply, or a task's start, continue, interrupt or steer, and when `returns` counts the computer back; a page turn plays none.
Join, Leave and Forget ask in alerts, which keep the cancel choice in view; on iOS 26 a confirmation dialog becomes a popover that hides it, and the Join request has no button to anchor to.

`PhoneCharacter` draws the Mac's character in a native Canvas with the numbers of the Mac's own character code (`src/renderer/src/character`), so the two move alike.
At rest the tesseract drifts slowly and the eyes blink every few seconds and wander; listening breathes as two counter-rotating hexagons; working speeds up with the Mac's ember, shimmer and halo, with white-hot cores.
It plays the desktop repertoire natively: greet, celebrate, ponder, confused and the five reply reactions, with the roll, yawn, orbit, constellation, Saturn, galaxy, Algol and black-hole fidgets.
The first character a person sees after opening or joining greets once (`CharacterCues.greetOnNextSight`).
A turn that starts mid-greeting lets the greeting play on as the ember eases in, then the character works, as on the Mac.
A character that leaves mid-greeting, such as the empty stage a join shows before its cards arrive, hands the greeting on to the next one shown.
A live `firstmate_emote` reaches the characters on screen; reply reactions wait for the turn to finish, with the first request winning as on the desktop.
A reaction replayed while reconnecting is not played, and a character off screen does not keep one for later.
The wire and halo boosts come from the design skill's tokens through `scripts/generate-phone-theme.ts`, like its colours.
Its isolated display clock requests the permitted screen cadence up to 120 frames per second, with the iPhone ProMotion opt-in; iOS still chooses the delivered cadence under power and thermal constraints.
The clock advances by elapsed time, excludes hidden/background time and stops callbacks while hidden, inactive or under Reduce Motion, which shows a settled pose without emotes.
`scripts/generate-phone-scene.ts` generates native geometry, targets, timing and reply comparison traces from the desktop owners; the phone gate checks that they are current.
Simulator callback timings measure that run, not physical ProMotion delivery, battery use or thermal behavior.
The DEBUG-only cadence observer identifies its target Canvas and records its mode, warmed heat and rotation so another window cannot contaminate a sample.
The same display-tick sample measures the isolated first mate and the production crowded scene with its real task roster, retaining drawing work, interval tails and the delivered display intervals separately.
A main-run-loop observer retains its actual before-sources, before-waiting and after-waiting timestamps for both warmup and sampling, without adding a wait or moving the 60-callback warmup, 240-callback sample or their deadlines.
The warmup and the sample each have 20 seconds on the load clock, read on the main thread that receives the callbacks, never a wall-clock XCTest wait (INF-1506).
A stall of the app itself, such as a busy Mac mini starving the simulator, counts at most two ticks, while a display link that stops delivering as the app runs still fails within the budget, and every wait ends by its wall cap.
Cadence failures name their source, phase, waiter outcome, observed and requested callbacks, elapsed time, longest callback and run-loop gaps, drawn mode counts, first unexpected mode, minimum heat and rotation endpoints.
The callback gap includes the wait's leading and trailing intervals, so a display link that never fires reports the whole wait rather than zero.
Sampling keeps its raw display timestamps and main-run-loop trace as attachments, and prints the diagnostic facts in the ordinary command log too.
A gap identifies missing main-thread progress but does not identify the blocking stack or establish a flake.
Idle cadence samples accept the character's automatic fidget, including the idle sample that requests a salute; working and listening samples gain no automatic-mode exception.
The named source and drawing scope, working heat, rotation advancement, requested-reaction presence, callback counts and budgets remain enforced.
Its accessibility value stays the state the conversation owner supplies; an emote never changes it.
The join stage uses idle; the empty stage follows the Mac's published busy snapshot and numbered busy events, never typing or a crew count.
Homes on `SCENE_OBSERVATIONS_SINCE` (`src/shared/ipc.ts`, major 12) or later, and older homes that advertise `native-scene-observations`, answer `inf:conversation:state` and the public `inf:computers:presence` read/push; the latter contains only each work computer's id, name and reach, never addresses or management facts.
A numbered push supersedes an older pending read; an older home retains event-only busy observation and unknown remote reach without sending unsupported requests.
Joining shows only the first mate until real board facts arrive, and the accessibility value names unknown conversation activity until the home supplies a reading.
`PhoneCrewScene` renders home's formation and every other computer's at the desktop's share of it in a continuous native scroller, with touch panning and arrow keys rather than paging or shrinking the entire scene, and no scroll bars.
The phone draws the desktop's orbits at `PhoneSceneRoster.ringScale`, derived so that eight crewmates on the first orbit stay inside the narrowest portrait iPhone (375 points), the captain's ask.
Crew glyphs keep the desktop's size: home's crowded glyph (`PLANES_GLYPH_PX`), and in another computer's cluster the smaller glyph `CLUSTER_LAYOUT` names, smaller again once that cluster holds more than its `crowdedCrew` (INF-1854).
Crew sit on the desktop's growing two-orbit ring (`docs/crew-orbits.md`): the first orbit widens with each crewmate up to its seats, the next arrival opens the second orbit inside it, and no third orbit opens.
`PhoneSceneRoster.SeatBook` remembers each crewmate's orbit and seat across board reads as the desktop's orbit does, logical membership counting every running part for allocation and growth, and each computer's area follows its first orbit's size.
`PhoneSceneMotion` keeps separate drawing seat books: only visible main-orbit occupants take angular seats, including program rings but excluding branch parts and circling crew (INF-1375, approved A).
`PhoneSceneCompanions` reads published wait/review facts and reproduces the desktop's eligibility, three-companion limit, perpendicular 64-scene-pixel circles, 24°/second travel, the circle that shrinks near the scene's edge (`PhoneSceneCompanions.radius`, INF-1532) and bounds fallback at the phone/computer scale.
Returning crew open a seat among visible survivors on the same logical orbit; a fallback crew member takes part in main-orbit spacing.
A re-spaced or resized orbit glides its crew around it, and neither orbits nor another computer's center are outlined.
`PhoneOrbitSeatsTests` replays the desktop's own seat choices, recorded by `scripts/generate-phone-scene.ts`.
Its native Browse crew command, Shift-Command-C, enters app-owned browsing with an accent viewport outline; arrow keys pan it, Tab selects a real crewmate and Space opens that crewmate's preview.
While browsing, a scene-owned responder holds first-responder status and offers those unmodified keys as priority key commands, because SwiftUI shortcuts for them lose to the system's focus and text handling.
Each crewmate and program answers touch across its 44-point square, not only the drawn circle.
Where two squares overlap, each point belongs to the nearer center (`PhoneTouchCell`), so a tap on a crewmate's own center always reaches it.
Selection has an accent outline and an accessibility value; Tab brings it into view without relying on SwiftUI's platform-focus reporting.
Escape, editing, a preview, a task record, leaving Home or backgrounding stops browsing and releases that responder, so the unmodified commands do not take over other controls.
Each crewmate retains the published tier, work posture, computer and review identity; programs draw only their live parts, with their actual dependency branches.
A crewmate whose task is in the phone's Waiting on you group wears the desktop's beacon, the ring that breathes round it, from the same generated numbers (`captain`), and holds it whole at mid light on a still frame (`docs/crew-orbits.md`, INF-1543).
A crewmate's summary opens in the system's standard sheet (INF-1926): it is the desktop's crew summary in its words, order and marks at 14 points, the board row at once and then the task record's own read, polled each second while it is open.
`PhoneTaskFacts` in the shared package ports the desktop's facts (`taskFactsOf`, its status, checks and plan), and `PhoneTaskFactsTests` replays the desktop's own readings, recorded by `scripts/generate-phone-scene.ts`.
The sheet closes the standard way, by a tap beside it, a swipe down or Escape, with no close mark; while it is open the scene stands still where it is, and the crewmate it describes wears the desktop's corner brackets.
A running part, a blocker, the task a review checks or a part's program shows its own summary in the same sheet, and Open task swaps the sheet for the existing native task record.
The computer preview names the computer's work and its state.
A crowded program fan widens up to the desktop's widest spread and then moves its layer outward, keeping the desktop's projected spacing without shrinking the parts.
A program seen running keeps its ring on each observed computer between stages, without finished, unstarted or remote-placeholder dots.
Its summary counts finished, running and waiting work, shows their shares and names each running part and where it runs.
The panned extent stays stable while work departs, and cross-computer flights reach the first mate with the desktop's distance-based timing.
`PhoneSceneViewport` alone owns placement: it centers home on entry or reconnection and preserves the viewed world point as the roster or viewport changes; the scroller's resize anchor does not add another adjustment.
Initial rosters and reconnects settle in place; an unreachable computer freezes its unknown activity, and hidden scenes discard transient report, steer, failure and usage effects.
Seats and program topology are prepared with the roster, outside the display callback; only the drawing subtree reads the clock.
No joining time is invented.
Joining still confirms the link's computer address, not a name obtained before authenticating that computer.
The details sheet names the connected view's ability to answer cards, send messages and control tasks, or explains read-only access when the Mac requires an update.

## Talk and tasks

The message box keeps the captain’s last two messages and the first mate’s replies above its native multiline field, by the Mac's rules and in its Chat layout (`docs/composer.md`, "The last turn"; INF-1517, INF-1771): the captain's words in a grey bubble on the right, each reply beside the first mate's mark on the left, the older round at half strength and only the newest while a card is up.
The phone sets them as a quiet glance (INF-1846): 15-point rows, one step under the box's 16-point words and one line each, the bubble hugging its words up to three quarters of the column, each reply in the secondary colour on a 24-point row pressable across its width, 4 points within a round and 12 between rounds and above the box.
While the first mate is busy its line shows three ember dots brightening in turn and Working…; a message that was only photos reads "A picture".
A completed reply fades after 15 seconds on screen over 0.7 seconds, an instant under reduced motion, keeping its room so the input never moves; the count runs only while Home is shown, the app is in front, the phone is upright and the first mate is idle.
A tap on a reply line opens that whole reply in a half-height sheet, titled by its message, as the Mac's reply note.
Its component owns messages and photos; the shared shell places it at the foot of Home.
A send carries the visible entry’s `visibleCardId`, `pastCardId` or `taskId` through the published conversation request as a hint, never as the message’s topic.
The native multiline field uses the keyboard’s own dictation; Infinitary adds no speech model or microphone permission.
Photos uses the system library picker, converts selected images to orientation-correct JPEG thumbnails up to 2,048 pixels, and bounds each attachment and turn by the published limits.
Selected photos appear as removable chips; messages and photos remain in memory until a confirmed send clears them.
Command-Return sends from either message field; native controls retain hardware-keyboard focus, VoiceOver and Dynamic Type.

The Tasks tab combines a filter of the live board with the Mac’s earlier-task search.
An unstarted task shows the home’s dated `queueWait` line below its title and record heading, without rewording it or deciding readiness on the phone.
Its five groups and their labels come from `src/shared/nowPanel.ts`, generated as a finite native lookup so the phone does not own another grouping rule.
The phone keeps active parent trees together, hides dropped rows and closed ordinary operations from the groups, and keeps them searchable.
Each group's header is a micro uppercase label with its count, as on the Mac.
Waiting on you, Working and Queued start expanded; Backlog and Done start collapsed, with counts and keyboard-reachable disclosure buttons.
Each row is one line: status mark, key, title and then the project, with the newest task first inside each group and dividers inset past the mark.
A card put aside on the Mac lists its task under Waiting on you by the Mac's `presentTask` rule, which `PhoneBoard.presenting` follows, and the generated lookup takes the minimized fact as its sixth input; a card with no task gets its own row titled by the card.
A tap on such a row brings its cards back on every Mac and shows them on Home; any other row opens the task's record.
The search waits above the list until the list is pulled down from its top, as the Mac's waits behind its icon.
Find a task (Shift-Command-F, the Mac's key) opens it with the caret in the field; Close search, or Escape on an empty field, puts it away.
VoiceOver cannot pull past the top of a list, so the search is always shown while it runs.
A record shows the goal, captain’s words, progress, latest report, model and timeline; its Crewmate section reads the redacted session and live words from their Mac owners.
The timeline's events sit on a hairline rail in caption size, each time right-aligned.
The open record refreshes once a second, as the desktop transcript does, and no hidden record polls.
Start and Continue come only from the Mac’s `moves`; Steer and Interrupt use the existing captain-owned task channels, never a phone worker.
Interrupt stops a running turn and keeps its task idle and steerable; Continue is offered only when the Mac marks a task Interrupted, such as after recovery.
The record's actions sit at its foot in a card's footer row: Start or Continue filled with the accent, and Interrupt outlined beside it.
The crewmate message box above them is a capsule whose arrow sends the steer.
Tool results open on demand through their published read.
Task cards, browser pages and rich transcript pictures remain outside this piece.

A mutation requires both **In reach** and the welcome’s `full` access.
The phone connects as a view, and its hello says its build's view floor (`viewFloor`, generated from the published contract), so it keeps changing things across majors that kept views, in both directions (`docs/contract.md`, "The version rule").
Outside that window the line under the message box names the older side (`PhoneUpdate`): "Update Infinitary on this phone to make changes." when the computer is newer, and "Update Infinitary on your computer to make changes." when it is older.
Every request has one connection-bound response and a bounded wait; a disconnect, timeout or unreadable mutation response explains that its outcome is unconfirmed.
The phone retains the draft, asks the captain to check the Mac, and never queues or retries a mutation after reconnecting.
A native draft, last turn, task and transcript are never written to the phone’s saved connection file.

A new card or an answered reply raises an in-app notice while the app is open, after reading the Mac’s Notifications switch.
The notice is a pill at the top of every tab, interactive glass on iOS 26, a New card or Reply label and the card's title; a tap opens that card on Home, and a swipe dismisses it.
It sits under the top bar, over the stage beside the landscape sidebar, and waits while an iPhone is on its side.
A reply notice leaves after five seconds unless VoiceOver is running; a new-card notice stays until its card is read or the pill is swiped, and no pill points at the card already on the stage.
The first snapshot and a reload seed the notice history without announcing old cards; a body-only revision is not new news.
The end of the app's background time stops the connection and clears the notice; there is no background notification service or push relay.

## Installing on a phone

The captain installs Infinitary through TestFlight, not Xcode.
Once a build is in internal testing, Apple emails each tester in the app's internal group an invitation.
On the phone, the tester opens Apple's TestFlight app with the Apple Account in that group, accepts the invitation and installs Infinitary; automatic distribution offers each later build there too.
The phone and Mac need a network route to one another and a Mac build that accepts `system: "ios"`.
Open **A phone** in the Mac app's Devices settings, scan or paste its link in the phone app, and confirm that Mac.
The phone should show Home, Tasks and Activity in its top bar, its cards on Home, and the Mac's name with In reach in the computer's sheet behind the bar's right-hand button.
Type a message or use keyboard dictation, attach a library photo, and confirm the last turn on the Mac.
Open a task’s record to start or continue it, and its Crewmate section to steer or interrupt its running turn.
TestFlight installation, camera scanning and the real Local Network prompt are the captain's checks on a physical phone.
Someone working on the phone app can still run it on their own iPhone or iPad from `ios/Infinitary/Infinitary.xcodeproj` with the Infinitary scheme and their own development sign-in.
Release signing runs only in the separately dispatched TestFlight workflow below.

## TestFlight releases

`.github/workflows/ios-release.yml` is dispatched from merged `main` with a numeric phone `version`, such as `0.1.0`.
A branch dispatch is refused before Apple is contacted.
Every job checks out the same full source commit recorded by the dispatch; the phone version is independent of the Mac's version and does not edit a version file or create a desktop release tag.
The build number is the workflow run number followed by `.1`, such as `42.1`; validation refuses a run beyond 9999 rather than exceeding Apple's four-digit first component.
The Mac job refuses release-job reruns immediately after Node setup, before dependency installation or either device gate; the upload command checks again before Xcode runs.
GitHub can preserve an earlier resolve job's outputs while advancing another job's attempt, and an unclear upload must not be renumbered or resubmitted.
A status-only request remains safe to rerun because it never uploads.
A fresh dispatch creates another build, not a retry of a prior upload.

The Linux preflight reads App Store Connect with the existing `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID` and base64-encoded `APP_STORE_CONNECT_API_KEY` secrets.
It requires exactly the app record named **Infinitary** for `com.getinfinitary.infinitary`, the registered bundle identifier, and an internal TestFlight group with automatic distribution and a configured, non-revoked tester.
Apple's identifier filters can return prefix matches; the preflight selects exact identifiers before requiring one match.
Apple sends the TestFlight invitation only after a build is available, so `NOT_INVITED` and `INVITED` are valid preflight states, not proof of installation ([Apple's internal-testing instructions](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/)).
These preflight reads use GET only; they create no app record or tester and change no account permissions.
It signs short-lived requests in memory, refuses redirects or pagination to another host, and prints neither credentials nor tester identities.
A successful read proves app access, not permission to manage signing; Xcode checks that authority during the archive.
A configured tester somewhere in the group is not proof that the captain accepted an invitation or installed the app.

The captain's one-time Apple setup is:

1. In Apple Developer → Certificates, Identifiers & Profiles → Identifiers, register the explicit identifier `com.getinfinitary.infinitary` for team `9T2J7MNUP9` if it does not exist.
2. In App Store Connect → Apps → + → New App, choose iOS, name **Infinitary**, a primary language, the registered identifier, a stable SKU such as `infinitary-ios` and Full Access.
   An existing record must have that name and identifier, and the API key must have access to it.
3. In that app's TestFlight tab, press + beside Internal Testing to create a group, or select one, enable automatic distribution, and add the captain with Invite Testers.
   Accept its TestFlight invitation once the first build is available; that acceptance is not an upload prerequisite.
   A missing eligible tester is managed through App Store Connect → Users and Access, not by this workflow.
4. Keep the three existing repository secrets set to a team key authorized for the app and Xcode automatic signing.
   The private-key secret contains base64 of the downloaded `.p8` file, never a value pasted into a task or a command argument.

After preflight, the existing disposable iPhone and iPad gates run on `REAL_MAC_RUNNER` when it is set, otherwise on `MAC_RUNNER`, falling back only to `mini-mac`; `RELEASE_REAL_MAC_RUNNER`, when set, comes first (`docs/testing.md`, "A release's own queues").
Xcode signs the upload with the captain's certificates, so the job asks for the real Mac, never a virtual one (`docs/testing.md`, "The real Mac's place").
Either failure prevents archive and upload; iPad still runs after an iPhone failure unless cancelled.
The release job waits in a line of its own, `ios-testflight`, apart from the phone checks; its device gates and release command run directly without excluding desktop checks.
The job retains the native lane's 165-minute allowance plus 60 minutes for release work; commands no longer wait for admission.
Install-time checks use a scratch HOME and an empty local-signing directory, as in `phone.yml`.

`scripts/release-phone.sh` uses ordinary Xcode automatic signing on the existing Mac runner with the same Apple team and API key as SSHHIP.
This CI path is captain-approved; it is not permission for a crewmate to sign locally or inspect the person's keychains.
There are no explicit `security`, Keychain or `codesign` commands; Xcode may reuse an existing development certificate rather than create one.
After a confirmed upload, `scripts/phone-certificates.ts` lists safe cleanup candidates inside the release command.
Only a runner named `mini-mac` or starting `mini-mac-` may select candidates, and an archive without a signing fingerprint selects nothing.
It protects every SHA-1 signing identity printed by archive and export, including nested targets, rather than just the last identity.
It reads all certificate pages through the existing host-checked App Store Connect reader, with a ten-page bound; malformed or incomplete listings fail closed.
A candidate must be a `DEVELOPMENT` certificate whose X.509 subject common name is exactly `Apple Development: Created via API (<this release key ID>)`, whose fingerprint is not protected, and whose X.509 `notBefore` is strictly more than 24 hours old.
The key ID in that naming convention is an inference from INF-259, not an Apple creator field; an unrecognised name is always kept.
Apple supplies no certificate creation date, so cleanup never sorts on `createdDate` or expiration.
The release entry point is list-only with no revocation input or environment switch: the first real candidate list appears in the job log and summary for the captain to read.
Revocation stays off until the captain reviews that list and a separate reviewed code change wires the revocation callback.
A listing failure leaves the accepted upload receipt intact and never retries upload.
This changes only Infinitary; SSHHIP and Eddie's Wallet have separate cleanup implementations.
The key is written with mode 0600 inside this invocation's owned mode-0700 temporary folder and supplied to Xcode by file path.
The uploader receives that exact file through `--p8-file-path`, bypassing its earlier working-directory and HOME search locations rather than relying on the last-searched `API_PRIVATE_KEYS_DIR`.
Archive, derived data, export and key cleanup run on exit, with an `always()` cleanup for the known invocation path; local verification uses only unsigned simulator runs and unsigned packaging rehearsals.
A force-killed job can interrupt cleanup, so the final cleanup and runner's temporary-directory lifecycle both matter.
The archive gate reads the built app's name, bundle identifier, version, build, iOS platform, compiled icon, all four iPad orientations and encryption declaration before export.
`ios/ExportOptions.plist` selects automatic App Store Connect export and disables automatic version/build renumbering.
Exactly one exported IPA is accepted for a single upload attempt; no upload is automatically retried.

The `phone-release-<version>-<build>` artifact keeps native results and a non-secret upload receipt, not keys, signed archives or unredacted signing logs.
An `attempted` receipt means the outcome is unknown; `accepted` means the uploader accepted it for processing, not that it reached a phone.
The final Linux job reads the exact marketing-version/build pair until Apple reports it in internal beta testing, for up to 60 readings separated by 30 seconds.
Rejected, expired or unknown states fail explicitly, and export-compliance holds name Apple's required action rather than uploading again.
A processing timeout or uncertain upload is checked by dispatching the same workflow with `version` and `check_build` set to the existing build number.
That mode performs only Apple reads, runs no Mac job and never uploads.
Apple's internal-testing state means testers can install the build, not that a phone has; a tester's installation through TestFlight is that check, and no Xcode installation is required of the captain.

## Disposable verification

`pnpm test:phone --evidence <absolute-folder-outside-the-project>` runs the foundation's native gate directly on a Mac with the pinned Xcode and its own iOS simulator.
On a computer in CI mode (`infinitary.checks = ci`, `docs/testing.md` "Where the heavy checks run") it refuses before starting the gate and names `phone.yml` on request instead.
Add `--ipad` for the iPad Pro 11-inch (M4); the default uses an iPhone 16.
`scripts/phone-pin.json` names the one Xcode, the one iOS simulator runtime by version and build, and the iPhone and iPad every Mac's phone check uses (INF-1645): the same pair on a crewmate's Mac, the Mac mini's TestFlight job and the virtual Mac image.
The gate refuses any other Xcode before it builds, and `scripts/phone-simulator.ts` refuses a Mac without that runtime, or one whose runtime does not support the device, naming the download that fixes it; it never takes a newer or older runtime in its place.
Moving to a new pair is one pull request that edits the pin, after the virtual Mac image and every Mac that runs the check have the new pair.
Add `--both` to run the checks and build once, then the iPhone and the iPad side by side; the evidence folder then holds the shared logs and an `iphone` and an `ipad` folder.
The native journey is six tests in `PhoneJourney`, its parts: `join` (join and recover), `talk` (talk and tasks), `relaunch` (relaunch, then Tasks), `cards`, `address` (join by its address), and `rest`, which runs the character and past choices with the app-hosted tests and any test no other part names (`scripts/phone-test-plan.ts`).
The gate starts one simulator per device, once, and runs that device's parts on it one after the other, in the order `scripts/phone-test-plan.ts` lists them; each part is its own gate with its own test home and a clean app, and `--simulators` (default 6) sets how many devices run side by side (INF-1438, the captain's "Start each simulated device once per phone check, not once per part").
Before every part the gate uninstalls the previous part's app and UI test runner, resets the simulator's Keychain and permission answers, sets light appearance and the default type size, detaches the hardware keyboard, and checks the app is gone; a simulator Xcode shut down after a failed part boots again.
The parent owns each simulator from create to delete, and passes it to the part's own process with `--simulator` beside `--xctestrun`; a lane whose simulator cannot start leaves its parts unstarted, and the gate names them.
A run that is killed, by a task stop or a restart, never reaches its own cleanup, so before its checks each gate removes what earlier runs left (`scripts/phone-leftovers.ts`, INF-1596).
It deletes each simulator named `Infinitary isolated test`, shut down or booted, and each `infinitary-native-` scratch folder in its temporary folder that came into being before the earliest phone check process still running began.
A gate makes both only after its process starts, so a running check's simulator and folder are never touched, nor a person's own simulator or another prefix's folder; the reading needs no record or age, so leftovers of runs before the sweep go the same way.
It reads the process list itself, never through the command log the evidence keeps, and a removal that fails is reported while the gate goes on.
A part's results are in its own folder, inside the device's folder with `--both`, and `--part` runs only the named parts.
A `--both` run of every part writes each part's minutes on each device to `part-times.json` in the evidence folder, which a pull request's phone check reads to keep within its budget.
The build is `xcodebuild build-for-testing` for any simulator, and each part runs `test-without-building` from a copy of the built test plan that names its own test home and selects its tests.
The simulators of the devices that run side by side start while that build runs, so the first parts begin as it ends; a device past `--simulators` starts its own when a place frees (INF-2125).
The Swift package tests and the build share one folder of fetched package repositories, so the build fetches nothing the package tests already did.
It is `INFINITARY_PHONE_PACKAGE_CACHE` when set, otherwise inside the gate's scratch folder.
`phone.yml` sets it outside that folder and restores it from the newest save of `main`, matched on both package lockfiles; only a run of `main` with no exact match saves it, since a pull request reads its base branch's saves and never another pull request's.
Any part failing fails the gate.
Local runs stop at their first failed part by default, so a failed repeat ends after cleanup and returns its load-line place rather than running the remaining parts (INF-2014).
With this default or `--stop-early`, which a pull request's phone check sets through `INFINITARY_PHONE_STOP_EARLY=1`, the first failed part ends the part still running on the other device, as an interrupted part does, and starts no other; every started simulator is still deleted, and the gate names the failed, stopped and unstarted parts and writes no `part-times.json`.
Set `INFINITARY_PHONE_STOP_EARLY=0` for deliberate full-discovery local runs; CI defaults to full discovery, and a workflow run on request sets `0` explicitly to run every part to its end.
Every explicit native observation goes through `InfinitaryUITests/PhoneWaits.swift`: element presence and absence, predicate reads and the disposable home's control requests.
`PhoneJourney.appearances` observes screenshot pixels before attaching each light/dark pair and before returning from its light restoration (INF-1537).
These fixtures have broad near-white or near-black surfaces: every screen quadrant's mean sRGB brightness must be on the requested side of the black/white midpoint, so an idle app or a dark card alone cannot stand in for a drawn dark screen.
It reads them only once a still part of the screen has redrawn and settled (`waitForRedraw`), since XCTest no longer waits out the native transition; after the first matching frame it observes again and attaches that exact screenshot, not a later unchecked capture.
A missing appearance fails with the last frame named `unconfirmed` and its quadrant readings in the log.
This checks the journey's fixtures, not the appearance of arbitrary pictures or other apps.
Its load clock, `PhoneWaitDeadline`, lives in `PhoneLoadClock/`, which both test targets compile, so the app-hosted display samples read the same clock.
On ordinary runs it samples the same load clock as journeys, with 25 ms ticks, at most two ticks counted across a stall, and a share reduced by one-minute load per active processor above 1.
Each wait ends by 20 times its budget on the monotonic wall clock, at most ten minutes; direct predicate evaluation preserves INF-975's short-window fix.
The phone launcher starts the Node load clock for its failure timers too, and the disposable control server keeps idle connections for a finite capped interval so a queued POST survives a frozen home.
A graded run keeps each original wall-clock budget, and the launcher writes that reading into every test target's own test plan.
XCTest timeouts are enabled in both modes: ordinary tests have 1200-second default and maximum allowances, while graded tests use Xcode's own allowances.
`PhoneWaitsTests` observes a real delayed file across a stalled reader, fails a missing file, expires a stalled clock at its wall cap and checks direct short-window observation.
Its delayed file is written by a thread of its own, never a Swift task, and the reader's stall ends only after that write, so busy shared task threads cannot hold the write past the wall cap (INF-1396).
Message-box, card-reply and address-sheet typing share `focusForPhoneTyping`: one tap, dismissal of iOS's first-use typing guide if shown, then observation of the field's actual keyboard focus before typing.
The address journey dismisses the iPad number-pad popover on the sheet's title and observes the keyboard leaving before focusing the address; it never retries the field tap or types a priming character.
A choice after paging waits for the restored native form reading as well as its enabled action.
The gate starts `simulator-live.log` before XCTest starts, so a failed test that tears down the simulator domain cannot erase the earlier app, WebKit and system log.
CI keeps each part's `simulator-live.log` in an artifact of its own, `phone-simulator-logs`, under `<device>/<part>`, never in `phone-logs`.
On failure it also prints the native wait's budget and cap, and the app's own WebContent launch requests and WebKit-measured startup durations, with their timestamps and app PIDs (`tests/helpers/phoneWebContent.ts`, INF-1888).
It reads both the live stream and the same simulator's kept log, deduplicates their witnesses, and keeps them in `webcontent-startup.log` beside the original test failure.
The post-failure app and system log queries stream both output pipes to their numbered command files with backpressure, never accumulate the whole log in a string, and join their children and file writers before cleanup (`scripts/phone-failure-logs.ts`, INF-1885).
The app log's startup witnesses are read back one line at a time.
A collection or read failure is reported without hiding the next log, the live-reader join, or the original test failure.
A missing launch completion stays unknown, and an earlier launch does not establish the cause of a later card failure; these readings identify startup delays without claiming CPU load, concurrent simulators or a runtime defect caused them.
No diagnostic changes the failed status, retries an action or extends a wait.
In the talk part, the first actual UIKit keyboard-queue timeout triggers a one-second stack sample after the runner confirms that PID still belongs to its own simulator's app.
It retains `keyboard-timeout-stack.log` and the capture outcome, joins the sampler before deleting the simulator, and never retries a capture or changes the photo-selection, tap or focus assertions.
A run without that fault records that no reproduction or stack capture is claimed.
The Cards journey keeps both its accessibility tree and the disposable home's card-state calls when a choice does not dismiss its card.
A request to `phone.yml` can name `parts`, `starve` and `perf`; the load controller stops each part's owned process tree with twelve-second long stalls and a 60-minute experiment limit.
The `waits` input (or `--waits`) selects only `PhoneWaitsTests` on both devices, so `perf: true, waits: true` proves the native deadline rule without also grading unrelated UI recovery latency.
This proof-only selection writes no whole-gate timing sample; an ordinary gate still runs every selected product journey and native test.
Selected parts, starvation, grading and proof-only selection use the normal or placed runner route; the fixed virtual-Mac switch refuses those options rather than silently dropping them.
A part that chooses a library photo (`talk` and `rest`) starts its tests only after the simulator's Photos says it has opened its shared-with-you library, because Photos hands over no chosen photo before then.
With simulators booting side by side that took up to six minutes after boot, and the gate waits for it once per device, from the device's start beside its first part: the wait reads what Photos logged since boot, so a library Photos opened during boot counts, and it fails if Photos has not opened it twenty minutes after boot, or fifteen on a graded run.
Photos can also fail to open that library, as with error 46110, or wait on a call that the simulator's background-task scheduler never takes up, and then its message never comes.
The wait reads both in Photos' own log and tells them from a slow start.
When Photos says it failed, the wait restarts Photos once and opens the Photos app so Photos opens its libraries again, and it ends the part at once if Photos fails again.
When the scheduler has not taken up a call 30 seconds on the load clock after Photos made it, the wait restarts the scheduler once for that call, and the restarted scheduler takes the call up.
Neither changes the ceiling.
The gate adds the library photo once Photos has opened the library, once per device, so a restart of Photos never cuts the photo's import short.
Minutes after boot Photos runs a background migration of its library whose actions wait on services the simulator lacks, until the simulator's scheduler ends the migration ten to sixteen minutes later, and a photo added meanwhile waits as long (INF-1438).
So when Photos has not taken the photo 30 seconds on the load clock after the gate added it, the gate restarts Photos once, adds the photo again, and lets the part start once Photos has opened its shared-with-you library again, within two minutes.
The gate keeps that wait's own log output, with Photos' calls and the scheduler's take-ups, in the device's `photos-stream.log`, and when the wait fails it also keeps the simulator's app and Photos log since boot with its command logs; a failed wait fails every part on that device that chooses a photo, and the device's other parts still run.
The phone workflow's `evidence_run` request exports native-scene attachments from an existing run that kept `phone-results`, a failed or recording one, on the Xcode host, without building or starting a simulator.
Request the export before that artifact's three-day retention expires (`docs/testing.md`, "Actions artifact retention").
It keeps the selected images, timing readings and scene recordings in a small artifact separately from the complete result bundles.
Add `--demo`, with FFmpeg installed, to keep real-speed reconnect, card, character, scene-panning and task-start recordings with their posters beside the test results.
A manual phone workflow request with `recording` enabled passes `--raw-demo` through `PHONE_RECORDING=1`, including the virtual-Mac route; ordinary checks do not record.
That mode keeps the simulator’s original silent H.264 capture as `*-raw.mp4` and needs no encoder on the test Mac.
Convert those captures to the card’s bounded H.264 format and inspect their posters on the evidence reader’s computer before publication; `--demo` still performs that conversion where FFmpeg is installed.
The reconnect recording crops the top of the phone view around the connection state and card; the card recordings keep the full native view.
An encoded demo retains real speed and holds the final frame for five seconds, within a fifteen-second cap; a raw capture preserves the complete recorded interaction.
The runner creates and deletes its own simulator, scratch HOME, real-core home, mock provider, data and keys, never borrows or erases a person's simulator, and saves logs and the result bundle outside the working copy.
The test home uses the real stores, dispatcher, pairing and TLS connection, with sample cards, feed lines and a task; its control interface listens only on loopback behind a fresh per-run token.
It attaches each connection it starts to the core, as the app does, so the core's phone door answers the address part's link only once that connection listens for it.
The simulator never ends an app's background time, so the journey sets `INFINITARY_TEST_BACKGROUND_TIME` to the seconds after which the app ends it itself, standing in for iOS; a phone always waits for iOS.
The simulator-only `INFINITARY_ISOLATED_PHONE_TEST` environment value disables real Bonjour browsing and the network sweep, so an offline fixture never causes attempts against a person's discovered Macs; physical discovery remains a captain check.
In that mode `INFINITARY_TEST_NEARBY_SSH` (`name|host|port`) names the one stand-in computer Join by its address lists, and `INFINITARY_TEST_SWEEP` (`host:port`, comma-separated) the only addresses its sweep tries.
`INFINITARY_TEST_RETRIED_CARD_LAG` (seconds) holds a retried card body's drawn height that long before its web view takes it, standing in for a loaded computer; the cards part sets it so its stalled-answer check taps a body that has drawn but not yet grown.
It first verifies the independent published-contract client can join and read the sample card.
The join part covers a wrong Mac pin, joining, cards and feed, Activity scrolled to its last whole row, identity across relaunch, out-of-reach state, catch-up after a home restart, a short trip to the background that keeps its connection, background/foreground replay after the background time ends, Leave, local Forget and Removed.
The address part starts the Mac's own `sshd` beside its home (`tests/helpers/sshServer.ts`), run as the test's user with a scratch home folder and every session handed the home's data folder; it checks the home's sshd listed as the stand-in computer, the sweep asked first and reading that sshd's real banner, a tap filling the address and port under the account, Not this one, the fingerprint asked again for a typed address, the key refused, a wrong password's words, then adds the key the phone shows and joins.
That `sshd` can check no password, so the password that lets the key in is checked by the package tests against an SSH server of their own (`SSHJoinTests`).
Every other part first joins its own home, and reaches the state the single journey had reached before it: the talk part puts the hero card on the stage and relaunches the app.
The relaunch part reaches the talk part's state before its relaunch pair: the hero card on the stage, the on-request harbour task and a sent captain ask, so each launch restores a last turn.
It then runs INF-1735's 20 relaunch pairs: each sets dark and relaunches, then light and relaunches, waits for the requested appearance drawn on the whole screen, and lights Tasks with its list after a single press (`repeatDiscarded: false`).
The talk part keeps one such pair, for its hero pictures and the Tasks journey after it; the 20 have their own part because they took about 11 of the talk part's 20-minute allowance on a loaded Mac mini (INF-1878).
The cards part drives forms, staged settings across paging, footer and body choices, the saved answer on the real home, close, threads and replies, pictures, a picture card drawn while the phone is still reaching after a reconnect, completed recording playback, seen, past cards, Mac-only doors and out-of-reach refusal without replay.
It checks both immediate script stalls and a stall during answer collection, and captures both appearances and the largest standard Dynamic Type size.
A scripted card attempts network access, parent access, direct native messages, injected scripts and a footer effect; the test home records whether any forbidden request reaches it.
The runner keeps the card interaction recording separately from the reconnect recording when `--demo` is selected.

It also photographs join, Home, Activity, the empty stage, details and Settings in both appearances, checks the largest standard Dynamic Type size, opens details and Settings by keyboard, checks the bar's order of Settings, strip and computer, and checks the iPad's landscape sidebar, its Tasks and Activity pair opening on Tasks and return to portrait.
Every native journey launch goes through `launchPhoneApp`, which renews the owned simulator's keyboard log subscription and waits for its startup before launching the app.
A live subscription is not proof that it still supplies registrations after relaunch; the new subscription starts with no cached witnesses and observes both launch and the home's keyboard attachment.
The runner joins the old output streams before appending the new subscription's gzip member, keeping all registrations in order.
Hardware chords go through `pressPhoneKey`, which asks the test home for backboardd's acknowledgement of that chord's registration for the current app process, then sends the chord once.
The scene's Command-Shift-C entry command keeps that exact-chord/current-process acknowledgement.
For its unmodified arrows, Tab and Space, the captain-approved contract instead observes app-owned browsing before one actual keypress and verifies the result on screen; BackBoard excludes these commands from its routable registrations.
There is no native-focus wait, priming input or retry.
Its touch drags read the target's and the viewport's current frames for each drag's direction and distance, at most eight drags, and a program opens from a tap near its square's corner.
The scene journey proves rightward panning, leftward return to the same world point, a visible real crewmate selected by Tab and that crewmate's matching summary opened by Space, retaining pictures and an optional keyboard recording.
It photographs the summaries of an idle, a working, a waiting, a blocked, a remote and a program crewmate and compares each one's words with the desktop's for the same task, which its fixture projects from the same records (`tests/helpers/phoneScene.ts`).
Its fixture's crew reach the phone one push at a time, and on the iPad the home's ring fits the screen, so only the other computer's formation gives Right somewhere to pan.
The journey therefore presses its first key only once the scene has drawn that formation's crewmate and the reviewer, the fixture's last crewmate (INF-1477).
The registration parser still reads empty modifier groups and normalizes BackBoard's arrow and Tab spellings without treating rejected commands as acknowledgements.
UIKit publishes an app's key commands to backboardd only while a hardware keyboard is attached when its deferred update runs after the next Core Animation commit, so for that wait the home attaches one to its owned simulator by setting the simulator-wide attached state `UIDevice` reads, the value backboardd itself writes when a keyboard connects, and detaches it again however the wait ends.
XCTest's virtual keyboard connects and disconnects within a millisecond of each key press, so a priming press only races that publication, and once a press has detached it no app process launched afterwards publishes at launch.
The native runner observes only its own simulator, and the isolated test home returns the acknowledgement to the key driver.
Subscription renewal happens only at the explicit launch boundary, never as a timeout retry or a second key press.
An evidence-writer failure stops the observer, rejects readiness and waits for both output streams before simulator cleanup.
An app-side command list is not that acknowledgement; a missing witness fails before sending the chord, without a delay, another priming attempt or a repeated chord.
For Return, the driver checks the router's carriage-return registration but supplies newline to XCTest: Xcode 26.4 emits the physical Return key for newline and no key for its Return constant.
Every tap a native journey sends, on an element or a point, goes through `tapOnPhone`, the one way a journey sends a tap again besides the photo pick below (INF-1477, the captain's "Allow a proven second tap").
A swipe, a drag or a key is sent once, as before.
XCTest gives each synthesized tap a virtual touch screen of its own, and on a starved simulator backboardd can fail to read that screen's properties in time.
It then attaches the screen as an accessory, or as a bad usage pair when it read no usage page, and ignores its touches, and XCTest confirms the tap after five seconds with no error.
The same backboardd subscription also carries touch screen attachments, touching contacts that name their screen and ignored touches, and the test home answers what happened to the first touch screen attached after the tap began.
The tap stays synchronous for its callers: the helper asks the test home off the main actor and turns the run loop until the answer arrives, so each tap also waits for its backboardd line to reach the test home.
If the live stream has no witness for the completed tap, the home reads the owned simulator's kept log once, through the same witness reader, alongside the live subscription (INF-1917).
That read starts inside the original outcome wait rather than after its deadline, adds no time or tap, and is cancelled when the outcome settles or the observer closes.
The witness also answers by the runner's request cap less one minute for the way there and back (`phoneTouchDeadline`), so on a host too starved for its load-clock budget to end first, the runner still reads the unknown before its own request ends (INF-2076).
A failed read or an accessory screen without a contact or ignored-touch line remains unknown, never permission for another tap.
A built-in touch screen was delivered, and so was a screen whose own contact backboardd reports touching, since iOS 27.0 attaches every XCTest screen as an accessory and still delivers its touches, naming the screen on each contact line.
Any other screen whose touches backboardd reports ignoring was discarded; only that proof sends one more tap, and two ignored taps fail the part.
A single-press check passes `repeatDiscarded: false` to the same owner; a proven discarded tap then fails at once instead of sending another (INF-1735's post-relaunch Tasks check).
Any other screen alone, a missing line or a stopped observer is unknown and sends nothing more.
Once a part has recorded a failure, XCTest synthesizes no more events, so a later tap attaches no touch screen; `tapOnPhone` then sends the tap without waiting for its target or reading its outcome (`PhoneFailures`).
A warning is not a failure: after UIKit's runtime warning about a reparented view, XCTest goes on sending events, so every later tap still waits for its target and reads its outcome.
A touch the app received but SpringBoard's gesture arbitration swallowed leaves no such proof, so it is not tapped again, with one exception: the photo pick.
On a busy iPhone the photo's lift can reach the photo picker late enough that the picker reads the tap as a press-and-hold and opens the photo's preview, choosing nothing.
The picker logs `performAllAnimations for animator: <_UIContextMenuAnimator` as it opens that preview, and the test home answers whether that line followed the tap (`PhonePickerPreviews`).
The iPad logged the same line and still chose the photo, so the line alone is not proof: the photo pick taps once more only after the photo holds still with no photo chosen and that line read (INF-1477, the captain's "Allow one more photo tap"), and a second press-and-hold fails the part.
The preview stays open after the lift and hides the photo from the accessibility tree, so when UIKit's element labeled `Preview` is on screen after that line, one tap on the dimmed screen below it closes it before the photo is tapped again (the captain's "Allow the closing tap").
Before and after each action XCTest waits for the app's main run loop to idle and for a reply from inside the app saying its animations finished (INF-1541, the captain's "The test code skips Apple's animation wait and checks each target itself").
On a busy Mac that reply can stop coming, as it did after a rotation in INF-1538, and XCTest then waits 60 seconds before every later action.
Every journey replaces XCTest's private `-[XCUIApplicationProcess waitForQuiescenceIncludingAnimationsIdle:usingActivity:isPreEvent:]`, which every one of those waits reaches in Xcode 26.4, with one that keeps the run loop wait and never asks for the animation reply, as WebDriverAgent does (`PhoneAnimationWait.swift`).
A tap checks its own target instead: `tapOnPhone` waits until the target's frame, and the screen's own pixels inside it, read the same twice in a row on the load clock (`waitForSteadyTarget`), except a crewmate orbiting in the scene, which never holds still.
A crewmate orbiting in the scene waits instead until every orbiting crewmate rides its own orbit no faster than that orbit's pace (`PhoneOrbitPace`, INF-2039), since the first mate's warp fidget speeds the crew up until a neighbour reaches the tapped point before the touch lands.
The frame alone is not enough: UIKit gives a sheet or an alert its final frame as it starts to slide or fade in, and drops a touch until it has arrived.
A check that a control can be pressed waits the same way before it asks XCTest, since right after the iPad's last card closed, XCTest found no tap point for the reply line when the check asked at once.
Any other such check waits on the load clock until XCTest finds the control's tap point (`waitForPhonePress`), since on a busy iPad the sidebar's first group read none right after it appeared.
A typed field waits for keyboard focus after its tap (`focusForPhoneTyping`), so a dropped tap fails where it happened rather than at the typing.
A display change, such as dark appearance or the largest type, waits until a still part of the screen draws differently than before the change and settles (`waitForRedraw`), and its pictures are taken after that.
The runner confirms each display change from the simulator's own log before it answers the journey (INF-1785, the captain's "Confirm each change from the simulator's log, and set it once more only when the log proves the phone missed it").
SpringBoard logs `Arbiter changing style from` as it applies an appearance, the simulator's bridge logs `Saved CategoryName` as it saves a text size, and the app logs `Read CategoryName` as it reads one (`PhoneDisplayChanges`).
The app's read of the new size applies the change, even when it is logged in the save's own millisecond.
A read of the old size after the save proves the app missed it, and only that proof sets the size once more; two proven misses fail the part.
A missing line or a stopped observer is unknown and sets nothing more.
A live log stream can drop a line the simulator's kept log holds, so before a witness answers unknown the runner reads the kept log since the change for it (INF-1799).
Every witness of one display request stops waiting at the journey's request cap less two minutes, one for that read and one for the request's way there and back (`phoneDisplayDeadline`), so the journey always hears the unknown before its own request ends.
An appearance SpringBoard misses leaves no line, and the simulator writes nothing when asked for the appearance it already has, so the runner sets each appearance once and prints one it could not confirm.
SpringBoard can apply an appearance minutes late, as it applied light 250 seconds after the request in run 40792658138, so the appearance witness waits for its line until `phoneDisplayDeadline` alone, with no shorter load-clock budget (INF-1786, the captain's "Wait for SpringBoard's own line, up to the request's 8-minute limit").
The journey's display requests carry a budget as long as their 10-minute cap (`displayBudget`, `PHONE_DISPLAY_REQUEST_BUDGET_MS`), so a request's load clock never ends it before the runner answers.
A turn of the device waits until a target the turn carries elsewhere has left its old frame and holds still in its new place (`turnPhone`), since until the app turns that target holds still where it was.
A check that read a dialog's button, a gliding row or a web page's answer right after an action waits for it on the load clock instead.
If Xcode stops offering that method, or changes what it takes, the journey fails naming it; the gate fails a part whose log never printed "Phone animation wait skipped", and prints how many animation waits XCTest still ran out in each part.
The talk part checks that Command-Return restores the field's observed empty value and writes exactly one captain message to the real home.
The talk part exercises details, keyboard dismissal, both card-paging shortcuts and Send as first chords after relaunch, retaining the original button and draft assertions.
The composed journey verifies keyboard dismissal and computer details after relaunch without changing its retained-text and retained-photo assertions.
It also checks that the card and Tasks start and end where the message box does, the reading column.
The fixture's display controls only change the launcher-owned simulator, never a developer's device or this Mac's appearance.
App-hosted shell tests render each native character's still pose, play the greeting, every held reply and every fidget through the character's machine, and read Activity from the real test home; the native journey also verifies the computer-authored task key.
The empty-stage character consumes the Mac's `firstmate_state.busy` event, the same conversation-state owner as the desktop, and the journey holds and completes a real first-mate turn through the mock provider to verify working and idle.
A stopped or lost connection clears the busy reading; a home on major 12 or later, or one advertising `native-scene-observations`, supplies an initial busy snapshot, while an older home stays unobserved until a busy event arrives.
Native keyboard dictation exposes no listening signal: the phone never infers listening from focus or typing, and the listening drawing is not a live conversation state.
Native hero pictures use the same crop in both themes from the simulator's full-resolution attachments; the desktop-only `heroShot` cannot capture a SwiftUI view.

The talk part chooses a project-owned picture from the disposable photo library, types a message, and checks the real Mac’s captain actor, image bytes and last turn.
It pulls the task search down, closes it, opens it again by Find a task's key, then searches and starts an on-request task, checks that the real Mac ran it, and interrupts its turn.
The fixture then gives that real task’s saved workspace and session the Interrupted state used by recovery; the phone continues it and sends a steer that the held mock-provider turn actually reads.
The fixture uses Pi with the mock provider’s Anthropic message format, matching its held-turn script; no Claude client or provider account is involved.
It also checks that the foreground notice sits under the top bar and over the iPad's landscape stage, waits on an iPhone on its side while the strip stays in the bar, and opens its own card on Home, retained offline drafts, an unconfirmed response with no automatic repeat, and a future-major home that allows reading but refuses changes.
The home records read and connection counts across streaming, pushed card revisions and an idle period longer than both pairing deadlines.
The journey also checks Control Center and removal while away with an owned endpoint that stalls TLS between authenticated refusals.
It pulls Control Center down in under a tenth of a second: a starved SpringBoard can stall on the pull's first touch while the system keeps only its first ~180 ms of touches, so a default-speed pull loses its lift and Control Center never finishes opening.
The home counts the TCP connections to its own port, the refusals pairing gives and the stalled handshakes since the removal, and the journey expects exactly two refusals and one stall after every attempt at the home but the last.
A starved simulator can outlast the phone's own handshake deadline at the home too, which sends no request and adds a round through the stalled address, so the count follows the phone's address order rather than the clock.
The launcher truncates the actual saved Mac only inside its owned simulator's app container; the same journey captures the damaged-record explanation and joins again with a fresh confirmed link.
Each part starts from its own fresh home and a clean app on its device's one simulator; the Xcode scheme's `PHONE_TEST_HOME` setting names that home's private control interface.
Native package tests exercise the Mac-produced link and certificate fixture and certificate/public-key compatibility without using a Mac Keychain.
App-hosted tests repair a missing certificate in the disposable simulator's own Keychain and inject protected-data read failures to check retry and the joining explanation.
They refuse to run on a physical device, and the iOS identity API itself refuses creation on macOS.

Unsigned simulator tests need an application identifier to use the simulator's own Keychain.
`SimulatorTests.xcconfig` disables signing and injects `Simulator.entitlements` into the app's simulator-only `__TEXT,__entitlements` section through the linker.
This is simulator metadata, not a signature: no `security` or `codesign` command, signing identity, profile, certificate lookup or keychain search-list change is involved.
Normal device builds use Xcode's own signing settings and do not include this test configuration.
The runner waits for simulator boot completion before launching tests and uses one test worker per simulator.

For interactive local development, `node scripts/phone-test-home.ts <output-json-outside-the-project>` keeps the same disposable real-core home open until interrupted.
The output names its control address and scratch root, and is private to that run.
`phone.yml` runs this same gate with `--both` for changes touching `ios/` or the phone-card or phone-contract generator and the contract shape guard.
A pull request no longer starts it (INF-2139): a crewmate whose change selects it requests it on its branch with `affected: "true"`, and its pull request selection below stays for the continuous run on `main` that replaces it.
The gate's own setup also selects it: `phone.yml`, `scripts/test-phone.ts`, `tests/helpers/phoneHome.ts`, `tests/helpers/phoneKeyboard.ts`, its activity writer `scripts/phone-activity.ts`, its leftover sweep `scripts/phone-leftovers.ts`, its check runner `scripts/phone-checks.ts` and its test plan helper `scripts/phone-test-plan.ts`.
Setup the gate never runs does not: `scripts/affected-phone.ts`, `scripts/replaced-phone-runs.ts`, `scripts/phone-test-home.ts`, and the virtual Mac scripts `scripts/virtual-mac/phone.sh`, `phone-job.sh` and `vm.sh` while `PHONE_VIRTUAL_MAC` is unset.
A pull request's gate keeps its six-minute part budget; the nightly check of `main` runs every part, while a crewmate's request with `affected: "true"` runs only touched parts and falls back to every part when scope is uncertain (`docs/testing.md`, "The phone parts a pull request runs").
Shared modules, connection/device code, general packages and the lockfile alone do not select it; a changed generated Swift file does, unless it changes only its `public static let version` line, which includes a new first number: the phone and the computer come from the same pull request, so they always agree on it, and `docs/contract.json` alone never selects the gate.
Every pull request still checks on Linux that the generated file is current, through `pnpm check` (`node scripts/generate-phone-contract.ts --check`).
Its Linux chooser reads the full git comparison with `scripts/affected-phone.ts`; an unreadable comparison runs the gate, and an unrelated change explicitly skips the native job.
A default run on request (`workflow_dispatch`, such as the nightly check of `main`) skips the chooser and runs every part on both devices, then keeps each part's minutes as `part-times.json` in `phone-logs`; it has no pull request, so nothing replaces or cancels it, and it starts no release step (`docs/testing.md`, "The phone check on request").
Inside a gate, a failed Swift package test is reported and the simulator tests still run (`scripts/phone-checks.ts`).
The gate does not check the generated Swift files: `pnpm check` does on every pull request, on Linux.
The native job uses `VIRTUAL_MAC_RUNNER` when it is set, otherwise `MAC_RUNNER`, falling back to the `mini-mac` label rather than a paid hosted Mac, and retains result bundles, logs and connection readings as `phone-results` when the job fails or a run on request records; a passing check uploads none of its result bundles, about 530 MB.
It also uploads command logs separately as `phone-logs`, so an Xcode failure can be read without downloading screenshot-heavy result bundles.
Each part's live simulator log goes to `phone-simulator-logs` instead, on every run: one part's log can pass 100 MB, and a full gate's twelve would take `phone-logs` past the app's 64 MiB artifact download (INF-2053).
A third artifact, `phone-pictures`, holds only the pictures the journeys took, exported from the result bundles under `<device>/<part>`, so a crewmate reads them within the app's artifact limit, which `phone-results` has outgrown.
A failed part adds to its command logs what the app, its card pages and Photos logged on its simulator, and names its failing lines in the job log.
It also keeps, in a log of its own, what the simulator's system logged from the part's first test: SpringBoard, backboardd, the accessibility server, the keyboard and the test runner, which answer XCUITest's check for interrupting elements.
Its package install also uses a scratch HOME and an empty local-signing directory, so the install-time signature check never reads this Mac's signing material.
A newer push never waits behind its pull request's older phone run: `phone.yml` has no run-level concurrency group.
Its `cancel-replaced` job cancels the pull request's older phone runs whose native job has not started its device gate, so a replaced version gives up its place in the Mac mini's line (`scripts/replaced-phone-runs.ts`).
A device gate that already started is never cancelled; it finishes and deletes the simulator it started for each device.
No simulator exists right before the gate, so there a replaced version cancels its own run instead of starting the gate; a failed reading of the pull request runs the gate.
That check also stops a manual rerun of a replaced version, which no newer run cancels, about a minute after it reaches the Mac mini.
It stops the run of a pull request that merged or closed while the run waited in the phone line the same way, so a merged pull request never holds that line for a device gate; the nightly check of `main` checks what merged.
On the Mac mini's own runners, native jobs share the repository-wide `mac-mini-phone` concurrency group, with `queue: max` and cancellation disabled at the job level; GitHub keeps up to 100 pending phone jobs.
A job on the placement service's virtual-Mac label takes a group of its own instead, so phone checks run side by side, one per free virtual place ("A phone check the placement service puts in a virtual Mac").
Desktop jobs from different pull requests have no common job-level concurrency group, so they can run side by side.
Desktop journeys and native device gates run directly, without a command lease, so real and virtual Mac checks can overlap.
The `test:phone` package script checks the configured execution mode before running `scripts/test-phone.ts` directly; the gate owns a scratch HOME and disposable simulators.
A local gate first waits for its place: in this computer's load line where its shell has one, otherwise in the crew place service's one line, and starts at once where neither runs (`docs/testing.md`, "A local heavy run's place").
Before the gate starts any phone work, `scripts/phone-activity.ts` publishes a private, atomic activity record for its supervisor in `IDLE_REBOOT_PHONE_ACTIVITY_DIR`, or the invoking account's real `Library/Caches/infinitary-ci/phone-activity` folder, never the disposable HOME.
Each invocation owns one uniquely named JSON file containing only `schemaVersion: 1`, its `pid` and `processStartedAt`, the normalized `LC_ALL=C TZ=UTC /bin/ps -o lstart=` reading for that PID.
The supervisor stays alive through teardown and removes only its own file after cleanup; this is activity reporting, with no lock, admission wait, heartbeat or age expiry.
The paired reader is dotfiles-private's `hosts/PHONE_ACTIVITY.md` contract and idle-reboot watchdog; producer and reader must merge together before the lock removals are complete.
The device gate has a 60-minute step limit on every route: the real Mac, the fixed virtual-Mac switch and a placed virtual Mac.
The native job retains its 165-minute job limit for setup, checks, cleanup and evidence upload, without command-admission waits.
Neither device's failure is ignored: their parts run side by side and any failing fails the gate; on a pull request the first failed part stops the rest.
This pull-request lane neither signs a physical-device build nor publishes one; `ios-release.yml` runs the same native gates before its separately dispatched TestFlight upload.
Mac-side checks remain the project's normal gate and affected Devices journeys.

### The phone check in a virtual Mac

On the Mac mini, a local virtual Mac runs only under `borrow-virtual-mac --label <text> --minutes <n> -- <command>`, borrowing `mini-vm1` or `mini-vm2` beside CI jobs.
Use `BORROW_MINUTES=45 scripts/virtual-mac/phone.sh run <results folder> iphone ipad` to keep one borrow through startup, the gates and deletion, returning the gate's exit status even on failure.
Outside CI the script borrows automatically where the command exists, reuses `BORROWED_PLACE` when already borrowed, and starts at once where the command is missing.
It uses `BORROWED_VM` and the granted size; a run with `BORROWED_PLACE` asks neither the load line nor a crew place and says it rides the borrow.
Do not add a load-line declaration, crew place or hand-made hold for that virtual Mac.
The borrow lasts until the command ends or the later of one hour and the declared minutes.
Local split `start`/`gate`/`delete` calls require an explicit outer borrow where the command exists; CI's split lifecycle below is unchanged.

The repository variable `PHONE_VIRTUAL_MAC` moves the pull request's two device gates off the Mac mini and into a fresh virtual Mac cloned from the lane's image (`docs/testing.md`, "A virtual Mac as a runner").
Unset or empty, `native-phone` runs exactly as described above.
Set, the job runs on the phone check's own runner, labelled `mini-mac-vm`, which takes no Mac mini slot, and it installs no packages on the Mac itself.
`scripts/virtual-mac/phone.sh start` deletes a clone an earlier check left, clones `infinitary-lane` as `infinitary-lane-phone`, starts it with the pull request's committed version and installs its packages inside it.
The version rides in as a `git archive` of the checkout, because a pull request's checkout is shallow and a bundle of it cannot be fetched into an empty clone.
The gate step then runs `phone.sh gate iphone ipad`, which runs `scripts/test-phone.ts --both --simulators 2` inside the clone, two simulators at a time for its 6 CPUs and 16 GB, and copies each device's results into `$RUNNER_TEMP/phone/<device>`, so a failed check's `phone-results` keeps what the Mac mini's gate keeps, a failed device's included.
The last step, `phone.sh delete`, stops and deletes the clone however the job ends, a cancelled or replaced run's included.
The phone workflow does not exclude journeys.
The `mac-mini-phone` queue is what keeps one phone clone running at a time, so with this variable set every phone check takes that shared line whatever `VIRTUAL_MAC_RUNNER` says.
Whatever its value, the gate is the same one step as on the Mac mini, `Read and recover on iPhone and iPad at once`, right after the replacement check.
The script prints in UTC when the virtual Mac started and when each device began and ended.
The image and its base image's download take about 80 GB together in tart's own `~/.tart` on the Mac mini.
Set the variable only once that runner is registered, finds `tart` on its search path and the image is built; otherwise every phone check waits for the runner or fails at its first step.
The Mac mini's idle watchdog counts a running `tart run` process as work for up to three hours, so it does not restart the Mac under a phone check.
While the variable is set, a crewmate's own `pnpm test:phone` stays on the Mac mini and checks the iPhone alone, leaving both devices to the pull request's phone check; `github_read` of `/repos/{owner}/{repo}/actions/variables` lists the variable when it is set.

### A phone check the placement service puts in a virtual Mac

Once `MAC_RUNNER` names the placement service's label (`docs/testing.md`, "One image for every project"), `native-phone` runs on whichever place the service gives it, usually a fresh virtual Mac of its own.
The gate step asks macOS whether it runs in a virtual Mac (`sysctl -n kern.hv_vmm_present`); there it runs `scripts/test-phone.ts --both --simulators 2` directly.
Two simulators at a time match the virtual Mac's 6 CPUs and 16 GB, as `phone-job.sh` runs them, and INF-621's two complete iPhone and iPad proofs passed in that image.
On the real Mac's place the gate runs directly too, using the gate's default simulator concurrency.
Leave `PHONE_VIRTUAL_MAC` unset with the placement service: a job already inside a virtual Mac cannot start another one.

The repository variable `VIRTUAL_MAC_RUNNER`, which `native-phone` reads before `MAC_RUNNER`, names the service's virtual-Mac label, `mini-mac-virtual`, so the phone check never takes the real Mac's place (INF-897).
GitHub hands a scale set's new runner whichever of that set's waiting jobs it picks, not the one the service started it for, so in the scale set the other Mac jobs share, the service's choice does not hold.
On that label each phone check takes a concurrency group of its own, so phone checks no longer wait in one line: each waits only for a free virtual place, and both virtual places can run phone checks at once (the captain's choice on INF-989: "let both virtual Macs run phone checks at once by ending the one-at-a-time line").
The real Mac never takes that label, so a phone check never takes its place.
A runner the service starts for one phone check may take another waiting phone check, or that rarer check in the same set; either is a job that asked for a virtual Mac.
The service gives a free virtual place first to the oldest job that asks for a virtual Mac (`Plan` in dotfiles-private's `pkgs/fm-placer/schedule.go`), so a released phone check starts on the next free virtual place instead of behind every Mac job already waiting.
Unset, the job runs where `MAC_RUNNER` sends it, as before; `tests/phone-ci.test.ts` evaluates the job's runner for each setting.

## Generated and bundled assets

The phone's `Assets.xcassets/AppIcon.appiconset` contains a flat, opaque 1024-pixel render of the existing design asset `.claude/skills/infinitary-design/assets/app-icon.svg`.
Unlike the desktop package icon, it has no inset or baked-in corner mask; iOS supplies its own shape.
`scripts/render-phone-icon.mjs` renders that source through a hidden Electron window and writes an RGB PNG with no alpha channel, as Apple requires.
To regenerate it, create an empty temporary folder outside the project, set `HOME`, `CFFIXED_USER_HOME` and `INFINITARY_ICON_HOME` to that folder, set `INFINITARY_LOCAL_CODESIGN_DIR` to an empty child of it, then run `node_modules/.bin/electron scripts/render-phone-icon.mjs`.
The renderer never launches the product or reads its saved data.
The app bundles BoringSSL as a dependency of `swift-certificates`, which builds the phone's self-signed sign-in certificate using a CryptoKit P-256 key.
Connections use iOS `URLSession` TLS in `PinnedTransport`; bundled BoringSSL does not provide the app's TLS transport.
`ITSAppUsesNonExemptEncryption` remains false for this sign-in and secure-connection use; revisit the declaration whenever the cryptography or its uses change.
The release-tool tests exercise version validation, Apple readiness and processing reads, the workflow's actual conditions, and archive/export/upload through disposable stand-in commands.
They run in the existing Linux PR cohorts; no secret or signing access is needed.
Set `INFINITARY_PHONE_RELEASE_EVIDENCE` to a folder outside the project to retain their non-secret command transcripts; the stand-in uploader's success is never proof of a real Apple upload.

`node scripts/generate-phone-theme.ts` copies light/dark values, spacing and radii from the design skill into adaptive native colors and lengths.
It also writes the void into the `LaunchBackground` color asset that `Info.plist`'s launch screen names, because the system draws that screen before any Swift runs.
The native TTF fonts are format-only conversions of the skill's Latin Space Grotesk and JetBrains Mono WOFF2 assets, retaining their original names and outlines.
To regenerate them with FontTools and Brotli installed in a disposable Python environment, load each WOFF2 with `fontTools.ttLib.TTFont`, set `flavor = None`, and save it to the matching file under `InfinitaryApp/Fonts/`.
The app includes their SIL Open Font License notice and the Apple packages' license and notice files.
Swift package versions and revisions are pinned in the package and Xcode workspace lockfiles.
