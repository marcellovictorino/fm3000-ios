import Foundation

/// The same log token mapping and damped filament envelope as character/flicker.ts.
enum CharacterFlicker {
    static func intensity(_ tokens: Double) -> Double {
        let t = CharacterCatalog.shared.flicker, low = max(1, t["tokenMin"]!), high = max(low + 1, t["tokenMax"]!)
        let k = clamp01((log(max(low, tokens)) - log(low)) / (log(high) - log(low)))
        return t["minBoost"]! + (t["maxBoost"]! - t["minBoost"]!) * k
    }
    static func envelope(_ age: Double) -> Double {
        let t = CharacterCatalog.shared.flicker, u = age / (t["durationMs"]! / 1000)
        guard u >= 0 && u < 1 else { return 0 }
        let attack = u < 0.07 ? easeInOut(u / 0.07) : 1
        return attack * pow(1 - u, 1.7) * (1 + t["depth"]! * sin(u * t["pulses"]! * 2 * .pi) * (1 - u))
    }
    static func wire(_ edge: Int, _ now: Double) -> Double {
        0.62 + 0.34 * sin(now / 103 + Double(edge) * 2.17) + 0.12 * sin(now / 41 + Double(edge) * 4.91)
    }
}
