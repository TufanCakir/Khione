//
//  ChatViewModel.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

internal import Combine
import Foundation
import FoundationModels
import UIKit

@MainActor
final class ChatViewModel: ObservableObject {

    enum ViewAction {
        case none
        case openImagePlayground
    }

    private enum DefaultsKey {
        static let startMode = "start_mode"
        static let khioneStartMode = "khione_start_mode"
        static let dailyChatCount = "daily_chat_count"
        static let dailyChatDate = "daily_chat_date"
    }

    // MARK: - UI State
    @Published var inputText = ""
    @Published var selectedImage: UIImage?
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isProcessing = false
    @Published private(set) var isSpeechRecording = false
    @Published private(set) var viewText: ViewLocalization
    @Published private(set) var dailyChatCount = 0
    @Published var errorMessage: String?

    // MARK: - Modes
    @Published private(set) var modes: [Mode]
    @Published private(set) var selectedMode: Mode?

    @Published private(set) var replyStyles: [ReplyStyle]
    @Published private(set) var selectedReplyStyle: ReplyStyle?

    // MARK: - Model
    private let subscriptionCatalog = Bundle.main.loadSubscriptionCatalog()
    private let model = SystemLanguageModel.default
    private let speech = SpeechRecognizer()
    private weak var chatStore: ChatStore?
    private var currentTask: Task<Void, Never>?
    private var greetings: [Greeting] = []
    var onMessagesChanged: (([ChatMessage]) -> Void)?

    init() {
        modes = Bundle.main.loadKhioneModes()
        replyStyles = Bundle.main.loadReplyStyles()
        viewText = Bundle.main.loadKhioneViewLocalization()
        selectedMode = modes.first
        selectedReplyStyle = replyStyles.first
        dailyChatCount = Self.loadDailyChatCount()
        speech.onTranscriptChanged = { [weak self] transcript in
            guard let self, self.speech.isRecording else { return }
            self.inputText = transcript
        }
        speech.onStateChanged = { [weak self] state in
            self?.isSpeechRecording = state == .recording
        }
        configure(
            language: Locale.current.language.languageCode?.identifier ?? "en"
        )
    }

    var greeting: Greeting {
        return greetings.first(where: { $0.isValidNow() })
            ?? greetings.first(where: { $0.id == "GENERIC" })
            ?? Greeting.fallback()
    }

    var isImageMode: Bool {
        selectedMode?.id == "image"
    }

    var activePlan: SubscriptionPlan {
        SubscriptionCatalog.activePlan(catalog: subscriptionCatalog)
    }

    var availableModes: [Mode] {
        modes
    }

    func canUseMode(_ mode: Mode) -> Bool {
        switch mode.id {
        case "chat":
            return true
        case "image":
            return activePlan.limits.canUseImageMode
        default:
            return activePlan.kind != .free
        }
    }

    var canUseReplyStyles: Bool {
        activePlan.limits.canUseReplyStyles
    }

    var canUseVoiceInput: Bool {
        activePlan.limits.canUseVoiceInput
    }

    func configure(language: String, chatStore: ChatStore? = nil) {
        if let chatStore {
            self.chatStore = chatStore
            loadMessages(chatStore.activeChat?.messages ?? [])
            onMessagesChanged = { [weak self, weak chatStore] newMessages in
                guard self?.activePlan.limits.historyMessages ?? 0 > 0 else {
                    return
                }

                chatStore?.update(messages: newMessages)
            }
        }

        reloadLocalizations(language: language)
        applyPendingStartMode()
    }

    func reloadLocalizations(language: String) {
        viewText = Bundle.main.loadKhioneViewLocalization(language: language)
        replyStyles = Bundle.main.loadReplyStyles(language: language)
        greetings = Bundle.main.loadGreetings(language: language)

        if let current = selectedReplyStyle,
            let match = replyStyles.first(where: { $0.id == current.id })
        {
            selectedReplyStyle = match
        } else {
            selectedReplyStyle = replyStyles.first
        }

        applyPlanRestrictions()
    }

