import Foundation
import FoundationModels
import UIKit
internal import Combine

@MainActor
final class ViewModel: ObservableObject {

    // MARK: - UI State
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isProcessing = false
    @Published var errorMessage: String?

    @Published private(set) var modes: [KhioneMode] = Bundle.main.loadKhioneModes()
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
        selectedMode = mode
        session = nil // reset context
    }

    func setModeByID(_ id: String) {
        guard let mode = KhioneModeRegistry.all.first(where: { $0.id == id }) else {
            return
        }
        setMode(mode)
    }

    // MARK: - Public API
    func send(text: String, image: UIImage?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || image != nil else { return }

        cancel()

        messages.append(
            ChatMessage(
                role: .user,
                text: trimmed.isEmpty ? nil : trimmed,
                image: image
            )
        )

        isProcessing = true
        errorMessage = nil

        currentTask = Task { [weak self] in
            await self?.generate(text: trimmed, hasImage: image != nil)
        }
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isProcessing = false
    }

    // MARK: - Core Logic
    private func generate(text: String, hasImage: Bool) async {
        guard model.isAvailable else {
            errorMessage = "Language model is not available on this device."
            isProcessing = false
            return
        }

        let prompt = buildPrompt(text: text, hasImage: hasImage)

        do {
            let session = session ?? LanguageModelSession()
            self.session = session

            let response = try await session.respond(to: prompt)
            guard !Task.isCancelled else { return }

            messages.append(
                ChatMessage(
                    role: .assistant,
                    text: response.content,
                    image: nil
                )
            )
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    // MARK: - Prompt Builder
    private func buildPrompt(text: String, hasImage: Bool) -> String {
        var prompt = """
        System:
        \(currentSystemPrompt())
        """

        if hasImage {
            prompt += """

            IMPORTANT:
            You cannot see images.
            If the user asks about an image, clearly say this and ask for a description.
            """
        }

        prompt += """

        User:
        \(text.isEmpty ? "Hello!" : text)
        """

        return prompt
    }

    private func currentSystemPrompt() -> String {
        let base = """
        You are Khione, a high-quality AI assistant.
        Always respond in the same language as the user.
        Explain things clearly and naturally.
        """

        return base + "\n\n" + (selectedMode?.systemPrompt ?? "")
    }
}
