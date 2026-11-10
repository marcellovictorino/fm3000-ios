import ImageIO
import InfinitaryKit
import PhotosUI
import SwiftUI

struct MessageComposer: View {
    let session: ReadOnlySession
    @Environment(PhoneMessageContext.self) private var messageContext
    @State private var text = ""
    @State private var photos: [Photo] = []
    @State private var selection: [PhotosPickerItem] = []
    @State private var loading = false
    @State private var problem: String?
    @State private var sent = 0
    @FocusState private var focused: Bool
    /// fm3000-ios: the label's switch; true sends this box's words to the first mate while a card is on screen.
    @State private var toMate = false
    @Environment(\.verticalSizeClass) private var verticalSize
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var replyOpen: OpenedReply?
    /// The reading clock (docs/composer.md "The last turn"): the reply it counts, the time left, and whether it faded.
    @State private var fadeKey: String?
    @State private var remaining = Self.readingTime
    @State private var faded = false

    /// The Mac's `READING_MS` (src/renderer/src/app/lastTurnFade.ts): the captain's choice.
    private static let readingTime = Duration.seconds(15)

    private var compact: Bool { phoneOnItsSide(verticalSize) }
    private var draftLayout: AnyLayout {
        compact ? AnyLayout(HStackLayout(spacing: PhoneTheme.space2))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: PhoneTheme.space2))
    }

    /// fm3000-ios: the card on screen that takes a reply from this box, unless the label has switched it to the first mate.
    private var replier: PhoneMessageContext.Replier? {
        guard messageContext.cardsVisible, let replier = messageContext.replier,
              messageContext.card == .current(replier.cardID) else { return nil }
        return replier
    }
    private var cardMode: Bool { replier != nil && !toMate }
    private var shownText: Binding<String> {
        guard cardMode, let id = replier?.cardID else { return $text }
        return Binding(get: { messageContext.replyDrafts[id] ?? "" }, set: { messageContext.replyDrafts[id] = $0 })
    }
    private var shownPhotos: Binding<[Photo]> {
        guard cardMode, let id = replier?.cardID else { return $photos }
        return Binding(get: { messageContext.replyPhotos[id] ?? [] }, set: { messageContext.replyPhotos[id] = $0.isEmpty ? nil : $0 })
    }

    private var canSend: Bool {
        let empty = shownText.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && shownPhotos.wrappedValue.isEmpty
        if cardMode, let replier {
            return session.canChange && !loading && replier.ready && !empty
                && shownText.wrappedValue.utf16.count <= PhoneLimits.reply
        }
        return session.canChange && !loading && !empty
    }

    typealias Photo = PhonePhoto

    var body: some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space2) {
            // INF-589 item 17: on its side an iPhone gives the card this height; the last turn returns upright.
            if let turn = session.lastTurn, !compact { lastTurn(turn) }
            // AnyLayout moves the same controls; neither rotation nor a tab creates a second draft.
            if let replier { targetLabel(replier) }
            draftLayout {
                if !shownPhotos.wrappedValue.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(shownPhotos.wrappedValue) { photo in
                                Button { shownPhotos.wrappedValue.removeAll { $0.id == photo.id } } label: {
                                    Image(uiImage: photo.image).resizable().scaledToFill()
                                        .frame(width: 44, height: 44).clipped()
                                        .overlay(alignment: .topTrailing) { Image(systemName: "xmark.circle.fill").foregroundStyle(PhoneTheme.text, PhoneTheme.surface) }
                                }.accessibilityLabel("Remove photo").accessibilityIdentifier("photo-chip")
                            }
                        }
                    }.frame(maxWidth: compact ? 96 : .infinity)
                }
                // INF-1517, the captain's pick from ChatGPT's input: 48 points tall, the photo glyph 16 points in,
                // the words 52 points in, and send a 32-point circle 8 points from the end, each in a 44-point touch area.
                HStack(alignment: .bottom, spacing: 0) {
                    PhotosPicker(selection: $selection, maxSelectionCount: max(1, PhoneLimits.images - shownPhotos.wrappedValue.count), matching: .images) {
                        // The glyph is about 22 points wide, centered in its 44: 5 + 11 puts it 16 in. The inset stays
                        // inside the button, so its frame starts where the box does, on the reading column.
                        Label("Photos", systemImage: "photo").labelStyle(.iconOnly).frame(width: 44, height: 48)
                            .padding(.leading, 5).contentShape(Rectangle())
                    }.disabled(loading || shownPhotos.wrappedValue.count >= PhoneLimits.images).accessibilityIdentifier("add-photos")
                    TextField(cardMode ? PhoneCardWords.replyHint : "Give your first mate a task", text: shownText, axis: .vertical)
                        .lineLimit(1...(compact ? 2 : 4)).focused($focused)
                        .padding(.vertical, PhoneTheme.space3).frame(minHeight: 48)
                        .padding(.leading, 3)
                        .accessibilityIdentifier("message-box")
                    Button { send() } label: {
                        Image(systemName: "arrow.up").font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(PhoneTheme.onAccent)
                            .frame(width: 32, height: 32)
                            .background(canSend ? PhoneTheme.accent : PhoneTheme.muted, in: Circle())
                            .frame(width: 44, height: 48).padding(.trailing, 2).contentShape(Rectangle())
                    }.keyboardShortcut(.return, modifiers: .command)
                        .disabled(!canSend)
                        .accessibilityLabel("Send")
                        .accessibilityIdentifier("send-message")
                        // INF-3106 direction B: the keyboard-down circle before send, matching its 32 points.
                        .hidesKeyboardBefore(focused && messageContext.keyboardUp, diameter: 32, height: 48)
                }
                    // INF-589 item 11: out of reach, the input dims; a draft stays typeable and is kept. INF-3462: only what
                    // the box holds dims, so its glass keeps blurring the crew scene that passes behind it.
                    .opacity(session.canChange ? 1 : 0.5)
                    .phoneInput(floating: true)
            }
            if loading { ProgressView("Adding photos…") }
            if let words = session.changesOffLine {
                Text(words).font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                    .accessibilityIdentifier("connection-refusal")
            }
            // INF-2553: on its side there is no notice pill, so a message taken back says why here, as a refusal did before.
            if let problem = problem ?? (compact ? session.takenBack[PhoneIntent.messagePlace] : nil) {
                Text(problem).foregroundStyle(PhoneTheme.warning).accessibilityIdentifier("message-problem")
            }
        }.font(PhoneFont.callout).padding(.top, compact ? PhoneTheme.space2 : PhoneTheme.space3)
            // INF-589 item 15: the message box lines up with the card above it, inside the gutters the footer keeps.
            .frame(maxWidth: PhoneColumn.inside).frame(maxWidth: .infinity)
            .task(id: selection) { await loadPhotos() }
            // INF-1524: a card's draft button puts its words at the start of the box, unsent, for the captain to finish.
            .onChange(of: messageContext.draft, initial: true) { _, draft in
                guard let draft else { return }
                messageContext.draft = nil
                let box = shownText
                box.wrappedValue = box.wrappedValue.isEmpty ? draft : "\(draft) \(box.wrappedValue)"
                focused = true
            }
            // fm3000-ios: each card opens with its box replying to it; the switch is for one card at a time.
            .onChange(of: messageContext.card) { toMate = false }
            // fm3000-ios: no Done above the keyboard here. On iOS 27 it floats over the send arrow, so a send took two
            // taps. The bar's own Done, a swipe down or a tap on the card close the keyboard instead.
            // INF-589 item 12: a soft tap once the computer accepts the message.
            .sensoryFeedback(.phone, trigger: sent)
    }

    /// fm3000-ios, the captain's pick: the label names the card on screen; pressing it switches this one box between
    /// replying to the card and messaging the first mate, which still carries the card as its hint.
    private func targetLabel(_ replier: PhoneMessageContext.Replier) -> some View {
        Button { toMate.toggle() } label: {
            HStack(spacing: 6) {
                Image(systemName: toMate ? "paperplane" : "arrow.turn.down.right").imageScale(.small)
                Text(toMate ? "First mate" : replier.title).lineLimit(1)
                Spacer(minLength: 4)
                Text(toMate ? "↺ \(replier.title)" : "→ First mate").lineLimit(1).foregroundStyle(PhoneTheme.secondary)
                    .frame(maxWidth: 140, alignment: .trailing)
            }
            .font(PhoneFont.caption).foregroundStyle(toMate ? PhoneTheme.text : PhoneTheme.accent)
            .padding(.horizontal, PhoneTheme.space3).frame(minHeight: 32)
            .background((toMate ? PhoneTheme.text.opacity(0.08) : PhoneTheme.accent.opacity(0.14)), in: Capsule())
            .contentShape(Capsule())
        }.buttonStyle(.plain)
            .accessibilityLabel(toMate ? "Messaging the first mate" : "Replying to \(replier.title)")
            .accessibilityHint("Switches where this message goes")
            .accessibilityIdentifier("box-target")
    }

    /// The Mac's last turn (src/renderer/src/app/LastTurn.tsx), drawn as INF-1770's Chat layout: the last two rounds,
    /// each the captain's words in a soft grey bubble on the right and the first mate's reply beside its mark on the
    /// left, the older round at half strength and only the newest while a card is up. While the first mate works, the
    /// newest round's mark turns ember and spins (INF-2483), beside its reply or Working…. After 15 seconds of a completed
    /// reply on screen the older round dissolves and keeps its room, so the input never moves. INF-1846 chose "A quiet
    /// glance": 15-point rows, 12 points between rounds and 12 above the box, one line each.
    private func lastTurn(_ turn: PhoneLastTurn) -> some View {
        let key = Self.fadeKey(turn)
        let hidden = faded && key != nil && key == fadeKey
        // The count runs only while Home is shown, the app is open, the phone is upright and the first mate is idle.
        let readable = messageContext.cardsVisible && phase == .active && !compact && !session.firstmateBusy
        let cardUp = messageContext.cardsVisible && messageContext.card != nil
        let older = cardUp ? nil : turn.previous
        return VStack(spacing: 12) {
            if let older {
                round(older, newest: false)
                    .opacity(hidden ? 0 : 1).accessibilityHidden(hidden).disabled(hidden)
            }
            round(PhoneLastRound(you: turn.you, reply: turn.reply), newest: true)
        }.font(PhoneFont.subheadline).lineLimit(1)
            // The composer's stack adds 8 points; these 4 make the 12 above the box.
            .frame(maxWidth: .infinity).padding(.bottom, 4)
            .task(id: "\(key ?? "")|\(readable)") { await read(key, readable: readable) }
            .sheet(item: $replyOpen) { opened in PhoneReplySheet(round: opened.round) }
    }

    /// One round: the captain's bubble, then the first mate's line, 4 points apart. The bubble hugs its words up to three
    /// quarters of the column, and the reply row is 24 points tall, in the secondary colour, pressable across its width.
    /// The older round's identifiers carry `older`.
    private func round(_ round: PhoneLastRound, newest: Bool) -> some View {
        let id = newest ? "last-turn" : "last-turn-older"
        let busy = newest && session.firstmateBusy
        // The older round is drawn at half strength.
        let strength = newest ? 1.0 : 0.5
        let bubble = UnevenRoundedRectangle(topLeadingRadius: 14, bottomLeadingRadius: 14, bottomTrailingRadius: 5, topTrailingRadius: 14)
        return VStack(alignment: .leading, spacing: 4) {
            BubbleColumn {
                Text(round.you.isEmpty ? "A picture" : round.you)
                    .foregroundStyle(PhoneTheme.text)
                    .padding(.vertical, 4).padding(.horizontal, 12)
                    .background(PhoneTheme.text.opacity(0.1), in: bubble)
                    .opacity(strength)
                    // INF-3462, the captain's pick: the bubble is solid in the colour it always showed, so the crew scene
                    // passing behind it is hidden.
                    .background(PhoneTheme.background, in: bubble)
                    .accessibilityIdentifier("\(id)-you")
            }
            if round.reply != nil || busy || (newest && session.messageSending) {
                HStack(spacing: 8) {
                    MateMark(working: busy, still: reduceMotion).frame(width: 16, height: 16)
                    if let reply = round.reply {
                        Button { replyOpen = OpenedReply(round: round) } label: {
                            Text(reply.text).foregroundStyle(reply.problem == true ? PhoneTheme.danger : PhoneTheme.secondary)
                                .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityHint("Opens the whole reply")
                            .accessibilityIdentifier("\(id)-reply")
                    } else if newest && session.messageSending {
                        // INF-2553: the message is the last turn at the tap, marked sending until the computer has it.
                        Text("Sending…").foregroundStyle(PhoneTheme.muted)
                            .frame(minHeight: 24).accessibilityElement(children: .combine).accessibilityIdentifier("last-turn-sending")
                    } else {
                        Text("Working…").foregroundStyle(PhoneTheme.muted)
                            .frame(minHeight: 24).accessibilityElement(children: .combine).accessibilityIdentifier("\(id)-reply")
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).opacity(strength)
            } else {
                Text(verbatim: " ").frame(minHeight: 24).accessibilityHidden(true)
            }
        }
    }

    /// The reply this clock may fade, or nil while the line must stay: a problem, a queued receipt or an unknown line.
    static func fadeKey(_ turn: PhoneLastTurn) -> String? {
        guard let reply = turn.reply, reply.problem != true, reply.eligibility == "completed" else { return nil }
        return "\(turn.you)\u{0}\(reply.text)"
    }

    /// A new reply starts a fresh 15 seconds; leaving Home, the background, a turn on its side or work in flight
    /// pauses the count and keeps what is left. The dissolve takes 0.7 seconds, an instant under reduced motion.
    private func read(_ key: String?, readable: Bool) async {
        if key != fadeKey { fadeKey = key; remaining = Self.readingTime; faded = false }
        guard key != nil, readable, !faded else { return }
        let start = ContinuousClock.now
        do { try await Task.sleep(for: remaining) } catch {
            remaining = max(.zero, remaining - (ContinuousClock.now - start)); return
        }
        remaining = .zero
        withAnimation(reduceMotion ? nil : .linear(duration: 0.7)) { faded = true }
    }

    /// INF-2553: the box clears at the tap and the message is the last turn, marked sending; a refusal puts the words and
    /// pictures back in front of anything typed since, and the session says why.
    private func send() {
        guard !loading, session.canChange else { return }
        // fm3000-ios: a reply goes through the card's own send, which keeps the card's answers and thread.
        if cardMode, let replier {
            guard canSend else { return }
            focused = false; problem = nil
            replier.send()
            return
        }
        guard text.utf16.count <= PhoneLimits.text else { problem = "This message is too long. Shorten it before sending."; return }
        let words = text, pictures = photos
        var payload: [String: Any] = ["text": words, "images": pictures.map(\.wire)]
        for (key, value) in messageContext.fields { payload[key] = value }
        focused = false
        problem = nil
        text = ""; photos = []
        // The computer keeps the words trimmed, and its turn for them follows the last turn shown now.
        let intent = PhoneIntent.Kind.send(text: words.trimmingCharacters(in: .whitespacesAndNewlines), before: PhoneTurnMark(session.lastTurn))
        Task {
            do {
                let box = $text, shelf = $photos
                let restore: @MainActor () -> Void = { @MainActor in
                    box.wrappedValue = box.wrappedValue.isEmpty ? words : words + "\n" + box.wrappedValue
                    shelf.wrappedValue = Array((pictures + shelf.wrappedValue).prefix(PhoneLimits.images))
                }
                try await session.change(intent, .converse, args: [payload], restore: restore)
                sent += 1
            } catch {}
        }
    }

    private func loadPhotos() async {
        guard !selection.isEmpty else { return }
        loading = true; problem = nil
        defer { loading = false; selection = [] }
        for item in selection {
            do {
                guard shownPhotos.wrappedValue.count < PhoneLimits.images, let bytes = try await item.loadTransferable(type: Data.self) else {
                    throw PhoneError.refused("Could not add this photo. Choose another.")
                }
                try Task.checkCancellation()
                shownPhotos.wrappedValue.append(try PhonePhoto(bytes: bytes))
            } catch is CancellationError { return }
            catch { problem = error.localizedDescription }
        }
    }
}

/// The captain's bubble on the right, hugging its words up to three quarters of the width it is offered.
private struct BubbleColumn: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let bubble = subviews.first?.sizeThatFits(widest(proposal.width)) ?? .zero
        return CGSize(width: proposal.width ?? bubble.width, height: bubble.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let bubble = subviews.first else { return }
        let offered = widest(bounds.width)
        bubble.place(at: CGPoint(x: bounds.maxX, y: bounds.minY), anchor: .topTrailing, proposal: offered)
    }

    private func widest(_ width: CGFloat?) -> ProposedViewSize {
        ProposedViewSize(width: width.map { $0 * 0.75 }, height: nil)
    }
}

