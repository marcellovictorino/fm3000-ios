import Foundation
import Testing
@testable import InfinitaryKit

/// The captain's Approve and build on the phone's own theme: Device, Dark or Light, saved on the device and starting on
/// Device, so nobody's app looks different after the update.
struct PhoneLookTests {
    /// A defaults domain of this test's own, removed after it, so the app's real choice is never read or changed.
    private func scratch() -> (UserDefaults, String) {
        let name = "phone-look-tests-\(UUID().uuidString)"
        return (UserDefaults(suiteName: name)!, name)
    }

    @Test func startsOnMatchingTheDevice() {
        let (defaults, name) = scratch()
        defer { defaults.removePersistentDomain(forName: name) }
        #expect(PhoneLook.saved(in: defaults) == .device)
    }

    @Test func keepsEachChoiceAcrossReads() {
        let (defaults, name) = scratch()
        defer { defaults.removePersistentDomain(forName: name) }
        for look in PhoneLook.allCases {
            look.save(in: defaults)
            // A fresh reader of the same domain stands in for the next launch.
            #expect(PhoneLook.saved(in: UserDefaults(suiteName: name)!) == look)
        }
    }

    @Test func readsAnUnknownChoiceAsTheDevice() {
        let (defaults, name) = scratch()
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set("sepia", forKey: PhoneLook.key)
        #expect(PhoneLook.saved(in: defaults) == .device)
    }

    @Test func wordsAreTheCaptainsShortOnes() {
        #expect(PhoneLook.allCases.map(\.words) == ["Device", "Dark", "Light"])
    }
}
