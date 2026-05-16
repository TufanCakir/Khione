//
//  ChatView.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import ImagePlayground
import SwiftUI
import UIKit

struct ChatView: View {

    // MARK: - State & Environment
    @StateObject private var viewModel = ViewModel()
    @StateObject private var speech = SpeechRecognizer()
    @ObservedObject var chatStore: ChatStore

    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @State private var inputText = ""
    @State private var selectedImage: UIImage?

    @State private var showImagePicker = false
    @State private var showImagePlayground = false

    @FocusState private var isInputFocused: Bool
    @AppStorage("username") private var username = ""

    @AppStorage("language")
    private var language =
        Locale.current.language.languageCode?.identifier ?? "en"
    @AppStorage("accessibilityCompactMode") private var compactMode = true
    @AppStorage("accessibilityLargeChatText") private var largeChatText = false
    @AppStorage("accessibilityReduceAnimations")
    private var reduceAnimations = false
    @AppStorage("accessibilityAlwaysShowSendButton")
    private var alwaysShowSendButton = false

    private var text: ViewLocalization {
        Bundle.main.loadKhioneViewLocalization(language: language)
    }

    // MARK: - Computed
    private var isImageMode: Bool {
        viewModel.selectedMode?.id == "image"
    }

    private var canSend: Bool {
        guard !viewModel.isProcessing,
            let mode = viewModel.selectedMode
        else { return false }
        if mode.id == "image" { return true }
        return !inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    private var showInlineLimitHint: Bool { false }

    // MARK: - Body
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()

            Color.white.opacity(0.02).ignoresSafeArea()

            VStack(spacing: mainSpacing) {
                messagesArea
                attachmentPreview
                footerBar
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, bottomPadding)
            }
            .contentShape(Rectangle())
            .onTapGesture { dismissInput() }
            .animation(
                shouldReduceMotion
                    ? nil
                    : .spring(response: 0.3, dampingFraction: 0.8),
                value: canSend
            )
        }
        .toolbar { toolbarContent }
        .imagePlaygroundSheet(isPresented: $showImagePlayground) { url in
            print("Image Playground result:", url)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: speech.transcript) { _, newValue in
            if speech.isRecording { inputText = newValue }
        }
        .onAppear {
            // Mode init (einmal)
            if viewModel.selectedMode == nil,
                let first = ModeRegistry.all.first
            {
                viewModel.setMode(first)
            }

            // Start mode override
            if let modeID = UserDefaults.standard.string(
                forKey: "khione_start_mode"
            ) {
                viewModel.setModeByID(modeID)
                UserDefaults.standard.removeObject(forKey: "khione_start_mode")
            }

            // Messages laden
            viewModel.loadMessages(chatStore.activeChat?.messages ?? [])

            // ReplyStyles initial passend zur Sprache laden
            viewModel.reloadLocalizations(language: language)

            // Persist messages
            viewModel.onMessagesChanged = { newMessages in
                chatStore.update(messages: newMessages)
            }
        }
        .onChange(of: inputText) { _, _ in
            withOptionalAnimation {
                viewModel.removeGreetingIfNeeded()
            }
        }
        .onChange(of: language) { _, newLanguage in
            viewModel.reloadLocalizations(language: newLanguage)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { isInputFocused = false }
        }
        .onChange(of: speech.transcript) { _, newValue in
            if speech.isRecording { inputText = newValue }
        }
        .onChange(of: viewModel.isProcessing) { _, isProcessing in
            announceProcessingStatus(isProcessing)
        }
        .onDisappear {
            dismissInput(animated: false)
        }
    }

    // MARK: - Toolbar
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(ModeRegistry.all) { mode in
                        Button {
                            viewModel.setMode(mode)
                        } label: {
                            Label(mode.name, systemImage: mode.icon)
                        }
                    }
                } label: {
                    HStack(alignment: .bottom, spacing: 16) {
                        Text(viewModel.selectedMode?.name ?? "Khione").font(
                            .headline
                        )
                        Image(systemName: "chevron.down").font(.caption)
                    }
                }
                .accessibilityLabel(a11yModeLabel)
                .accessibilityHint(a11yModeHint)
                .accessibilityValue(viewModel.selectedMode?.name ?? "Khione")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    chatStore.createNewChat()
                    viewModel.reset()
                    inputText = ""
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(a11yNewChatLabel)
                .accessibilityHint(a11yNewChatHint)
            }
        }
    }

    // Combines the messages list with an overlayed greeting when appropriate
    private var messagesArea: some View {
        ZStack {
            messagesList

            if viewModel.messages.isEmpty && !isInputFocused {
                centerGreeting
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }

    // MARK: - Messages
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: messageSpacing) {
                    ForEach(viewModel.messages) { message in
                        ChatBubbleView(message: message).id(message.id)
                    }

                    if viewModel.isProcessing {
                        ProgressView(text.thinking)
                            .padding(.top, 6)
                            .id("typing")
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: viewModel.isProcessing) { _, _ in
                scrollToBottom(proxy)
            }
        }
    }

    private var currentGreeting: Greeting {

        let greetings =
            Bundle.main.loadGreetings(
                language: language
            )

        return greetings.first(where: { $0.isValidNow() })
            ?? greetings.first(where: { $0.id == "GENERIC" })
            ?? Greeting.fallback()
    }

    private var centerGreeting: some View {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let greeting = viewModel.greeting

        let title =
            clean.isEmpty
            ? greeting.text
            : "\(greeting.text), \(clean)"

        return VStack(spacing: compactMode ? 10 : 14) {

            Image(systemName: greeting.sfSymbol ?? "snowflake")
                .font(
                    .system(
                        size: largeChatText ? 30 : 26,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .foregroundStyle(themeManager.accentColor)
                .transition(.scale.combined(with: .opacity))

            Text(title)
                .font(
                    .system(
                        size: largeChatText ? 30 : 26,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .foregroundStyle(themeManager.accentColor)
        }
    }

    // MARK: - Footer Switch
    @ViewBuilder
    private var footerBar: some View {
        isImageMode ? AnyView(imageFooter) : AnyView(chatFooter)
    }

    @ViewBuilder
    private var actionButton: some View {
        if viewModel.isProcessing {
            stopButton
        } else if canSend {
            sendButton
                .transition(.scale.combined(with: .opacity))
                .padding(.horizontal)
        }
    }

    // MARK: - Chat Footer
    private var chatFooter: some View {
        VStack(spacing: compactMode ? 6 : 10) {

            ZStack(alignment: .bottomTrailing) {

                TextField(
                    text.messagePlaceholder,
                    text: $inputText,
                    axis: .vertical
                )
                .focused($isInputFocused)
                .accessibilityLabel(a11yMessageFieldLabel)
                .accessibilityHint(a11yMessageFieldHint)
                .lineLimit(1...4)
                .font(largeChatText ? .title3 : .body)
                .padding(.vertical, compactMode ? 10 : 12)
                .padding(.leading, compactMode ? 12 : 14)
                .padding(.trailing, 46)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                )

                if viewModel.isProcessing {
                    stopButton
                        .padding(6)
                } else if canSend || alwaysShowSendButton {
                    Button(action: handleSend) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 28, height: 28)
                            .background(sendButtonBackground)
                            .foregroundColor(sendButtonForeground)
                            .clipShape(Circle())
                    }
                    .frame(width: 44, height: 44)
                    .disabled(!canSend)
                    .accessibilityLabel(a11ySendLabel)
                    .accessibilityHint(a11ySendHint)
                    .transition(.scale.combined(with: .opacity))
                }
            }

            HStack(spacing: compactMode ? 8 : 12) {
                attachmentButton
                replyStyleButton
                speechButton
                Spacer()
            }
            .padding(.horizontal, 2)
        }
        .padding(compactMode ? 10 : 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    private func iconButton(_ system: String) -> some View {
        Image(systemName: system)
            .font(.system(size: 15, weight: .semibold))
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }

    private var replyStyleButton: some View {
        Menu {
            ForEach(viewModel.replyStyles) { style in
                Button {
                    viewModel.selectedReplyStyle = style
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: style.icon)
                            .foregroundStyle(
                                viewModel.selectedReplyStyle?.id == style.id
                                    ? themeManager.accentColor
                                    : .secondary
                            )

                        Text(style.name)
                    }
                }
            }
        } label: {
            iconButton(viewModel.selectedReplyStyle?.icon ?? "wand.and.stars")
        }
        .accessibilityLabel(a11yReplyStyleLabel)
        .accessibilityHint(a11yReplyStyleHint)
        .accessibilityValue(viewModel.selectedReplyStyle?.name ?? "")
    }

    private func formatInline(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(format: "%02dm %02ds", m, s)
    }

    private func dismissInput(animated: Bool = true) {
        if animated {
            withAnimation(shouldReduceMotion ? nil : .easeOut(duration: 0.2)) {
                isInputFocused = false
            }
        } else {
            isInputFocused = false
        }

        DispatchQueue.main.async {
            UIApplication.shared.dismissKeyboard()
        }
    }

    // MARK: - Image Footer
    private var imageFooter: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Image(systemName: "apple.image.playground")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Text(text.imageInfo)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                dismissInput()
                showImagePlayground = true
            } label: {
                Label(
                    text.openImagePlayground,
                    systemImage: "apple.image.playground"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint(a11yImagePlaygroundHint)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
    }

    // MARK: - Buttons
    private var attachmentButton: some View {
        Button {
            showImagePicker = true
        } label: {
            iconButton("plus")
        }
        .accessibilityLabel(a11yAttachmentLabel)
        .accessibilityHint(a11yAttachmentHint)
    }

    private var sendButton: some View {
        Button(action: handleSend) {
            Image(systemName: "arrow.up")
                .font(.title3)
                .contentShape(Rectangle())

        }
        .buttonStyle(.borderedProminent)
        .disabled(!canSend)
        .accessibilityLabel(a11ySendLabel)
        .accessibilityHint(a11ySendHint)
    }

    private var stopButton: some View {
        Button {
            viewModel.cancel()
        } label: {
            Image(systemName: "xmark")
                .font(.title3)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .accessibilityLabel(a11yStopLabel)
        .accessibilityHint(a11yStopHint)
    }

    private var speechButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            if speech.isRecording {
                speech.stop()
            } else {
                Task {
                    if await speech.requestPermission() {
                        try? speech.start()
                    }
                }
            }
        } label: {
            iconButton(speech.isRecording ? "stop.fill" : "mic.fill")
                .foregroundStyle(speech.isRecording ? .red : .primary)
        }
        .accessibilityLabel(a11ySpeechLabel)
        .accessibilityHint(a11ySpeechHint)
        .onChange(of: viewModel.selectedMode?.id) { _, _ in
            if speech.isRecording { speech.stop() }
        }
    }

    // MARK: - Attachment Preview
    @ViewBuilder
    private var attachmentPreview: some View {
        if let image = selectedImage {
            HStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    selectedImage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel(a11yRemoveImageLabel)
                .accessibilityHint(a11yRemoveImageHint)

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Logic
    private func handleSend() {
        guard let mode = viewModel.selectedMode else { return }

        dismissInput()

        if mode.id == "image" {
            showImagePlayground = true
            inputText = ""
            return
        }

        viewModel.send(text: inputText, image: selectedImage)

        if chatStore.activeChat?.title == "New Chat" {
            chatStore.renameActiveChat(to: String(inputText.prefix(32)))
        }

        inputText = ""
        selectedImage = nil
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = viewModel.messages.last {
            withAnimation(shouldReduceMotion ? nil : .easeOut(duration: 0.25)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

extension ChatView {

    fileprivate var isGerman: Bool { language == "de" }

    fileprivate var shouldReduceMotion: Bool {
        reduceMotion || reduceAnimations
    }

    fileprivate var mainSpacing: CGFloat {
        compactMode ? 8 : 14
    }

    fileprivate var messageSpacing: CGFloat {
        compactMode ? 10 : 14
    }

    fileprivate var horizontalPadding: CGFloat {
        compactMode ? 12 : 16
    }

    fileprivate var verticalPadding: CGFloat {
        compactMode ? 8 : 12
    }

    fileprivate var bottomPadding: CGFloat {
        compactMode ? 8 : 12
    }

    fileprivate var sendButtonBackground: Color {
        if !canSend {
            return Color.secondary.opacity(0.25)
        }

        return colorSchemeContrast == .increased ? .primary : .white
    }

    fileprivate var sendButtonForeground: Color {
        if !canSend {
            return .secondary
        }

        return colorSchemeContrast == .increased
            ? Color(.systemBackground)
            : .black
    }

    fileprivate func withOptionalAnimation(_ updates: () -> Void) {
        if shouldReduceMotion {
            updates()
        } else {
            withAnimation {
                updates()
            }
        }
    }

    fileprivate func announceProcessingStatus(_ isProcessing: Bool) {
        let message: String

        if isProcessing {
            message = isGerman ? "Khione denkt" : "Khione is thinking"
        } else {
            message = isGerman ? "Antwort erhalten" : "Response received"
        }

        UIAccessibility.post(notification: .announcement, argument: message)
    }

    fileprivate var a11yModeLabel: String {
        isGerman ? "Modus auswählen" : "Choose mode"
    }

    fileprivate var a11yModeHint: String {
        isGerman
            ? "Ändert den Modus für die nächste Nachricht."
            : "Changes the mode for the next message."
    }

    fileprivate var a11yNewChatLabel: String {
        isGerman ? "Neuer Chat" : "New chat"
    }

    fileprivate var a11yNewChatHint: String {
        isGerman
            ? "Startet eine neue Unterhaltung."
            : "Starts a new conversation."
    }

    fileprivate var a11ySendLabel: String {
        isGerman ? "Nachricht senden" : "Send message"
    }

    fileprivate var a11yMessageFieldLabel: String {
        isGerman ? "Nachricht" : "Message"
    }

    fileprivate var a11yMessageFieldHint: String {
        isGerman
            ? "Gib eine Nachricht an Khione ein."
            : "Enter a message for Khione."
    }

    fileprivate var a11ySendHint: String {
        isGerman
            ? "Sendet deine aktuelle Eingabe an Khione."
            : "Sends your current input to Khione."
    }

    fileprivate var a11yStopLabel: String {
        isGerman ? "Antwort stoppen" : "Stop response"
    }

    fileprivate var a11yStopHint: String {
        isGerman
            ? "Bricht die laufende Antwort ab."
            : "Cancels the current response."
    }

    fileprivate var a11yAttachmentLabel: String {
        isGerman ? "Bild anhängen" : "Attach image"
    }

    fileprivate var a11yAttachmentHint: String {
        isGerman
            ? "Öffnet die Bildauswahl."
            : "Opens the image picker."
    }

    fileprivate var a11yReplyStyleLabel: String {
        isGerman ? "Antwortstil auswählen" : "Choose reply style"
    }

    fileprivate var a11yReplyStyleHint: String {
        isGerman
            ? "Ändert den Ton der Antwort."
            : "Changes the tone of the response."
    }

    fileprivate var a11ySpeechLabel: String {
        if speech.isRecording {
            return isGerman ? "Spracheingabe stoppen" : "Stop dictation"
        }

        return isGerman ? "Spracheingabe starten" : "Start dictation"
    }

    fileprivate var a11ySpeechHint: String {
        isGerman
            ? "Startet oder stoppt die Spracheingabe."
            : "Starts or stops voice input."
    }

    fileprivate var a11yImagePlaygroundHint: String {
        isGerman
            ? "Öffnet Apple Image Playground für Bilder."
            : "Opens Apple Image Playground for images."
    }

    fileprivate var a11yRemoveImageLabel: String {
        isGerman ? "Bild entfernen" : "Remove image"
    }

    fileprivate var a11yRemoveImageHint: String {
        isGerman
            ? "Entfernt das angehängte Bild aus der Nachricht."
            : "Removes the attached image from the message."
    }
}

// MARK: - RefillCountdownView

struct RefillCountdownView: View {
    let nextRefillDate: Date
    let localizedTemplate: String

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(
                nextRefillDate.timeIntervalSince(context.date),
                0
            )
            Text(String(format: localizedTemplate, format(remaining)))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func format(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
        } else {
            return String(format: "%02dm %02ds", minutes, seconds)
        }
    }
}

extension UIApplication {
    func dismissKeyboard() {
        sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

#Preview {
    PreviewRoot {
        NavigationStack {
            ChatView(chatStore: ChatStore())
        }
    }
}
