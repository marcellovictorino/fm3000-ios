import Foundation

/// INF-2631: what a phone's usage events say about the phone itself: its kind and its own app version.
public struct PhoneUsage: Equatable, Sendable {
    public let device: PhoneDiagnosticDevice
    public let version: String

    public init(device: PhoneDiagnosticDevice, version: String) {
        self.device = device
        self.version = version
    }
}

/// INF-2631 (docs/sharing.md, "A phone's events"): the phone's own usage events wait here, in memory only, until its
/// computer is in reach, and go to that computer alone. The computer decides from its own Diagnostics switch whether
/// anything leaves, so the phone holds no switch, no install ID and no address but its computer's.
public struct PhoneDiagnosticsQueue: Sendable {
    public struct Waiting: Equatable, Sendable {
        public let event: PhoneDiagnosticEvent
        /// When it happened on the phone, in milliseconds since 1970.
        public let at: Int
    }

    /// The most that wait while the computer is away, as many as the computer itself keeps waiting; past it a new
    /// event is dropped, so the oldest stay.
    public static let held = 200

    public private(set) var waiting: [Waiting] = []

    public init() {}

    public mutating func note(_ event: PhoneDiagnosticEvent, at date: Date) {
        guard waiting.count < Self.held else { return }
        waiting.append(Waiting(event: event, at: Int((date.timeIntervalSince1970 * 1000).rounded(.down))))
    }

    /// Every waiting event as the computer's request reads it, oldest first, leaving none: one is handed over once.
    public mutating func handOver(as usage: PhoneUsage) -> [[String: Any]] {
        defer { waiting = [] }
        return waiting.map { waiting in
            ["name": waiting.event.rawValue, "data": ["device": usage.device.rawValue], "version": usage.version, "at": waiting.at]
        }
    }

    /// The computer takes none of them: it is older than this change, or this phone may only read from it.
    public mutating func drop() { waiting = [] }
}
