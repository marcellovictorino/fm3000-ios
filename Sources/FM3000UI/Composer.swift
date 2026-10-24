import FM3000Core
import SwiftUI
#if canImport(UIKit)
import PhotosUI
import UIKit
import UniformTypeIdentifiers
#endif

/// The message box on every screen that sends words: an attach button on the left, a rounded pill that grows with its
/// text up to six lines, and a round send button that appears when there is something to send.
/// Pin it with `.safeAreaInset(edge: .bottom)` so the keyboard lifts it and the content above shrinks.
struct Composer: View {
    let placeholder: String
    @Binding var text: String
    /// Nil hides the attach button (the crewmate thread takes text only: `inf:task:steer`).
    var attachments: Binding<[Attachment]>?
    var enabled: Bool
    var sending: Bool
    var onSend: () -> Void
    @FocusState private var focused: Bool
    #if canImport(UIKit)
    @StateObject private var dictation = Dictation()
    #endif
    @State private var problem: String?
    #if canImport(UIKit)
    @State private var pickedPhotos: [PhotosPickerItem] = []
    @State private var showPhotos = false
    @State private var showCamera = false
    @State private var showFiles = false
    #endif

    private var hasText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var hasContent: Bool { hasText || !(attachments?.wrappedValue.isEmpty ?? true) }

    var body: some View {
        VStack(spacing: 6) {
            #if canImport(UIKit)
            if let problem = dictation.problem { Text(problem).font(.caption).foregroundStyle(Theme.warn).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16) }
            #endif
            if let problem { Text(problem).font(.caption).foregroundStyle(Theme.warn).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16) }
            if let items = attachments?.wrappedValue, !items.isEmpty { chips(items) }
            HStack(alignment: .bottom, spacing: 8) {
                if attachments != nil { attachMenu }
                TextField(placeholder, text: $text, axis: .vertical)
                    .lineLimit(1...8)
                    .focused($focused)
                    .font(.body)
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(Theme.bg2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    // The desktop's focus ring: a hairline and a soft accent glow, faint at rest and lit while typing.
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(focused ? Theme.accent.opacity(0.6) : Theme.accent.opacity(0.28), lineWidth: focused ? 1 : 0.75))
                    .shadow(color: Theme.accent.opacity(focused ? 0.4 : 0.16), radius: focused ? 10 : 6)
                    .animation(.easeOut(duration: 0.16), value: focused)
                #if canImport(UIKit)
                if !hasContent || dictation.listening { micButton }
                #endif
                if hasContent {
                    Button(action: { stopDictation(); focused = false; problem = nil; onSend() }) {
                        Image(systemName: sending ? "ellipsis" : "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.bg0)
                            .frame(width: 36, height: 36)
                            .background(enabled && !sending ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.fg3), in: Circle())
                    }
                    .disabled(!enabled || sending)
                    .accessibilityLabel("Send")
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.bg1.ignoresSafeArea(edges: .bottom))
        .animation(.easeOut(duration: 0.15), value: hasContent)
    }

