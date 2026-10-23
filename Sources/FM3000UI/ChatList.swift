import FM3000Core
import SwiftUI

/// A chat as WhatsApp draws it: oldest at the top, newest at the bottom, opening at the bottom and following new messages.
/// The captain's words are on the right in the accent colour; replies are on the left in a neutral bubble, with who said it
/// and when above. Tokens come from the desktop's thread (`cards/cardThread.css`): accent for crew and mate, `--bg-2` and
/// `--line-1` for a quiet bubble, `--accent-dim` for yours.
struct ChatList: View {
    let items: [ChatItem]
    var empty: String
    /// Shows the other side "typing" (three pulsing dots) at the end while an answer is on its way.
    var typing = false

    private var ordered: [ChatItem] { ChatItem.chronological(items) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if items.isEmpty { Text(empty).font(.footnote).foregroundStyle(Theme.fg2).padding(.top, 24) }
                    ForEach(ordered) { item in bubble(item) }
                    if typing { TypingBubble() }
                    Color.clear.frame(height: 1).id(Self.end)
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .onChange(of: ordered.last?.id) { _ in scrollToEnd(proxy, animated: true) }
            .onChange(of: typing) { _ in scrollToEnd(proxy, animated: true) }
            .onChange(of: ordered.count) { _ in scrollToEnd(proxy, animated: true) }
            #if os(iOS)
            // The keyboard shrinks the list: keep the newest message in view as it opens.
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in scrollToEnd(proxy, animated: true) }
            #endif
            .onAppear { scrollToEnd(proxy, animated: false) }
        }
        .background(Theme.backdrop)
    }

    private static let end = "chat-end"

    /// Scrolls once now and once after the new row has been laid out, which a lazy stack needs.
    private func scrollToEnd(_ proxy: ScrollViewProxy, animated: Bool) {
        func go() {
            if animated { withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(Self.end, anchor: .bottom) } }
            else { proxy.scrollTo(Self.end, anchor: .bottom) }
        }
        go()
        // A long history loads late and a lazy stack estimates row heights, so settle on the end again.
        for delay in [0.15, 0.5] { DispatchQueue.main.asyncAfter(deadline: .now() + delay) { go() } }
    }

    private func bubble(_ item: ChatItem) -> some View {
        VStack(alignment: item.isMine ? .trailing : .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(item.label).foregroundStyle(item.who == "firstmate" || item.who == "crewmate" ? Theme.accent : Theme.fg3)
                Text(stamp(item.at)).foregroundStyle(Theme.fg3)
            }
            .font(.caption2)
            Text(item.text)
                .foregroundStyle(item.problem ? Theme.danger : Theme.fg1)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(item.isMine ? Theme.accent.opacity(0.18) : Theme.bg2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(item.isMine ? Theme.accent.opacity(0.35) : Theme.line.opacity(0.6), lineWidth: 0.5))
                .frame(maxWidth: 520, alignment: item.isMine ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity, alignment: item.isMine ? .trailing : .leading)
    }

    private func stamp(_ millis: Double) -> String {
        let date = Date(timeIntervalSince1970: millis / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = Calendar.current.isDateInToday(date) ? "HH:mm" : "d MMM HH:mm"
        return formatter.string(from: date)
    }
}

/// A reply bubble with three dots that pulse in turn, as chat apps show while the other side is writing.
private struct TypingBubble: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Firstmate").font(.caption2).foregroundStyle(Theme.accent)
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { i in
                        let phase = (sin(t * 5 - Double(i) * 0.9) + 1) / 2
                        Circle().fill(Theme.fg2).frame(width: 7, height: 7)
                            .opacity(0.35 + 0.65 * phase).scaleEffect(0.8 + 0.3 * phase)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Theme.bg2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.line.opacity(0.6), lineWidth: 0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Firstmate is answering")
    }
}
