import InfinitaryKit
import Synchronization
import SwiftUI

/// INF-209's native three-state first mate, moving as the Mac's character does (INF-589 item 18).
/// The conversation owner supplies its real state. Every number below is the Mac character's own, from
/// src/renderer/src/character (Firstmate.tsx, machine.ts, face.ts, replies.ts and glow.ts), so the two stay the same.
struct PhoneCharacter: View {
    enum State: String, CaseIterable { case idle, listening, working }
    var state: State = .idle
    /// The first mate shortening its conversation: the cinch over working (CharacterCinch).
    var fold = CharacterFold()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    @SwiftUI.State private var visible = false
    @SwiftUI.State private var motion = CharacterMotion()
    @SwiftUI.State private var clock = CharacterDisplayClock()

    var body: some View {
        Group {
            if reduceMotion { drawing(at: 0) }
            else { CharacterDrawing(clock: clock, motion: motion, state: state, fold: fold) }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your first mate")
        .accessibilityValue(state.rawValue)
        .accessibilityIdentifier("phone-character")
        .onAppear { visible = true; syncClock() }
        .onDisappear { visible = false; clock.setRunning(false); CharacterCues.left(motion) }
        .onChange(of: reduceMotion) { _, _ in syncClock() }
        .onChange(of: phase) { _, _ in syncClock() }
    }

    private func syncClock() {
        let running = visible && !reduceMotion && phase == .active
        clock.setRunning(running)
        if running { CharacterCues.shown.add(motion) }
        else { CharacterCues.shown.remove(motion); motion.discardReactions() }
    }

    /// The still pose Reduce Motion shows, which the native snapshot test also photographs.
    func drawing(at time: Double) -> some View {
        let pose = CharacterPose.still(state, folding: fold.folding, at: time)
        return Canvas { context, size in CharacterPainter.draw(pose, in: &context, size: size) }
    }
}

/// Only this small subtree observes per-display updates; cards, composer and task records do not.
private struct CharacterDrawing: View {
    let clock: CharacterDisplayClock
    let motion: CharacterMotion
    let state: PhoneCharacter.State
    let fold: CharacterFold
    @SwiftUI.State private var cache = CharacterPainter.Cache()
    var body: some View {
        let pose = motion.advance(to: clock.now, state: state, fold: fold)
        Canvas { context, size in CharacterPainter.draw(pose, in: &context, size: size, cache: cache) }
    }
}

/// Live-only reactions and the greeting handed between visible native scenes.
@MainActor enum CharacterCues {
    /// The first character a person sees after the app opens or joins a computer greets once. A scene's motion
    /// starts on its own render thread, so the flag is shared under a lock.
    private nonisolated static let greeting = Mutex(true)
    nonisolated static var greetingPending: Bool {
        get { greeting.withLock { $0 } }
        set { greeting.withLock { $0 = newValue } }
    }
    /// Takes the pending greeting for a character starting now, so exactly one character greets.
    nonisolated static func takeGreeting() -> Bool {
        greeting.withLock { pending in defer { pending = false }; return pending }
    }
    /// The characters on screen now; a reaction reaches only these, never one shown later.
    static let shown = NSHashTable<CharacterMotion>.weakObjects()

    static func greetOnNextSight() { greetingPending = true }

    /// A character that leaves mid-greeting, such as the empty stage a join shows before its cards arrive,
    /// hands the greeting on to the next one a person sees.
    static func left(_ motion: CharacterMotion) {
        shown.remove(motion)
        if motion.greeting { greetingPending = true }
    }

    static let crews = NSHashTable<PhoneSceneMotion>.weakObjects()
    static func signal(_ signal: PhoneSceneSignal) {
        if signal.kind == .usage && signal.taskID == CharacterCatalog.shared.firstmateID {
            for motion in shown.allObjects { motion.flicker(tokens: signal.tokens) }
        } else { for scene in crews.allObjects { scene.receive(signal) } }
    }

    static func reacted(_ emote: String) {
        guard let emote = CharacterMachine.Emote(rawValue: emote), CharacterMachine.seconds(emote) != nil else { return }
        for motion in shown.allObjects { motion.request(emote) }
    }
}

/// The Mac's per-state targets (FM_STATES), which the drawing eases toward.
struct CharacterTargets: Sendable, Decodable {
    var sa, sb, pulse, glow, shimmer, breath, flat, scale, lidBase, eyeScale, jitter: Double

    static func of(_ mode: CharacterMachine.Mode) -> Self {
        CharacterCatalog.shared.targets[mode.rawValue]!
    }

