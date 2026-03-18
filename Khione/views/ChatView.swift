//
//  ChatView.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import ImagePlayground
import SwiftUI

struct ChatView: View {

    // MARK: - State & Environment
    @StateObject private var viewModel = ViewModel()
    @StateObject private var speech = SpeechRecognizer()
    @ObservedObject var chatStore: ChatStore

    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var inputText = ""
    @State private var selectedImage: UIImage?

    @State private var showImagePicker = false
    @State private var showImagePlayground = false

    @FocusState private var isInputFocused: Bool
    @AppStorage("username") private var username = ""

    @AppStorage("language")
    private var language =
        Locale.current.language.languageCode?.identifier ?? "en"

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

            VStack(spacing: 16) {
                messagesArea
                attachmentPreview
                footerBar
                    .padding()
            }
            .contentShape(Rectangle())
            .onTapGesture { dismissInput() }
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
            withAnimation { viewModel.removeGreetingIfNeeded() }
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
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        ChatBubbleView(message: message).id(message.id)
                    }

                    if viewModel.isProcessing {
                        ProgressView(text.thinking).padding(.top).id("typing")
                    }
                }
                .padding()
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

        return VStack(spacing: 16) {

            Image(systemName: greeting.sfSymbol ?? "snowflake")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(themeManager.accentColor)
                .transition(.scale.combined(with: .opacity))

            Text(title)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
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
        VStack(spacing: 8) {

            // 🔹 INPUT + SEND
            ZStack(alignment: .bottomTrailing) {

                TextField(
                    text.messagePlaceholder,
                    text: $inputText,
                    axis: .vertical
                )
                .focused($isInputFocused)
                .lineLimit(1...5)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )

                if viewModel.isProcessing {
                    stopButton
                        .padding(8)
                } else if canSend {
                    Button(action: handleSend) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 30, height: 30)
                            .background(.white)
                            .foregroundColor(.black)
                            .clipShape(Circle())
                    }
                    .padding(10)
                    .transition(.scale.combined(with: .opacity))
                }
            }

            // 🔹 TOOL ROW (JETZT DIREKT DRUNTER)
            HStack(spacing: 12) {
                attachmentButton
                replyStyleButton
                speechButton
                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
        

    private func iconButton(_ system: String) -> some View {
        Image(systemName: system)
            .foregroundStyle(.white) 
    }

    private var replyStyleButton: some View {
        Menu {
            ForEach(viewModel.replyStyles) { style in
                Button {
                    viewModel.selectedReplyStyle = style
                } label: {
                    HStack(spacing: 16) {
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
            VStack(spacing: 16) {
                Image(systemName: "apple.image.playground")
                    .font(.system(size: 44))
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
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal)
    }

    // MARK: - Buttons
    private var attachmentButton: some View {
        Button {
            showImagePicker = true
        } label: {
            iconButton("plus")
        }
    }

    private var sendButton: some View {
        Button(action: handleSend) {
            Image(systemName: "arrow.up")
                .font(.title3)
                .contentShape(Rectangle())

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
                .contentShape(Rectangle())
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
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal)
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
            withAnimation(.easeOut(duration: 0.25)) {
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
    PreviewRoot {
        NavigationStack {
            ChatView(chatStore: ChatStore())
        }
    }
}