    #if canImport(UIKit)
    /// Dictation: tap, speak, tap again. The words land in the box to check before sending.
    private var micButton: some View {
        Button {
            // The box stays focused while dictating, so its caret follows the newest words and the text scrolls with them.
            if !dictation.listening { focused = true }
            dictation.toggle(into: $text)
        } label: {
            Image(systemName: dictation.listening ? "stop.fill" : "mic.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(dictation.listening ? Theme.bg0 : Theme.accent)
                .frame(width: 36, height: 36)
                .background(dictation.listening ? AnyShapeStyle(Theme.danger) : AnyShapeStyle(Theme.bg2), in: Circle())
        }
        .accessibilityLabel(dictation.listening ? "Stop dictating" : "Dictate")
        .disabled(!enabled)
    }
    #endif

    private func stopDictation() {
        #if canImport(UIKit)
        dictation.stop()
        #endif
    }

    private func chips(_ items: [Attachment]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    HStack(spacing: 6) {
                        chipThumbnail(item)
                        Text(item.name).font(.caption).lineLimit(1).frame(maxWidth: 140)
                        Button { attachments?.wrappedValue.removeAll { $0.id == item.id } } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.fg3) }
                            .accessibilityLabel("Remove \(item.name)")
                    }
                    .padding(6).background(Theme.bg2, in: Capsule())
                    .overlay(Capsule().stroke(Theme.line.opacity(0.6), lineWidth: 0.5))
                }
            }
            .padding(.horizontal, 4)
        }
    }

    @ViewBuilder private func chipThumbnail(_ item: Attachment) -> some View {
        #if canImport(UIKit)
        if case .image(_, let data) = item.content, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill().frame(width: 28, height: 28).clipShape(RoundedRectangle(cornerRadius: 6))
        } else { Image(systemName: "doc.text").frame(width: 28, height: 28) }
        #else
        Image(systemName: "doc.text").frame(width: 28, height: 28)
        #endif
    }

    #if canImport(UIKit)
    private var cameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    private var attachMenu: some View {
        Menu {
            Button { showPhotos = true } label: { Label("Photo library", systemImage: "photo.on.rectangle") }
            Button { showCamera = true } label: { Label("Take photo", systemImage: "camera") }.disabled(!cameraAvailable)
            Button { showFiles = true } label: { Label("File (text)", systemImage: "doc") }
        } label: {
            Image(systemName: "plus").font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.accent)
                .frame(width: 36, height: 36).background(Theme.bg2, in: Circle())
        }
        .accessibilityLabel("Attach")
        .photosPicker(isPresented: $showPhotos, selection: $pickedPhotos, maxSelectionCount: Attachment.maxPerMessage, matching: .images)
        .onChange(of: pickedPhotos) { items in
            guard !items.isEmpty else { return }
            Task {
                for item in items { if let data = try? await item.loadTransferable(type: Data.self) { add(image: data, name: "Photo") } }
                pickedPhotos = []
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in if let data { add(image: data, name: "Camera photo") } }.ignoresSafeArea()
        }
        .fileImporter(isPresented: $showFiles, allowedContentTypes: [.plainText, .text, .json, .sourceCode, .xml, .commaSeparatedText], allowsMultipleSelection: true) { result in
            guard case .success(let urls) = result else { return }
            for url in urls {
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                do { try append(Attachments.textFile(name: url.lastPathComponent, data: Data(contentsOf: url))) }
                catch { problem = error.localizedDescription }
            }
        }
    }

    /// A photo is re-encoded as a JPEG no wider than 1600 points so it stays far below the Mac's 7.5 MB limit.
    private func add(image data: Data, name: String) {
        guard let image = UIImage(data: data) else { problem = "That photo could not be read."; return }
        let scale = min(1, 1600 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let jpeg = UIGraphicsImageRenderer(size: size).jpegData(withCompressionQuality: 0.8) { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        do { try append(Attachments.image(name: name, mimeType: "image/jpeg", data: jpeg)) } catch { problem = error.localizedDescription }
    }
    #else
    private var attachMenu: some View { EmptyView() }
    #endif

    private func append(_ item: Attachment) throws {
        guard (attachments?.wrappedValue.count ?? 0) < Attachment.maxPerMessage else { throw AttachmentError.tooMany }
        attachments?.wrappedValue.append(item)
        problem = nil
    }
}

#if canImport(UIKit)
/// The system camera, as a sheet. It answers the photo's bytes, or nil when cancelled.
struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onPick: (Data?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.onPick((info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.9))
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.onPick(nil); parent.dismiss() }
    }
}
#endif

/// Puts the keyboard away from anywhere, so the tab bar is reachable again.
func dismissKeyboard() {
    #if canImport(UIKit)
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    #endif
}

extension View {
    /// A tap on the background puts the keyboard away; taps on buttons and links still reach them.
    func dismissKeyboardOnTap() -> some View { simultaneousGesture(TapGesture().onEnded { dismissKeyboard() }) }
}