    func eased(toward target: Self, by k: Double) -> Self {
        func ease(_ from: Double, _ to: Double) -> Double { from + (to - from) * k }
        return Self(sa: ease(sa, target.sa), sb: ease(sb, target.sb), pulse: ease(pulse, target.pulse),
                    glow: ease(glow, target.glow), shimmer: ease(shimmer, target.shimmer), breath: ease(breath, target.breath),
                    flat: ease(flat, target.flat), scale: ease(scale, target.scale), lidBase: ease(lidBase, target.lidBase),
                    eyeScale: ease(eyeScale, target.eyeScale), jitter: ease(jitter, target.jitter))
    }
}

/// Everything one frame draws from, independent of the drawing's size.
struct CharacterPose: Sendable {
    var mode = CharacterMachine.Mode.idle
    var progress = 0.0
    var variant: CharacterMachine.Fidget?
    var flicker = 0.0
    var cur = CharacterTargets.of(.idle)
    var heat = 0.0
    var a = 0.4, b = 0.9, hs = 0.0
    var milliseconds = 0.0
    var eyeX = 0.0, eyeY = 0.0
    var lid = 0.0, wink = 0.0, happy = 0.0
    /// The cinch's frame while one plays, and how far the working state lets it show (attention and emotes ease it out).
    var cinch: CharacterCinch.Frame?
    var cinchGate = 0.0
    var still = false
    /// The cinch's tightness as drawn.
    var cinchK: Double { (cinch?.k ?? 0) * cinchGate }

    /// Reduce Motion's still: the state's targets settled, eyes open and on the state's own look.
    /// A shortening shows its tight pose, with no ring throw, glint or motes.
    static func still(_ state: PhoneCharacter.State, folding: Bool = false, at time: Double) -> Self {
        let mode: CharacterMachine.Mode = state == .listening ? .listening : state == .working ? .working : .idle
        var pose = Self(mode: mode, cur: .of(mode), heat: state == .working ? 1 : 0, milliseconds: time * 1000)
        pose.still = true
        pose.cinch = CharacterCinch.still(folding)
        pose.cinchGate = mode == .working ? 1 : 0
        let body = CharacterCinch.body(pose.cinchK)
        pose.a += pose.cur.sa * body.spin * time
        pose.b += pose.cur.sb * body.spin * time
        pose.hs = 0.5 * time * pose.cur.flat
        if mode == .working { (pose.eyeX, pose.eyeY) = body.look }
        pose.lid = max(pose.cur.lidBase, body.lid)
        return pose
    }
}

/// The Mac's soft-light pulse and band (face.ts) and the nod's beat (replies.ts).
func pulse(_ t: Double, _ at: Double, _ width: Double) -> Double {
    let u = (t - at) / width
    return u <= 0 || u >= 1 ? 0 : sin(u * .pi)
}
func clamp01(_ x: Double) -> Double { max(0, min(1, x)) }
func band(_ t: Double, _ a: Double, _ wa: Double, _ b: Double, _ wb: Double) -> Double {
    clamp01((t - a) / wa) * (1 - clamp01((t - b) / wb))
}
func nodBeat(_ t: Double) -> Double { pulse(t, 0.05, 0.3) + pulse(t, 0.36, 0.24) * 0.6 }

/// The Mac's Spring, Blinker and Gaze (face.ts): blinks every few seconds, a wandering look at rest.
private struct Spring {
    var x = 0.0, v = 0.0
    let freq = 2.2, zeta = 0.9

    mutating func step(_ target: Double, _ dt: Double) {
        let w = 2 * Double.pi * freq, n = max(1, Int((dt * w / 0.5).rounded(.up))), h = dt / Double(n)
        for _ in 0..<n {
            v += (-2 * zeta * w * v - w * w * (x - target)) * h
            x += v * h
        }
    }
}

private struct Blinker {
    var next = 1.5 + Double.random(in: 0..<1) * 3
    var t = -1.0
    var again = false

    mutating func update(_ dt: Double, suppressed: Bool) -> Double {
        if t < 0 {
            if !suppressed {
                next -= dt
                if next <= 0 { t = 0; again = Double.random(in: 0..<1) < 0.22 }
            }
            return 0
        }
        t += dt
        let length = 0.16
        if t >= length {
            if again { again = false; t = 0; return 0 }
            t = -1; next = 2.4 + Double.random(in: 0..<1) * 4.2
            return 0
        }
        return sin(t / length * .pi)
    }
}

private struct Gaze {
    var sx = Spring(), sy = Spring()
    var tx = 0.0, ty = 0.0
    var next = 1 + Double.random(in: 0..<1) * 2

