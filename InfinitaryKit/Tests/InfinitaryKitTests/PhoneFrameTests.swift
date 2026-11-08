import Foundation
import Testing
@testable import InfinitaryKit

/// INF-2566, the captain's approved direction B: "board decoding off the main thread". The phone session hands each
/// frame from the computer to `PhoneFrame.decode` from the main actor; the parsing and decoding run elsewhere, and
/// the session reads the decoded values in arrival order.
struct PhoneFrameTests {
    private func row(_ index: Int) -> [String: Any] {
        [
            "id": "t-\(index)", "key": "INF-\(index)", "projectId": "proj-harbour", "parentId": NSNull(), "kind": "work",
            "title": "Chart the northern entrance, leg \(index)", "status": index % 3 == 0 ? "open" : "active",
            "activity": "running", "createdAt": 1_793_000_000_000 + index, "startPolicy": "when-ready", "blockedBy": [],
            "waitingCardId": NSNull(),
        ]
    }

    private func text(_ object: [String: Any]) throws -> String {
        String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self)
    }

    /// The board a busy home pushes: two hundred tasks in one frame.
    private func boardPush(seq: Int = 7) throws -> String {
        try text(["t": "push", "seq": seq, "channel": "inf:tasks",
                  "payload": ["seq": 41, "tasks": (1...200).map(row), "projects": [["id": "proj-harbour", "name": "Harbour"]]]])
    }

    @MainActor @Test func aPushedBoardIsDecodedOffTheMainThread() async throws {
        #expect(pthread_main_np() != 0, "The test asks from the main thread, as the session does")
        let frame = try await PhoneFrame.decode(try boardPush(), reads: [:])
        #expect(!frame.onMain)
        let board = try frame.board()
        #expect(board.tasks.count == 200)
        #expect(board.tasks.first?.key == "INF-1")
        #expect(frame.frame["seq"] as? Int == 7)
    }

    @MainActor @Test func aReadIsDecodedByTheChannelTheSessionWaitedFor() async throws {
        let value: [String: Any] = ["seq": 41, "tasks": [row(1)], "projects": [["id": "proj-harbour", "name": "Harbour"]]]
        let result = try text(["t": "result", "id": 12, "ok": true, "value": value])
        let waited = try await PhoneFrame.decode(result, reads: [12: PhoneRequest.board.rawValue])
        #expect(!waited.onMain)
        #expect(try waited.board().tasks.map(\.key) == ["INF-1"])
        // A call's answer, which no read waited for, keeps its bytes for the caller and decodes nothing.
        let called = try await PhoneFrame.decode(result, reads: [:])
        #expect(called.payload.map { _ in true } == nil)
        let answer = try JSONSerialization.jsonObject(with: try #require(called.answer)) as? [String: Any]
        #expect(answer?["seq"] as? Int == 41)
    }

    /// The session ignores a presence push from a home without scene observations, so a payload it cannot decode
    /// fails only when the session reads it, as the decoding in place did.
    @MainActor @Test func aPayloadThatCannotDecodeFailsOnlyWhenRead() async throws {
        let frame = try await PhoneFrame.decode(try text(["t": "push", "seq": 3, "channel": "inf:computers:presence", "payload": ["not": "a list"]]), reads: [:])
        #expect(frame.frame["channel"] as? String == "inf:computers:presence")
        #expect(throws: PhoneError.self) { try frame.computers() }
        await #expect(throws: (any Error).self) { try await PhoneFrame.decode("not json", reads: [:]) }
    }

    /// INF-2832 (`frame-parts`): the computer sends a long frame as a `parts` message and pieces of its text, cut
    /// between characters; the phone reads the frame once the last piece has arrived, and a short frame as it came.
    @Test func aFrameInPartsIsReadOnceWhole() throws {
        let frame = try boardPush()
        let bytes = Array(frame.utf8)
        var cuts = [0]
        while cuts.last! < bytes.count {
            var end = min(cuts.last! + 4_096, bytes.count)
            while end < bytes.count, bytes[end] & 0xC0 == 0x80 { end -= 1 }
            cuts.append(end)
        }
        let pieces = zip(cuts, cuts.dropFirst()).map { String(decoding: bytes[$0..<$1], as: UTF8.self) }
        #expect(pieces.count > 2)
        var parts = PhoneParts()
        #expect(try parts.read(try text(["t": "parts", "bytes": bytes.count])) == nil)
        for piece in pieces.dropLast() { #expect(try parts.read(piece) == nil) }
        #expect(try parts.read(pieces.last!) == frame)
        let short = try text(["t": "push", "seq": 8, "channel": "parts", "payload": "é😀"])
        #expect(try parts.read(short) == short)
    }

    /// Parts that run past the length the computer named, or a length past the largest frame, are a broken reply.
    @Test func partsPastTheirLengthAreRefused() throws {
        var parts = PhoneParts()
        _ = try parts.read(try text(["t": "parts", "bytes": 4]))
        #expect(throws: PhoneError.self) { try parts.read("{} {}") }
        #expect(try parts.read("{}") == "{}")
        #expect(throws: PhoneError.self) { try parts.read(try text(["t": "parts", "bytes": PhoneContract.maxFrameBytes + 1])) }
        #expect(throws: PhoneError.self) { try parts.read(#"{"t":"parts"}"#) }
    }
}
