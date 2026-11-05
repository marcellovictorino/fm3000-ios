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
                } else if presentation["type"].text == "diagram", let svg = presentation["svg"].text {
                    // Fork: a tapped diagram, zoomable like a picture.
                    PassiveCardMedia(source: "", session: session, diagram: (svg, presentation["fonts"].text ?? ""))
                    Text(presentation["alt"].text ?? "").font(PhoneFont.caption)
                } else if pictures.indices.contains(index), let source = pictures[index]["src"].text {
                    PassiveCardMedia(source: source, session: session).id(index)
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
                .phoneTitle(presentation["type"].text == "demo" ? "Card recording" : presentation["type"].text == "diagram" ? "Card diagram" : "Card picture")
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

/// No script, native handler, filesystem URL, external page or shared website data in a picture viewer.
/// Fork: it pinches from 1x to 8x, pans when zoomed, and a double tap zooms in at the tap or back out.
private struct PassiveCardMedia: UIViewRepresentable {
    let source: String
    let session: ReadOnlySession
    /// A diagram's drawing and the card's font faces, shown in place of the picture at `source`.
    var diagram: (svg: String, fonts: String)?
    func makeCoordinator() -> Coordinator { Coordinator(session: session) }
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        configuration.setURLSchemeHandler(context.coordinator.assets, forURLScheme: "app-frame")
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.allowsLinkPreview = false
        view.navigationDelegate = context.coordinator
        view.isOpaque = false; view.backgroundColor = .clear; view.accessibilityIdentifier = "card-picture"
        view.scrollView.contentInsetAdjustmentBehavior = .never
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.zoom(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = context.coordinator
        view.addGestureRecognizer(doubleTap)
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {
        let key = diagram?.svg ?? source
        guard context.coordinator.source != key else { return }
        context.coordinator.source = key
        let escaped = source.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;").replacingOccurrences(of: "<", with: "&lt;")
        // A diagram's copy is drawn as it is; scripts are off and the policy below loads nothing but card fonts and pictures.
        let element = diagram.map { "<div class=\"diagram\">\($0.svg)</div>" } ?? "<img alt=\"Card picture\" src=\"\(escaped)\">"
        let fonts = (diagram?.fonts ?? "").replacingOccurrences(of: "</", with: "<\\/")
        view.loadHTMLString("""
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1,minimum-scale=1,maximum-scale=8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data: app-frame://images app-frame://media; font-src app-frame: data:; media-src 'none'; style-src 'unsafe-inline'; base-uri 'none'">
        <style>\(fonts)
        html,body{margin:0;height:100%;background:transparent}body{display:flex;align-items:center;justify-content:center}img,video{max-width:100%;max-height:100%;object-fit:contain}.diagram{width:100%;height:100%}</style>
        </head><body>\(element)</body></html>
        """, baseURL: nil)
    }
    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) { view.stopLoading(); coordinator.assets.cancel() }
    @MainActor final class Coordinator: NSObject, WKNavigationDelegate, UIGestureRecognizerDelegate {
        let assets: CardAssets
        var source: String?
        init(session: ReadOnlySession) { assets = CardAssets(session: session) }
        @objc func zoom(_ tap: UITapGestureRecognizer) {
            guard let scroller = (tap.view as? WKWebView)?.scrollView else { return }
            if scroller.zoomScale > scroller.minimumZoomScale + 0.01 { return scroller.setZoomScale(scroller.minimumZoomScale, animated: true) }
            // The scroller's own points are the page's, times its zoom.
            let at = tap.location(in: scroller), point = CGPoint(x: at.x / scroller.zoomScale, y: at.y / scroller.zoomScale)
            let scale = min(3, scroller.maximumZoomScale)
            let size = CGSize(width: scroller.bounds.width / scale, height: scroller.bounds.height / scale)
            scroller.zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height), animated: true)
        }
        // WebKit's own double tap, which zooms to fit what was tapped, waits for this one; its other touches keep working.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool { Self.isDoubleTap(other) }
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { !Self.isDoubleTap(other) }
        private static func isDoubleTap(_ recognizer: UIGestureRecognizer) -> Bool {
            (recognizer as? UITapGestureRecognizer)?.numberOfTapsRequired == 2
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
            decisionHandler(navigationAction.request.url?.absoluteString == "about:blank" && navigationAction.navigationType == .other ? .allow : .cancel)
        }
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