    // MARK: - Mode Handling
    func setMode(_ mode: Mode) {
        guard selectedMode?.id != mode.id else { return }
        guard canUseMode(mode) else {
            errorMessage = upgradeMessage
            return
        }
        selectedMode = mode
        reset()
    }

    func setModeByID(_ id: String) {
        guard let mode = modes.first(where: { $0.id == id }) else { return }
        setMode(mode)
    }

    func setReplyStyle(_ style: ReplyStyle) {
        guard canUseReplyStyles else {
            errorMessage = upgradeMessage
            return
        }
        guard selectedReplyStyle?.id != style.id else { return }
        selectedReplyStyle = style
    }

    // MARK: - Public API
    var canSend: Bool {
        guard !isProcessing, selectedMode != nil else { return false }
        guard !hasReachedDailyChatLimit else { return false }
        return isImageMode
            || !inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
    }

    var canAttachImages: Bool {
        activePlan.limits.canSendImages
    }

    var speechIconName: String {
        isSpeechRecording ? "stop.fill" : "mic.fill"
    }

    var selectedReplyStyleIcon: String {
        selectedReplyStyle?.icon ?? "wand.and.stars"
    }

    var selectedReplyStyleName: String {
        selectedReplyStyle?.name ?? ""
    }

    func greetingTitle(username: String) -> String {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? greeting.text : "\(greeting.text), \(clean)"
    }

    func startNewChat() {
        chatStore?.createNewChat()
        reset()
        inputText = ""
        selectedImage = nil
    }

    func handleSend() -> ViewAction {
        guard selectedMode != nil else { return .none }
        guard canSend else {
            errorMessage = limitMessage
            return .none
        }

        if isImageMode {
            guard activePlan.limits.canUseImageMode else {
                errorMessage = upgradeMessage
                return .none
            }
            inputText = ""
            return .openImagePlayground
        }

        let allowedImage = activePlan.limits.canSendImages ? selectedImage : nil
        if selectedImage != nil, allowedImage == nil {
            errorMessage = upgradeMessage
        }

        let sentText = send(text: inputText, image: allowedImage)

        if let sentText, chatStore?.activeChat?.title == ChatStore.newChatTitle
        {
            chatStore?.renameActiveChat(to: String(sentText.prefix(32)))
        }

        inputText = ""
        selectedImage = nil
        return .none
    }

    func consumePendingSharedPrompt(_ prompt: String?) -> Bool {
        guard
            let prompt = prompt?.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            !prompt.isEmpty
        else { return false }

        inputText = prompt
        return true
    }

    func processingAnnouncement(isGerman: Bool) -> String {
        if isProcessing {
            return isGerman ? "Khione denkt" : "Khione is thinking"
        }

        return isGerman ? "Antwort erhalten" : "Response received"
    }

    func toggleSpeech() async {
        guard canUseVoiceInput else {
            errorMessage = upgradeMessage
            return
        }

        if speech.isRecording {
            speech.stop()
            return
        }

        guard await speech.requestPermission() else { return }
        try? speech.start()
    }

    func stopSpeechIfNeeded() {
        if speech.isRecording {
            speech.stop()
        }
    }

    @discardableResult
    func send(text: String, image: UIImage?) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeText =
            trimmed.isEmpty && image != nil
            ? "Please describe the image." : trimmed
        guard !safeText.isEmpty else { return nil }

        cancelCurrentTask()
        appendUserMessage(text: safeText, image: image)
        incrementDailyChatCount()
        isProcessing = true

        currentTask = Task { [weak self] in
            await self?.generateResponse()
        }

