import CryptoKit
import InfinitaryKit
import Observation
import SwiftUI
@preconcurrency import WebKit

/// A separate, nonpersistent web process holds only its own card: the shown one or one beside it in the row. No account or
/// Mac URL enters it.
@MainActor @Observable final class CardWebHost: NSObject, WKScriptMessageHandlerWithReply, WKNavigationDelegate, WKUIDelegate {
    var height: CGFloat = 48
    var drawn = false
    var busy = false
    var chosen = false
    var changing: Bool { busy || chosen }
    var failure: String?
    var reading: PhoneJSON = .object(["answers": .array([])])
    var presentation: PhoneJSON?
    var notice: String?
    /// A field in the body holds the keyboard.
    var typing = false
    private(set) var card: PhoneCard
    private let session: ReadOnlySession
    private var view: WKWebView?
    private var assets: CardAssets?
    private var watchdog: Task<Void, Never>?
    private var collection: (id: UUID, continuation: CheckedContinuation<PhoneJSON, Error>)?
    private var collectionTimeout: Task<Void, Never>?
    private var watch = CardWatchdog()
    private var theme = "light"
    private(set) var revealed = false
    /// INF-3110: the card sits beside the shown one in the row, so its body is one closed element with no name, which
    /// no search reaches; WebKit ignores the hidden-children flag, so this is the only way to keep its page out.
    var aside = false { didSet { if aside != oldValue { applyReach() } } }
    /// The height the page last reported its body drew at; `height` is the frame native code asks the view for.
    private var bodyHeight: CGFloat = 48
    private let fill: PhoneJSON
    private let heightLag: TimeInterval
    /// INF-1524: a settle card draws its fact strip in a second, read-only host pinned above its choices, as the Mac does.
    enum Part { case body, facts }
    private let part: Part
    private let keys: [String]
    /// The body's own fact strip, once the page has split it off; nil when the card takes none.
    var facts: String?
    /// The body is a playable preview, so the count of its answers reads as settings.
    var preview = false
    var onReading: ((PhoneJSON) -> Void)?
    var onDrawn: (() -> Void)?
    var onLink: ((URL) -> Void)?
    var onDraft: ((String) -> Void)?
    var onTask: ((String) -> Void)?

    init(card: PhoneCard, session: ReadOnlySession, fill: PhoneJSON, part: Part = .body, keys: [String] = [],
         heightLag: TimeInterval = 0) {
        self.card = card; self.session = session; self.fill = fill; self.part = part; self.keys = keys
        self.heightLag = heightLag
    }

    /// INF-1574: the isolated phone gate's stand-in for a loaded computer, where a retried body's drawn height reaches
    /// its native frame this many seconds after the page reports it.
    static var retriedHeightLag: TimeInterval {
        #if targetEnvironment(simulator)
        let environment = ProcessInfo.processInfo.environment
        guard environment["INFINITARY_ISOLATED_PHONE_TEST"] == "1" else { return 0 }
        return TimeInterval(environment["INFINITARY_TEST_RETRIED_CARD_LAG"] ?? "") ?? 0
        #else
        0
        #endif
    }