    /// A held look, or nil to wander.
    mutating func update(_ dt: Double, look: (x: Double, y: Double)?) -> (x: Double, y: Double) {
        var target = (x: tx, y: ty)
        if let look { target = look } else {
            next -= dt
            if next <= 0 {
                next = 1.2 + Double.random(in: 0..<1) * 2.6
                let angle = Double.random(in: 0..<1) * 2 * .pi, radius = Double.random(in: 0..<1) * 0.7
                (tx, ty) = Double.random(in: 0..<1) < 0.3 ? (0, 0) : (cos(angle) * radius, sin(angle) * radius * 0.6)
            }
            target = (tx, ty)
        }
        sx.step(target.x, dt); sy.step(target.y, dt)
        return (sx.x, sy.x)
    }
}

/// One character's running motion: the machine, the eased targets, the ember, the turning and the face.
/// The crew scene advances it on its render thread while cues arrive on the main thread, so every entry takes its lock.
final class CharacterMotion: @unchecked Sendable {
    private let lock = NSLock()
    private var machine: CharacterMachine?
    private var last: Double?
    private var pose = CharacterPose()
    private var vel = 0.5
    private var blinker = Blinker(), gaze = Gaze()
    private var cinch: CharacterCinch.Clock?
    private var requests: [(CharacterMachine.Emote, CharacterMachine.Fidget?)] = []
    func request(_ emote: CharacterMachine.Emote, variant: CharacterMachine.Fidget? = nil) { lock.withLock { requests.append((emote, variant)) } }
    private var flickerAt = -Double.infinity, flickerBoost = 0.0
    func flicker(tokens: Double) {
        lock.withLock {
            guard let last else { return }
            flickerBoost = max(CharacterFlicker.intensity(tokens), flickerBoost * CharacterFlicker.envelope(last - flickerAt))
            flickerAt = last
        }
    }
    func discardReactions() { lock.withLock { requests.removeAll(keepingCapacity: true); flickerBoost = 0 } }
    var greeting: Bool { lock.withLock { machine?.mode == .greet } }

    func advance(to time: Double, state: PhoneCharacter.State, fold: CharacterFold = .init()) -> CharacterPose {
        lock.withLock { advanceLocked(to: time, state: state, fold: fold) }
    }
    private func advanceLocked(to time: Double, state: PhoneCharacter.State, fold: CharacterFold) -> CharacterPose {
        if machine == nil {
            machine = CharacterMachine(now: time)
            if CharacterCues.takeGreeting() { machine?.request(.greet, now: time) }
        }
        // The cinch keeps its own clock beside the machine, which never hears it: a starting count from before the
        // character was drawn plays nothing.
        if cinch == nil { cinch = CharacterCinch.Clock(starts: fold.starts) }
        cinch?.update(time, fold)
        guard var machine else { return pose }
        // Inputs first, then the request: a nod asked for as a turn starts is held for that turn's end.
        machine.setInputs(listening: state == .listening, busy: state == .working, now: time)
        for (emote, variant) in requests { machine.request(emote, now: time, variant: variant) }
        requests.removeAll(keepingCapacity: true)
        let (mode, et) = machine.update(now: time)
        self.machine = machine
        let dt = min(max(0, time - (last ?? time)), 0.05)
        last = time
        pose.mode = mode
        pose.progress = et
        pose.variant = machine.variant
        pose.flicker = flickerBoost * CharacterFlicker.envelope(time - flickerAt)
        pose.cur = pose.cur.eased(toward: .of(mode), by: min(dt * 4, 1))
        pose.heat += ((state == .working ? 1 : 0) - pose.heat) * min(dt * 3, 1)
        pose.still = false
        pose.cinch = cinch?.frame(time)
        pose.cinchGate += ((mode == .working ? 1 : 0) - pose.cinchGate) * min(dt * 3, 1)
        let body = CharacterCinch.body(pose.cinchK)
        vel += (0.5 - vel) * min(dt * 1.5, 1)
        // A warp (CharacterWarp) adds its own spin, squint and held look.
        let warp = CharacterWarp.pose(of: pose)
        pose.a += (pose.cur.sa * body.spin + (warp?.sa ?? 0)) * dt
        pose.b += (pose.cur.sb * body.spin + (warp?.sb ?? 0)) * dt
        pose.hs += dt * vel * pose.cur.flat
        pose.milliseconds += dt * 1000
        let reply = CharacterReply.frame(mode, et)
        var look: (x: Double, y: Double)? = reply.gaze.map { ($0.x, $0.y) }
        switch mode {
        case .listening: look = (0, 0)
        case .working: look = body.look
        case .ponder: look = (-0.8, -0.9)
        case .confused: look = (CharacterSky.twinkle(pose.milliseconds / 1000 * 6) * 0.8, CharacterSky.twinkle(pose.milliseconds / 1000 * 5 + 9) * 0.5)
        case .fidget:
            if machine.variant == .orbit {
                let angle = -.pi / 2 + easeInOut(clamp01((et - 0.1) / 0.75)) * 2 * .pi
                look = (cos(angle) * 0.9, sin(angle) * 0.7)
            } else if machine.variant == .yawn { look = (0, -0.35 * pulse(et, 0.12, 0.62)) }
            else if machine.variant == .blackhole { look = (0, 0.12) }
            else if machine.variant == .saturn { look = (0, 0.1) }
            else if let warp { look = warp.look }
            else { look = (0, 0) }
            if let constellation = CharacterCatalog.shared.constellations[machine.variant?.rawValue ?? ""] {
                look = (constellation.gaze[0], constellation.gaze[1])
            }
        default: break
        }
        (pose.eyeX, pose.eyeY) = gaze.update(dt, look: look)
        pose.lid = max(pose.cur.lidBase, max(reply.lid, blinker.update(dt, suppressed: mode == .listening || mode == .celebrate || reply.suppressBlink)))
        // The cinch narrows the eyes, and its end gives one slow blink.
        pose.lid = max(pose.lid, body.lid)
        if let frame = pose.cinch, frame.phase == .out { pose.lid = max(pose.lid, pulse(frame.u, 0.1, 0.65) * pose.cinchGate) }
        if machine.variant == .roll { pose.lid = max(pose.lid, band(et, 0.3, 0.15, 0.6, 0.22)) }
        if machine.variant == .yawn { pose.lid = max(pose.lid, pulse(et, 0.12, 0.62) * 0.95) }
        if machine.variant == .blackhole { pose.lid = max(pose.lid, CharacterSky.envelope(pose) * 0.3) }
        if let warp { pose.lid = max(pose.lid, warp.lid) }
        if machine.variant == .galaxy { pose.lid = max(pose.lid, CharacterSky.envelope(pose) * CharacterCatalog.shared.galaxy["lid"]!) }
        pose.wink = mode == .greet ? band(et, 0.42, 0.1, 0.68, 0.12) : 0
        pose.happy = mode == .greet ? band(et, 0.12, 0.18, 0.82, 0.18) : mode == .celebrate ? band(et, 0.08, 0.15, 0.85, 0.15) : reply.happy
        return pose
    }
}

/// The Mac's drawFrame for the phone's states and emotes: the tesseract, its halo, and the two soft-light eyes.
enum CharacterPainter {
    struct RGB: Sendable {
        var r, g, b: Double
        init(_ r: Double, _ g: Double, _ b: Double) { (self.r, self.g, self.b) = (r, g, b) }
        init(_ color: Color, in environment: EnvironmentValues) {
            let resolved = color.resolve(in: environment)
            self.init(Double(resolved.red) * 255, Double(resolved.green) * 255, Double(resolved.blue) * 255)
        }
        func mix(_ other: RGB, _ t: Double) -> RGB { RGB(r + (other.r - r) * t, g + (other.g - g) * t, b + (other.b - b) * t) }
        func color(_ opacity: Double) -> PenColor { PenColor(red: r / 255, green: g / 255, blue: b / 255, alpha: opacity) }
    }
    fileprivate struct Point { var x, y, depth, w: Double }

