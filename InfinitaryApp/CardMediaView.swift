@preconcurrency import AVKit
import InfinitaryKit
import UniformTypeIdentifiers
import SwiftUI
@preconcurrency import WebKit

struct CardMediaView: View {
    let presentation: PhoneJSON
    let session: ReadOnlySession
    @State private var index = 0
    @State private var recording: MemoryCardRecording?
    @State private var gif: String?
    @State private var playGif = false
    @State private var recordingFinished = false
    @State private var playbackFailed = false
    @State private var failure: String?
    @Environment(\.dismiss) private var dismiss
    private var pictures: [PhoneJSON] { presentation["pictures"].list }
    var body: some View {
        NavigationStack {
            VStack {
                if presentation["type"].text == "demo" {
                    if let recording {
                        CardRecordingPlayer(recording: recording, play: presentation["play"].flag)
                            .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime,
                                object: recording.player.currentItem)) { _ in recordingFinished = true }
                            .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime,
                                object: recording.player.currentItem)) { _ in playbackFailed = true }
                        if recordingFinished {
                            Text("Recording finished").font(PhoneFont.caption).accessibilityIdentifier("recording-finished")
                            Button("Play again") {
                                recordingFinished = false
                                Task { await recording.player.seek(to: .zero); recording.player.play() }
                            }
                        }
                        if playbackFailed { Text("This recording could not play.").foregroundStyle(PhoneTheme.warning) }
                    } else if let gif {
                        if playGif { PassiveCardMedia(source: gif, session: session) }
                        else if let poster = presentation["poster"]["src"].text { PassiveCardMedia(source: poster, session: session) }
                        Button(playGif ? "Stop recording" : "Play recording") { playGif.toggle() }
                    } else if let failure {
                        Text(failure).foregroundStyle(PhoneTheme.warning)
                        Button("Retry") { Task { await loadRecording() } }
                    } else { ProgressView("Loading recording") }
                    Text(presentation["caption"].text ?? "").font(PhoneFont.caption)
                } else if pictures.indices.contains(index), let source = pictures[index]["src"].text {
                    // INF-3107: one viewer for pictures and diagrams - fitted, pinch to 8x, double-tap to its own size, drag.
                    PassiveCardMedia(source: source, session: session,
                                     zoom: CardMediaZoom(width: pictures[index]["width"].numeric ?? 0,
                                                         height: pictures[index]["height"].numeric ?? 0,
                                                         drawing: source.hasPrefix(CardDrawing.prefix)),
                                     close: { dismiss() }).id(index)
                    Text(pictures[index]["alt"].text ?? "").font(PhoneFont.caption)
                    if pictures.count > 1 {
                        HStack {
                            Button("Previous picture") { index -= 1 }.disabled(index == 0)
                            Text("\(index + 1) of \(pictures.count)")
                            Button("Next picture") { index += 1 }.disabled(index == pictures.count - 1)
                        }.padding()
                    }
                }
            }.background(PhoneTheme.background)
                .phoneTitle(presentation["type"].text == "demo" ? "Card recording"
                    : (pictures.indices.contains(index) && pictures[index]["src"].text?.hasPrefix(CardDrawing.prefix) == true)
                        ? "Card diagram" : "Card picture")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.onAppear { index = Int(presentation["index"].numeric ?? 0); playGif = presentation["play"].flag }
            .task { if presentation["type"].text == "demo" { await loadRecording() } }
    }
    private func loadRecording() async {
        guard let source = presentation["src"].text, let url = URL(string: source) else { return }
        failure = nil
        do {
            // The native player reads only these verified bytes, never a network or filesystem URL.
            let (bytes, type) = try await CardAssets(session: session).load(url)
            try Task.checkCancellation()
            guard type == "video/mp4" || type == "image/gif" else { throw PhoneError.invalidReply }
            if type == "video/mp4" { recording = MemoryCardRecording(bytes: bytes) }
            else { gif = "data:image/gif;base64,\(bytes.base64EncodedString())" }
        } catch { if !Task.isCancelled { failure = "This recording could not load. Try again when your computer is in reach." } }
    }
}