    func makeView(theme: String) -> WKWebView {
        self.theme = theme
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        configuration.allowsInlineMediaPlayback = true
        let assets = CardAssets(session: session)
        self.assets = assets
        configuration.setURLSchemeHandler(assets, forURLScheme: "app-frame")
        configuration.userContentController.addScriptMessageHandler(self, contentWorld: .page, name: "cardHost")
        // INF-3110: the body's own sideways controls, read in a world of their own, which the row's swipe leaves alone.
        configuration.userContentController.addUserScript(CardClaims.script)
        configuration.userContentController.add(CardClaimsReader(), contentWorld: CardClaims.world, name: CardClaims.handler)
        let view = CardBodyView(frame: .zero, configuration: configuration)
        view.onLayout = { [weak self] in self?.revealIfShown() }
        view.onTyping = { [weak self] typing in self?.typing = typing }
        view.allowsLinkPreview = false
        view.navigationDelegate = self; view.uiDelegate = self
        view.isOpaque = false; view.backgroundColor = .clear; view.scrollView.backgroundColor = .clear
        // INF-944 items 1 and 2: the card's native scroller is the only one. The web view is always as tall as its
        // body, takes no safe-area insets of its own and cannot be zoomed, so it never scrolls inside the card.
        view.scrollView.isScrollEnabled = false
        view.scrollView.bounces = false
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.scrollView.minimumZoomScale = 1; view.scrollView.maximumZoomScale = 1
        view.scrollView.pinchGestureRecognizer?.isEnabled = false
        view.accessibilityIdentifier = part == .facts ? "card-facts" : "card-body"
        // INF-1263 / INF-1651: until the reveal, the body is one closed accessibility element that takes no taps.
        // WebKit ignores the hidden-children flag, and hiding the frame inside the page sticks on iOS 27.0.
        view.isAccessibilityElement = true; view.isUserInteractionEnabled = false
        self.view = view
        applyReach()
        // Agent HTML is assigned to an opaque iframe's srcdoc, never interpolated into this parent.
        // Its own hash policy narrows this parent's inline permission. Neither realm can use the network.
        view.onWindow = { [weak self] in self?.loadOnWindow() }
        page = """
        <!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline' app-frame://runtime; style-src 'unsafe-inline'; frame-src about:; img-src data: app-frame:; font-src app-frame:; base-uri 'none'; form-action 'none'">
        <style>html,body{margin:0;padding:0;background:transparent}iframe{width:100%;border:0}</style>
        <script src="app-frame://runtime/CardHost.generated.js"></script></head><body></body></html>
        """
        loadOnWindow()
        watch = CardWatchdog()
        watchdog = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled, let self else { return }
                // INF-804: only a shown card can stall. WebKit pauses a card behind another tab or in the background,
                // and a page still loading is WebKit starting the card's own process, which a busy device can take a while to do.
                let page = self.view
                let shown = UIApplication.shared.applicationState == .active && page?.window != nil && page?.isLoading == false
                switch self.watch.look(shown: shown) {
                case .wait: continue
                case .stalled: self.fail(); return
                case .ping(let seq):
                    page?.evaluateJavaScript("window.phoneCard?.ping(\(seq))") { [weak self] _, _ in self?.watch.pageAnswered(seq) }
                }
            }
        }
        return view
    }

    /// The card's page, kept until its view reaches a window.
    private var page: String?
    /// A body built behind another tab loads only once it is on the screen. WebKit suspends a hidden view's process, and a
    /// page that began loading there drew about half a minute after its tab showed again, its choices unusable until then.
    private func loadOnWindow() {
        guard let view, view.window != nil, let page else { return }
        self.page = nil
        view.loadHTMLString(page, baseURL: nil)
    }

    func close() {
        watchdog?.cancel(); watchdog = nil
        if let id = collection?.id { finishCollection(id, .failure(PhoneRequestError("This card did not answer. Your choice was not sent."))) }
        onReading = nil; onDrawn = nil; onLink = nil; onDraft = nil; onTask = nil
        view?.configuration.userContentController.removeScriptMessageHandler(forName: "cardHost", contentWorld: .page)
        view?.configuration.userContentController.removeScriptMessageHandler(forName: CardClaims.handler, contentWorld: CardClaims.world)
        assets?.cancel(); assets = nil
        view?.stopLoading(); view?.navigationDelegate = nil; view?.uiDelegate = nil; view = nil
    }
    private func fail() { failure = "This card stopped responding."; close() }

    func updateTheme(_ theme: String) {
        guard theme != self.theme else { return }
        self.theme = theme
        view?.evaluateJavaScript("window.phoneCard?.theme('\(theme == "dark" ? "dark" : "light")')", completionHandler: nil)
    }

    /// INF-1263 / INF-1574: the body takes taps and reaches accessibility, and the footer enables, only once
    /// the view's own layout holds the drawn height, so nothing is offered where the 48-point placeholder clipped it.
    /// A SwiftUI update that reads `drawn` runs before that layout, so it cannot be the signal. The reveal waits one
    /// main-queue turn, so no view update or layout pass changes what the footer reads.
    func revealIfShown() {
        guard isShown else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isShown else { return }
            self.revealed = true
            self.view?.isUserInteractionEnabled = true
            self.applyReach()
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }
    }
    private func applyReach() {
        guard let view else { return }
        view.accessibilityIdentifier = aside ? nil : part == .facts ? "card-facts" : "card-body"
        view.isAccessibilityElement = aside || !revealed
    }
    private var isShown: Bool {
        guard drawn, !revealed, let view else { return false }
        return abs(view.bounds.height - bodyHeight) < 0.5
    }

    func beginChange() -> Bool {
        guard !changing, session.canChange else { return false }
        busy = true
        return true
    }

    /// A failed body may use its last observed draft, never label it as a fresh reading.
    /// A timeout during this press still refuses it; only a later deliberate press takes this fallback.
    func submissionReading() async throws -> (value: PhoneJSON, fresh: Bool) {
        if failure != nil, reading["of"].numeric != nil { return (reading, false) }
        return (try await collect(), true)
    }

    func collect() async throws -> PhoneJSON {
        guard drawn, let view, failure == nil, collection == nil else { throw PhoneRequestError("This card is not ready. Your choice was not sent.") }
        return try await withCheckedThrowingContinuation { continuation in
            let id = UUID()
            collection = (id, continuation)
            // The JavaScript timeout cannot run if the web process is stalled. Native chrome must still recover.
            collectionTimeout = Task { [weak self] in
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }
                self?.finishCollection(id, .failure(PhoneRequestError("This card did not answer. Your choice was not sent.")))
            }
            view.callAsyncJavaScript("return await window.phoneCard.collect()", arguments: [:], in: nil, in: .page) { [weak self] result in
                do { self?.finishCollection(id, .success(try PhoneJSON.read(result.get()))) }
                catch { self?.finishCollection(id, .failure(PhoneRequestError("This card did not answer. Your choice was not sent."))) }
            }
        }
    }
    private func finishCollection(_ id: UUID, _ result: Result<PhoneJSON, Error>) {
        guard let pending = collection, pending.id == id else { return }
        collection = nil; collectionTimeout?.cancel(); collectionTimeout = nil
        pending.continuation.resume(with: result)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let effectIDs = Set(card.actions.filter { $0["effect"] != .null }.compactMap { $0["id"].text })
        let actions = card.actions.compactMap { action -> PhoneJSON? in
            guard let id = action["id"].text, !effectIDs.contains(id) else { return nil }; return .string(id)
        }
        var input: PhoneJSON = .object(["body": .string(card.body), "theme": .string(theme), "readOnly": .bool(card.isPast || part == .facts),
            "fill": fill, "actions": .array(part == .facts ? [] : actions), "width": card.value["width"] == .null ? .string("wide") : card.value["width"],
            "keys": .array(keys.map(PhoneJSON.string))])
        if part == .body, case .object(var fields) = input {
            var facts: [String: PhoneJSON] = ["actions": .array(card.actions)]
            for key in ["reviewTaskId", "risk"] where card.value[key] != .null { facts[key] = card.value[key] }
            fields["card"] = .object(facts)
            fields["marks"] = card.value["changes"]["marks"] == .null ? .array([]) : card.value["changes"]["marks"]
            input = .object(fields)
        }
        do {
            webView.callAsyncJavaScript("await window.phoneCard.mount(input)", arguments: ["input": try input.foundation], in: nil, in: .page) { [weak self] result in
                if case .failure = result { self?.fail() }
            }
        } catch { fail() }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage,
                               replyHandler: @escaping @MainActor (Any?, String?) -> Void) {
        // The opaque child can see WebKit's handler too. It may NEVER call the native host directly.
        guard message.frameInfo.isMainFrame, message.webView === view,
              let payload = try? PhoneJSON.read(message.body), let type = payload["type"].text else {
            replyHandler(nil, "This frame has no native access."); return
        }
        switch type {
        case "hash":
            let scripts = payload["scripts"].list.compactMap(\.text)
            guard scripts.reduce(0, { $0 + $1.utf8.count }) <= 262_144 else { replyHandler(nil, "The card is too large."); return }
            replyHandler(scripts.map { "sha256-" + Data(SHA256.hash(data: Data($0.utf8))).base64EncodedString() }, nil)
        case "answers":
            reading = payload["reading"]; onReading?(reading); replyHandler(true, nil)
            // A field that grows as it types, such as a text area, keeps its caret in view.
            (view as? CardBodyView)?.queueReveal()
        case "drawn":
            let drawnHeight = max(48, min(100_000, payload["height"].numeric ?? 48))
            bodyHeight = drawnHeight
            if heightLag > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + heightLag) { [weak self] in self?.height = drawnHeight }
            } else { height = drawnHeight }
            if !drawn { drawn = true; onDrawn?() }
            revealIfShown()
            replyHandler(true, nil)
        case "ready": watch.bodyReady(); replyHandler(true, nil)
        case "pong": watch.bodyAnswered(Int(payload["seq"].numeric ?? 0)); replyHandler(true, nil)
        case "mac-only": notice = "Do this on \(session.mac.name)."; replyHandler(true, nil)
        case "mounted":
            watch.pageMounted()
            if part == .body { facts = payload["facts"].text; preview = payload["preview"] == .bool(true) }
            replyHandler(true, nil)
        case "link":
            // The page checked the address against the Mac's own rule; this checks the scheme once more before it leaves.
            guard let url = URL(string: payload["href"].text ?? ""), ["https", "http"].contains(url.scheme?.lowercased() ?? "") else {
                replyHandler(nil, "This link cannot open."); return
            }
            onLink?(url); replyHandler(true, nil)
        case "draft":
            guard let text = payload["text"].text, !text.isEmpty else { replyHandler(nil, "This card cannot do that."); return }
            onDraft?(text); replyHandler(true, nil)
        case "task":
            guard let key = payload["key"].text, keys.contains(key) else { replyHandler(nil, "This card cannot do that."); return }
            onTask?(key); replyHandler(true, nil)
        case "image", "demo": presentation = payload; replyHandler(true, nil)
        case "action":
            guard !card.isPast, let id = payload["id"].text,
                  card.actions.contains(where: { $0["id"].text == id }),
                  !card.actions.contains(where: { $0["id"].text == id && $0["effect"] != .null }) else {
                replyHandler(nil, "Only the card’s own footer can do that."); return
            }
            guard beginChange() else {
                let words = session.changeRefusal ?? "This card already has a choice in progress."
                notice = words; replyHandler(nil, words); return
            }
            Task {
                defer { busy = false }
                do {
                    // INF-2553: a body choice leaves the stage at the tap, as a footer choice does.
                    let result = try await session.change(.choose(card: card.id, lifecycle: card.lifecycleID, offer: card.offerID), .act,
                        [.string(card.id), .string(id), .string("frame"), payload["value"], card.submission()])
                    chosen = true
                    replyHandler(try result.foundation, nil)
                } catch {
                    // The session's own notice says why a change was taken back; the page still hears the refusal.
                    replyHandler(nil, error.localizedDescription)
                }
            }
        default: replyHandler(nil, "This card cannot do that.")
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString ?? ""
        // Only the initial parent and its one srcdoc child. Even a meta refresh cannot leave the page.
        decisionHandler((url == "about:blank" || url == "about:srcdoc") && navigationAction.navigationType == .other ? .allow : .cancel)
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { fail() }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? { nil }
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping @MainActor @Sendable (WKPermissionDecision) -> Void) { decisionHandler(.deny) }
}

