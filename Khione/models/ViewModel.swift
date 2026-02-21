//
//  ViewModel.swift
//  Khione
//
//  Created by Tufan Cakir on 21.02.26.
//

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
    @Published private(set) var modes: [Mode] = Bundle.main
        .loadKhioneModes()
    @Published private(set) var selectedMode: Mode?

    @Published var replyStyles: [ReplyStyle] = Bundle.main
        .loadReplyStyles()
    @Published var selectedReplyStyle: ReplyStyle?

    // MARK: - Model
    private let model = SystemLanguageModel.default
    private var currentTask: Task<Void, Never>?
    private var greetings: [Greeting] = []
    var onMessagesChanged: (([ChatMessage]) -> Void)?

    init() {
        modes = Bundle.main.loadKhioneModes()
        replyStyles = Bundle.main.loadReplyStyles()
        selectedMode = modes.first
        selectedReplyStyle = replyStyles.first
        reloadLocalizations(
            language:
                Locale.current.language.languageCode?.identifier ?? "en"
        )
        if let modeID = UserDefaults.standard.string(
            forKey: "start_mode"
        ),
            let mode = modes.first(where: { $0.id == modeID })
        {
            selectedMode = mode
            UserDefaults.standard.removeObject(forKey: "start_mode")
        }
    }

    var greeting: Greeting {

        greetings.first(where: {

            $0.isValidNow()

        }) ?? Greeting.fallback()
    }

    func reloadLocalizations(language: String) {

        replyStyles =
            Bundle.main.loadReplyStyles(
                language: language
            )

        greetings =
            Bundle.main.loadGreetings(
                language: language
            )

        if let current = selectedReplyStyle,
            let match = replyStyles.first(where: {

                $0.id == current.id

            })
        {

            selectedReplyStyle = match

        } else {

            selectedReplyStyle = replyStyles.first
        }
    }

    // MARK: - Mode Handling
    func setMode(_ mode: Mode) {
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
            .suffix(10)
            .compactMap { $0.text }
            .joined(separator: "\n---\n")

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
            You are Taenttra, an on-device AI assistant.
            You run locally and are optimized for speed, privacy, and clarity.
            Always respond in the user's language.

            Core principles:
            - Be clear, direct, and natural.
            - Avoid marketing language and generic phrases.
            - Explain only what is necessary.
            - Prefer simple words over complex terms.
            - If something is uncertain, say so clearly.

            Behavior rules:
            - If the user asks for code, respond technically and precisely.
            - Provide code only when relevant.
            - Always format code using Markdown code blocks.
            - If the user describes a problem or error, focus on diagnosis and concrete fixes.
            - If the user asks for an explanation, explain step by step.
            - If the user asks for a decision, compare options and give a clear recommendation.
            - If the user asks creatively, allow flexible and original thinking.

            Accessibility:
            - If the user appears to need simple language or assistance, use short sentences.
            - Keep structure clear and calm.
            - Avoid unnecessary complexity.

            Constraints:
            - Do not invent facts.
            - Do not assume missing information.
            - Ask a brief clarifying question if required.

            Vision limitations:
            - You cannot see or interpret images.
            - If an image is attached, you only receive text provided by the user.
            - Never describe visual details unless the user explicitly describes them in text.
            - If an image is relevant and not described, ask the user to describe it briefly.
            - Do not guess or assume image content.

            """

        if let mode = selectedMode?.systemPrompt {
            base += "\nMODE:\n" + mode
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