/// INF-3107: how the viewer zooms a picture or diagram - its own size, from the card, and whether it is a drawing,
/// which may fill the screen larger than its own size since it stays sharp at any zoom.
struct CardMediaZoom: Equatable {
    var width: Double
    var height: Double
    var drawing: Bool
    /// The deepest pinch, counted from the fitted view.
    static let deepest: CGFloat = 8
    /// What a double-tap goes to: the picture's own size, one unit to a point, where that is larger than fitted,
    /// and otherwise twice fitted.
    func doubleTapScale(room: CGSize) -> CGFloat {
        guard width > 0, height > 0, room.width > 0, room.height > 0 else { return 2 }
        let fitted = min(drawing ? .infinity : 1, room.width / width, room.height / height)
        let own = 1 / fitted
        return min(Self.deepest, own > 1.05 ? own : 2)
    }
}

/// A diagram the card wrote out (`DRAWING_SOURCE_PREFIX`): its typefaces go inside it, since a picture loads nothing.
enum CardDrawing {
    static let prefix = "data:image/svg+xml;charset=utf-8,"
    @MainActor static func withFaces(_ source: String, assets: CardAssets) async -> String {
        guard source.hasPrefix(prefix), let markup = String(source.dropFirst(prefix.count)).removingPercentEncoding,
              let pattern = try? NSRegularExpression(pattern: "app-frame://fonts/([a-z0-9-]+\\.woff2)") else { return source }
        let whole = NSRange(markup.startIndex..., in: markup)
        var faces: [String: String] = [:]
        for match in pattern.matches(in: markup, range: whole) {
            guard let range = Range(match.range, in: markup), faces[String(markup[range])] == nil,
                  let url = URL(string: String(markup[range])),
                  let face = try? await assets.load(url), face.1 == "font/woff2" else { continue }
            faces[String(markup[range])] = "data:font/woff2;base64,\(face.0.base64EncodedString())"
        }
        var embedded = markup
        for (address, face) in faces { embedded = embedded.replacingOccurrences(of: address, with: face) }
        return "data:image/svg+xml;base64,\(Data(embedded.utf8).base64EncodedString())"
    }
}

/// No script, native handler, filesystem URL, external page or shared website data in a picture viewer.
private struct PassiveCardMedia: UIViewRepresentable {
    let source: String
    let session: ReadOnlySession
    var zoom: CardMediaZoom? = nil
    var close: (() -> Void)? = nil
    func makeCoordinator() -> Coordinator { Coordinator(session: session) }
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        configuration.setURLSchemeHandler(context.coordinator.assets, forURLScheme: "app-frame")
        let view = FittingWebView(frame: .zero, configuration: configuration)
        view.allowsLinkPreview = false
        view.navigationDelegate = context.coordinator
        view.isOpaque = false; view.backgroundColor = .clear; view.accessibilityIdentifier = "card-picture"
        view.scrollView.backgroundColor = .clear
        if zoom != nil {
            // WebKit's own double-tap is off (touch-action below); this one goes to the picture's own size where tapped.
            let twice = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTapped(_:)))
            twice.numberOfTapsRequired = 2
            twice.delegate = context.coordinator
            view.addGestureRecognizer(twice)
            let down = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.swipedDown(_:)))
            down.direction = .down
            down.delegate = context.coordinator
            view.addGestureRecognizer(down)
        }
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {
        context.coordinator.zoom = zoom
        context.coordinator.close = close
        guard context.coordinator.source != source else { return }
        context.coordinator.source = source
        let drawing = zoom?.drawing == true
        let assets = context.coordinator.assets
        context.coordinator.loading?.cancel()
        context.coordinator.loading = Task { @MainActor in
            let shown = drawing ? await CardDrawing.withFaces(source, assets: assets) : source
            guard !Task.isCancelled else { return }
            view.loadHTMLString(Self.page(shown, zoom: zoom), baseURL: nil)
        }
    }
    /// Fitted at first: a drawing fills the screen, a picture never grows past its own pixels. Pinch runs from fitted to 8x.
    private static func page(_ source: String, zoom: CardMediaZoom?) -> String {
        let escaped = source.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;").replacingOccurrences(of: "<", with: "&lt;")
        let element = "<img alt=\"Card picture\" src=\"\(escaped)\"\(zoom?.drawing == true ? " class=\"drawing\"" : "")>"
        let viewport = zoom == nil ? "width=device-width,initial-scale=1"
            : "width=device-width,initial-scale=1,minimum-scale=1,maximum-scale=\(Int(CardMediaZoom.deepest))"
        return """
        <!doctype html><html><head><meta name="viewport" content="\(viewport)">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data: app-frame://images app-frame://media; media-src 'none'; style-src 'unsafe-inline'; base-uri 'none'">
        <style>html,body{margin:0;height:100%;background:transparent}html{touch-action:manipulation}body{display:flex;align-items:center;justify-content:center}img,video{max-width:100%;max-height:100%;object-fit:contain}img.drawing{width:100%;height:100%}</style>
        </head><body>\(element)</body></html>
        """
    }
    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) {
        coordinator.loading?.cancel(); view.stopLoading(); coordinator.assets.cancel()
    }
    @MainActor final class Coordinator: NSObject, WKNavigationDelegate, UIGestureRecognizerDelegate {
        let assets: CardAssets
        var source: String?
        var zoom: CardMediaZoom?
        var close: (() -> Void)?
        var loading: Task<Void, Never>?
        init(session: ReadOnlySession) { assets = CardAssets(session: session) }
        /// Fitted: to its own size, centred where tapped. Zoomed: back to fitted, as Photos does.
        @objc func doubleTapped(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? WKWebView, let zoom else { return }
            let scroll = view.scrollView
            if scroll.zoomScale > scroll.minimumZoomScale + 0.01 { scroll.setZoomScale(scroll.minimumZoomScale, animated: true); return }
            // WebKit keeps its zooming view to itself, so the tap is read in the scroll view and divided by the
            // current zoom, the zooming view's own units.
            let scale = zoom.doubleTapScale(room: scroll.bounds.size)
            let tapped = gesture.location(in: scroll)
            let point = CGPoint(x: tapped.x / scroll.zoomScale, y: tapped.y / scroll.zoomScale)
            let size = CGSize(width: scroll.bounds.width / scale, height: scroll.bounds.height / scale)
            scroll.zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height),
                        animated: true)
        }
        /// A swipe down while fitted closes the viewer; zoomed, the drag pans instead.
        @objc func swipedDown(_ gesture: UISwipeGestureRecognizer) {
            guard let view = gesture.view as? WKWebView, view.scrollView.zoomScale <= view.scrollView.minimumZoomScale + 0.01 else { return }
            close?()
        }
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
            decisionHandler(navigationAction.request.url?.absoluteString == "about:blank" && navigationAction.navigationType == .other ? .allow : .cancel)
        }
    }
}