/// The card body's own layout is when its drawn height becomes the geometry taps and accessibility use.
final class CardBodyView: WKWebView {
    var onLayout: (() -> Void)?
    override func layoutSubviews() { super.layoutSubviews(); onLayout?() }
    var onWindow: (() -> Void)?
    override func didMoveToWindow() {
        super.didMoveToWindow()
        watchTyping(window != nil)
        onWindow?()
    }
    /// INF-3427, the captain: "when i tap on a textbox inside of a card body, the keyboard pops up, and the textbox would
    /// no longer be in the viewport.. it gets scrolled away. so i can't see what i type". WebKit reveals a focused field by
    /// moving the page inside the web view's own scroll view, which never scrolls (INF-944), so the page slid away from
    /// where the card's scroller draws it; and nothing moved the card's scroller to the field. The web view's page now
    /// stays at its top, and the card's scroller brings the caret's line, with room around it, into the room it shows.
    private var offsetWatch: NSKeyValueObservation?
    private var keyboardWatch: [NSObjectProtocol] = []
    private var revealQueued = false
    private func watchTyping(_ on: Bool) {
        keyboardWatch.forEach(NotificationCenter.default.removeObserver)
        keyboardWatch = []
        guard on else { readTyping(hides: true); keyboardFrame = nil; return }
        if offsetWatch == nil {
            offsetWatch = scrollView.observe(\.contentOffset) { [weak self] scroll, _ in
                MainActor.assumeIsolated {
                    guard scroll.contentOffset != .zero else { return }
                    // WebKit asked to reveal what takes the keyboard: the card's own scroller does that instead.
                    scroll.contentOffset = .zero
                    self?.queueReveal()
                }
            }
        }
        for name in [UIResponder.keyboardDidShowNotification, UIResponder.keyboardDidChangeFrameNotification] {
            keyboardWatch.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                let end = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
                MainActor.assumeIsolated { self?.keyboardFrame = end; self?.queueReveal() }
            })
        }
        for name in [UIResponder.keyboardWillShowNotification, UIResponder.keyboardWillChangeFrameNotification,
                     UIResponder.keyboardWillHideNotification] {
            let hides = name == UIResponder.keyboardWillHideNotification
            keyboardWatch.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.readTyping(hides: hides) }
            })
        }
    }
    /// Whether a field in the body holds the keyboard, which on a phone on its side asks the message box to step aside
    /// for it, as a card's reply does (INF-2568).
    var onTyping: ((Bool) -> Void)?
    private var typing = false
    private func readTyping(hides: Bool) {
        if hides { keyboardFrame = nil }
        let now = !hides && window != nil && firstResponder(in: self) != nil
        guard now != typing else { return }
        typing = now
        onTyping?(now)
    }
    /// After the layout the keyboard brought, such as the stage shortening and the frame reshaping, has run.
    func queueReveal() {
        guard !revealQueued else { return }
        revealQueued = true
        DispatchQueue.main.async { [weak self] in self?.revealQueued = false; self?.revealTyping() }
    }
    /// Scrolls the card to the caret of the body's field that holds the keyboard; a keyboard raised by anything else,
    /// or a body beside the shown card, leaves it alone.
    /// The keyboard's last frame on the screen, its accessory bar included: on an iPhone, WebKit's own bar with a form's
    /// previous, next and Done stands above the keys, and the card's scroller does not count it as the keyboard's.
    private var keyboardFrame: CGRect?
    private func revealTyping() {
        guard let window, let typing = firstResponder(in: self) as? UITextInput,
              let range = typing.selectedTextRange, let scroller = enclosingScroller() else { return }
        let caret = typing.caretRect(for: range.end)
        guard !caret.isNull, !caret.isInfinite, caret.height > 0 else { return }
        let line = (typing.textInputView ?? self).convert(caret, to: window)
        // The room the scroller shows, in the window: inside its insets, such as the bar's, and above the keyboard.
        let frame = scroller.convert(scroller.bounds, to: window)
        let inset = scroller.adjustedContentInset
        var top = frame.minY + inset.top, foot = frame.maxY - inset.bottom
        if let keyboardFrame {
            let keys = window.convert(keyboardFrame, from: window.screen.coordinateSpace)
            if keys.minY < window.bounds.maxY - 1 { foot = min(foot, keys.minY) }
        }
        top = max(top, window.bounds.minY)
        // The field's own padding and edge lie around its caret's line; where the room is short, the line comes first.
        let margin = min(PhoneTheme.space4, max(0, (foot - top - line.height) / 2))
        var move: CGFloat = 0
        if line.maxY + margin > foot { move = line.maxY + margin - foot }
        if line.minY - margin - move < top { move = line.minY - margin - top }
        guard abs(move) > 0.5 else { return }
        let lowest = max(-inset.top, scroller.contentSize.height + inset.bottom - scroller.bounds.height)
        let y = min(max(scroller.contentOffset.y + move, -inset.top), lowest)
        scroller.setContentOffset(CGPoint(x: scroller.contentOffset.x, y: y), animated: true)
    }
    private func firstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder { return view }
        for child in view.subviews { if let found = firstResponder(in: child) { return found } }
        return nil
    }
    private func enclosingScroller() -> UIScrollView? {
        var parent = superview
        while let view = parent { if let scroller = view as? UIScrollView { return scroller }; parent = view.superview }
        return nil
    }
    /// INF-3110: where the body's own sideways controls sit, in the view's points, as its frame last reported them.
    var claimed: [CGRect] = []
    func claims(_ point: CGPoint) -> Bool { claimed.contains { $0.contains(point) } }
}

