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
    @StateObject private var viewModel = ChatViewModel()
    @ObservedObject var chatStore: ChatStore
    @Binding private var pendingSharedPrompt: String?

    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @State private var showImagePicker = false
    @State private var showImagePlayground = false
    @State private var showSubscriptions = false

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

    init(
        chatStore: ChatStore,
        pendingSharedPrompt: Binding<String?> = .constant(nil)
    ) {
        self.chatStore = chatStore
        self._pendingSharedPrompt = pendingSharedPrompt
    }

    // MARK: - Computed
    private var isImageMode: Bool {
        viewModel.isImageMode
    }

    private var canSend: Bool {
        viewModel.canSend
    }

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
        .imagePlaygroundSheet(isPresented: $showImagePlayground) { _ in }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $viewModel.selectedImage)
        }
        .sheet(isPresented: $showSubscriptions) {
            NavigationStack {
                SubscriptionView()
            }
        }
        .alert(
            viewModel.errorMessage ?? "",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        }
        .onAppear {
            viewModel.updateActivePlan(id: subscriptionManager.activePlanID)
            viewModel.configure(language: language, chatStore: chatStore)
            consumePendingSharedPrompt()
        }
        .onChange(of: subscriptionManager.activePlanID) { _, newPlanID in
            viewModel.updateActivePlan(id: newPlanID)
        }
        .onChange(of: language) { _, newLanguage in
            viewModel.reloadLocalizations(language: newLanguage)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { isInputFocused = false }
        }
        .onChange(of: pendingSharedPrompt) { _, _ in
            consumePendingSharedPrompt()
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
                    ForEach(viewModel.availableModes) { mode in
                        Button {
                            handleModeSelection(mode)
                        } label: {
                            Label(
                                mode.name,
                                systemImage: viewModel.canUseMode(mode)
                                    ? mode.icon
                                    : "lock.fill"
                            )
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(viewModel.selectedMode?.name ?? "Khione")
                            .font(.headline.weight(.semibold))
                        Image(systemName: "chevron.down")
                            .font(.footnote.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(a11yModeLabel)
                .accessibilityHint(a11yModeHint)
                .accessibilityValue(viewModel.selectedMode?.name ?? "Khione")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.startNewChat()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(a11yNewChatLabel)
                .accessibilityHint(a11yNewChatHint)
            }
        }
    }

    // Combines the messages list with an overlayed greeting when appropriate
    private var messagesArea: some View {
        ZStack {
            ChatMessagesView(
                messages: viewModel.messages,
                isProcessing: viewModel.isProcessing,
                thinkingText: viewModel.viewText.thinking,
                messageSpacing: messageSpacing,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                shouldReduceMotion: shouldReduceMotion
            )

            if viewModel.messages.isEmpty && !isInputFocused {
                centerGreeting
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }

    private var centerGreeting: some View {
        CenterGreetingView(
            greeting: viewModel.greeting,
            title: viewModel.greetingTitle(username: username),
            accentColor: themeManager.accentColor,
            compactMode: compactMode,
            largeChatText: largeChatText
        )
        .offset(y: isInputFocused ? -28 : -58)
    }

    // MARK: - Footer Switch
    @ViewBuilder
    private var footerBar: some View {
        if isImageMode {
            imageFooter
        } else {
            chatFooter
        }
    }

    // MARK: - Chat Footer
    private var chatFooter: some View {
        ChatInputBarView(
            inputText: $viewModel.inputText,
            isInputFocused: $isInputFocused,
            placeholder: viewModel.viewText.messagePlaceholder,
            replyStyles: viewModel.replyStyles,
            selectedReplyStyle: viewModel.selectedReplyStyle,
            isProcessing: viewModel.isProcessing,
            canSend: canSend,
            canAttachImages: viewModel.canAttachImages,
            canUseReplyStyles: viewModel.canUseReplyStyles,
            canUseVoiceInput: viewModel.canUseVoiceInput,
            alwaysShowSendButton: alwaysShowSendButton,
            largeChatText: largeChatText,
            colorSchemeContrast: colorSchemeContrast,
            accentColor: themeManager.accentColor,
            isSpeechRecording: viewModel.isSpeechRecording,
            speechIconName: viewModel.speechIconName,
            accessibility: inputAccessibility,
            onAttach: handleAttachImage,
            onReplyStyle: viewModel.setReplyStyle,
            onSpeech: { Task { await viewModel.toggleSpeech() } },
            onUpgrade: { showSubscriptions = true },
            onSend: handleSend,
            onStop: viewModel.cancel
        )
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
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "apple.image.playground")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(themeManager.accentColor)

                Text(viewModel.viewText.imageInfo)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button {
                dismissInput()
                showImagePlayground = true
            } label: {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Circle())
            .accessibilityLabel(viewModel.viewText.openImagePlayground)
            .accessibilityHint(a11yImagePlaygroundHint)
        }
        .padding(.leading, 18)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
    }

    // MARK: - Attachment Preview
    @ViewBuilder
    private var attachmentPreview: some View {
        AttachmentPreviewView(
            image: $viewModel.selectedImage,
            removeLabel: a11yRemoveImageLabel,
            removeHint: a11yRemoveImageHint
        )
    }

    private func handleSend() {
        dismissInput()

        if viewModel.handleSend() == .openImagePlayground {
            showImagePlayground = true
        }
    }

    private func handleModeSelection(_ mode: Mode) {
        if viewModel.canUseMode(mode) {
            viewModel.setMode(mode)
        } else {
            showSubscriptions = true
        }
    }

    private func handleAttachImage() {
        if viewModel.canAttachImages {
            showImagePicker = true
        } else {
            showSubscriptions = true
        }
    }

    private func consumePendingSharedPrompt() {
        guard viewModel.consumePendingSharedPrompt(pendingSharedPrompt) else {
            return
        }
        pendingSharedPrompt = nil
        isInputFocused = true
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

    fileprivate func announceProcessingStatus(_ isProcessing: Bool) {
        UIAccessibility.post(
            notification: .announcement,
            argument: viewModel.processingAnnouncement(isGerman: isGerman)
        )
    }

    fileprivate var inputAccessibility: ChatInputAccessibility {
        ChatInputAccessibility(
            attachmentLabel: a11yAttachmentLabel,
            attachmentHint: a11yAttachmentHint,
            replyStyleLabel: a11yReplyStyleLabel,
            replyStyleHint: a11yReplyStyleHint,
            speechLabel: a11ySpeechLabel,
            speechHint: a11ySpeechHint,
            sendLabel: a11ySendLabel,
            sendHint: a11ySendHint,
            stopLabel: a11yStopLabel,
            stopHint: a11yStopHint,
            messageFieldLabel: a11yMessageFieldLabel,
            messageFieldHint: a11yMessageFieldHint
        )
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
        if viewModel.isSpeechRecording {
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
