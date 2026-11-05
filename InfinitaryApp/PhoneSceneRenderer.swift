import Metal
import QuartzCore
import SwiftUI
import UIKit

/// INF-2566 (the captain's approved B): the crew scene draws on a render thread of its own, on its own display clock,
/// so work on the main thread (a board read, a card's web view, SwiftUI's layout) no longer holds the motion.
/// The main thread only hands it new inputs - the roster, the state, the pan - when they change; it never observes
/// a display tick. The painters are the scene's own (`ScenePen`), so the drawing and the motion stay the desktop's.
final class PhoneSceneRenderer: NSObject, @unchecked Sendable {
    /// Everything one frame draws from that the main thread owns.
    struct Input {
        var roster: PhoneSceneRoster
        var state: PhoneCharacter.State
        /// A settled drawing: Reduce Motion, hidden, behind a record or in the background.
        var still: Bool
        /// The clock advances; a stopped clock leaves the scene standing where it is, as under an open summary.
        var running: Bool
        /// Where the scene's origin sits in the scroller's content.
        var offset: CGSize
        var palette: CharacterPainter.Palette
        /// The crewmate keyboard browsing selected, by its touch identity.
        var selection: String?
        /// The crewmate whose summary is open, by task and computer, which wears the desktop's corner brackets.
        var bracketed: (task: String, computer: String)?
        /// Names the drawing for the DEBUG frame sample (`characterEvidenceSource`).
        var source = ""
    }

    let character = CharacterMotion()
    let crew = PhoneSceneMotion()

    private let lock = NSLock()
    // Guarded by `lock`: written on the main thread, read by the render thread at each frame.
    private var input: Input?
    private var pan = CGPoint.zero
    private var size = CGSize.zero
    private var scale: CGFloat = 1
    private var layer: CAMetalLayer?
    private var thread: Thread?
    /// Each attached surface's render thread; a thread whose surface has gone draws nothing more and ends.
    private var generation = 0
    private var maximumRate: Float = 60

    // The render thread's own.
    private var now = 0.0
    private var last: Double?
    private let cache = CharacterPainter.Cache()
    private var device: MTLDevice?
    private var queue: MTLCommandQueue?
    private var targets: [Target] = []
    private var next = 0
    private let inFlight = DispatchSemaphore(value: PhoneSceneRenderer.buffers)
    private static let buffers = 3

    /// One CPU-drawn frame: a shared Metal buffer the painters draw into through Core Graphics, then copied to the drawable.
    private struct Target {
        let buffer: MTLBuffer
        let context: CGContext
        let width: Int, height: Int, bytesPerRow: Int
    }

    // MARK: main thread

    /// Starts the render thread for this surface's layer. The motion lives on with the renderer across surfaces.
    @MainActor func attach(_ layer: CAMetalLayer) {
        let device = MTLCreateSystemDefaultDevice()
        layer.device = device
        layer.pixelFormat = .bgra8Unorm
        layer.framebufferOnly = false
        layer.isOpaque = false
        layer.colorspace = PenColor.space
        layer.maximumDrawableCount = PhoneSceneRenderer.buffers
        // The captain selected the permitted display rate, up to 120. iOS retains power/thermal control.
        let maximum = Float(min(120, (layer.delegate as? UIView)?.window?.screen.maximumFramesPerSecond ?? UIScreen.main.maximumFramesPerSecond))
        let generation = lock.withLock { () -> Int in
            self.generation += 1
            return self.generation
        }
        let thread = Thread { [self] in run(generation) }
        thread.name = "crew-scene-render"
        thread.qualityOfService = .userInteractive
        lock.withLock {
            self.layer = layer; self.device = device; queue = device?.makeCommandQueue()
            self.thread = thread; maximumRate = maximum
        }
        thread.start()
    }