struct CardWebView: UIViewRepresentable {
    let host: CardWebHost
    @Environment(\.colorScheme) private var scheme
    func makeUIView(context: Context) -> WKWebView { host.makeView(theme: scheme == .dark ? "dark" : "light") }
    func updateUIView(_ view: WKWebView, context: Context) {
        host.updateTheme(scheme == .dark ? "dark" : "light")
        host.revealIfShown()
    }
    static func dismantleUIView(_ view: WKWebView, coordinator: ()) {
        (view.navigationDelegate as? CardWebHost)?.close()
    }
}

/// INF-804 / INF-1338: whether a shown card's body stopped answering. The host looks every two seconds and pings;
/// three looks in a row that heard nothing since the one before are a stall.
struct CardWatchdog {
    enum Look: Equatable { case wait, ping(Int), stalled }
    private var sent = 0
    private var heard = 0
    private var answered = 0
    private var missed = 0
    private var born = false
    private var running = false

    mutating func look(shown: Bool) -> Look {
        guard shown else { missed = 0; return .wait }
        // INF-2076: a loaded page that has run nothing yet is WebKit still starting it, as a page still loading is. On a
        // busy iPad the page waited 7.9 seconds for WebKit's own GPU process before it ran the card's mount or a ping.
        if running {
            // A stall is a card that answered nothing since the last look; a slow answer is still an answer.
            if heard >= sent || heard > answered { missed = 0 } else { missed += 1 }
            answered = heard
            if missed >= 3 { return .stalled }
        }
        sent += 1
        return .ping(sent)
    }

