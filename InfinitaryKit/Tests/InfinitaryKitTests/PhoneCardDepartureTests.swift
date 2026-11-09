import Foundation
import Testing
@testable import InfinitaryKit

/// INF-3155, the captain: "when all the cards are already read, dismissing the current card should reveal the next one,
/// not going back to the first. this should behave consistently on both desktop and ios". These replay the Mac's own
/// choice for each stack (`departureIndex` with `neighboursOf`), which scripts/generate-phone-scene.ts records, so the
/// iPhone and iPad bring up the card the Mac does.
struct PhoneCardDepartureTests {
    private struct Reading: Decodable {
        let name: String
        let previous: [String]
        let left: String
        let ids: [String]
        let unread: [String]
        let comesUp: String?
    }

    @Test func picksTheCardTheMacPicks() throws {
        let url = try #require(Bundle.module.url(forResource: "PhoneCardDeparture.generated", withExtension: "json", subdirectory: "Fixtures"))
        let readings = try JSONDecoder().decode([Reading].self, from: Data(contentsOf: url))
        #expect(!readings.isEmpty)
        for reading in readings {
            let picked = PhoneCardDeparture.comesUp(after: reading.left, previous: reading.previous, ids: reading.ids,
                unread: { reading.unread.contains($0) })
            #expect(picked == reading.comesUp, "\(reading.name)")
        }
    }
}