/// The round whose reply line was pressed: the newest or the older one.
private struct OpenedReply: Identifiable {
    let id = UUID()
    let round: PhoneLastRound
}

/// The first mate's mark beside each reply line: the app's hexagon in accent, as the Mac draws it (lastTurn.css,
/// LastTurn.tsx). While the first mate works it turns ember over 0.16 s and spins one steady turn every 2 s (INF-2483's
/// plan, the captain's Approve and build: "turn the mark to orange and spin it"); when work ends it eases on to its next
/// resting sixth of a turn over 0.36 s as it fades back to accent. Under reduced motion it turns ember and stands still.
private struct MateMark: View {
    let working: Bool
    let still: Bool
    /// One whole turn, in seconds: INF-2483's chosen steady turn.
    static let turn = 2.0
    @State private var started = Date()
    @State private var resting = 0.0

    var body: some View {
        TimelineView(.animation(paused: !working || still)) { clock in
            ZStack {
                MarkHexagon(points: [(8, 1.2), (13.9, 4.6), (13.9, 11.4), (8, 14.8), (2.1, 11.4), (2.1, 4.6)])
                MarkHexagon(points: [(12, 8), (10, 11.46), (6, 11.46), (4, 8), (6, 4.54), (10, 4.54)]).opacity(0.45)
                MarkDot()
            }
            .foregroundStyle(working ? PhoneTheme.hot : PhoneTheme.accent)
            .rotationEffect(.degrees(working && !still ? angle(at: clock.date) : resting))
        }
        .animation(.linear(duration: working ? 0.16 : 0.36), value: working)
        .onChange(of: working) { was, now in
            if now { started = Date(); resting = 0; return }
            guard was, !still else { resting = 0; return }
            let at = angle(at: Date())
            resting = at
            withAnimation(.easeOut(duration: 0.36)) { resting = (at / 60).rounded(.up) * 60 }
        }
        .onAppear { started = Date() }
        .accessibilityHidden(true)
    }

