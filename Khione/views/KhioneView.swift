//
//  KhioneView.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import ImagePlayground
import StoreKit
import SwiftUI

struct KhioneView: View {

    // MARK: - State & Environment
    @StateObject private var viewModel = ViewModel()
    @StateObject private var speech = SpeechRecognizer()
    @ObservedObject var chatStore: ChatStore

    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var inputText = ""
    @State private var selectedImage: UIImage?

    @State private var showUpgradeSheet = false
    @State private var showImagePicker = false
    @State private var showImagePlayground = false

    @FocusState private var isInputFocused: Bool
    @AppStorage("khione_username") private var username = ""

    @AppStorage("khione_language")
    private var language =
        Locale.current.language.languageCode?.identifier ?? "en"

    private var text: KhioneViewLocalization {
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

    private var showInlineLimitHint: Bool {
        subscription.tier == .free && subscription.remainingMessagesToday == 0
            && !viewModel.isProcessing
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                messagesArea
                attachmentPreview
            }
            .contentShape(Rectangle())
            .onTapGesture { dismissInput() }
            .safeAreaInset(edge: .bottom) {
                footerBar
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .padding()
            }
            .animation(
                .spring(response: 0.3, dampingFraction: 0.8),
                value: canSend
            )
        }
        .toolbar { toolbarContent }
        .imagePlaygroundSheet(isPresented: $showImagePlayground) { url in
            print("Image Playground result:", url)
        }
        .sheet(isPresented: $showImagePicker) {
            if subscription.canUseVision {
                ImagePicker(image: $selectedImage)
            }
        }
        .onChange(of: speech.transcript) { _, newValue in
            if speech.isRecording { inputText = newValue }
        }
        .onAppear {
            if viewModel.selectedMode == nil,
                let first = KhioneModeRegistry.all.first
            {
                viewModel.setMode(first)
            }

            if let modeID = UserDefaults.standard.string(
                forKey: "khione_start_mode"
            ) {
                viewModel.setModeByID(modeID)
                UserDefaults.standard.removeObject(forKey: "khione_start_mode")
            }
        }
        .onDisappear { dismissInput(animated: false) }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { isInputFocused = false }
        }
        .sheet(isPresented: $showUpgradeSheet) {
            SubscriptionView()
        }
        .onChange(of: chatStore.activeID) { _, _ in
            viewModel.reset()
            viewModel.loadMessages(chatStore.activeChat?.messages ?? [])
        }
        .onChange(of: inputText) { _, newValue in
            withAnimation {
                viewModel.removeGreetingIfNeeded()
            }
        }
        .onAppear {
            viewModel.onMessagesChanged = { newMessages in
                chatStore.update(messages: newMessages)
            }
        }
    }

    // MARK: - Toolbar
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(subscription.allowedModes()) { mode in
                        Button {
                            viewModel.setMode(mode)
                        } label: {
                            Label(mode.name, systemImage: mode.icon)
                        }
                    }
                } label: {
                    HStack(alignment: .bottom, spacing: 10) {
                        Text(viewModel.selectedMode?.name ?? "Khione").font(
                            .headline
                        )
                        Image(systemName: "chevron.down").font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    chatStore.createNewChat()
                    viewModel.reset()
                    inputText = ""
                } label: {
                    Image(systemName: "plus")
                }
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
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        ChatBubbleView(message: message).id(message.id)
                    }

                    if viewModel.isProcessing {
                        ProgressView(text.thinking).padding(.top).id("typing")
                    }
                }
                .padding(.vertical)
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
        let greetings = Bundle.main.loadGreetings()
        return greetings.first(where: { $0.isValidNow() })
            ?? Greeting.fallback()
    }

    private var centerGreeting: some View {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let greeting = currentGreeting

        let title =
            clean.isEmpty
            ? greeting.text
            : String(format: text.welcomeWithName, clean)

        return VStack(spacing: 16) {

            Image(systemName: greeting.sfSymbol ?? "snowflake")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(themeManager.accentColor)
                .shadow(
                    color: themeManager.accentColor.opacity(0.35),
                    radius: 14
                )
                .transition(.scale.combined(with: .opacity))

            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
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
        }
    }

    // MARK: - Chat Footer
    private var chatFooter: some View {
        VStack(spacing: 8) {

            // INPUT ROW
            HStack(alignment: .bottom, spacing: 8) {

                TextField(
                    text.messagePlaceholder,
                    text: $inputText,
                    axis: .vertical
                )
                .focused($isInputFocused)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(.white.opacity(0.06))
                )
                .opacity(showInlineLimitHint ? 0.35 : 1)
                .disabled(showInlineLimitHint)

                actionButton
            }

            // TOOL ROW
            HStack(spacing: 18) {
                attachmentButton
                replyStyleButton
                speechButton
                Spacer()
            }
            .padding(.horizontal, 6)

            // LIMIT HINT
            if showInlineLimitHint {
                inlineLimitHint
                    .font(.footnote)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func iconButton(_ system: String) -> some View {
        Image(systemName: system)
            .symbolRenderingMode(.hierarchical)
            .font(.title3)
            .foregroundStyle(themeManager.accentColor)  // ← 💎 Theme hier!
            .frame(width: 36, height: 36)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var replyStyleButton: some View {
        Menu {
            ForEach(viewModel.replyStyles) { style in
                Button {
                    viewModel.selectedReplyStyle = style
                } label: {
                    HStack(spacing: 10) {
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
    }

    private var inlineLimitHint: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(
                subscription.nextRefillDate.timeIntervalSince(context.date),
                0
            )
            Text(String(format: text.nextMessageIn, formatInline(remaining)))
                .font(.footnote.weight(.medium))
                .foregroundColor(.secondary)
        }
    }

    private func formatInline(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(format: "%02dm %02ds", m, s)
    }

    private func dismissInput(animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) { isInputFocused = false }
        } else {
            isInputFocused = false
        }

        DispatchQueue.main.async {
            UIApplication.shared.dismissKeyboard()
        }
    }

    // MARK: - Image Footer
    private var imageFooter: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Image(systemName: "photo.artframe")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)

                Text(text.imageInfo)
                    .font(.footnote)
                    .foregroundColor(.secondary)
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
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding()
    }

    // MARK: - Buttons
    private var attachmentButton: some View {
        Button {
            subscription.canUseVision
                ? (showImagePicker = true) : (showUpgradeSheet = true)
        } label: {
            iconButton("plus")
        }
        .disabled(!subscription.canUseVision)
        .opacity(subscription.canUseVision ? 1 : 0.35)
    }

    private var sendButton: some View {
        Button(action: handleSend) {
            Image(systemName: "arrow.up")
                .font(.title3)
                .frame(width: 36, height: 36)

        }
        .buttonStyle(.borderedProminent)
        .disabled(!canSend)
    }

    private var stopButton: some View {
        Button {
            viewModel.cancel()
        } label: {
            Image(systemName: "xmark")
                .font(.title3)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.bordered)
        .tint(.red)
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
        .animatedRainbowBorder(
            active: speech.isRecording,
            lineWidth: 2,
            radius: 14
        )
        .onChange(of: viewModel.selectedMode?.id) { _, _ in
            if speech.isRecording { speech.stop() }
        }
    }

    // MARK: - Attachment Preview
    @ViewBuilder
    private var attachmentPreview: some View {
        if subscription.canUseVision, let image = selectedImage {
            HStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    selectedImage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
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

        guard subscription.canSendMessage else {
            showUpgradeSheet = true
            return
        }

        viewModel.send(text: inputText, image: selectedImage)
        subscription.consumeMessageIfNeeded()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            chatStore.update(messages: viewModel.messages)
        }

        if chatStore.activeChat?.title == "New Chat" {
            chatStore.renameActiveChat(to: String(inputText.prefix(32)))
        }

        inputText = ""
        selectedImage = nil
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = viewModel.messages.last {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
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
    KhionePreviewRoot {
        NavigationStack {
            KhioneView(chatStore: ChatStore())
        }
    }
}
