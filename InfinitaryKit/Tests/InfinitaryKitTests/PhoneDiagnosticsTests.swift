import Foundation
import Testing
@testable import InfinitaryKit

/// INF-2631, the captain's "Approve and build" on routing the phone's usage events through its computer: the phone holds
/// its events in memory and hands each to the computer once, in the shape the computer's request reads.
struct PhoneDiagnosticsTests {
    let usage = PhoneUsage(device: .ipad, version: "0.1.0")

    @Test func handsEachWaitingEventOverOnceOldestFirst() throws {
        var queue = PhoneDiagnosticsQueue()
        queue.note(.launch, at: Date(timeIntervalSince1970: 1_800_000_000.25))
        queue.note(.messageSent, at: Date(timeIntervalSince1970: 1_800_000_060))
        let handed = queue.handOver(as: usage)
        #expect(handed.count == 2)
        let first = try #require(handed.first)
        #expect(first["name"] as? String == "ios_launch")
        #expect((first["data"] as? [String: String]) == ["device": "ipad"])
        #expect(first["version"] as? String == "0.1.0")
        #expect(first["at"] as? Int == 1_800_000_000_250)
        #expect(handed.last?["name"] as? String == "ios_message_sent")
        #expect(Set(first.keys) == ["name", "data", "version", "at"])
        // Handed over once: a lost answer never sends it again.
        #expect(queue.handOver(as: usage).isEmpty)
    }

    @Test func keepsTheOldestWhileTheComputerIsAway() {
        var queue = PhoneDiagnosticsQueue()
        for _ in 0..<PhoneDiagnosticsQueue.held { queue.note(.opened, at: Date()) }
        queue.note(.cardAnswered, at: Date())
        #expect(queue.waiting.count == PhoneDiagnosticsQueue.held)
        #expect(!queue.waiting.contains { $0.event == .cardAnswered })
    }

    @Test func aComputerThatTakesNoneKeepsNone() {
        var queue = PhoneDiagnosticsQueue()
        queue.note(.ftueJoined, at: Date())
        queue.drop()
        #expect(queue.handOver(as: usage).isEmpty)
    }
}
