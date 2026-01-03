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

    @Published var replyStyles: [KhioneReplyStyle] = Bundle.main
        .loadReplyStyles()
    @Published var selectedReplyStyle: KhioneReplyStyle?

    // MARK: - Model
    private let model = SystemLanguageModel.default
    private var currentTask: Task<Void, Never>?

    var onMessagesChanged: (([ChatMessage]) -> Void)?

    init() {
        modes = Bundle.main.loadKhioneModes()
        replyStyles = Bundle.main.loadReplyStyles()
        selectedMode = modes.first
        selectedReplyStyle = replyStyles.first
        onMessagesChanged?(messages)
    }
    var greeting: Greeting {
        GreetingManager.randomGreeting()
    }

    // MARK: - Mode Handling
    func setMode(_ mode: KhioneMode) {
        guard selectedMode?.id != mode.id else { return }
        selectedMode = mode
        reset()
    }

    func setModeByID(_ id: String) {
        guard let mode = modes.first(where: { $0.id == id }) else { return }
        setMode(mode)
    }

    // MARK: - Public API
    func send(text: String, image: UIImage?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeText =
            trimmed.isEmpty && image != nil
            ? "Please describe the image." : trimmed
        guard !safeText.isEmpty else { return }

        cancelCurrentTask()
        appendUserMessage(text: safeText, image: image)
        isProcessing = true

        currentTask = Task { [weak self] in
            await self?.generateResponse()
        }
    }

    func removeGreetingIfNeeded() {
        messages.removeAll { $0.kind == .greeting }
    }

    func loadMessages(_ newMessages: [ChatMessage]) {
        messages = newMessages
    }

    func reset() {
        messages.removeAll()
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
    private func generateResponse() async {
        guard model.isAvailable else {
            handleError("Language model not available.")
            return
        }

        let prompt = buildPrompt()

        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            guard !Task.isCancelled else { return }

            appendAssistantMessage(
                response.content.isEmpty ? "…" : response.content
            )
        } catch {
            handleError(error.localizedDescription)
        }

        isProcessing = false
    }

    // MARK: - Prompt Builder
    private func buildPrompt() -> String {
        var blocks: [String] = []

        blocks.append(systemPrompt())

        let history =
            messages
            .suffix(12)
            .map { $0.text ?? "" }
            .joined(separator: "\n")

        blocks.append(history)

        return blocks.joined(separator: "\n\n")
    }

    private func conversationHistoryWithoutLastUser() -> String {
        messages
            .dropLast()
            .suffix(16)
            .map { msg in
                "\(msg.role == .user ? "User" : "Assistant"):\n\(msg.text ?? "")"
            }
            .joined(separator: "\n\n")
    }

    private func currentUserPrompt() -> String {
        guard let last = messages.last, last.role == .user else { return "" }
        return """
            User:
            \(last.text ?? "")
            """
    }

    private func conversationHistory() -> String {
        messages.suffix(16).map {
            "\( $0.role == .user ? "User" : "Assistant"):\n\($0.text ?? "")"
        }.joined(separator: "\n\n")
    }

    private func systemPrompt() -> String {
        var base = """
            System:
            You are Khione.
            Always reply in the user’s language.
            """

        if let mode = selectedMode?.systemPrompt {
            base += "\n\n" + mode
        }

        if let style = selectedReplyStyle?.prompt {
            base += "\n\nREPLY STYLE:\n" + style
        }

        return base
    }

    // MARK: - Message Handling
    private func appendUserMessage(text: String, image: UIImage?) {
        messages.append(ChatMessage(role: .user, text: text, image: image))
        onMessagesChanged?(messages)
    }

    private func appendAssistantMessage(_ text: String) {
        messages.append(ChatMessage(role: .assistant, text: text))
        onMessagesChanged?(messages)
    }

    private func handleError(_ message: String) {
        errorMessage = message
        isProcessing = false
    }
}