    /// The page ran the card's mount, which tells the host before it builds the body, so from here a card that stops
    /// answering is the card's own, a body whose script loops as it loads included.
    mutating func pageMounted() { running = true }

    /// Until the body's frame can answer, the card's page answers each ping for it. A body still loading on a busy device
    /// is never counted, and one that wedges as it loads stops its page answering too, since the frame runs on its page's thread.
    mutating func pageAnswered(_ seq: Int) { running = true; if !born { heard = max(heard, seq) } }

    /// The body's bridge is listening. Its first word answers every ping before it; from here only its own pongs count.
    mutating func bodyReady() { running = true; born = true; heard = sent }

    mutating func bodyAnswered(_ seq: Int) { heard = max(heard, seq) }
}

/// A closed file-name namespace, served from the bundle or pinned connection, never a path or URL fetch.
@MainActor final class CardAssets: NSObject, WKURLSchemeHandler {
    private let session: ReadOnlySession
    private var tasks: [ObjectIdentifier: Task<Void, Never>] = [:]
    private var cache: [String: (Data, String)] = [:]
    init(session: ReadOnlySession) { self.session = session }
    func cancel() { for task in tasks.values { task.cancel() }; tasks.removeAll(); cache.removeAll() }
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        tasks.removeValue(forKey: ObjectIdentifier(urlSchemeTask))?.cancel()
    }
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let key = ObjectIdentifier(urlSchemeTask)
        tasks[key] = Task {
            do {
                guard let url = urlSchemeTask.request.url, urlSchemeTask.request.httpMethod == "GET" else { throw PhoneError.invalidReply }
                let (data, type) = try await load(url)
                guard !Task.isCancelled, tasks[key] != nil else { return }
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [
                    "Content-Type": type, "Content-Length": String(data.count), "Access-Control-Allow-Origin": "*", "X-Content-Type-Options": "nosniff",
                ])!
                urlSchemeTask.didReceive(response); urlSchemeTask.didReceive(data); urlSchemeTask.didFinish()
            } catch {
                if !Task.isCancelled, tasks[key] != nil { urlSchemeTask.didFailWithError(error) }
            }
            tasks.removeValue(forKey: key)
        }
    }
    func load(_ url: URL) async throws -> (Data, String) {
        if let cached = cache[url.absoluteString] { return cached }
        guard url.scheme == "app-frame", url.user == nil, url.password == nil, url.port == nil,
              url.query == nil, url.fragment == nil, url.pathComponents.count == 2 else { throw PhoneError.invalidReply }
        let name = url.lastPathComponent
        let result: (Data, String)
        if url.host == "runtime", name == "CardHost.generated.js" {
            guard let file = Bundle.main.url(forResource: "CardHost.generated", withExtension: "js") else { throw PhoneError.invalidReply }
            result = (try Data(contentsOf: file), "text/javascript")
        } else if url.host == "fonts", name.range(of: "^[a-z0-9-]+\\.woff2$", options: .regularExpression) != nil {
            guard let file = Bundle.main.url(forResource: String(name.dropLast(6)), withExtension: "woff2") else { throw PhoneError.invalidReply }
            result = (try Data(contentsOf: file), "font/woff2")
        } else {
            let kind: PhoneCardRequest
            let extensions: String
            switch url.host {
            case "images": kind = .picture; extensions = "png|jpg|webp"
            case "typefaces": kind = .typeface; extensions = "woff2|woff|ttf|otf"
            case "media": kind = .media; extensions = "mp4|gif"
            default: throw PhoneError.invalidReply
            }
            guard name.range(of: "^[A-Za-z0-9_-]{1,64}-[0-9a-f]{32}\\.(\(extensions))$", options: .regularExpression) != nil else { throw PhoneError.invalidReply }
            var bytes = Data()
            var contentType = ""
            if kind == .media {
                var size = 1
                while bytes.count < size {
                    try Task.checkCancellation()
                    let part = try await session.read(.media, [.string(name), .number(Double(bytes.count)), .number(1_048_576)])
                    guard let total = part["size"].numeric, total > 0, total <= 16 * 1024 * 1024,
                          let data = Data(base64Encoded: part["data"].text ?? ""), !data.isEmpty else { throw PhoneError.invalidReply }
                    if bytes.count > 0 && size != Int(total) { throw PhoneError.invalidReply }
                    size = Int(total); bytes.append(data); contentType = part["contentType"].text ?? ""
                    guard bytes.count <= size else { throw PhoneError.invalidReply }
                }
            } else {
                let file = try await session.read(kind, [.string(name)])
                guard let data = Data(base64Encoded: file["data"].text ?? ""), data.count <= 8 * 1024 * 1024 else { throw PhoneError.invalidReply }
                bytes = data; contentType = file["contentType"].text ?? ""
            }
            result = (bytes, contentType)
        }
        if cache.values.reduce(0, { $0 + $1.0.count }) + result.0.count <= 32 * 1024 * 1024 { cache[url.absoluteString] = result }
        return result
    }
}