        return safeText
    }

    func loadMessages(_ newMessages: [ChatMessage]) {
        messages = activePlan.limits.historyMessages > 0 ? newMessages : []
    }

    func reset() {
        messages.removeAll()
        stopSpeechIfNeeded()
    }

    func cancel() {
        cancelCurrentTask()
        isProcessing = false
    }

    func clearError() {
        errorMessage = nil
    }

    private func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }

    private var hasReachedDailyChatLimit: Bool {
        guard let limit = activePlan.limits.dailyChatLimit else { return false }
        return dailyChatCount >= limit
    }

    private var limitMessage: String {
        "Daily chat limit reached."
    }

    private var upgradeMessage: String {
        "Upgrade required for this feature."
    }

    private func incrementDailyChatCount() {
        Self.resetDailyChatCountIfNeeded()
        dailyChatCount += 1
        UserDefaults.standard.set(
            dailyChatCount,
            forKey: DefaultsKey.dailyChatCount
        )
    }

    private static func loadDailyChatCount() -> Int {
        resetDailyChatCountIfNeeded()
        return UserDefaults.standard.integer(forKey: DefaultsKey.dailyChatCount)
    }

    private static func resetDailyChatCountIfNeeded() {
        let today = Calendar.current.startOfDay(for: .now).timeIntervalSince1970
        let stored = UserDefaults.standard.double(
            forKey: DefaultsKey.dailyChatDate
        )

        guard stored != today else { return }

        UserDefaults.standard.set(today, forKey: DefaultsKey.dailyChatDate)
        UserDefaults.standard.set(0, forKey: DefaultsKey.dailyChatCount)
    }

    // MARK: - Core Logic
    private func generateResponse() async {
        defer {
            isProcessing = false
            currentTask = nil
        }

        guard model.isAvailable else {
            errorMessage = "Language model not available."
            return
        }

        let prompt = buildPrompt()

        do {
            let session = LanguageModelSession(
                model: model,
                instructions: buildInstructions()
            )
            let response = try await session.respond(to: prompt)
            guard !Task.isCancelled else { return }

            appendAssistantMessage(
                response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
                    ? "..."
                    : response.content
            )
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Prompt Builder
    private func buildPrompt() -> String {
        let history =
            messages
            .filter { $0.kind == .normal }
            .suffix(10)
            .compactMap(conversationLine)
            .joined(separator: "\n")

        return """
            Continue this conversation. Answer the latest user message.

            \(history)
            """
    }

    private func buildInstructions() -> String {
        [
            baseInstructions,
            selectedMode.map { "Mode:\n\($0.systemPrompt)" },
            canUseReplyStyles
                ? selectedReplyStyle.map { "Reply style:\n\($0.prompt)" }
                : nil,
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
    }

    private var baseInstructions: String {
        """
        You are Khione, an on-device AI assistant.
        Always respond in the user's language.
        Be clear, direct, natural, and concise.
        Do not invent facts or assume missing information.
        Ask one brief clarifying question when required.

        Code requests: be technical and precise; use Markdown code blocks only when useful.
        Problem reports: focus on diagnosis and concrete fixes.
        Explanations: structure the answer step by step when that helps.
        Decisions: compare options and give a clear recommendation.

        You cannot inspect images. If an image matters and the user did not describe it, ask for a short description instead of guessing.
        """
    }

    private func conversationLine(for message: ChatMessage) -> String? {
        guard
            let text = message.text?.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            !text.isEmpty
        else { return nil }

        let role = message.role == .user ? "User" : "Assistant"
        return "\(role): \(text)"
    }

    private func applyPendingStartMode() {
        for key in [DefaultsKey.khioneStartMode, DefaultsKey.startMode] {
            guard let modeID = UserDefaults.standard.string(forKey: key) else {
                continue
            }
            setModeByID(modeID)
            UserDefaults.standard.removeObject(forKey: key)
            return
        }
    }

    private func applyPlanRestrictions() {
        if !canUseReplyStyles {
            selectedReplyStyle = nil
        }

        if let selectedMode,
            !canUseMode(selectedMode)
        {
            self.selectedMode = modes.first { $0.id == "chat" } ?? modes.first
        }
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
}
