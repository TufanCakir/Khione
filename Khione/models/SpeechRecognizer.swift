//
//  SpeechRecognizer.swift
//  Khione
//

import AVFAudio
import AVFoundation
internal import Combine
import Foundation
import Speech

@MainActor
final class SpeechRecognizer: ObservableObject {

    enum State: Equatable {
        case idle
        case recording
        case finishing
        case error(String)
    }

    @Published private(set) var transcript: String = ""
    @Published private(set) var state: State = .idle

    var isRecording: Bool { state == .recording }

    // ✅ Technische Ressourcen → explizit freigegeben
    nonisolated(unsafe) private let audioEngine = AVAudioEngine()
    nonisolated(unsafe) private let recognizer: SFSpeechRecognizer?

    // 🔥 DAS ist der Schlüssel
    nonisolated(unsafe) private var request:
        SFSpeechAudioBufferRecognitionRequest?
    nonisolated(unsafe) private var task: SFSpeechRecognitionTask?

    private var permissionGranted: Bool?

    init(locale: Locale = .current) {
        self.recognizer = SFSpeechRecognizer(locale: locale)
    }

    // ✅ deinit ist IMMER nonisolated
    deinit {
        cleanupImmediately()
    }

    // ✅ explizit nonisolated
    nonisolated private func cleanupImmediately() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        task?.cancel()
        request = nil
        task = nil
    }

    // MARK: - Permissions
    func requestPermission() async -> Bool {
        if let cached = permissionGranted { return cached }

        let speechAuth = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization {
                cont.resume(returning: $0)
            }
        }

        let micAuth = await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission {
                cont.resume(returning: $0)
            }
        }

        let granted = (speechAuth == .authorized && micAuth)
        permissionGranted = granted
        return granted
    }

    // MARK: - Start
    func start() throws {
        guard state == .idle else { return }

        guard let recognizer, recognizer.isAvailable else {
            state = .error("Speech recognition unavailable.")
            throw SpeechError.recognizerUnavailable
        }

        transcript = ""
        state = .recording

        try configureAudioSession()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer.recognitionTask(with: request) {
            [weak self] result, error in
            guard let self else { return }

            Task { @MainActor in
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }

                if error != nil || result?.isFinal == true {
                    self.finish()
                }
            }
        }
    }

    func stop() {
        guard state == .recording else { return }
        finish()
    }

    private func finish() {
        guard state == .recording else { return }

        state = .finishing

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        request?.endAudio()
        request = nil

        task?.cancel()
        task = nil

        try? AVAudioSession.sharedInstance().setActive(false)

        state = .idle
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.duckOthers, .defaultToSpeaker]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }
}

enum SpeechError: LocalizedError {
    case recognizerUnavailable
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognition is currently unavailable."
        case .permissionDenied:
            return "Speech recognition permission was denied."
        }
    }
}
