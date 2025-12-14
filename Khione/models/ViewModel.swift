import Foundation
import FoundationModels
internal import Combine
import UIKit

@MainActor
final class ViewModel: ObservableObject {
    
    // MARK: - UI State
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    @Published var modes: [KhioneMode] = Bundle.main.loadKhioneModes()
    @Published var selectedMode: KhioneMode?
    
    // MARK: - Model
    private let model = SystemLanguageModel.default
    private var session: LanguageModelSession?
    private var currentTask: Task<Void, Never>?
    private var userMessageCountToday: Int {
        messages.filter { $0.role == .user }.count
    }

    init() {
        selectedMode = modes.first
    }
    
    // MARK: - Public API
    func send(text: String, image: UIImage?) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || image != nil else {
            return
        }

        currentTask?.cancel()

        messages.append(
            ChatMessage(
                role: .user,
                text: text.isEmpty ? nil : text,
                image: image
            )
        )

        currentTask = Task {
            await generate(
                text: text,
                hasImage: image != nil
            )
        }
    }


 


    
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        isProcessing = false
    }
    
    func setMode(_ mode: KhioneMode) {
        selectedMode = mode
        session = nil
    }
    
    // MARK: - Core Logic
    private func generate(text: String, hasImage: Bool) async {
        guard model.isAvailable else {
            errorMessage = "Language model is not available on this device."
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        errorMessage = nil

        let finalPrompt = buildPrompt(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            hasImage: hasImage
        )

        do {
            let session = session ?? LanguageModelSession()
            self.session = session

            let response = try await session.respond(to: finalPrompt)
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
    }


    
    // MARK: - Prompt Builder
    private func buildPrompt(text: String, hasImage: Bool) -> String {
        var prompt = """
        System: \(currentSystemPrompt())
        """

        if hasImage {
            prompt += """

            IMPORTANT:
            You cannot see images.
            If the user asks about an image, clearly say this and ask for a description.
            """
        }

        prompt += """

        User: \(text.isEmpty ? "Hello!" : text)
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
