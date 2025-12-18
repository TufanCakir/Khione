internal import Combine
import Foundation
import FoundationModels
import UIKit

@MainActor
final class ViewModel: ObservableObject {

    // MARK: - UI State
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isProcessing = false
    @Published var errorMessage: String?

    // MARK: - Modes
    @Published private(set) var modes: [KhioneMode] = Bundle.main
        .loadKhioneModes()
    @Published private(set) var selectedMode: KhioneMode?

    // MARK: - Model
    private let model = SystemLanguageModel.default
    private var session: LanguageModelSession?
    private var currentTask: Task<Void, Never>?

    // MARK: - Init
    init() {
        selectedMode = modes.first
    }

    // MARK: - Mode Handling
    func setMode(_ mode: KhioneMode) {
        guard selectedMode?.id != mode.id else { return }
        selectedMode = mode
        resetSession()
    }

    func setModeByID(_ id: String) {
        guard let mode = modes.first(where: { $0.id == id }) else { return }
        setMode(mode)
    }

    private func resetSession() {
        session = nil
    }

    // MARK: - Public API
    func send(text: String, image: UIImage?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || image != nil else { return }

        cancelCurrentTask()

        appendUserMessage(text: trimmed, image: image)
        isProcessing = true
        errorMessage = nil

        currentTask = Task { [weak self] in
            await self?.generateResponse(
                text: trimmed,
                hasImage: image != nil
            )
        }
    }

    func cancel() {
        cancelCurrentTask()
        isProcessing = false
    }

    private func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }

    // MARK: - Core Logic
    private func generateResponse(text: String, hasImage: Bool) async {
        guard model.isAvailable else {
            handleError("Language model is not available on this device.")
            return
        }

        let prompt = buildPrompt(
            userText: text,
            hasImage: hasImage
        )

        do {
            let activeSession = session ?? LanguageModelSession()
            session = activeSession

            let response = try await activeSession.respond(to: prompt)
            guard !Task.isCancelled else { return }

            appendAssistantMessage(response.content)

        } catch is CancellationError {
            return
        } catch {
            handleError(error.localizedDescription)
        }

        isProcessing = false
    }

    // MARK: - Message Handling
    private func appendUserMessage(text: String, image: UIImage?) {
        messages.append(
            ChatMessage(
                role: .user,
                text: text.isEmpty ? nil : text,
                image: image
            )
        )
    }

    private func appendAssistantMessage(_ text: String) {
        messages.append(
            ChatMessage(
                role: .assistant,
                text: text,
                image: nil
            )
        )
    }

    private func handleError(_ message: String) {
        errorMessage = message
        isProcessing = false
    }

    // MARK: - Prompt Builder
    private func buildPrompt(userText: String, hasImage: Bool) -> String {
        var components: [String] = []

        components.append(systemPrompt())

        if hasImage {
            components.append(imageNotice())
        }

        components.append(userPrompt(userText))

        return components.joined(separator: "\n\n")
    }

    private func systemPrompt() -> String {
        let base = """
            System:
            You are Khione, a high-quality AI assistant.
            Always respond in the same language as the user.
            Be clear, natural and helpful.
            """

        let modePrompt = selectedMode?.systemPrompt ?? ""
        return base + "\n\n" + modePrompt
    }

    private func imageNotice() -> String {
        """
        IMPORTANT:
        You cannot see images.
        If the user refers to an image, clearly say this and ask for a description.
        """
    }

    private func userPrompt(_ text: String) -> String {
        """
        User:
        \(text.isEmpty ? "Hello!" : text)
        """
    }
}
