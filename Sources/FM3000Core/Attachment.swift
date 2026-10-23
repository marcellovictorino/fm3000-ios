import Foundation

/// Something the person adds to a message. The Mac takes up to four images (png, jpeg, gif, webp, 7.5 MB each as base64)
/// and four text files per message on `inf:converse` and `inf:cards:reply` (`docs/contract.json`); nothing else.
public struct Attachment: Equatable, Identifiable {
    public enum Content: Equatable {
        case image(mimeType: String, data: Data)
        case textFile(text: String)
    }
    public let id: UUID
    public let name: String
    public let content: Content

    public init(id: UUID = UUID(), name: String, content: Content) { self.id = id; self.name = name; self.content = content }

    public static let maxPerMessage = 4
    public static let imageTypes = ["image/png", "image/jpeg", "image/gif", "image/webp"]
    /// The Mac's limit on an image's base64 text (`data` maxLength).
    public static let maxImageBase64 = 7_500_000
}

public enum AttachmentError: Error, LocalizedError, Equatable {
    case notText(String), tooMany, tooBig(String), notImage(String)
    public var errorDescription: String? {
        switch self {
        case .notText(let name): return "\(name) is not a text file. Your Mac takes images and text files only."
        case .tooMany: return "A message takes up to \(Attachment.maxPerMessage) attachments."
        case .tooBig(let name): return "\(name) is too large for your Mac (7.5 MB as an image)."
        case .notImage(let name): return "\(name) is not an image type your Mac reads (png, jpeg, gif, webp)."
        }
    }
}

public enum Attachments {
    /// A picked file: kept only when it reads as UTF-8 text, since the Mac takes file text, not bytes.
    public static func textFile(name: String, data: Data) throws -> Attachment {
        guard let text = String(data: data, encoding: .utf8), !text.contains("\0") else { throw AttachmentError.notText(name) }
        return Attachment(name: name, content: .textFile(text: text))
    }

    public static func image(name: String, mimeType: String, data: Data) throws -> Attachment {
        guard Attachment.imageTypes.contains(mimeType) else { throw AttachmentError.notImage(name) }
        guard data.base64EncodedString().utf8.count <= Attachment.maxImageBase64 else { throw AttachmentError.tooBig(name) }
        return Attachment(name: name, content: .image(mimeType: mimeType, data: data))
    }

    /// The argument of `inf:converse` and `inf:cards:reply`: plain text when there is nothing attached, else the object form.
    public static func payload(text: String, attachments: [Attachment]) -> JSONValue {
        guard !attachments.isEmpty else { return .string(text) }
        var object: [String: JSONValue] = ["text": .string(text)]
        let images: [JSONValue] = attachments.compactMap {
            if case .image(let mime, let data) = $0.content {
                return .object(["mimeType": .string(mime), "data": .string(data.base64EncodedString()), "name": .string(String($0.name.prefix(120)))])
            }
            return nil
        }
        let files: [JSONValue] = attachments.compactMap {
            if case .textFile(let body) = $0.content { return .object(["name": .string(String($0.name.prefix(120))), "text": .string(body)]) }
            return nil
        }
        if !images.isEmpty { object["images"] = .array(images) }
        if !files.isEmpty { object["files"] = .array(files) }
        return .object(object)
    }
}
