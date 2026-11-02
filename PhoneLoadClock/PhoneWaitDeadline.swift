import Foundation

// One load clock for both test targets: the UI journeys' observations and the app-hosted
// display samples (INF-1506) read the same deadline, never a second clock of their own.

/// INF-1083: the launcher writes the shared budget reading into every test target's plan.
let gradesBudgets = ProcessInfo.processInfo.environment["INFINITARY_PERF_BUDGETS"] == "1"

/// Mirrors tests/helpers/budgets.ts: the load clock samples every 25 ms, counts at most
/// two ticks across a stall, and slows when the one-minute load exceeds the processor count.
/// Each observation still ends at min(20 × budget, 10 minutes) on the monotonic wall clock.
struct PhoneWaitDeadline {
    private let budget: TimeInterval
    private let graded: Bool
    private let started: TimeInterval
    private var last: TimeInterval
    private var counted: TimeInterval = 0
    private var share: Double = 1
    static let tick: TimeInterval = 0.025

    init(_ budget: TimeInterval, graded: Bool = gradesBudgets,
         now: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        precondition(budget.isFinite && budget >= 0)
        self.budget = budget
        self.graded = graded
        started = now
        last = now
    }

    mutating func expired(now: TimeInterval = ProcessInfo.processInfo.systemUptime,
                          load: Double = phoneLoad(), processors: Int = ProcessInfo.processInfo.activeProcessorCount) -> Bool {
        counted += min(max(0, now - last), 2 * Self.tick) * share
        last = now
        share = min(1, Double(processors) / max(Double(processors), load))
        let elapsed = now - started
        return graded ? elapsed >= budget : counted >= budget || elapsed >= phoneRequestBudget(budget)
    }
}

private func phoneLoad() -> Double {
    var reading: Double = 0
    return getloadavg(&reading, 1) == 1 ? reading : 0
}

/// The transport is an outer safety boundary only; the request's failure timer uses the clock.
func phoneRequestBudget(_ seconds: TimeInterval) -> TimeInterval {
    min(20 * seconds, 600)
}