    private static let edges: [(Int, Int)] = (0..<16).flatMap { i in
        (i + 1..<16).filter { j in (i ^ j).nonzeroBitCount == 1 }.map { (i, $0) }
    }
    /// The listening form: two counter-rotating hexagons, and the inner square's vertices sinking to the centre.
    private static let rings = [[0, 1, 5, 4, 12, 8], [9, 11, 10, 14, 15, 13], [2, 3, 7, 6]]
    private static let slots: [(ring: Int, k: Int, n: Int)] = (0..<16).map { vertex in
        let ring = rings.firstIndex { $0.contains(vertex) }!
        return (ring, rings[ring].firstIndex(of: vertex)!, rings[ring].count)
    }
    private static let ringEdge = edges.map { p, q in
        let a = slots[p], b = slots[q]
        return a.ring == b.ring && a.ring < 2 && ((a.k + 1) % a.n == b.k || (b.k + 1) % b.n == a.k)
    }

    fileprivate struct Primitives {
        var edgeAlpha = [Double](repeating: 0, count: 32), edgeMix = [Double](repeating: 0, count: 32)
        var edgeCore = [Double](repeating: 0, count: 32), edgeSkip = [Bool](repeating: true, count: 32)
        var dotAlpha = [Double](repeating: 0, count: 16), dotMix = [Double](repeating: 0, count: 16)
        var dotR = [Double](repeating: 0, count: 16), dotCore = [Double](repeating: 0, count: 16)
    }

