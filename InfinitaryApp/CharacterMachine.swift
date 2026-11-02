import Foundation

/// Native counterpart of character/machine.ts. Real inputs win; emotes never invent activity.
struct CharacterMachine {
    enum Mode: String, CaseIterable, Sendable {
        case idle, listening, working, greet, celebrate, ponder, confused, fidget, nod, salute, tick, tuck, aww
        var reply: Bool { [.nod, .salute, .tick, .tuck, .aww].contains(self) }
    }
    typealias Emote = Mode
    enum Fidget: String, CaseIterable, Sendable { case roll, yawn, orbit, orion, dipper, saturn, galaxy, algol, tunnel, sphere, corkscrew, blackhole }
    static func seconds(_ mode: Mode) -> Double? { CharacterCatalog.shared.durations[mode.rawValue].map { $0 / 1000 } }
    private(set) var mode = Mode.idle
    private(set) var variant: Fidget?
    private var lastFidget: Fidget?
    private var busy = false
    private var enteredAt: Double
    private var fidgetAfter: Double
    private var heldReply: Emote?
    private let random: () -> Double

    init(now: Double, random: @escaping () -> Double = { Double.random(in: 0..<1) }) {
        enteredAt = now; self.random = random; fidgetAfter = 9 + random() * 7
    }
    private mutating func go(_ to: Mode, _ now: Double) {
        mode = to; enteredAt = now
        if to == .idle { fidgetAfter = 9 + random() * 7 }
        if to != .fidget { variant = nil }
    }
    mutating func setInputs(listening: Bool, busy: Bool, now: Double) {
        let fell = !busy && self.busy
        self.busy = busy
        let reply = fell ? heldReply : nil
        if fell { heldReply = nil }
        if listening { if mode != .listening { go(.listening, now) }; return }
        if mode == .listening { go(busy ? .working : .idle, now); return }
        if Self.seconds(mode) != nil { return }
        if let reply { go(reply, now); return }
        if mode == .idle && busy { go(.working, now) }
        if mode == .working && !busy { go(.idle, now) }
    }
    @discardableResult mutating func request(_ emote: Emote, now: Double, variant: Fidget? = nil) -> Bool {
        guard Self.seconds(emote) != nil else { return false }
        if busy && emote.reply {
            if let heldReply { return heldReply == emote }
            heldReply = emote; return true
        }
        guard mode == .idle || mode == .working else { return false }
        if emote == .fidget {
            let pool = Fidget.allCases.filter { $0 != lastFidget }
            self.variant = variant ?? pool[min(pool.count - 1, Int(random() * Double(pool.count)))]
            lastFidget = self.variant
        }
        go(emote, now); return true
    }
    private var duration: Double? {
        if mode == .fidget { return (CharacterCatalog.shared.fidgets[(variant ?? .roll).rawValue] ?? 2300) / 1000 }
        return Self.seconds(mode)
    }
    mutating func update(now: Double) -> (mode: Mode, progress: Double) {
        if let duration, now - enteredAt >= duration { go(busy ? .working : .idle, now) }
        if mode == .idle && now - enteredAt >= fidgetAfter { request(.fidget, now: now) }
        return (mode, duration.map { min(1, max(0, now - enteredAt) / $0) } ?? 0)
    }
}
