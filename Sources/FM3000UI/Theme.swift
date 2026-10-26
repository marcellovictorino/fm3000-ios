import FM3000Core
import SwiftUI

/// The desktop app's dark look, from its design tokens (`--bg-0..3`, `--fg-1..3`, `--accent`, `--warn`, `--danger`
/// in Infinitary's `design/tokens/colors.css`), so the phone has the same visual identity.
enum Theme {
    static let bg0 = Color(hex: 0x05070D)      // void: text on bright fills
    static let bg1 = Color(hex: 0x0B1120)      // surface: bars, inputs
    static let bg2 = Color(hex: 0x111A30)      // raised: rows and cards
    static let bg3 = Color(hex: 0x192440)      // hover / selected
    static let line = Color(red: 150 / 255, green: 180 / 255, blue: 1).opacity(0.2)
    static let fg1 = Color(hex: 0xE9EEF8)      // primary text
    static let fg2 = Color(hex: 0x98A4BD)      // secondary text
    static let fg3 = Color(hex: 0x7A86A0)      // tertiary text
    /// The screen behind the navy surfaces: the desktop's glass window, a grey with a green-teal cast that
    /// brightens toward one corner.
    static var backdrop: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x1D2624), Color(hex: 0x151B1A), Color(hex: 0x101514)], startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [Color(hex: 0x2E4A44).opacity(0.5), .clear], center: .topLeading, startRadius: 0, endRadius: 520)
        }
        .ignoresSafeArea()
    }
    static let accent = Color(hex: 0x7FDCFF)
    static let accentStrong = Color(hex: 0x2F8FFF)
    /// The icon's cyan-to-blue sweep: the sent bubble, the send button.
    static let accentGradient = LinearGradient(colors: [Color(hex: 0x7FE3FF), Color(hex: 0x2F8FFF)], startPoint: .topLeading, endPoint: .bottomTrailing)
    /// The first mate's own mark: a rank-stripe gold, used sparingly.
    static let gold = Color(hex: 0xE8B04A)
    /// Within pace on the quota meters.
    static let ok = Color(hex: 0x5FD38D)
    static let warn = Color(hex: 0xFFA257)
    static let danger = Color(hex: 0xFF6B52)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

extension View {
    /// A screen in the Infinitary look: dark void behind, raised rows, hairline lines, cyan accent.
    func infinitaryScreen() -> some View {
        self.scrollContentBackground(.hidden)
            .background(Theme.backdrop)
            .listRowBackgroundCompat()
    }

    /// Raised row colour for lists and forms.
    func infinitaryRow() -> some View { listRowBackground(Theme.bg2).listRowSeparatorTint(Theme.line) }

    @ViewBuilder fileprivate func listRowBackgroundCompat() -> some View { self }

    /// The root: forces dark, tints with the accent, and paints the system bars in the same colours.
    func infinitaryRoot() -> some View {
        self.preferredColorScheme(.dark)
            .tint(Theme.accent)
            
            .background(Theme.backdrop)
            .onAppear(perform: Theme.applyBars)
    }
}

extension Theme {
    static func applyBars() {
        #if os(iOS)
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(bg1)
        nav.titleTextAttributes = [.foregroundColor: UIColor(fg1)]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(fg1)]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(bg1)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        #endif
    }
}

/// Simulator runs only: launch arguments that open a screen so a script can photograph it (`-startTab 1`,
/// `-openCard`, `-openThread`). A release build ignores them.
enum DebugLaunch {
    static func has(_ flag: String) -> Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains(flag)
        #else
        return false
        #endif
    }
    static var tab: Int {
        #if DEBUG
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-startTab"), i + 1 < a.count, let n = Int(a[i + 1]) { return n }
        #endif
        return 0
    }
}

extension DebugLaunch {
    /// `-layout board` opens Tasks as the board without rotating the simulator.
    static var layout: TasksLayout? {
        #if DEBUG
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-layout"), i + 1 < a.count { return a[i + 1] == "board" ? .board : .list }
        #endif
        return nil
    }
}