    /// The drawing owns these reusable inputs and buffers; theme resolution happens only on a theme change.
    final class Cache {
        fileprivate var points = [Point](repeating: Point(x: 0, y: 0, depth: 1, w: 0), count: 16)
        fileprivate var prims = Primitives()
        fileprivate var sky = [CharacterSky.Placed](repeating: .init(point: .zero), count: 16)
        fileprivate var colors: Palette?
        func palette(_ environment: EnvironmentValues) -> Palette {
            if colors?.scheme != environment.colorScheme { colors = Palette(environment) }
            return colors!
        }
    }
    /// Resolved once per theme on the main thread, so a render thread draws with plain values.
    struct Palette: Sendable {
        let scheme: ColorScheme
        let acc, dim, hot, bg: RGB
        let boost, haloBoost: Double
        /// The scene's selection outline and the open summary's corner brackets.
        let accent, muted: PenColor
        init(_ environment: EnvironmentValues) {
            scheme = environment.colorScheme
            acc = RGB(PhoneTheme.wire, in: environment); dim = RGB(PhoneTheme.wireDim, in: environment)
            hot = RGB(PhoneTheme.wireHot, in: environment); bg = RGB(PhoneTheme.background, in: environment)
            boost = PhoneTheme.wireBoost(scheme); haloBoost = PhoneTheme.haloBoost(scheme)
            accent = PenColor(PhoneTheme.accent, in: environment); muted = PenColor(PhoneTheme.muted, in: environment)
        }
        init(_ scheme: ColorScheme) {
            var environment = EnvironmentValues()
            environment.colorScheme = scheme
            self.init(environment)
        }
    }

    /// A SwiftUI Canvas draws through the same pen as the render thread, so the two never drift.
    static func draw(_ p: CharacterPose, in context: inout GraphicsContext, size: CGSize, cache: Cache = Cache()) {
        let palette = cache.palette(context.environment)
        #if DEBUG
        let source = context.environment.characterEvidenceSource
        #else
        let source = ""
        #endif
        context.withCGContext { cg in
            var pen = ScenePen(cg)
            draw(p, in: &pen, size: size, cache: cache, palette: palette, source: source)
        }
    }

