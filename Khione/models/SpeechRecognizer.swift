//
//  SpeechRecognizer.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
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

    @Published private(set) var transcript = ""
    @Published private(set) var state: State = .idle

    var onTranscriptChanged: ((String) -> Void)?
    var onStateChanged: ((State) -> Void)?

    var isRecording: Bool { state == .recording }

    private let audioEngine = AVAudioEngine()
    nonisolated(unsafe) private let recognizer: SFSpeechRecognizer?
    nonisolated(unsafe) private var request:
        SFSpeechAudioBufferRecognitionRequest?
    nonisolated(unsafe) private var task: SFSpeechRecognitionTask?

    private var permissionGranted: Bool?

    init(locale: Locale = .current) {
        recognizer = SFSpeechRecognizer(locale: locale)
    }

    deinit {
        cleanupImmediately()
    }

    nonisolated private func cleanupImmediately() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
    }

    // MARK: - Permissions

    func requestPermission() async -> Bool {
        if let permissionGranted {
            return permissionGranted
        }

        let speechAuthorization = await withCheckedContinuation {
            continuation in
            SFSpeechRecognizer.requestAuthorization {
                continuation.resume(returning: $0)
            }
        }

        let microphoneAuthorization = await withCheckedContinuation {
            continuation in
            AVAudioApplication.requestRecordPermission {
                continuation.resume(returning: $0)
            }
        }

        let isGranted =
            speechAuthorization == .authorized && microphoneAuthorization
        permissionGranted = isGranted
        return isGranted
    }

    // MARK: - Recognition

    func start() throws {
        guard state != .recording, state != .finishing else { return }

        guard let recognizer, recognizer.isAvailable else {
            updateState(
                .error(String(localized: "Speech recognition unavailable."))
            )
            throw SpeechError.recognizerUnavailable
        }

        cancelRecognition()
        updateTranscript("")

        do {
            try configureAudioSession()

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            self.request = request

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(
                onBus: 0,
                bufferSize: 1024,
                format: format
            ) { buffer, _ in
                request.append(buffer)
            }

            task = recognizer.recognitionTask(with: request) {
                [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    if let result {
                        self.updateTranscript(
                            result.bestTranscription.formattedString
                        )
                    }

                    if error != nil || result?.isFinal == true {
                        self.completeRecognition(error: error)
                    }
                }
            }

            audioEngine.prepare()
            try audioEngine.start()
            updateState(.recording)
        } catch {
            cancelRecognition()
            updateState(.error(error.localizedDescription))
            throw error
        }
    }

    func stop() {
        guard state == .recording else { return }

        updateState(.finishing)
        stopAudioCapture()
        request?.endAudio()
        task?.finish()
    }

    private func completeRecognition(error: Error?) {
        stopAudioCapture()
        request = nil
        task = nil
        deactivateAudioSession()

        if let error, state != .finishing {
            updateState(.error(error.localizedDescription))
        } else {
            updateState(.idle)
        }
    }

    private func cancelRecognition() {
        stopAudioCapture()
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        deactivateAudioSession()
        updateState(.idle)
    }

    private func stopAudioCapture() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
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

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    private func updateTranscript(_ newTranscript: String) {
        transcript = newTranscript
        onTranscriptChanged?(newTranscript)
    }

    private func updateState(_ newState: State) {
        state = newState
        onStateChanged?(newState)
    }
}

enum SpeechError: LocalizedError {
    case recognizerUnavailable
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return String(
                localized: "Speech recognition is currently unavailable."
            )
        case .permissionDenied:
            return String(
                localized: "Speech recognition permission was denied."
            )
        }
    }
}
