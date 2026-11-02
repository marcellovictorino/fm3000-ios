import Observation
import QuartzCore
import UIKit

/// INF-1066: display-synchronized elapsed time. Only the scene observes this clock, not the shell.
/// A stopped clock consumes no callbacks and excludes time spent behind cards or in the background.
@MainActor @Observable final class CharacterDisplayClock {
    private(set) var now = 0.0
    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private var last: Double?
    @ObservationIgnored private let target = DisplayTarget()

    var running: Bool { link != nil }
    func setRunning(_ running: Bool, screen: UIScreen? = nil) {
        guard running != self.running else { return }
        if !running { link?.invalidate(); link = nil; last = nil; return }
        target.owner = self
        let link = CADisplayLink(target: target, selector: #selector(DisplayTarget.tick(_:)))
        // The captain selected the permitted display rate, up to 120. iOS retains power/thermal control.
        let maximum = Float(min(120, (screen ?? UIScreen.main).maximumFramesPerSecond))
        // Core Animation requires a positive minimum for a nondefault range; zero raises an exception.
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 1, maximum: maximum, preferred: maximum)
        self.link = link
        link.add(to: .main, forMode: .common)
    }
    func advance(timestamp: Double) {
        if let last { now += max(0, timestamp - last) }
        last = timestamp
    }
    @MainActor private final class DisplayTarget: NSObject {
        weak var owner: CharacterDisplayClock?
        @objc func tick(_ link: CADisplayLink) { owner?.advance(timestamp: link.timestamp) }
    }
}
