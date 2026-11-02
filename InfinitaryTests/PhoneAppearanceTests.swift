import SwiftUI
import XCTest
@testable import Infinitary

/// The captain asked for a Dark/Light choice kept on the phone, starting on Dark (the desktop's default).
final class PhoneAppearanceTests: XCTestCase {
    func testChoiceStartsDarkAndSurvivesRelaunch() throws {
        let suite = "appearance-\(UUID().uuidString)"
        let first = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { first.removePersistentDomain(forName: suite) }
        XCTAssertNil(first.string(forKey: PhoneAppearance.storageKey), "Nothing stored means the @AppStorage default, dark")
        first.set(PhoneAppearance.light.rawValue, forKey: PhoneAppearance.storageKey)
        let relaunched = try XCTUnwrap(UserDefaults(suiteName: suite))
        let kept = PhoneAppearance(rawValue: try XCTUnwrap(relaunched.string(forKey: PhoneAppearance.storageKey)))
        XCTAssertEqual(kept?.scheme, .light)
        XCTAssertEqual(PhoneAppearance.dark.scheme, .dark)
    }
}