    @MainActor func detach() {
        let thread = lock.withLock { () -> Thread? in
            generation += 1; layer = nil
            defer { self.thread = nil }
            return self.thread
        }
        // Wakes the thread's run loop, which then sees its surface gone and ends.
        guard let thread else { return }
        perform(#selector(resume), on: thread, with: nil, waitUntilDone: false)
    }

    @MainActor func update(_ input: Input) {
        lock.withLock { self.input = input }
        wake()
    }

    /// The scroller's offset, straight from its geometry change, never through a SwiftUI update.
    @MainActor func pan(to point: CGPoint) {
        let changed = lock.withLock { () -> Bool in
            defer { pan = point }
            return pan != point
        }
        if changed { wake() }
    }

    @MainActor func layout(size: CGSize, scale: CGFloat) {
        lock.withLock { self.size = size; self.scale = scale }
        wake()
    }

    /// A stopped clock still draws once for each change of its inputs.
    private func wake() {
        guard let thread = lock.withLock({ self.thread }) else { return }
        perform(#selector(resume), on: thread, with: nil, waitUntilDone: false)
    }

    // MARK: render thread

    private func current(_ generation: Int) -> Bool { lock.withLock { self.generation == generation } }

    private func run(_ generation: Int) {
        let tick = Tick(self, generation: generation)
        let link = CADisplayLink(target: tick, selector: #selector(Tick.tick(_:)))
        let maximum = lock.withLock { maximumRate }
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 1, maximum: maximum, preferred: maximum)
        link.add(to: .current, forMode: .default)
        Thread.current.threadDictionary[Self.linkKey] = link
        while current(generation) {
            _ = RunLoop.current.run(mode: .default, before: .distantFuture)
        }
        link.invalidate()
        Thread.current.threadDictionary.removeObject(forKey: Self.linkKey)
    }
    private static let linkKey = "crew-scene-link"

    /// Runs on the render thread, whose own display link it starts again.
    @objc private func resume() { (Thread.current.threadDictionary[Self.linkKey] as? CADisplayLink)?.isPaused = false }

    /// A display link retains its target, so the renderer is reached weakly.
    private final class Tick: NSObject {
        weak var renderer: PhoneSceneRenderer?
        let generation: Int
        init(_ renderer: PhoneSceneRenderer, generation: Int) { self.renderer = renderer; self.generation = generation }
        @objc func tick(_ link: CADisplayLink) {
            guard let renderer, renderer.current(generation) else { link.isPaused = true; return }
            renderer.frame(link)
        }
    }

    private func frame(_ link: CADisplayLink) {
        let (input, pan, size, scale, layer) = lock.withLock { (self.input, self.pan, self.size, self.scale, self.layer) }
        guard let input, let layer else { link.isPaused = true; return }
        // The clock advances by elapsed time and excludes time stopped, as the main-thread clock did.
        if input.running {
            if let last { now += max(0, link.timestamp - last) }
            last = link.timestamp
        } else {
            last = nil; link.isPaused = true
        }
        draw(input, pan: pan, size: size, scale: scale, into: layer)
    }

    private func draw(_ input: Input, pan: CGPoint, size: CGSize, scale: CGFloat, into layer: CAMetalLayer) {
        let width = Int((size.width * scale).rounded(.up)), height = Int((size.height * scale).rounded(.up))
        guard width > 0, height > 0, let queue else { return }
        if layer.drawableSize != CGSize(width: width, height: height) {
            CATransaction.begin(); CATransaction.setDisableActions(true)
            layer.drawableSize = CGSize(width: width, height: height)
            CATransaction.commit()
        }
        inFlight.wait()
        guard let target = target(width: width, height: height), let drawable = layer.nextDrawable(),
              let commands = queue.makeCommandBuffer(), let blit = commands.makeBlitCommandEncoder() else { inFlight.signal(); return }
        let cg = target.context
        cg.saveGState()
        cg.clear(CGRect(x: 0, y: 0, width: width, height: height))
        // The painters draw top down in points, as a Canvas does.
        cg.translateBy(x: 0, y: CGFloat(height)); cg.scaleBy(x: scale, y: -scale)
        var pen = ScenePen(cg)
        pen.translateBy(x: input.offset.width - pan.x, y: input.offset.height - pan.y)
        paint(input, in: &pen)
        cg.restoreGState()
        let copied = MTLSize(width: min(width, drawable.texture.width), height: min(height, drawable.texture.height), depth: 1)
        blit.copy(from: target.buffer, sourceOffset: 0, sourceBytesPerRow: target.bytesPerRow, sourceBytesPerImage: target.bytesPerRow * height,
                  sourceSize: copied, to: drawable.texture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOrigin())
        blit.endEncoding()
        commands.addCompletedHandler { [inFlight] _ in inFlight.signal() }
        commands.present(drawable)
        commands.commit()
    }

    /// The scene as the Canvas drew it: the warp's backdrop, the crew, the first mate, then the selection and brackets.
    func paint(_ input: Input, in pen: inout ScenePen) {
        #if DEBUG
        let started = ProcessInfo.processInfo.systemUptime
        #endif
        let roster = input.roster, still = input.still, now = still ? 0 : self.now
        let pose = still ? CharacterPose.still(input.state, at: 0) : character.advance(to: now, state: input.state)
        // A warp takes the home crew along (CharacterWarp), as the first mate's 280-point drawing plays it.
        let frame = crew.frame(roster: roster, now: now, settled: still, warp: CharacterWarp.frame(pose, coreR: 280 * 0.27))
        let palette = input.palette
        // A warp's wormhole and stars lie behind every crewmate and the first mate.
        if let warp = crew.warp {
            CharacterWarp.drawBackdrop(warp, at: CGPoint(x: roster.homeX, y: roster.height / 2), riders: crew.riders,
                                       scale: PhoneSceneRoster.ringScale, palette: palette, in: &pen)
        }
        PhoneCrewPainter.draw(frame, roster: roster, now: now, still: still, in: &pen, palette: palette)
        var firstmate = pen
        firstmate.translateBy(x: roster.homeX - 140, y: roster.height / 2 - 140)
        CharacterPainter.draw(pose, in: &firstmate, size: CGSize(width: 280, height: 280), cache: cache, palette: palette, source: input.source)
        PhoneCrewPainter.drawMarks(frame, selection: input.selection, bracketed: input.bracketed, in: &pen, palette: palette)
        #if DEBUG
        // The scene scope excludes the nested first mate's separate character reading.
        CharacterFrameMetrics.shared.record(start: started, source: input.source, mode: pose.mode.rawValue, heat: pose.heat, rotation: pose.a, drawing: .scene)
        #endif
    }

    private func target(width: Int, height: Int) -> Target? {
        if targets.first?.width != width || targets.first?.height != height {
            // A resize waits for every frame still reading the old buffers before replacing them.
            for _ in 1..<PhoneSceneRenderer.buffers { inFlight.wait() }
            defer { for _ in 1..<PhoneSceneRenderer.buffers { inFlight.signal() } }
            targets = []
            let bytesPerRow = (width * 4 + 255) / 256 * 256
            for _ in 0..<PhoneSceneRenderer.buffers {
                guard let buffer = device?.makeBuffer(length: bytesPerRow * height, options: .storageModeShared),
                      let context = ScenePen.bitmap(width: width, height: height, data: buffer.contents(), bytesPerRow: bytesPerRow)
                else { targets = []; return nil }
                targets.append(Target(buffer: buffer, context: context, width: width, height: height, bytesPerRow: bytesPerRow))
            }
        }
        next = (next + 1) % targets.count
        return targets[next]
    }
}

/// The scene's surface: a Metal layer the render thread fills. It takes no touches and holds no accessibility;
/// `PhoneSceneTouches` answers both in the scroller's content.
final class PhoneSceneSurfaceView: UIView {
    override class var layerClass: AnyClass { CAMetalLayer.self }
    var metalLayer: CAMetalLayer { layer as! CAMetalLayer }
    var renderer: PhoneSceneRenderer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false; isOpaque = false; backgroundColor = .clear
        accessibilityElementsHidden = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func layoutSubviews() {
        super.layoutSubviews()
        renderer?.layout(size: bounds.size, scale: window?.screen.scale ?? traitCollection.displayScale)
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        metalLayer.contentsScale = window?.screen.scale ?? traitCollection.displayScale
        setNeedsLayout()
    }
}

/// Hands the scene's inputs to its renderer whenever SwiftUI updates them; nothing here runs per frame.
struct PhoneSceneSurface: UIViewRepresentable {
    let renderer: PhoneSceneRenderer
    let roster: PhoneSceneRoster
    let state: PhoneCharacter.State
    let still: Bool
    let running: Bool
    var offset: CGSize = .zero
    var selection: String?
    var bracketed: (task: String, computer: String)?

    func makeUIView(context: Context) -> PhoneSceneSurfaceView {
        let view = PhoneSceneSurfaceView()
        view.renderer = renderer
        renderer.attach(view.metalLayer)
        return view
    }

    func updateUIView(_ view: PhoneSceneSurfaceView, context: Context) {
        #if DEBUG
        let source = context.environment.characterEvidenceSource
        #else
        let source = ""
        #endif
        renderer.update(.init(roster: roster, state: state, still: still, running: running, offset: offset,
                              palette: CharacterPainter.Palette(context.environment), selection: selection, bracketed: bracketed, source: source))
    }

    static func dismantleUIView(_ view: PhoneSceneSurfaceView, coordinator: ()) {
        view.renderer?.detach()
        view.renderer = nil
    }
}
