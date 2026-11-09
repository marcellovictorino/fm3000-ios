import InfinitaryKit
import SwiftUI

/// INF-1524 piece 1, the captain's pick: the Mac's raised card. A solid fill, its thin edge, the light line inside its top
/// and its soft drop shadows, all read from the Mac's tokens through the theme generator, so both follow light and dark.
struct PhoneCardSurface: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    private let shape = RoundedRectangle(cornerRadius: PhoneTheme.cardRadius, style: .continuous)

    func body(content: Content) -> some View {
        content
            // The surface sits over the shadows: a later background draws behind an earlier one.
            .background(PhoneTheme.surface, in: shape)
            .background { shadows }
            .overlay { edge.allowsHitTesting(false).accessibilityHidden(true) }
    }

    /// CSS's `inset 0 1px 0`: a band inside the border along the top, thinning into the corners as the Mac draws it.
    private var edge: some View {
        let inner = shape.inset(by: 1)
        return ZStack {
            shape.strokeBorder(PhoneTheme.line, lineWidth: 1)
            inner.fill(PhoneTheme.cardEdge)
                .mask(inner.subtracting(inner.offset(y: PhoneTheme.cardEdgeHeight(scheme))))
        }
    }

    /// Each drop shadow as CSS writes it: the shape grown by its spread, moved by its offset and blurred.
    private var shadows: some View {
        ZStack {
            ForEach(Array(PhoneTheme.cardShadows(scheme).enumerated()), id: \.offset) { _, shadow in
                shape.inset(by: -shadow.spread).fill(shadow.color)
                    .offset(x: shadow.x, y: shadow.y).blur(radius: shadow.blur / 2)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

extension View {
    func phoneCardSurface() -> some View { modifier(PhoneCardSurface()) }
}

/// INF-1524 piece 3, the captain's C: a merge card's risk as one row of seven dots, one per dimension in the Mac's
/// order and in its level's color. A tap opens a sheet naming each dimension, its level's words and the crewmate's why.
struct PhoneRiskDots: View {
    let declared: PhoneJSON
    @State private var open = false

    static func color(_ level: String?) -> Color {
        switch PhoneCardWords.riskTone[level ?? ""] {
        case "ok": PhoneTheme.ok
        case "warn": PhoneTheme.warning
        case "danger": PhoneTheme.danger
        default: PhoneTheme.muted
        }
    }

    var body: some View {
        Button { open = true } label: {
            HStack(spacing: 4) {
                ForEach(PhoneCardWords.riskDimensions, id: \.id) { dimension in
                    Circle().fill(Self.color(declared[dimension.id]["level"].text)).frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, PhoneTheme.space2).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Risk")
        .accessibilityValue(PhoneCardWords.riskDimensions.compactMap { dimension in
            declared[dimension.id]["level"].text.flatMap { dimension.levels[$0] }.map { "\(dimension.label): \($0)" }
        }.joined(separator: ", "))
        .accessibilityIdentifier("card-risk")
        .sheet(isPresented: $open) {
            NavigationStack {
                PhoneRiskSheet(declared: declared)
                    .phoneTitle("Risk")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { open = false } } }
            }
            .presentationDetents([.medium, .large]).phoneSheetSurface()
            .font(PhoneFont.body).tint(PhoneTheme.accent)
        }
    }
}

/// Each dimension as the Mac's note reads it: "Label · level words", then the line the crewmate gave.
private struct PhoneRiskSheet: View {
    let declared: PhoneJSON

    var body: some View {
        ScrollView {
            PhoneList {
                ForEach(PhoneCardWords.riskDimensions, id: \.id) { dimension in
                    let level = declared[dimension.id]["level"].text
                    HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space3) {
                        Circle().fill(PhoneRiskDots.color(level)).frame(width: 8, height: 8).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(dimension.label) · \(level.flatMap { dimension.levels[$0] } ?? "")")
                                .font(PhoneFont.callout).foregroundStyle(PhoneTheme.text)
                            Text(declared[dimension.id]["why"].text ?? "").font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, PhoneTheme.space4).padding(.vertical, PhoneTheme.space3)
                    .accessibilityElement(children: .combine).accessibilityIdentifier("risk-\(dimension.id)")
                }
            }.padding(PhoneTheme.space4)
        }.accessibilityIdentifier("risk-sheet")
    }
}

/// INF-3149, the captain's direction C, as the Mac's AfterMergeStrip: what happens after the merge, at the top of the
/// card's body where it scrolls away. The captain's own actions come first under a lead in the warning color, then the
/// steps the crew starts on its own, each with its goal, what it waits for and who does it. A card with neither draws
/// nothing.
struct PhoneAfterMerge: View {
    let actions: [PhoneJSON]
    let steps: [PhoneJSON]

    var body: some View {
        if !actions.isEmpty || !steps.isEmpty {
            VStack(alignment: .leading, spacing: PhoneTheme.space3) {
                if !actions.isEmpty {
                    group(PhoneCardWords.requiredActionsLead, color: PhoneTheme.warning, id: "card-required-actions") {
                        ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                            entry("\(action["title"].text ?? "") · \(action["target"].text ?? "")", [action["consequence"].text ?? ""])
                        }
                    }
                }
                if !steps.isEmpty {
                    group(PhoneCardWords.afterMergeLead, color: PhoneTheme.text, id: "card-after-merge") {
                        ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                            let key = step["key"].text.map { "\($0) " } ?? ""
                            let waits = step["waitsFor"].list.compactMap(\.text)
                            entry(key + (step["title"].text ?? ""), [
                                step["goal"].text, waits.isEmpty ? nil : PhoneCardWords.afterMergeWait(waits),
                                PhoneCardWords.afterMergeDoer[step["doer"].text ?? "crewmate"],
                            ].compactMap { $0 })
                        }
                    }
                }
            }
            .padding(PhoneTheme.space3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: PhoneTheme.controlRadius).stroke(PhoneTheme.line, lineWidth: 1))
        }
    }

    private func group(_ lead: String, color: Color, id: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space2) {
            Text(lead).font(PhoneFont.callout).foregroundStyle(color)
            rows()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain).accessibilityIdentifier(id)
    }

    private func entry(_ title: String, _ lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(PhoneFont.callout).foregroundStyle(PhoneTheme.text)
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line).font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
            }
        }
    }
}

