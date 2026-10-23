import FM3000Core
import SwiftUI

/// The desktop app's dark look, from its design tokens (`--bg-0..3`, `--fg-1..3`, `--accent`, `--warn`, `--danger`
/// in Infinitary's `design/tokens/colors.css`), so the phone has the same visual identity.
enum Theme {
    static let bg0 = Color(hex: 0x05070D)      // void: screen background
    static let bg1 = Color(hex: 0x0A0E18)      // surface: bars, inputs
    static let bg2 = Color(hex: 0x0F1424)      // raised: rows and cards
    static let bg3 = Color(hex: 0x161C30)      // hover / selected
    static let line = Color(red: 150 / 255, green: 180 / 255, blue: 1).opacity(0.2)
    static let fg1 = Color(hex: 0xE9EEF8)      // primary text
    static let fg2 = Color(hex: 0x98A4BD)      // secondary text
    static let fg3 = Color(hex: 0x7A86A0)      // tertiary text
    static let accent = Color(hex: 0x7FDCFF)
    static let accentStrong = Color(hex: 0x38AAE6)
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
            .background(Theme.bg0.ignoresSafeArea())
            .listRowBackgroundCompat()
    }

    /// Raised row colour for lists and forms.
    func infinitaryRow() -> some View { listRowBackground(Theme.bg2).listRowSeparatorTint(Theme.line) }

    @ViewBuilder fileprivate func listRowBackgroundCompat() -> some View { self }

    /// The root: forces dark, tints with the accent, and paints the system bars in the same colours.
    func infinitaryRoot() -> some View {
        self.preferredColorScheme(.dark)
            .tint(Theme.accent)
            
            .background(Theme.bg0.ignoresSafeArea())
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
