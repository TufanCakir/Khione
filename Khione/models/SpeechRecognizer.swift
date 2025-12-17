//
//  SpeechRecognizer.swift
//  Khione
//

import Foundation
import Speech
import AVFoundation
internal import Combine

@MainActor
final class SpeechRecognizer: ObservableObject {

    // MARK: - State
    enum State: Equatable {
        case idle
        case recording
        case finishing
        case error(String)
    }

    @Published private(set) var transcript: String = ""
    @Published private(set) var state: State = .idle

    var isRecording: Bool { state == .recording }

    // MARK: - Private
    private let recognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()

    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private var permissionGranted: Bool?

    // MARK: - Init
    init(locale: Locale = .current) {
        self.recognizer = SFSpeechRecognizer(locale: locale)
    }

    nonisolated deinit {
        // deinit runs in a nonisolated context; hop to the main actor for cleanup
        Task { @MainActor [weak self] in
            self?.cleanupOnMainActor()
        }
    }


    // MARK: - Permissions
    func requestPermission() async -> Bool {
        if let cached = permissionGranted {
            return cached
        }

        let speechAuth = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization {
                continuation.resume(returning: $0)
            }
        }

        let micAuth: Bool = await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        let granted = (speechAuth == .authorized && micAuth)
        permissionGranted = granted
        return granted
    }

    // MARK: - Start
    func start() throws {
        guard state == .idle else { return }

        transcript = ""
        state = .recording

        guard let recognizer, recognizer.isAvailable else {
            state = .error("Spracherkennung nicht verfügbar.")
            throw SpeechError.recognizerUnavailable
        }

        try configureAudioSession()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format
        ) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer.recognitionTask(with: request) {
            [weak self] result, error in
            guard let self else { return }

            if let result {
                self.transcript = result.bestTranscription.formattedString
            }

            if error != nil || result?.isFinal == true {
                self.finish()
            }
        }
    }

    // MARK: - Stop (User)
    func stop() {
        guard state == .recording else { return }
        finish()
    }

    // MARK: - Finish (Internal)
    private func finish() {
        guard state == .recording else { return }
        state = .finishing

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        request?.endAudio()
        request = nil

        task?.finish()
        task = nil

        try? AVAudioSession.sharedInstance().setActive(false)

        state = .idle
    }

    // MARK: - Audio Session
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.duckOthers, .defaultToSpeaker]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Hard Stop (Safety)
    private func cleanupOnMainActor() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        task?.cancel()
        request = nil
        task = nil
        state = .idle
    }
}

// MARK: - Errors
enum SpeechError: LocalizedError {
    case recognizerUnavailable

    var errorDescription: String? {
        "Spracherkennung ist aktuell nicht verfügbar."
    }
}

