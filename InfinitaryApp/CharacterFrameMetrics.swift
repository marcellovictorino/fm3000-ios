#if DEBUG
import Foundation
import SwiftUI

private struct CharacterEvidenceSource: EnvironmentKey { static let defaultValue = "" }
extension EnvironmentValues {
    var characterEvidenceSource: String {
        get { self[CharacterEvidenceSource.self] }
        set { self[CharacterEvidenceSource.self] = newValue }
    }
}

/// Observe only the named visible Canvas and drawing scope, never another window or its nested painter.
/// Release builds contain neither this buffer nor its drawing calls.
final class CharacterFrameMetrics: @unchecked Sendable {
    static let shared = CharacterFrameMetrics()
    enum Drawing: Sendable, Equatable { case character, scene }
    struct Frame: Sendable {
        let timestamp: Double
        let work: Double
        let mode: String
        let heat: Double
        let rotation: Double
    }
    private let lock = NSLock()
    private var source: String?
    private var drawing: Drawing = .character
    private var frames: [Frame] = []

    func start(source: String, drawing: Drawing = .character) {
        lock.lock(); defer { lock.unlock() }
        frames = []; self.source = source; self.drawing = drawing
    }
    func record(start: Double, source: String, mode: String, heat: Double, rotation: Double, drawing: Drawing = .character) {
        let end = ProcessInfo.processInfo.systemUptime
        lock.lock(); defer { lock.unlock() }
        if self.source == source && self.drawing == drawing {
            frames.append(Frame(timestamp: start, work: end - start, mode: mode, heat: heat, rotation: rotation))
        }
    }
    func finish() -> [Frame] {
        lock.lock(); defer { lock.unlock() }
        source = nil
        let result = frames; frames = []
        return result
    }
}
#endif