/// INF-1524 piece 4: a crewmate's browser on its card, as the Mac's strip names it: Browser, the page's site and who is
/// driving, read from its task's record. The browser itself stays on the computer.
struct PhoneBrowserStrip: View {
    let attachment: PhoneJSON
    let session: ReadOnlySession
    let open: () -> Void
    @State private var line: (site: String?, words: String)?

    var body: some View {
        HStack(spacing: PhoneTheme.space3) {
            Text("Browser").textCase(.uppercase).font(PhoneFont.micro).tracking(1).foregroundStyle(PhoneTheme.secondary).fixedSize()
            Group {
                if let line {
                    Text("\(Text(line.site ?? "").font(PhoneFont.mono).foregroundStyle(PhoneTheme.text))\(line.site == nil ? "" : " · ")\(line.words)")
                } else { Text(verbatim: "") }
            }.font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary).lineLimit(1)
            Spacer(minLength: 0)
            if !attachment["handoff"].flag {
                Button(attachment["label"].text ?? "Open browser", action: open)
                    .buttonStyle(PhoneChoiceStyle(.secondary)).fixedSize().accessibilityIdentifier("card-browser")
            }
        }
        .accessibilityElement(children: .contain).accessibilityIdentifier("card-browser-strip")
        .task(id: session.board?.tasks.first { $0.id == attachment["taskId"].text }?.activity) { await read() }
    }

    private func read() async {
        guard attachment["kind"].text == "browser", let id = attachment["taskId"].text,
              let detail: PhoneJSON = try? await session.request(.detail, args: [id]) else { return }
        let fact = detail["browser"]
        // The Mac's attachmentStanding: a browser that restarted or was replaced is no longer this card's.
        guard fact != .null, fact["session"] == attachment["session"], fact["generation"] == attachment["generation"] else {
            line = (nil, PhoneCardWords.staleBrowser); return
        }
        let site = fact["site"].text
        if fact["state"].text == "stopped" {
            line = (site, PhoneCardWords.stopLineWords[fact["stopped"].text ?? ""] ?? ""); return
        }
        // The Mac's browserDriverOf: who holds it, else the crewmate while its turn runs, else nobody.
        let driver: String
        if let control = fact["control"].text { driver = control }
        else if detail["workPosture"] != .null {
            driver = detail["workPosture"]["state"].text == "active" && detail["workPosture"]["reason"].text == "turn" ? "crewmate" : "nobody"
        } else { driver = ["running", "starting"].contains(detail["activity"].text ?? "") ? "crewmate" : "nobody" }
        line = (site, PhoneCardWords.driverWords[driver] ?? "")
    }
}

