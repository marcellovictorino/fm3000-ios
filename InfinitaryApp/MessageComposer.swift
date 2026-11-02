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
    @State private var sending = false
    @State private var problem: String?
    @State private var sent = 0
    @FocusState private var focused: Bool
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

    private var canSend: Bool {
        session.canChange && !sending && !loading && !(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && photos.isEmpty)
    }

    typealias Photo = PhonePhoto

    var body: some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space2) {
            // INF-589 item 17: on its side an iPhone gives the card this height; the last turn returns upright.
            if let turn = session.lastTurn, !compact { lastTurn(turn) }
            // AnyLayout moves the same controls; neither rotation nor a tab creates a second draft.
            draftLayout {
                if !photos.isEmpty {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(photos) { photo in
                                Button { photos.removeAll { $0.id == photo.id } } label: {
                                    Image(uiImage: photo.image).resizable().scaledToFill()
                                        .frame(width: 44, height: 44).clipped()
                                        .overlay(alignment: .topTrailing) { Image(systemName: "xmark.circle.fill").foregroundStyle(PhoneTheme.text, PhoneTheme.surface) }
                                }.accessibilityLabel("Remove photo").accessibilityIdentifier("photo-chip")
                            }
                        }
                    }.frame(maxWidth: compact ? 96 : .infinity).disabled(sending)
                }
                // INF-1517, the captain's pick from ChatGPT's input: 48 points tall, the photo glyph 16 points in,
                // the words 52 points in, and send a 32-point circle 8 points from the end, each in a 44-point touch area.
                HStack(alignment: .bottom, spacing: 0) {
                    PhotosPicker(selection: $selection, maxSelectionCount: max(1, PhoneLimits.images - photos.count), matching: .images) {
                        // The glyph is about 22 points wide, centered in its 44: 5 + 11 puts it 16 in. The inset stays
                        // inside the button, so its frame starts where the box does, on the reading column.
                        Label("Photos", systemImage: "photo").labelStyle(.iconOnly).frame(width: 44, height: 48)
                            .padding(.leading, 5).contentShape(Rectangle())
                    }.disabled(loading || sending || photos.count >= PhoneLimits.images).accessibilityIdentifier("add-photos")
                    TextField("Give your first mate a task", text: $text, axis: .vertical)
                        .lineLimit(1...(compact ? 2 : 4)).focused($focused).disabled(sending)
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
                }.phoneInput(floating: true)
                    // INF-589 item 11: out of reach, the input dims; a draft stays typeable and is kept.
                    .opacity(session.canChange ? 1 : 0.5)
            }
            if loading { ProgressView("Adding photos…") }
            if sending { ProgressView("Sending…") }
            if let words = session.changesOffLine {
                Text(words).font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                    .accessibilityIdentifier("connection-refusal")
            }
            if let problem {
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
                text = text.isEmpty ? draft : "\(draft) \(text)"
                focused = true
            }
            // INF-589 item 12: a soft tap once the computer accepts the message.
            .sensoryFeedback(.phone, trigger: sent)
    }

    /// The Mac's last turn (src/renderer/src/app/LastTurn.tsx), drawn as INF-1770's Chat layout: the last two rounds,
    /// each the captain's words in a soft grey bubble on the right and the first mate's reply beside its mark on the
    /// left, the older round at half strength and only the newest while a card is up. While the first mate works, ember
    /// dots follow the newest reply, or stand with Working… where no reply is yet. After 15 seconds of a completed
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
                    .opacity(hidden ? 0 : 0.5).accessibilityHidden(hidden).disabled(hidden)
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
        return VStack(alignment: .leading, spacing: 4) {
            BubbleColumn {
                Text(round.you.isEmpty ? "A picture" : round.you)
                    .foregroundStyle(PhoneTheme.text)
                    .padding(.vertical, 4).padding(.horizontal, 12)
                    .background(PhoneTheme.text.opacity(0.1), in: UnevenRoundedRectangle(
                        topLeadingRadius: 14, bottomLeadingRadius: 14, bottomTrailingRadius: 5, topTrailingRadius: 14))
                    .accessibilityIdentifier("\(id)-you")
            }
            if round.reply != nil || busy {
                HStack(spacing: 8) {
                    MateMark().frame(width: 16, height: 16)
                    if let reply = round.reply {
                        Button { replyOpen = OpenedReply(round: round) } label: {
                            HStack(spacing: 8) {
                                Text(reply.text).foregroundStyle(reply.problem == true ? PhoneTheme.danger : PhoneTheme.secondary)
                                if busy { WorkingDots(still: reduceMotion) }
                            }.frame(maxWidth: .infinity, minHeight: 24, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityHint("Opens the whole reply")
                            .accessibilityIdentifier("\(id)-reply")
                    } else {
                        HStack(spacing: 6) {
                            WorkingDots(still: reduceMotion)
                            Text("Working…").foregroundStyle(PhoneTheme.muted)
                        }.frame(minHeight: 24).accessibilityElement(children: .combine).accessibilityIdentifier("\(id)-reply")
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
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

    private func send() {
        guard !sending, !loading, session.canChange else { return }
        guard text.utf16.count <= PhoneLimits.text else { problem = "This message is too long. Shorten it before sending."; return }
        var payload: [String: Any] = ["text": text, "images": photos.map(\.wire)]
        for (key, value) in messageContext.fields { payload[key] = value }
        focused = false
        sending = true; problem = nil
        Task {
            defer { sending = false }
            do {
                let result: PhoneAnswer = try await session.request(.converse, args: [payload])
                try result.accepted()
                text = ""; photos = []; sent += 1
            } catch { problem = error.localizedDescription }
        }
    }

    private func loadPhotos() async {
        guard !selection.isEmpty else { return }
        loading = true; problem = nil
        defer { loading = false; selection = [] }
        for item in selection {
            do {
                guard photos.count < PhoneLimits.images, let bytes = try await item.loadTransferable(type: Data.self) else {
                    throw PhoneError.refused("Could not add this photo. Choose another.")
                }
                try Task.checkCancellation()
                photos.append(try PhonePhoto(bytes: bytes))
            } catch is CancellationError { return }
            catch { problem = error.localizedDescription }
        }
    }
}

/// The Mac's working dots (lastTurn.css) at the phone's size (INF-1846): three 5-point ember dots 4 points apart, each
/// brightening in turn over 1.2 s.
private struct WorkingDots: View {
    let still: Bool
    var body: some View {
        TimelineView(.animation(paused: still)) { clock in
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { dot in
                    Circle().fill(PhoneTheme.hot).frame(width: 5, height: 5)
                        .opacity(still ? 1 : Self.opacity(clock.date.timeIntervalSinceReferenceDate - Double(dot) * 0.2))
                }
            }
        }.accessibilityHidden(true)
    }

    /// 0.25 at rest and 1 at 30% of the cycle, eased in and out, as the Mac's keyframes.
    static func opacity(_ time: Double) -> Double {
        let phase = (time.truncatingRemainder(dividingBy: 1.2) + 1.2).truncatingRemainder(dividingBy: 1.2) / 1.2
        guard phase < 0.6 else { return 0.25 }
        let rise = phase < 0.3 ? phase / 0.3 : (0.6 - phase) / 0.3
        return 0.25 + 0.75 * (0.5 - cos(rise * .pi) / 2)
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

/// The first mate's mark beside each reply line: the app's hexagon in accent, as the Mac draws it (lastTurn.css).
private struct MateMark: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 16
            func hexagon(_ points: [(CGFloat, CGFloat)]) -> Path {
                var path = Path()
                path.addLines(points.map { CGPoint(x: $0.0 * scale, y: $0.1 * scale) })
                path.closeSubpath()
                return path
            }
            let stroke = StrokeStyle(lineWidth: 1.2 * scale)
            context.stroke(hexagon([(8, 1.2), (13.9, 4.6), (13.9, 11.4), (8, 14.8), (2.1, 11.4), (2.1, 4.6)]),
                           with: .color(PhoneTheme.accent), style: stroke)
            context.stroke(hexagon([(12, 8), (10, 11.46), (6, 11.46), (4, 8), (6, 4.54), (10, 4.54)]),
                           with: .color(PhoneTheme.accent.opacity(0.45)), style: stroke)
            let dot = 1.3 * scale
            context.fill(Path(ellipseIn: CGRect(x: 8 * scale - dot, y: 8 * scale - dot, width: dot * 2, height: dot * 2)),
                         with: .color(PhoneTheme.accent))
        }.accessibilityHidden(true)
    }
}

/// INF-1517, the captain's pick: the reply line opens the whole reply in a half-height sheet, as the Mac's reply note.
/// Its title is the captain's message in quotation marks; its body the reply as written, a problem in red.
private struct PhoneReplySheet: View {
    let round: PhoneLastRound
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PhoneTheme.space2) {
                    Text(round.you.isEmpty ? "A picture" : "“\(round.you)”").font(PhoneFont.headline)
                        .accessibilityIdentifier("reply-note-title")
                    if let reply = round.reply {
                        Text(reply.words ?? reply.text).font(PhoneFont.callout)
                            .foregroundStyle(reply.problem == true ? PhoneTheme.danger : PhoneTheme.text)
                            .textSelection(.enabled).accessibilityIdentifier("reply-note-words")
                    }
                }.padding(PhoneTheme.space5).frame(maxWidth: .infinity, alignment: .leading)
            }
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