/// Turning the device refits the picture: a new size starts fitted again.
private final class FittingWebView: WKWebView {
    private var laidOut: CGSize = .zero
    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != laidOut else { return }
        let first = laidOut == .zero
        laidOut = bounds.size
        if !first { scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false) }
    }
}

/// AVFoundation's resource loader is a byte reader, not a URL fetcher. Nothing is written to disk.
// The delegate is registered exclusively on the main queue below.
@MainActor private final class MemoryCardRecording: NSObject, @preconcurrency AVAssetResourceLoaderDelegate {
    private let bytes: Data
    lazy var player: AVPlayer = {
        let asset = AVURLAsset(url: URL(string: "infinitary-recording://local/clip.mp4")!, options: [
            AVURLAssetReferenceRestrictionsKey: AVAssetReferenceRestrictions.forbidAll.rawValue,
        ])
        asset.resourceLoader.setDelegate(self, queue: .main)
        let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        player.allowsExternalPlayback = false
        return player
    }()
    init(bytes: Data) { self.bytes = bytes }
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource request: AVAssetResourceLoadingRequest) -> Bool {
        if let information = request.contentInformationRequest {
            information.contentType = UTType.mpeg4Movie.identifier
            information.contentLength = Int64(bytes.count)
            information.isByteRangeAccessSupported = true
        }
        if let data = request.dataRequest {
            let start = data.currentOffset
            guard start >= 0, start <= bytes.count else { request.finishLoading(with: PhoneError.invalidReply); return true }
            let end = data.requestsAllDataToEndOfResource ? bytes.count : min(bytes.count, Int(start) + data.requestedLength)
            data.respond(with: bytes.subdata(in: Int(start)..<end))
        }
        request.finishLoading(); return true
    }
}

private struct CardRecordingPlayer: UIViewControllerRepresentable {
    let recording: MemoryCardRecording
    let play: Bool
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = recording.player
        controller.allowsPictureInPicturePlayback = false
        controller.view.accessibilityIdentifier = "card-recording"
        if play { recording.player.play() }
        return controller
    }
    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {}
    static func dismantleUIViewController(_ controller: AVPlayerViewController, coordinator: ()) {
        controller.player?.pause(); controller.player = nil
    }
}
