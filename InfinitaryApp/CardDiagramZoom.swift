import InfinitaryKit
@preconcurrency import WebKit

/// A tapped diagram (an inline SVG drawing) in a card body opens in the card picture viewer, where it can be zoomed,
/// as a tapped picture already does. The card's own bridge only opens `<img>` pictures, so this listens beside it.
///
/// The script runs in its own content world, which the card's scripts cannot see or call, inside the body's frame.
/// It answers only a real tap (`isTrusted`), skips links and controls, and sends a copy of the drawing with its
/// computed colours and type written in, so it looks the same outside the card's stylesheet.
/// The viewer shows that copy in a script-free web view with no network, as it shows pictures.
@MainActor enum CardDiagramZoom {
    static let handlerName = "cardDiagram"
    static let world = WKContentWorld.world(name: "cardDiagramZoom")
    /// The largest drawing copy the viewer takes, in UTF-8 bytes.
    static let maxBytes = 4 * 1024 * 1024

    static func install(in controller: WKUserContentController, handler: WKScriptMessageHandler) {
        controller.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false, in: world))
        controller.add(handler, contentWorld: world, name: handlerName)
    }

    static func remove(from controller: WKUserContentController) {
        controller.removeScriptMessageHandler(forName: handlerName, contentWorld: world)
    }

    /// The viewer's presentation for a message the script sent, or nil when it is not one.
    static func presentation(_ body: Any) -> PhoneJSON? {
        guard let message = try? PhoneJSON.read(body), let svg = message["svg"].text, svg.hasPrefix("<svg"),
              svg.utf8.count <= maxBytes else { return nil }
        let fonts = message["fonts"].text ?? ""
        return .object([
            "type": .string("diagram"), "svg": .string(svg),
            "fonts": .string(fonts.utf8.count <= 256 * 1024 ? fonts : ""),
            "alt": .string(String((message["alt"].text ?? "").prefix(500))),
        ])
    }

    private static let script = """
    (() => {
      if (window === window.top) return;
      const SKIP = "a, button, summary, label, input, select, textarea, [data-inf-action], [data-inf-draft], [data-inf-demo]";
      const PROPS = ["fill", "fill-opacity", "fill-rule", "stroke", "stroke-width", "stroke-opacity", "stroke-dasharray",
        "stroke-linecap", "stroke-linejoin", "opacity", "font-family", "font-size", "font-weight", "font-style",
        "text-anchor", "dominant-baseline", "letter-spacing", "color", "visibility", "display"];
      document.addEventListener("click", (event) => {
        if (!event.isTrusted) return;
        const target = event.target;
        if (!(target instanceof Element) || target.closest(SKIP)) return;
        let svg = target.closest("svg");
        if (!svg) return;
        for (let outer = svg.parentElement?.closest("svg"); outer; outer = outer.parentElement?.closest("svg")) svg = outer;
        const box = svg.getBoundingClientRect();
        // Icons and small marks are not diagrams.
        if (box.width < 120 || box.height < 60) return;
        const copy = svg.cloneNode(true);
        const from = [svg, ...svg.querySelectorAll("*")], to = [copy, ...copy.querySelectorAll("*")];
        from.forEach((element, i) => {
          const style = getComputedStyle(element);
          const own = i === 0 ? "" : (to[i].getAttribute("style") || "") + ";";
          to[i].setAttribute("style", own + PROPS.map((name) => `${name}:${style.getPropertyValue(name)}`).join(";"));
        });
        for (const node of [copy, ...copy.querySelectorAll("*")]) {
          for (const attribute of [...node.attributes]) if (/^on/i.test(attribute.name)) node.removeAttribute(attribute.name);
        }
        copy.querySelectorAll("script").forEach((node) => node.remove());
        if (!copy.getAttribute("viewBox")) copy.setAttribute("viewBox", `0 0 ${box.width} ${box.height}`);
        copy.setAttribute("xmlns", "http://www.w3.org/2000/svg");
        copy.removeAttribute("width"); copy.removeAttribute("height");
        copy.setAttribute("style", copy.getAttribute("style") + ";display:block;width:100%;height:100%;max-width:none");
        const fonts = [];
        for (const sheet of document.styleSheets) {
          try { for (const rule of sheet.cssRules) if (rule instanceof CSSFontFaceRule) fonts.push(rule.cssText); } catch {}
        }
        const alt = svg.closest("figure")?.getAttribute("aria-label") || svg.getAttribute("aria-label") || "";
        window.webkit.messageHandlers.\(handlerName).postMessage({ svg: copy.outerHTML, fonts: fonts.join("\\n"), alt });
      });
    })();
    """
}

/// Hands a tapped diagram to the card's viewer. Only the card's own web view, and only the isolated script, reach it.
@MainActor final class CardDiagramReceiver: NSObject, WKScriptMessageHandler {
    var open: ((WKWebView, PhoneJSON) -> Void)?
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.world == CardDiagramZoom.world, let view = message.webView,
              let presentation = CardDiagramZoom.presentation(message.body) else { return }
        open?(view, presentation)
    }
}
