import SwiftUI

/// INF-589 item 15: one reading column, centred, holds the card, its pager, the message box, Tasks and Activity on any width.
enum PhoneColumn {
    /// The column with its gutters: the card stage's own 560 points.
    static let width: CGFloat = 560
    /// What fills the column inside its gutters: the card itself, and the message box and notice that line up with it.
    static let inside: CGFloat = width - 2 * PhoneTheme.space4
}

/// INF-589 item 17: an iPhone on its side gives the card the height, so the shell keeps only what reading it needs.
/// Native compact height identifies it, not a keyboard shrinking the window.
@MainActor func phoneOnItsSide(_ vertical: UserInterfaceSizeClass?) -> Bool {
    UIDevice.current.userInterfaceIdiom == .phone && vertical == .compact
}

/// The app's own field, as the Mac draws its input: the panel fill, a hairline and the control radius.
struct PhoneFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, PhoneTheme.space3).padding(.vertical, PhoneTheme.space2)
            .frame(minHeight: 44)
            .background(PhoneTheme.panel, in: RoundedRectangle(cornerRadius: PhoneTheme.controlRadius))
            .overlay(RoundedRectangle(cornerRadius: PhoneTheme.controlRadius).strokeBorder(PhoneTheme.line))
    }
}

extension TextFieldStyle where Self == PhoneFieldStyle {
    static var phone: PhoneFieldStyle { PhoneFieldStyle() }
}

/// The Mac's input: one shape holding its field and send arrow, a pill at one line and a rounded rectangle taller.
/// Floating at the foot it is native glass on iOS 26, its corners concentric with the screen's (INF-944 item 4);
/// elsewhere it is the app's field fill and hairline.
private struct PhoneInputSurface: ViewModifier {
    let floating: Bool
    private let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            if floating { content.glassEffect(.regular, in: ConcentricRectangle(corners: .concentric(minimum: 22), isUniform: true)) } else { plain(content) }
        } else { plain(content) }
    }
    private func plain(_ content: Content) -> some View {
        content.background(PhoneTheme.panel, in: shape).overlay { shape.strokeBorder(PhoneTheme.line) }
    }
}

extension View {
    func phoneInput(floating: Bool = false) -> some View { modifier(PhoneInputSurface(floating: floating)) }
}

extension SensoryFeedback {
    /// INF-589 item 12: the one soft tap when something is sent, a task starts or stops, or the computer comes back.
    static let phone = SensoryFeedback.impact(flexibility: .soft)
}

extension View {
    /// A sheet's title, inline in the app's own type, drawn as the joined computer's name is.
    func phoneTitle(_ title: String) -> some View {
        navigationTitle(title).navigationBarTitleDisplayMode(.inline).toolbar {
            ToolbarItem(placement: .principal) { Text(title).font(PhoneFont.headline).accessibilityAddTraits(.isHeader) }
        }
    }

    /// A sheet floats over the app, so on iOS 26 it is the system's glass sheet with no backdrop of its own.
    /// Earlier systems draw it on the panel color with a hairline at its edge, as the Mac draws an aside.
    func phoneSheetSurface() -> some View { modifier(PhoneSheetSurface()) }
}

private struct PhoneSheetSurface: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26, *) { content } else {
            content.presentationBackground {
                PhoneTheme.panel.overlay { ContainerRelativeShape().strokeBorder(PhoneTheme.line) }
            }
        }
    }
}

/// INF-944 item 5, the captain's pick on INF-945: a card's choices in the Mac's row.
/// INF-1312: every button of the phone's own screens takes this shape too; none fills the width.
/// Rounded rectangles at the Mac's size, the default filled with the accent, a danger choice in a red outline,
/// the rest in a hairline outline. Each is drawn about 37 points tall inside a 44-point touch area.
struct PhoneChoiceStyle: ButtonStyle {
    /// INF-1524: `muted` is the Mac's default choice while a required question waits, drawn quiet until it is answered.
    enum Kind { case primary, secondary, danger, muted }
    let kind: Kind
    /// INF-1524: on a past card, the choice that was made keeps full contrast with an accent edge, as on the Mac.
    var chosen = false
    @Environment(\.isEnabled) private var enabled

