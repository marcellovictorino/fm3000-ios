import SwiftUI
import XCTest
@testable import Infinitary
@testable import InfinitaryKit

/// INF-209: native three-state drawing, and the Mac-authored Activity key/age presentation.
/// Uses the disposable test home and simulator; no account, camera or signing operation.
@MainActor final class PhoneShellTests: XCTestCase {
    func testNativeCharacterHasThreeDistinctReducedMotionPoses() throws {
        var drawings = Set<Data>()
        for state in PhoneCharacter.State.allCases {
            for theme in [ColorScheme.light, .dark] {
                let renderer = ImageRenderer(content: PhoneCharacter(state: state).drawing(at: 0)
                    .frame(width: 240, height: 240).padding(24).background(PhoneTheme.background)
                    .environment(\.colorScheme, theme))
                renderer.scale = 2
                let image = try XCTUnwrap(renderer.uiImage)
                drawings.insert(try XCTUnwrap(image.pngData()))
                let picture = XCTAttachment(image: image)
                picture.name = "native-character-\(state.rawValue)-\(theme == .dark ? "dark" : "light")"
                picture.lifetime = .keepAlways; add(picture)
            }
        }
        XCTAssertEqual(drawings.count, PhoneCharacter.State.allCases.count * 2,
                       "Idle, listening and working must draw differently in each appearance")
    }