/// INF-1524 piece 4: the card's thread as the Mac's reads: who wrote each message in its short label and color, the
/// time, the words, a captain's settings folded on one line, and the working line while its author is at work.
struct PhoneCardThread: View {
    let messages: [PhoneJSON]
    let working: Bool

    /// The color a message's writer is named in: the captain's own, the author's accent, the app's quiet one.
    static func color(_ who: String) -> Color {
        who == "captain" ? PhoneTheme.captain : who == "host" ? PhoneTheme.secondary : PhoneTheme.accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PhoneTheme.space3) {
            ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                PhoneThreadMessage(message: message).id(index)
            }
            if working {
                HStack(spacing: PhoneTheme.space2) {
                    Text(PhoneCardWords.threadWorking).font(PhoneFont.mono).foregroundStyle(PhoneTheme.secondary)
                    ProgressView().controlSize(.mini)
                }.accessibilityIdentifier("thread-working")
            }
        }
    }
}

/// INF-3124, the captain's direction B: the card back's thread keeps the captain's place, as the Mac's does
/// (docs/card-threads.md, "Keeping your place"). It opens at its foot and follows new messages and the working line
/// only while the captain rests there; new messages taller than the thread open at their first line, the captain's
/// own reply always goes to the foot, and once they scroll up nothing else moves it. While they read above, the jump
/// down floats over the foot: a plain arrow until messages arrive below, then how many.
struct PhoneThreadScroller: View {
    let messages: [PhoneJSON]
    let working: Bool
    let bounce: ScrollBounceBehavior
    let onHeight: (CGFloat) -> Void
    let onPhase: (ScrollPhase) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Whether the thread follows: true at its foot, false once the captain leaves it or a long reply opens at its start.
    @State private var follows = true
    @State private var atFoot = true
    /// New messages were brought to the top, so the next move away from the foot is that, not the captain's own.
    @State private var opening = false
    /// The first message that came while the captain read above, by its place in the thread, and how many came.
    @State private var unreadFrom: Int?
    @State private var unreadCount = 0

    /// The thread's whole content, whose bottom is the foot.
    private static let content = "thread-content"

    var body: some View {
        ScrollViewReader { scroller in
            ScrollView {
                PhoneCardThread(messages: messages, working: working)
                    .padding(.horizontal, PhoneTheme.space4).padding(.vertical, PhoneTheme.space3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(Self.content)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { onHeight($0) }
            }
            .defaultScrollAnchor(.bottom, for: .initialOffset)
            .scrollBounceBehavior(bounce)
            .scrollDismissesKeyboard(.interactively)
            // About one line from the foot still counts as at it, the Mac's slack. Read again whenever the content grows
            // too, so new lines that fit, which leave the distance below unchanged, still end an opening.
            .onScrollGeometryChange(for: ThreadFoot.self) { geometry in
                ThreadFoot(
                    below: geometry.contentSize.height + geometry.contentInsets.bottom - geometry.visibleRect.maxY,
                    height: geometry.contentSize.height)
            } action: { _, foot in
                atFoot = foot.below <= PhoneTheme.space5
                if atFoot {
                    follows = true; opening = false; unreadFrom = nil; unreadCount = 0
                } else if opening {
                    follows = false; opening = false
                }
            }
            // Only the captain's own scroll ends or starts following, once it comes to rest.
            .onScrollPhaseChange { _, phase in
                if phase == .idle { follows = atFoot }
                onPhase(phase)
            }
            .onChange(of: messages.count) { old, count in arrived(from: old, to: count, scroller) }
            // A tall reply opening at its first line keeps its place when the working line leaves with it.
            .onChange(of: working) { if follows && !opening { scroller.scrollTo(Self.content, anchor: .bottom) } }
            // The keyboard or the card's foot shortening the thread keeps a following foot in view.
            .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.height } action: { _, _ in
                if follows { scroller.scrollTo(Self.content, anchor: .bottom) }
            }
            // The thread's own name sits on the scroll view, under the jump down, which keeps its own.
            .accessibilityIdentifier("card-thread")
            .overlay(alignment: .bottom) {
                if !follows { jump(scroller) }
            }
        }
    }

