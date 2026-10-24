import AVFoundation
import FM3000Core
import SwiftUI
#if canImport(UIKit)
import Speech
#endif

/// Reads text aloud with the iPhone's own voices (`AVSpeechSynthesizer`): nothing leaves the phone.
@MainActor
final class Speaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = Speaker()
    /// What is being read now, so its button can turn into Stop.
    @Published private(set) var speaking: String?
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func toggle(_ text: String, id: String) {
        if speaking == id { stop(); return }
        stop()
        let words = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !words.isEmpty else { return }
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        let utterance = AVSpeechUtterance(string: words)
        // The language the text is written in, so Portuguese or French is not read in an English accent.
        let language = NSLinguisticTagger.dominantLanguage(for: words) ?? AVSpeechSynthesisVoice.currentLanguageCode()
        utterance.voice = Self.bestVoice(for: language) ?? Self.bestVoice(for: AVSpeechSynthesisVoice.currentLanguageCode())
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speaking = id
        synthesizer.speak(utterance)
    }

    /// The best voice installed for a language: Premium over Enhanced over the compact default, which is what sounds robotic.
    /// More are free in Settings > Accessibility > Spoken Content > Voices.
    static func bestVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let base = language.split(separator: "-").first.map(String.init) ?? language
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language || $0.language.hasPrefix(base + "-") }
        return candidates.max { rank($0) < rank($1) } ?? AVSpeechSynthesisVoice(language: language)
    }

    private static func rank(_ voice: AVSpeechSynthesisVoice) -> Int {
        // An exact regional match breaks ties between voices of the same quality.
        voice.quality.rawValue * 10 + (voice.language == AVSpeechSynthesisVoice.currentLanguageCode() ? 1 : 0)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        speaking = nil
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.speaking = nil }
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.speaking = nil }
    }
}

/// A Listen / Stop button for one piece of text.
struct ListenButton: View {
    let text: String
    let id: String
    @ObservedObject private var speaker = Speaker.shared

    var body: some View {
        let on = speaker.speaking == id
        Button { speaker.toggle(text, id: id) } label: {
            Label(on ? "Stop" : "Listen", systemImage: on ? "stop.fill" : "speaker.wave.2")
        }
        .accessibilityLabel(on ? "Stop reading aloud" : "Read aloud")
    }
}

#if canImport(UIKit)
/// Speech to text on the phone: the microphone feeds Apple's recogniser, which runs on the device when the language allows it.
/// What was heard is put in the message box for the person to check and send; no audio is kept or sent.
@MainActor
final class Dictation: ObservableObject {
    @Published private(set) var listening = false
    @Published var problem: String?
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func toggle(into text: Binding<String>) {
        if listening { stop(); return }
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                guard status == .authorized else { self.problem = "Allow speech recognition in Settings to dictate."; return }
                self.askMicrophone { granted in
                    guard granted else { self.problem = "Allow the microphone in Settings to dictate."; return }
                    self.begin(into: text)
                }
            }
        }
    }

    private func askMicrophone(_ done: @escaping @MainActor (Bool) -> Void) {
        if #available(iOS 17, *) {
            AVAudioApplication.requestRecordPermission { granted in Task { @MainActor in done(granted) } }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in Task { @MainActor in done(granted) } }
        }
    }

    private func begin(into text: Binding<String>) {
        guard let recognizer = SFSpeechRecognizer(locale: Locale.current) ?? SFSpeechRecognizer(), recognizer.isAvailable else {
            problem = "Speech recognition is not available right now."; return
        }
        let prefix = text.wrappedValue.isEmpty ? "" : text.wrappedValue + " "
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        self.request = request
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            let input = engine.inputNode
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in request.append(buffer) }
            engine.prepare()
            try engine.start()
        } catch {
            problem = "The microphone could not start."
            stop()
            return
        }
        problem = nil
        listening = true
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result { text.wrappedValue = prefix + result.bestTranscription.formattedString }
                if error != nil || result?.isFinal == true { self?.stop() }
            }
        }
    }

    func stop() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()
        request = nil
        task = nil
        listening = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
#endif
