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
                .phoneTitle(presentation["type"].text == "demo" ? "Card recording" : "Card picture")
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
private struct PassiveCardMedia: UIViewRepresentable {
    let source: String
    let session: ReadOnlySession
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
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {
        guard context.coordinator.source != source else { return }
        context.coordinator.source = source
        let escaped = source.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;").replacingOccurrences(of: "<", with: "&lt;")
        let element = "<img alt=\"Card picture\" src=\"\(escaped)\">"
        view.loadHTMLString("""
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data: app-frame://images app-frame://media; media-src 'none'; style-src 'unsafe-inline'; base-uri 'none'">
        <style>html,body{margin:0;height:100%;background:transparent}body{display:flex;align-items:center;justify-content:center}img,video{max-width:100%;max-height:100%;object-fit:contain}</style>
        </head><body>\(element)</body></html>
        """, baseURL: nil)
    }
    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) { view.stopLoading(); coordinator.assets.cancel() }
    @MainActor final class Coordinator: NSObject, WKNavigationDelegate {
        let assets: CardAssets
        var source: String?
        init(session: ReadOnlySession) { assets = CardAssets(session: session) }
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