    /// Messages that came: the captain's own takes the thread to its foot; read above, they are counted; at the
    /// foot the first of them goes to the top, which a scroll that cannot go so far leaves at the foot.
    private func arrived(from old: Int, to count: Int, _ scroller: ScrollViewProxy) {
        guard count > old, old >= 0 else { return }
        if messages[old..<count].contains(where: { $0["who"].text == "captain" }) {
            follows = true; unreadFrom = nil; unreadCount = 0
            scroller.scrollTo(Self.content, anchor: .bottom)
        } else if !follows {
            unreadFrom = unreadFrom ?? old
            unreadCount += count - old
        } else {
            opening = true
            scroller.scrollTo(old, anchor: .top)
        }
    }

    /// The jump down: to the first message that came while the captain read above, or to the foot.
    private func jump(_ scroller: ScrollViewProxy) -> some View {
        let unread = unreadCount > 0
        return Button {
            let from = unreadFrom
            unreadFrom = nil; unreadCount = 0
            let move = {
                if let from { scroller.scrollTo(from, anchor: .top) } else { scroller.scrollTo(Self.content, anchor: .bottom) }
            }
            if reduceMotion { move() } else { withAnimation(PhoneTheme.surfaceMove) { move() } }
        } label: {
            Text(PhoneCardWords.threadJump(unreadCount).uppercased()).font(PhoneFont.micro)
                .foregroundStyle(unread ? PhoneTheme.accent : PhoneTheme.secondary)
                .padding(.horizontal, PhoneTheme.space3).padding(.vertical, 6)
                .background {
                    Capsule().fill(PhoneTheme.surface)
                    if unread { Capsule().fill(PhoneTheme.accentDim) }
                }
                .overlay { Capsule().stroke(PhoneTheme.line) }
                .frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.bottom, PhoneTheme.space2)
        .accessibilityIdentifier("thread-jump")
    }
}

/// How far the thread's foot is below the view, and how tall its content is.
private struct ThreadFoot: Equatable {
    let below: CGFloat
    let height: CGFloat
}

private struct PhoneThreadMessage: View {
    let message: PhoneJSON
    @State private var settingsOpen = false