    private func angle(at date: Date) -> Double {
        let turns = date.timeIntervalSince(started) / Self.turn
        return (turns - turns.rounded(.down)) * 360
    }
}

/// A hexagon of the mark as its 1.2-unit outline, its points on the mark's 16-unit grid, drawn at any size.
private struct MarkHexagon: Shape {
    let points: [(CGFloat, CGFloat)]
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 16
        var path = Path()
        path.addLines(points.map { CGPoint(x: rect.minX + $0.0 * scale, y: rect.minY + $0.1 * scale) })
        path.closeSubpath()
        return path.strokedPath(StrokeStyle(lineWidth: 1.2 * scale))
    }
}

/// The mark's centre dot, 1.3 units of 16 in radius.
private struct MarkDot: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 16
        let dot = 1.3 * scale
        return Path(ellipseIn: CGRect(x: rect.midX - dot, y: rect.midY - dot, width: dot * 2, height: dot * 2))
    }
}

/// INF-2218, A · Open reply: the saved question in the shared bubble above an unboxed answer.
/// Reading stays inside the existing sheet, with native sizing and Done dismissal; nothing is sent.
private struct PhoneReplySheet: View {
    let round: PhoneLastRound
    @Environment(\.dismiss) private var dismiss
    @State private var questionOpen = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PhoneTheme.space5) {
                    BubbleColumn {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("You").font(PhoneFont.mono).foregroundStyle(PhoneTheme.muted)
                            PhoneQuestionBubble(
                                text: round.you,
                                open: $questionOpen,
                                identifier: "reply-note-question")
                        }
                    }
                    if let reply = round.reply {
                        VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                            HStack(spacing: PhoneTheme.space2) {
                                MateMark(working: false, still: true).frame(width: 16, height: 16)
                                Text("First mate").font(PhoneFont.mono).foregroundStyle(PhoneTheme.muted)
                            }
                            Text(reply.words ?? reply.text).font(PhoneFont.callout)
                                .foregroundStyle(reply.problem == true ? PhoneTheme.danger : PhoneTheme.text)
                                .textSelection(.enabled).accessibilityIdentifier("reply-note-words")
                                .padding(.leading, PhoneTheme.space4 + PhoneTheme.space2)
                        }
                    }
                }.padding(PhoneTheme.space5).frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityIdentifier("reply-note-scroll")
            .phoneTitle("Reply")
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }.accessibilityIdentifier("close-reply-note")
            } }
        }
        .font(PhoneFont.body).foregroundStyle(PhoneTheme.text).tint(PhoneTheme.accent)
        .presentationDetents([.medium, .large]).presentationDragIndicator(.visible).phoneSheetSurface()
    }
}

/// A photo the captain adds to a message or a card's reply: scaled to at most 2,048 pixels and sent as a JPEG.
struct PhonePhoto: Identifiable {
    let id = UUID()
    let data: Data
    let image: UIImage
    var wire: [String: String] { ["mimeType": "image/jpeg", "data": data.base64EncodedString(), "name": "Photo.jpg"] }

    init(bytes: Data) throws {
        guard let source = CGImageSourceCreateWithData(bytes as CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 2048,
              ] as CFDictionary) else { throw PhoneError.refused("Could not add this photo. Choose another.") }
        try self.init(image: UIImage(cgImage: thumbnail))
    }

    init(image: UIImage) throws {
        guard let data = image.jpegData(compressionQuality: 0.85), data.count <= 5 * 1024 * 1024,
              ((data.count + 2) / 3) * 4 <= PhoneLimits.imageBase64 else {
            throw PhoneError.refused("This photo is too large. Choose a smaller photo.")
        }
        self.data = data; self.image = image
    }
}
