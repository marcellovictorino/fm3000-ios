import Testing
@testable import InfinitaryKit

/// INF-1649, the captain's "Yes, “Update Infinitary on this phone” or “on your computer”": the line names the older side.
struct PhoneUpdateTests {
    @Test func namesTheOlderSide() {
        #expect(PhoneUpdate.side(phone: "12.0.0", computer: "14.0.0") == .phone)
        #expect(PhoneUpdate.side(phone: "12.0.0", computer: "10.1.0") == .computer)
        #expect(PhoneUpdate.side(phone: "12.0.0", computer: nil) == .phone)
        #expect(PhoneUpdate.computer.words == "Update Infinitary on your computer to make changes.")
        #expect(PhoneUpdate.phone.words == "Update Infinitary on this phone to make changes.")
    }
}
