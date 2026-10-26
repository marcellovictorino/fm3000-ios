import FM3000CardWeb
import FM3000Core
import SwiftUI
import WebKit

/// A card body drawn the way the Mac draws it: the body's HTML in a web view that carries Infinitary's own
/// stylesheet, so headings, colours, tables, code and SVG diagrams look the same. The page runs no scripts and
/// loads nothing from the network; links do not navigate. It follows its content's height as it changes (an expandable
/// section opening, a picture loading), so the screen's own scroll view does the scrolling.
struct CardBody: View {
    let html: String
    @State private var height: CGFloat = 40

    var body: some View {
        CardWebView(html: html, height: $height)
            .frame(height: height)
    }

    static func document(_ body: String) -> String {
        """
        <!doctype html><html><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <style>\(CardStyle.css)
        html, body { background: transparent; -webkit-text-size-adjust: 100%; }
        body { padding: 0; font-size: 15px; overflow-wrap: anywhere; }
        pre { overflow-x: auto; }
        </style></head><body>\(body)</body></html>
        """
    }
}

#if os(iOS)
private struct CardWebView: UIViewRepresentable {
    let html: String
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let height = $height
        let view = WKWebView(frame: .zero, configuration: CardPage.configuration { new in if height.wrappedValue != new { height.wrappedValue = new } })
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        view.scrollView.isScrollEnabled = false
        view.navigationDelegate = context.coordinator
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        guard context.coordinator.loaded != html else { return }
        context.coordinator.loaded = html
        view.loadHTMLString(CardBody.document(html), baseURL: nil)
        #if DEBUG
        // Simulator runs: `-openDetails` opens every expandable section after the page loads, as a tap on its summary would.
        if ProcessInfo.processInfo.arguments.contains("-openDetails") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { view.evaluateJavaScript("document.querySelectorAll('details').forEach(d => d.open = true)") }
        }
        #endif
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var loaded = ""

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            action.navigationType == .other ? .allow : .cancel
        }
    }
}
#else
private struct CardWebView: View {
    let html: String
    @Binding var height: CGFloat
    var body: some View { Text(HTMLText.plain(html)) }
}
#endif
