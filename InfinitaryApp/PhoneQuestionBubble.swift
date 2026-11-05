import InfinitaryKit
import SwiftUI

/// INF-1963: the question bubble itself opens and folds the message, with no separate Show all link.
/// INF-2219 reuses this view in its reply sheet; the caller owns its label, time and expansion state.
struct PhoneQuestionBubble: View {
    let text: String
    @Binding var open: Bool
    var identifier = "question-bubble"
    @State private var folded: CGFloat = 0
    @State private var whole: CGFloat = 0

    var body: some View {
        let interactive = open || whole > folded + 1
        Button { open.toggle() } label: {
            Text(phoneQuestionWords(text, open: open))
                .font(PhoneFont.caption).foregroundStyle(PhoneTheme.secondary)
                .lineLimit(open ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { folded = $0 }
                .background(alignment: .topLeading) {
                    // Measure just the words at the bubble's width, without the caller's label or padding.
                    Text(phoneQuestionWords(text, open: false)).font(PhoneFont.caption)
                        .fixedSize(horizontal: false, vertical: true).hidden()
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { whole = $0 }
                }
                .padding(.vertical, 3).padding(.horizontal, 10)
                .background(PhoneTheme.text.opacity(0.08), in: UnevenRoundedRectangle(
                    topLeadingRadius: 4, bottomLeadingRadius: 11, bottomTrailingRadius: 11, topTrailingRadius: 11))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!interactive)
        .accessibilityIdentifier(identifier)
    }
}
