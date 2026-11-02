import XCTest

/// INF-1541 piece 1 (the captain's choice "The test code skips Apple's animation wait and checks each target itself"):
/// before and after each action XCTest waits for the app's main run loop to idle and, separately, for a reply from
/// inside the app saying its animations finished. On a busy Mac that reply can stop coming: in INF-1538 it stopped after
/// a rotation while the app sat idle, and XCTest then waited 60 seconds before every action until the part ran out of
/// time. Every one of those waits reaches this private method of Xcode 26.4's XCUIAutomation, so the journeys replace it,
/// as WebDriverAgent does, with one that keeps the run loop wait and never asks for the animation reply; a tap checks its
/// own target instead (tapOnPhone). Apple offers no public way to do this. If Xcode stops offering the method, or changes
/// what it takes, the part fails naming it, and the gate fails a part that never said it skipped the wait
/// (scripts/phone-test-plan.ts, `phoneAnimationWaits`).
private let quiescenceClass = "XCUIApplicationProcess"
private let quiescenceSelector = "waitForQuiescenceIncludingAnimationsIdle:usingActivity:isPreEvent:"
/// No result; the process, the selector, then three C booleans: animations idle, using an activity, before the event.
private let quiescenceTypes = "v@:BBB"

@MainActor private var animationWaitSkipped = false

@MainActor func skipPhoneAnimationWait() throws {
    guard !animationWaitSkipped else { return }
    let name = "-[\(quiescenceClass) \(quiescenceSelector)]"
    guard let process = NSClassFromString(quiescenceClass),
          let method = class_getInstanceMethod(process, NSSelectorFromString(quiescenceSelector)) else {
        throw NSError(domain: "PhoneAnimationWait", code: 1, userInfo: [NSLocalizedDescriptionKey:
            "XCTest's animation wait hook is missing: this Xcode has no \(name)"])
    }
    let types = method_getTypeEncoding(method).map { String(cString: $0).filter { !$0.isNumber } }
    guard types == quiescenceTypes else {
        throw NSError(domain: "PhoneAnimationWait", code: 2, userInfo: [NSLocalizedDescriptionKey:
            "XCTest's animation wait hook is missing: \(name) takes \(types ?? "unknown types"), not \(quiescenceTypes)"])
    }
    typealias Wait = @convention(c) (AnyObject, Selector, Bool, Bool, Bool) -> Void
    let original = unsafeBitCast(method_getImplementation(method), to: Wait.self)
    let selector = method_getName(method)
    let replacement: @convention(block) @Sendable (AnyObject, Bool, Bool, Bool) -> Void = { process, _, activity, preEvent in
        original(process, selector, false, activity, preEvent)
    }
    method_setImplementation(method, imp_implementationWithBlock(replacement))
    animationWaitSkipped = true
    print("Phone animation wait skipped: \(name)")
}
