import Foundation
import WebKit

/// How a card body's web view is set up and how it reports its height. Kept apart from SwiftUI so `fm-checks` can load a real
/// page and watch it, on the Mac and with no phone.
public enum CardPage {
    static let handlerName = "cardHeight"

    /// Reports the page's content height now and again whenever it changes: an expandable section opening or closing, a picture
    /// loading, the text reflowing. The page's own scripts stay off (`allowsContentJavaScript`); this one belongs to the app and runs
    /// in its own world, out of the page's reach.
    static let observer = """
    (function () {
      var last = -1;
      function post() {
        var height = Math.ceil(document.body.getBoundingClientRect().bottom + window.scrollY);
        if (height !== last) { last = height; window.webkit.messageHandlers.\(handlerName).postMessage(height); }
      }
      new ResizeObserver(post).observe(document.body);
      post();
    })();
    """

    /// A configuration whose pages run no scripts of their own and call `onHeight`, on the main thread, with the content's height in points.
    @MainActor
    public static func configuration(onHeight: @escaping @MainActor (CGFloat) -> Void) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        let receiver = HeightReceiver(onHeight: onHeight)
        configuration.userContentController.add(receiver, contentWorld: .defaultClient, name: handlerName)
        configuration.userContentController.addUserScript(WKUserScript(source: observer, injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: .defaultClient))
        return configuration
    }

    private final class HeightReceiver: NSObject, WKScriptMessageHandler {
        let onHeight: @MainActor (CGFloat) -> Void
        init(onHeight: @escaping @MainActor (CGFloat) -> Void) { self.onHeight = onHeight }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let value = message.body as? Double, value > 0 else { return }
            MainActor.assumeIsolated { onHeight(CGFloat(value)) }   // WebKit calls this on the main thread
        }
    }
}
