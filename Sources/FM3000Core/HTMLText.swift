import Foundation

/// Turns a card's HTML fragment into readable plain text for the phone's first version.
/// Cards can carry figures, forms and scripts; those are dropped, and the Mac shows them whole.
public enum HTMLText {
    public static func plain(_ html: String) -> String {
        var text = html
        for tag in ["script", "style", "svg", "figure", "details"] {
            text = text.replacingOccurrences(of: "<\(tag)\\b[\\s\\S]*?</\(tag)>", with: "", options: [.regularExpression, .caseInsensitive])
        }
        text = text.replacingOccurrences(of: "<li\\b[^>]*>", with: "\n• ", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "</(p|div|h[1-6]|ul|ol|tr|section|fieldset|legend|pre|blockquote)>", with: "\n\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = decodeEntities(text)
        text = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: " ?\\n ?", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static let named = ["amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " ", "mdash": "—", "ndash": "–", "hellip": "…", "rarr": "→"]

    static func decodeEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }
        var result = ""
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if character == "&", let semicolon = text[index...].prefix(10).firstIndex(of: ";") {
                let name = String(text[text.index(after: index)..<semicolon])
                var replacement: String?
                if name.hasPrefix("#x"), let value = UInt32(name.dropFirst(2), radix: 16) { replacement = Unicode.Scalar(value).map(String.init) }
                else if name.hasPrefix("#"), let value = UInt32(name.dropFirst()) { replacement = Unicode.Scalar(value).map(String.init) }
                else { replacement = named[name] }
                if let replacement {
                    result += replacement
                    index = text.index(after: semicolon)
                    continue
                }
            }
            result.append(character)
            index = text.index(after: index)
        }
        return result
    }
}