    private var who: String { message["who"].text ?? "host" }
    private var color: Color { PhoneCardThread.color(who) }
    private var time: String {
        guard let at = message["at"].numeric else { return "" }
        return Date(timeIntervalSince1970: at / 1000).formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: PhoneTheme.space2) {
                Text(PhoneCardWords.threadWho[who] ?? who).font(PhoneFont.mono).foregroundStyle(color)
                // INF-2553: a reply the computer has not carried yet is marked sending where its time will be.
                if message["sending"].flag {
                    Text("Sending…").font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted).accessibilityIdentifier("thread-sending")
                } else {
                    Text(time).font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted)
                }
            }
            Text(message["text"].text ?? "").textSelection(.enabled)
                .foregroundStyle(who == "host" ? PhoneTheme.secondary : PhoneTheme.text)
            let contributor = PhoneCardWords.contributor(
                host: who == "host",
                label: message["contributor"]["label"].text,
                clarification: message["clarification"].flag
            )
            if !contributor.isEmpty {
                Text(contributor).font(PhoneFont.micro).foregroundStyle(PhoneTheme.muted)
                    .accessibilityIdentifier("thread-contributor")
            }
            let rows = Self.settingsRows(message["answers"].list)
            if who == "captain", !rows.isEmpty {
                DisclosureGroup(PhoneCardWords.settingsCount(rows.count), isExpanded: $settingsOpen) {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                            Text("\(Text(row.key).foregroundStyle(PhoneTheme.secondary))  \(row.value)").font(PhoneFont.mono)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.font(PhoneFont.mono).tint(PhoneTheme.secondary).accessibilityIdentifier("thread-settings")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    /// The Mac's settingsRows: a question reads as what was picked and the words written in; a staged snapshot opens
    /// into one row per leaf, keyed by its dotted path.
    static func settingsRows(_ answers: [PhoneJSON]) -> [(key: String, value: String)] {
        var rows: [(key: String, value: String)] = []
        for answer in answers {
            let name = answer["name"].text ?? ""
            let values = answer["values"].list.compactMap(\.text)
            guard answer["json"].flag else {
                let labels = answer["labels"].list.map(\.text)
                var picked = values.enumerated().map { index, value in
                    labels.indices.contains(index) ? labels[index].flatMap { $0.isEmpty ? nil : $0 } ?? value : value
                }
                if let written = answer["written"].text { picked.append("“\(written)”") }
                rows.append((name, picked.isEmpty ? "no answer" : picked.joined(separator: ", ")))
                continue
            }
            let raw = values.first ?? ""
            let before = rows.count
            if let data = raw.data(using: .utf8), let snapshot = try? JSONDecoder().decode(PhoneJSON.self, from: data) {
                leaves(snapshot, answers.count > 1 ? name : "", into: &rows)
            }
            if rows.count == before { rows.append((name, raw)) }
        }
        return rows
    }

    private static func leaves(_ value: PhoneJSON, _ path: String, into rows: inout [(key: String, value: String)]) {
        if case .object(let fields) = value {
            for (key, inner) in fields.sorted(by: { $0.key < $1.key }) { leaves(inner, path.isEmpty ? key : "\(path).\(key)", into: &rows) }
            return
        }
        guard !path.isEmpty else { return }
        switch value {
        case .string(let text): rows.append((path, text))
        case .number(let number): rows.append((path, number.rounded() == number ? String(Int(number)) : String(number)))
        case .bool(let flag): rows.append((path, flag ? "true" : "false"))
        case .null: rows.append((path, "null"))
        default:
            let text = (try? JSONEncoder().encode(value)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
            rows.append((path, text))
        }
    }
}

/// The card head's first line: its chips from the leading edge, wrapping onto another line where they do not fit,
/// each centred on its line.
struct PhoneFlowRow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = arrange(width: proposal.width ?? .infinity, subviews)
        let width = lines.map(\.width).max() ?? 0
        let height = lines.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, lines.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in arrange(width: bounds.width, subviews) {
            var x = bounds.minX
            for index in line.items {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (line.height - size.height) / 2), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += line.height + spacing
        }
    }

    private struct Line { var items: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }
    private func arrange(width: CGFloat, _ subviews: Subviews) -> [Line] {
        var lines: [Line] = []
        var line = Line()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let next = line.items.isEmpty ? size.width : line.width + spacing + size.width
            if !line.items.isEmpty && next > width { lines.append(line); line = Line() }
            line.width = line.items.isEmpty ? size.width : line.width + spacing + size.width
            line.height = max(line.height, size.height)
            line.items.append(index)
        }
        if !line.items.isEmpty { lines.append(line) }
        return lines
    }
}

/// INF-1524, the captain's yes: a photo taken with the camera for a card's reply.
struct PhoneCamera: UIViewControllerRepresentable {
    let take: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(take: take, dismiss: { dismiss() }) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    @MainActor final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let take: (UIImage) -> Void
        let dismiss: () -> Void
        init(take: @escaping (UIImage) -> Void, dismiss: @escaping () -> Void) { self.take = take; self.dismiss = dismiss }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { take(image) }
            dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { dismiss() }
    }
}