    /// `source` names the drawing for the DEBUG frame sample (`characterEvidenceSource`).
    static func draw(_ p: CharacterPose, in context: inout ScenePen, size: CGSize, cache: Cache, palette colors: Palette, source: String) {
        #if DEBUG
        let frameStarted = ProcessInfo.processInfo.systemUptime
        defer { CharacterFrameMetrics.shared.record(start: frameStarted, source: source, mode: p.mode.rawValue, heat: p.heat, rotation: p.a) }
        #endif
        let s = min(size.width, size.height), c = s / 2
        context.translateBy(x: (size.width - s) / 2, y: (size.height - s) / 2)
        let acc = colors.acc, dim = colors.dim, hot = colors.hot, bg = colors.bg
        let boost = colors.boost, haloBoost = colors.haloBoost
        let cur = p.cur, heat = p.heat, now = p.milliseconds, et = p.progress
        let bright = acc.mix(hot, heat), dimUse = dim.mix(RGB(hot.r * 0.55, hot.g * 0.5, hot.b * 0.45), heat)
        let breathe = 1 + cur.breath * sin(now / 650)
        let warp = CharacterWarp.pose(of: p)
        let R0 = s * 0.27 * breathe * cur.scale * (warp?.scale ?? 1)
        // The cinch draws the body tight, and it springs back past its size.
        let cinchK = p.cinchK, cinchKz = clamp01(cinchK), cinchLift = (p.cinch?.lift ?? 0) * p.cinchGate
        let cinchBody = CharacterCinch.body(cinchK)
        let cinchFlight = p.cinch.map { p.still ? (motes: [], arrival: 0) : CharacterCinch.motes($0) } ?? (motes: [], arrival: 0)
        let R = R0 * cinchBody.scale

        // Every body transform feeds the same projected points for the combined glow and crisp pass.
        let reply = CharacterReply.frame(p.mode, et)
        var rotation = reply.rot, ty = reply.ty * s, sx = reply.sx, sy = reply.sy
        let pitch = reply.pitch, replyGlow = reply.glow
        var spin = reply.spin
        if p.mode == .greet {
            let bow = sin(min(1, et / 0.55) * .pi) * 0.14
            rotation = bow * 0.5; ty = bow * s * 0.12
        } else if p.mode == .ponder { rotation = -0.1 * sin(min(1, et * 1.4) * .pi) }
        else if p.mode == .confused {
            rotation = sin(et * .pi * 3) * 0.08 * sin(et * .pi)
            spin += sin(et * .pi * 5) * 0.9 * sin(et * .pi) * 0.2
        } else if p.mode == .fidget {
            if p.variant == .roll { spin += easeInOut(clamp01((et - 0.08) / 0.75)) * .pi }
            if p.variant == .yawn { let y = pulse(et, 0.12, 0.62); sy = 1 + 0.16 * y; sx = 1 - 0.09 * y }
            // The corkscrew leans into the wormhole and stretches with the speed.
            if let warp { rotation = warp.rot; sx = warp.sx; sy = warp.sy }
        }
        context.opacity *= CharacterSky.dim(p)
        let poseCos = cos(rotation), poseSin = sin(rotation)
        func posed(_ x: Double, _ y: Double) -> (x: Double, y: Double) {
            let dx = (x - c) * sx, dy = (y - c) * sy
            return (c + dx * poseCos - dy * poseSin, c + ty + dx * poseSin + dy * poseCos)
        }

        // The ambient glow, breathing while listening.
        let glowA = haloBoost * cur.glow * (warp?.glow ?? 1) * (0.1 + heat * 0.16 + cur.breath * 0.6 * (0.5 + 0.5 * sin(now / 650))) + replyGlow * 0.18
            + cinchKz * 0.08 * (0.4 + 0.6 * cinchFlight.arrival) + cinchLift * 0.3
        context.fill(Path(CGRect(x: 0, y: 0, width: s, height: s)), with: .radialGradient(
            PenGradient(colors: [bright.color(glowA), bright.color(0)]), center: CGPoint(x: c, y: c), startRadius: 0, endRadius: s / 2))

        // Rotate xw and yz, then project 4D to 3D to 2D.
        let ca = cos(p.a + spin), sa = sin(p.a + spin), cb = cos(p.b + pitch), sb = sin(p.b + pitch)
        for i in 0..<16 {
            let x: Double = i & 1 != 0 ? 1 : -1, y: Double = i & 2 != 0 ? 1 : -1
            let z: Double = i & 4 != 0 ? 1 : -1, w: Double = i & 8 != 0 ? 1 : -1
            let x1 = x * ca - w * sa, w1 = x * sa + w * ca, y1 = y * cb - z * sb, z1 = y * sb + z * cb
            let k4 = 2.6 / (2.6 - w1 * 0.55), k3 = 3.4 / (3.4 - z1 * k4 * 0.5)
            cache.points[i] = Point(x: c + x1 * k4 * k3 * R * 0.5, y: c + y1 * k4 * k3 * R * 0.5, depth: (k4 + k3) / 2, w: w1)
        }
        let f = cur.flat * cur.flat * (3 - 2 * cur.flat)
        if f > 0.001 {
            let rf = s * 0.4 * breathe
            for i in 0..<16 {
                let slot = slots[i]
                if slot.ring == 2 {
                    cache.points[i].x += (c - cache.points[i].x) * f; cache.points[i].y += (c - cache.points[i].y) * f
                    continue
                }
                let angle = (slot.ring == 0 ? 1 : -1) * p.hs + Double(slot.k) / Double(slot.n) * 2 * .pi - .pi / 2
                let radius = (slot.ring == 0 ? 1 : 0.62) * rf
                cache.points[i].x += (c + cos(angle) * radius - cache.points[i].x) * f
                cache.points[i].y += (c + sin(angle) * radius - cache.points[i].y) * f
            }
        }
        for i in 0..<16 {
            let jitter = cur.jitter * sin(et * .pi) * 0.09 * R
            cache.points[i].x += CharacterSky.twinkle(now / 1000 * 14 + Double(i) * 3.1) * jitter
            cache.points[i].y += CharacterSky.twinkle(now / 1000 * 13 + Double(i) * 5.7) * jitter
            if let warp, warp.jitter > 0.0005 {
                // The tunnel's tremble at warp speed.
                cache.points[i].x += CharacterSky.twinkle(now / 1000 * 14 + Double(i) * 3.1) * warp.jitter * R
                cache.points[i].y += CharacterSky.twinkle(now / 1000 * 13 + Double(i) * 5.7) * warp.jitter * R
            }
            var placed = CharacterSky.place(i, base: CGPoint(x: cache.points[i].x, y: cache.points[i].y), pose: p, c: c, r: R)
            // The sphere warp: the vertices take their places on the wormhole's rim.
            if warp != nil, p.variant == .sphere,
               let rim = CharacterWarp.sphereVertex(i, base: placed.point, et: et, c: c, r: R, time: now / 1000) {
                placed.point = rim.point; placed.progress = rim.progress
            }
            cache.sky[i] = placed
            (cache.points[i].x, cache.points[i].y) = posed(placed.point.x, placed.point.y)
            if let w = placed.w { cache.points[i].w += (w - cache.points[i].w) * placed.progress }
        }


        // Resolve every edge and dot once; the halo and the crisp pass both replay them.
        let neon = heat
        for (i, (p0, q0)) in edges.enumerated() {
            cache.prims.edgeSkip[i] = true
            let P = cache.points[p0], Q = cache.points[q0]
            let depth = (P.depth + Q.depth) / 2 - 0.9
            var alpha = max(0.3, min(0.9, 0.35 + depth * 0.5)) * boost
            if cur.shimmer > 0 { alpha *= 1 - cur.shimmer * 0.3 * (0.5 + 0.5 * sin(now / 240 + Double(i) * 2.7)) }
            if !ringEdge[i] {
                alpha *= 1 - f
            } else {
                alpha += (min(1, 0.85 * boost) - alpha) * f
            }
            alpha *= 1 - min(cache.sky[p0].progress, cache.sky[q0].progress) * 0.97
            // The cinch dims the outer cell and lifts every wire at its end.
            if P.w > 0 && Q.w > 0 { alpha *= cinchBody.outer }
            alpha *= 1 + 0.5 * cinchLift
            if alpha < 0.02 { continue }
            let m = max(clamp01(0.5 + (P.w + Q.w) * 0.35), f * 0.9)
            cache.prims.edgeSkip[i] = false
            cache.prims.edgeMix[i] = m
            cache.prims.edgeAlpha[i] = min(1, alpha * (0.85 + 0.15 * m) * (1 + 0.9 * p.flicker * CharacterFlicker.wire(i, now)))
            cache.prims.edgeCore[i] = max(neon > 0.02 && m > 0.5 ? min(1, alpha) * neon * 0.85 : 0, min(1, p.flicker * CharacterFlicker.wire(i, now) * 0.7))
        }
        for i in 0..<16 {
            let P = cache.points[i]
            let fade = (slots[i].ring == 2 ? 1 - f : 1) * cache.sky[i].fade
            let pulseK = 1 + cur.pulse * 0.6 * max(0, sin(now / 300 + Double(i) * 0.8))
            let m = max(clamp01(0.5 + P.w * 0.6), f)
            cache.prims.dotMix[i] = m
            cache.prims.dotR[i] = (2.1 + 0.7 * m) * pulseK * (s / 280) * cache.sky[i].scale
            cache.prims.dotAlpha[i] = min(1, max(0.65, min(1, 0.6 + (P.depth - 0.9) * 0.5)) * boost) * fade * (1 + 0.4 * cinchLift)
            cache.prims.dotCore[i] = max(heat > 0.02 && m > 0.4 && fade > 0.5 ? heat * fade : 0, cache.sky[i].white)
        }

        // The cinch's centre and ring, under the wires.
        if let frame = p.cinch {
            CharacterCinch.drawUnder(frame, k: cinchK, gate: p.cinchGate, arrival: cinchFlight.arrival, still: p.still, c: c, r0: R0, size: s,
                                     dim: dimUse, bright: bright, boost: boost, in: &context)
        }
        // The halo: every hot primitive in one tint, accumulated, blurred once and laid under the wires.
        let halo = min(1.6, neon * haloBoost)
        if halo > 0.02 {
            let tint = hot.mix(RGB(255, 236, 200), 0.3)
            context.blurredLayer(bounds: CGRect(x: 0, y: 0, width: s, height: s), radius: 7 * halo * (s / 280), opacity: min(1, 0.9 * halo)) { mask in
                mask.blendMode = .plusLighter
                paint(cache.prims, cache.points, in: &mask) { _, _ in tint }
            }
        }
        // The sphere warp's wormhole, under the wires that ring it.
        if warp != nil, p.variant == .sphere {
            CharacterWarp.drawSphere(et, c: c, r: R, time: now / 1000, bright: bright, background: bg, boost: boost, in: &context)
        }
        CharacterSky.draw(p, over: false, context: &context, c: c, r: R, color: bright.color(1), background: bg.color(1))
        paint(cache.prims, cache.points, in: &context) { kind, mix in
            switch kind {
            case .edge: dimUse.mix(bright, mix)
            case .edgeCore: bright.mix(RGB(255, 244, 224), 0.75)
            case .dot: dimUse.mix(bright, max(mix, 0.35))
            case .dotCore: bright.mix(RGB(255, 248, 235), 0.8)
            }
        }

        CharacterSky.draw(p, over: true, context: &context, c: c, r: R, color: bright.color(1), background: bg.color(1))
        // The cinch's motes streaming in to the centre, under the eyes.
        if let frame = p.cinch, !cinchFlight.motes.isEmpty {
            let corners = cache.points.filter { $0.w > 0 }.map { CGPoint(x: $0.x, y: $0.y) }
            CharacterCinch.drawOver(frame, motes: cinchFlight.motes, k: cinchK, gate: p.cinchGate, c: c, r0: R0, size: s,
                                    corners: corners.isEmpty ? cache.points.map { CGPoint(x: $0.x, y: $0.y) } : corners, bright: bright, in: &context)
        }

        // The eyes: two soft lights in the inner cell, with white-hot cores, on the wires' colour family.
        let eyeBase = acc.mix(hot, heat), eyeCol = eyeBase.mix(RGB(255, 246, 230), 0.45)
        let gxo = p.eyeX * R * 0.1, gyo = p.eyeY * R * 0.08
        let pxo = sin(p.a) * R * 0.05 * (1 - f), pyo = sin(p.b * 0.8) * R * 0.04 * (1 - f)
        let eyes = [-1.0, 1.0].map { side -> (Double, CharacterSky.Eye) in
            let base = posed(c + side * R * 0.34 + gxo + pxo, c - R * 0.1 + gyo + pyo)
            return (side, CharacterSky.eye(side, base: CGPoint(x: base.x, y: base.y), pose: p, c: c, r: R))
        }.sorted { $0.1.z < $1.1.z }
        let bodyOpacity = context.opacity
        for (side, eye) in eyes {
            let e = eye.point
            context.opacity = bodyOpacity * eye.alpha
            let lid = max(p.lid, side == 1 ? p.wink : 0)
            let open = (1 - lid) * cur.eyeScale
            let rw = R * 0.085 * cur.eyeScale * eye.depth
            let socket = rw * 3.2
            context.fill(circle(e.x, e.y, socket), with: .radialGradient(PenGradient(colors: [bg.color(0.75), bg.color(0)]),
                center: CGPoint(x: e.x, y: e.y), startRadius: 0, endRadius: socket))
            if p.happy > 0.5 {
                var arc = Path()
                for k in 0...16 {
                    let angle = Double.pi * (1.15 + 0.7 * Double(k) / 16)
                    let point = CGPoint(x: e.x + cos(angle) * rw * 1.15, y: e.y + rw * 0.7 + sin(angle) * rw * 1.15)
                    if k == 0 { arc.move(to: point) } else { arc.addLine(to: point) }
                }
                context.stroke(arc, with: .color(eyeCol.color(0.95)), style: StrokeStyle(lineWidth: max(1.4, rw * 0.5), lineCap: .round, lineJoin: .round))
            } else if open < 0.12 {
                var line = Path()
                line.move(to: CGPoint(x: e.x - rw, y: e.y)); line.addLine(to: CGPoint(x: e.x + rw, y: e.y))
                context.stroke(line, with: .color(eyeCol.color(0.8)), style: StrokeStyle(lineWidth: max(1.2, rw * 0.4), lineCap: .round))
            } else {
                let rh = rw * 1.35 * max(0.1, open), glowR = rw * 2.1
                context.fill(circle(e.x, e.y, glowR), with: .radialGradient(
                    PenGradient(stops: [.init(color: eyeCol.color(0.95), location: 0), .init(color: eyeBase.color(0.5), location: 0.45),
                                     .init(color: eyeBase.color(0), location: 1)]),
                    center: CGPoint(x: e.x, y: e.y), startRadius: 0, endRadius: glowR))
                // The core leads the light along the gaze by half its offset, the Mac's resting pupil shift.
                let core = CGRect(x: e.x + gxo * 0.5 - rw * 0.62, y: e.y + gyo * 0.5 - rh * 0.62, width: rw * 1.24, height: rh * 1.24)
                context.fill(Path(ellipseIn: core), with: .color(RGB(255, 248, 235).color(0.95)))
            }
        }
        context.opacity = bodyOpacity
        CharacterGarnish.draw(p, in: &context, c: c, r: R, size: s, color: bright.color(1), eyes: eyes.map { $0.1.point }) { x, y in
            let at = posed(x, y); return CGPoint(x: at.x, y: at.y)
        }
    }