    /// INF-589 item 1: the system draws the launch screen before any Swift runs, so its color must be the void the app opens onto.
    func testLaunchScreenIsTheVoidInEachAppearance() throws {
        let launch = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "UILaunchScreen") as? [String: Any])
        let name = try XCTUnwrap(launch["UIColorName"] as? String, "An empty launch screen is pure white or black")
        let color = try XCTUnwrap(UIColor(named: name, in: .main, compatibleWith: nil))
        for (style, scheme) in [(UIUserInterfaceStyle.light, ColorScheme.light), (.dark, .dark)] {
            var environment = EnvironmentValues()
            environment.colorScheme = scheme
            let void = PhoneTheme.background.resolve(in: environment)
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            XCTAssertTrue(color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)).getRed(&red, green: &green, blue: &blue, alpha: &alpha))
            XCTAssertEqual(Float(red), void.red, accuracy: 0.002)
            XCTAssertEqual(Float(green), void.green, accuracy: 0.002)
            XCTAssertEqual(Float(blue), void.blue, accuracy: 0.002)
            XCTAssertEqual(Float(alpha), void.opacity, accuracy: 0.002)
        }
    }

    /// INF-499 #3: only the shown card, past card or open task supplies the message hint.
    func testMessageContextFollowsTheShownEntry() {
        let context = PhoneMessageContext()
        context.card = .current("card-fm-phone-choice")
        XCTAssertEqual(context.fields, ["visibleCardId": "card-fm-phone-choice"])
        context.cardsVisible = false
        XCTAssertEqual(context.fields, [:], "An Activity or Tasks tab does not point at a hidden card")
        context.taskID = "phone-work"
        XCTAssertEqual(context.fields, ["taskId": "phone-work"])
        context.taskID = nil
        XCTAssertEqual(context.fields, [:], "Closing the task record clears its hint")
        context.cardsVisible = true
        context.card = .past("card-fm-phone-conversation")
        XCTAssertEqual(context.fields, ["pastCardId": "card-fm-phone-conversation"])
        context.card = nil
        XCTAssertEqual(context.fields, [:])
    }

    /// INF-1533: the strip in the top bar has the same frames from launch through a change of appearance or type size,
    /// so the join journey's strip check holds whether or not a dark switch reached the app first. While the strip took
    /// its segmented control's fitted size, it drew 42-point segments until the first such change widened them to 48.
    func testTabStripKeepsItsSizeFromLaunch() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        defer { window.isHidden = true; window.rootViewController = nil }
        // The strip shows in an upright window; a wide one gives the iPad its sidebar instead.
        let size = scene.coordinateSpace.bounds.size
        window.frame = CGRect(x: 0, y: 0, width: min(size.width, size.height), height: max(size.width, size.height))
        window.rootViewController = UIHostingController(rootView: TabStripBar())
        window.makeKeyAndVisible()
        func control() -> UISegmentedControl? {
            var views: [UIView] = [window]
            while let view = views.popLast() {
                if let control = view as? UISegmentedControl { return control }
                views += view.subviews
            }
            return nil
        }
        // Each reading follows an observed change and two drawn frames, so SwiftUI's update after it has been drawn,
        // each due on the load clock (INF-1506).
        func drawn(_ witness: () -> Bool, _ change: String) async throws -> CGRect {
            var deadline = PhoneWaitDeadline(20)
            while !witness() {
                if deadline.expired() { XCTFail("The bar never showed \(change)"); break }
                try await Task.sleep(for: .seconds(PhoneWaitDeadline.tick))
            }
            let frames = DisplaySample(ticks: 2)
            let shown = await frames.complete(within: 20)
            frames.stop(); XCTAssertEqual(shown, .completed, "No frame was drawn after \(change)")
            let strip = try XCTUnwrap(control(), "The bar has no strip after \(change)")
            return strip.convert(strip.bounds, to: window).integral
        }
        let launched = try await drawn({ control()?.window != nil }, "launch")
        window.overrideUserInterfaceStyle = .dark
        let dark = try await drawn({ control()?.traitCollection.userInterfaceStyle == .dark }, "dark appearance")
        XCTAssertEqual(dark, launched, "The first change of appearance keeps the strip's segments")
        window.overrideUserInterfaceStyle = .light
        window.traitOverrides.preferredContentSizeCategory = .extraExtraExtraLarge
        let largest = try await drawn({
            window.rootViewController?.view.traitCollection.preferredContentSizeCategory == .extraExtraExtraLarge
                && control()?.traitCollection.userInterfaceStyle == .light
        }, "the largest standard type")
        XCTAssertEqual(largest, launched, "The largest standard type keeps the strip's segments")
    }

    func testActivityUsesTheHomesReadings() async throws {
        let control = try XCTUnwrap(ProcessInfo.processInfo.environment["PHONE_TEST_HOME"])
        let (data, _) = try await URLSession.shared.data(from: XCTUnwrap(URL(string: control + "/state")))
        let state = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let bytes = try JSONSerialization.data(withJSONObject: XCTUnwrap(state["feed"]))
        let lines = try JSONDecoder().decode([ActivityLine].self, from: bytes)
        let line = try XCTUnwrap(lines.last)
        let at = Date(timeIntervalSince1970: line.at / 1000)
        XCTAssertEqual(PhoneActivity.age(line.at, now: at), "now")
        XCTAssertEqual(PhoneActivity.age(line.at, now: at.addingTimeInterval(120)), "2m")
        XCTAssertEqual(PhoneActivity.age(line.at, now: at.addingTimeInterval(7200)), "2h")
        XCTAssertEqual(PhoneActivity.age(line.at, now: at.addingTimeInterval(172800)), "2d")
    }
}

/// The top bar as `PhoneView` and `PhoneWorkspace` draw it: the tab controller with its own bar hidden, Settings at the
/// left, the strip in the middle and the computer at the right, under the app's own type and colors.
private struct TabStripBar: View {
    @State private var selection = PhoneTab.home

    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                ForEach(PhoneTab.allCases, id: \.self) { tab in
                    PhoneTheme.background.toolbar(.hidden, for: .tabBar).tag(tab)
                }
            }
            .toolbar { ToolbarItem(placement: .principal) { PhoneTabStrip(tabs: PhoneTab.allCases, selection: $selection) } }
            .navigationTitle("Infinitary").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {} label: { PhoneSymbol.settings.image }.accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: { PhoneSymbol.computer.image }.accessibilityLabel("Your computer")
                }
            }
        }
        .font(PhoneFont.body).tint(PhoneTheme.accent).foregroundStyle(PhoneTheme.text)
    }
}