    init(_ kind: Kind, chosen: Bool = false) { self.kind = kind; self.chosen = chosen }
    init(primary: Bool, danger: Bool = false) { kind = primary ? .primary : danger ? .danger : .secondary }

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: PhoneTheme.controlRadius, style: .continuous)
        configuration.label
            .font(PhoneFont.callout)
            .foregroundStyle(kind == .primary ? PhoneTheme.onAccent : kind == .danger ? PhoneTheme.danger : kind == .muted ? PhoneTheme.muted : PhoneTheme.text)
            .padding(.horizontal, PhoneTheme.space4).padding(.vertical, PhoneTheme.space2)
            .frame(minHeight: PhoneChoiceRow.drawnHeight)
            .background { if kind == .primary { shape.fill(PhoneTheme.accent) } }
            .overlay {
                if chosen { shape.strokeBorder(PhoneTheme.accent, lineWidth: 1.5) }
                else if kind != .primary { shape.strokeBorder(kind == .danger ? PhoneTheme.danger : PhoneTheme.line) }
            }
            .opacity(chosen ? 1 : !enabled ? 0.5 : configuration.isPressed ? 0.7 : 1)
            .padding(.vertical, (44 - PhoneChoiceRow.drawnHeight) / 2)
            .contentShape(Rectangle())
    }
}

/// The Mac's footer row: choices keep their own width, sit at the trailing edge and wrap onto another line
/// when they do not fit, the default last. An optional leading fact (the answered count) starts the first line.
struct PhoneChoiceRow: Layout {
    /// The Mac's button height; the touch area around it stays 44 points.
    static let drawnHeight: CGFloat = 37
    /// Subviews marked with this key start the first line at the leading edge.
    struct Leading: LayoutValueKey { static let defaultValue = false }
    private let gap = PhoneTheme.space2
    /// Each choice carries its own vertical touch padding, so lines sit closer to keep the Mac's drawn gap.
    private var lineGap: CGFloat { max(0, gap - (44 - Self.drawnHeight)) }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let width = proposal.width ?? lines.map(\.width).max() ?? 0
        return CGSize(width: width, height: lines.reduce(0) { $0 + $1.height } + lineGap * CGFloat(max(0, lines.count - 1)))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.maxX - line.trailingWidth
            for index in line.items {
                let size = subviews[index].sizeThatFits(.init(width: bounds.width, height: nil))
                let leading = subviews[index][Leading.self]
                subviews[index].place(at: CGPoint(x: leading ? bounds.minX : x, y: y + (line.height - size.height) / 2),
                                      proposal: .init(width: min(size.width, bounds.width), height: size.height))
                if !leading { x += size.width + gap }
            }
            y += line.height + lineGap
        }
    }

    private struct Line { var items: [Int] = []; var width: CGFloat = 0; var trailingWidth: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Line] {
        var lines: [Line] = []
        var line = Line()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.init(width: width, height: nil))
            let leading = subviews[index][Leading.self]
            let added = line.items.isEmpty ? min(size.width, width) : size.width + gap
            if !line.items.isEmpty && line.width + added > width {
                lines.append(line); line = Line()
            }
            let step = line.items.isEmpty ? min(size.width, width) : size.width + gap
            line.items.append(index); line.width += step
            if !leading { line.trailingWidth += line.trailingWidth == 0 ? min(size.width, width) : size.width + gap }
            line.height = max(line.height, size.height)
        }
        if !line.items.isEmpty { lines.append(line) }
        return lines
    }
}

/// INF-1312: a list of rows where a choice is a way in or a thing to pick rather than a decision.
/// The rows sit on the panel fill inside a hairline, as the Mac draws a list, with a hairline between them.
struct PhoneList<Content: View>: View {
    @ViewBuilder let content: Content
    private let shape = RoundedRectangle(cornerRadius: PhoneTheme.cardRadius, style: .continuous)

    var body: some View {
        VStack(spacing: 0) {
            Group(subviews: content) { rows in
                ForEach(rows) { row in
                    if row.id != rows.first?.id { Rectangle().fill(PhoneTheme.line).frame(height: 1) }
                    row
                }
            }
        }
        .background(PhoneTheme.panel, in: shape).clipShape(shape)
        .overlay { shape.strokeBorder(PhoneTheme.line) }
    }
}

/// One row of a `PhoneList`: an optional symbol in the accent, the row's name, one line under it, and a chevron
/// when the row opens something. It fills the row, so the whole row is its touch area.
struct PhoneRow: View {
    var symbol: PhoneSymbol?
    let title: String
    let line: String
    var lineFont = PhoneFont.caption
    var chevron = false

    var body: some View {
        HStack(spacing: PhoneTheme.space3) {
            if let symbol { symbol.image.foregroundStyle(PhoneTheme.accent).accessibilityHidden(true) }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(PhoneFont.body).foregroundStyle(PhoneTheme.text)
                Text(line).font(lineFont).foregroundStyle(PhoneTheme.secondary)
            }.multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            if chevron { PhoneSymbol.chevron.image.foregroundStyle(PhoneTheme.muted).accessibilityHidden(true) }
        }
        .padding(.horizontal, PhoneTheme.space4).padding(.vertical, PhoneTheme.space3)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
    }
}

/// A pressed row lights the field's surface under it, and a disabled one dims.
struct PhoneRowStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background { if configuration.isPressed { PhoneTheme.surface } }
            .opacity(enabled ? 1 : 0.5)
    }
}