    private enum Kind { case edge, edgeCore, dot, dotCore }

    private static func circle(_ x: Double, _ y: Double, _ r: Double) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }

    /// Replays the resolved edges, their filament cores, the dots and their incandescent cores.
    private static func paint(_ prims: Primitives, _ points: [Point], in context: inout ScenePen,
                              color: (Kind, Double) -> RGB) {
        let wire = StrokeStyle(lineWidth: 1.4, lineCap: .round), filament = StrokeStyle(lineWidth: 0.7, lineCap: .round)
        for (i, (p, q)) in edges.enumerated() where !prims.edgeSkip[i] {
            var line = Path()
            line.move(to: CGPoint(x: points[p].x, y: points[p].y)); line.addLine(to: CGPoint(x: points[q].x, y: points[q].y))
            context.stroke(line, with: .color(color(.edge, prims.edgeMix[i]).color(prims.edgeAlpha[i])), style: wire)
            if prims.edgeCore[i] > 0 {
                context.stroke(line, with: .color(color(.edgeCore, 0).color(prims.edgeCore[i])), style: filament)
            }
        }
        for i in 0..<16 where prims.dotAlpha[i] > 0.01 {
            let P = points[i], r = prims.dotR[i]
            context.fill(circle(P.x, P.y, r), with: .color(color(.dot, prims.dotMix[i]).color(prims.dotAlpha[i])))
            if prims.dotCore[i] > 0 {
                context.fill(circle(P.x, P.y, r * 0.45), with: .color(color(.dotCore, 0).color(prims.dotCore[i])))
            }
        }
    }
}
