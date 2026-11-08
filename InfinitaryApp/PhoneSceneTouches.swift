import InfinitaryKit
import SwiftUI
import UIKit

/// INF-2566: the crew answer touch and accessibility from the frame the render thread last drew, read only when a
/// touch or an accessibility query arrives, so the main thread no longer lays out a button per crewmate every frame.
/// Each crewmate and program keeps its 44-point square, nearer centers winning where squares overlap (`PhoneTouchCell`).
struct PhoneSceneTouches: UIViewRepresentable {
    let crew: PhoneSceneMotion
    let roster: PhoneSceneRoster
    let offset: CGSize
    let selection: String?
    let open: (PhoneTask, String) -> Void

    func makeUIView(context: Context) -> PhoneSceneTouchView { PhoneSceneTouchView(crew: crew) }
    func updateUIView(_ view: PhoneSceneTouchView, context: Context) {
        view.roster = roster; view.offset = offset; view.selection = selection; view.open = open; view.latestRead = nil
    }
}

final class PhoneSceneTouchView: UIView, UIGestureRecognizerDelegate {
    struct Target {
        let id: String, task: PhoneTask, computer: String, point: CGPoint, label: String, words: String
    }
    let crew: PhoneSceneMotion
    var roster: PhoneSceneRoster?
    var offset = CGSize.zero
    var selection: String?
    var open: (PhoneTask, String) -> Void = { _, _ in }
    private var elements: [String: Element] = [:]
    var latestRead: (at: Double, targets: [Target])?

    init(crew: PhoneSceneMotion) {
        self.crew = crew
        super.init(frame: .zero)
        backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tap.delegate = self
        addGestureRecognizer(tap)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// Every crewmate and program `frame` drew (the last frame by default), in content coordinates, in the roster's order.
    func targets(in drawn: PhoneSceneMotion.Frame? = nil) -> [Target] {
        guard let drawn else {
            // One accessibility query asks every crewmate for each of its attributes; they share one reading of the
            // latest frame within a display frame, rather than building every target again for each attribute.
            let now = ProcessInfo.processInfo.systemUptime
            if let read = latestRead, now - read.at < 1.0 / 120 { return read.targets }
            let targets = targets(in: crew.current)
            latestRead = (now, targets)
            return targets
        }
        guard let roster else { return [] }
        let frame = drawn
        let glyphs = frame.glyphs.map { glyph -> (Target, Int) in
            let computer = roster.computers.first { $0.id == PhoneSceneRoster.computerID(glyph.task) }
            let words = computer.map { PhoneSceneRoster.words(glyph.task, computer: $0) } ?? glyph.task.state
            return (Target(id: glyph.task.id, task: glyph.task, computer: PhoneSceneRoster.computerID(glyph.task), point: shifted(glyph.point),
                           label: glyph.task.key + ", " + glyph.task.title, words: words), roster.order[glyph.task.id] ?? roster.tasks.count)
        }
        let marks = frame.marks.map { mark -> (Target, Int) in
            (Target(id: mark.id, task: mark.task, computer: mark.computerID, point: shifted(mark.point), label: mark.task.key + ", " + mark.task.title,
                    words: "Program, " + String(mark.parts.count) + " running parts"), roster.order[mark.task.id] ?? roster.tasks.count)
        }
        return (glyphs + marks).sorted { $0.1 == $1.1 ? $0.0.id < $1.0.id : $0.1 < $1.1 }.map(\.0)
    }
    private func shifted(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x + offset.width, y: point.y + offset.height) }

    /// The target whose 44-point square holds the point, the nearer center winning where squares overlap.
    func target(at point: CGPoint, in drawn: PhoneSceneMotion.Frame? = nil) -> Target? {
        let all = targets(in: drawn), centers = all.map(\.point)
        return all.first { target in
            PhoneTouchCell(center: target.point, neighbors: centers).path(in: Self.square(target.point)).contains(point)
        }
    }
    static func square(_ point: CGPoint) -> CGRect { CGRect(x: point.x - 22, y: point.y - 22, width: 44, height: 44) }

    /// Where and when the finger landed. The tap is recognized only as the finger lifts, while the crew keep moving on
    /// the render thread; the crewmate under the finger is the one the frame on screen at touch-down drew there, as a
    /// button under the finger is chosen at touch-down. The tap recognizer receives each touch as it lands, so it reads
    /// the landing. The view's own touchesBegan cannot: the scroller holds a touch back from the view, so a quick tap is
    /// recognized before the view hears it land, while a drag the scroller takes over is heard landing and never taps.
    /// The next tap then opened the crewmate where that drag had started, not the one under the finger.
    private var landed: (point: CGPoint, at: Double)?
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        landed = (touch.location(in: self), touch.timestamp)
        return true
    }

    @objc private func tapped(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: self)
        let found = landed.flatMap { target(at: $0.point, in: crew.frame(at: $0.at)) } ?? target(at: point)
        landed = nil
        guard let target = found else { return }
        open(target.task, target.computer)
    }

    // MARK: accessibility

    override var isAccessibilityElement: Bool { get { false } set {} }
    override var accessibilityElements: [Any]? {
        get {
            let all = targets()
            var kept: [String: Element] = [:]
            let list = all.map { target -> Element in
                let element = elements[target.id] ?? Element(accessibilityContainer: self)
                element.id = target.id
                kept[target.id] = element
                return element
            }
            elements = kept
            return list
        }
        set {}
    }

    /// One crewmate or program, reading its place and words from the latest frame each time it is asked.
    final class Element: UIAccessibilityElement {
        var id = ""
        private var view: PhoneSceneTouchView? { accessibilityContainer as? PhoneSceneTouchView }
        private var target: Target? { view?.targets().first { $0.id == id } }
        override var accessibilityIdentifier: String? { get { "crew-task-" + id } set {} }
        override var accessibilityLabel: String? { get { target?.label } set {} }
        override var accessibilityValue: String? {
            get { target.map { view?.selection == id ? "Selected, " + $0.words : $0.words } }
            set {}
        }
        override var accessibilityTraits: UIAccessibilityTraits {
            get { view?.selection == id ? [.button, .selected] : .button }
            set {}
        }
        override var accessibilityFrameInContainerSpace: CGRect {
            get { target.map { PhoneSceneTouchView.square($0.point) } ?? .zero }
            set {}
        }
        override var accessibilityFrame: CGRect {
            get {
                guard let view, let target else { return .zero }
                return UIAccessibility.convertToScreenCoordinates(PhoneSceneTouchView.square(target.point), in: view)
            }
            set {}
        }
        override func accessibilityActivate() -> Bool {
            guard let target else { return false }
            view?.open(target.task, target.computer)
            return true
        }
    }
}
