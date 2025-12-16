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
    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showUpgradeSheet = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var inputText = ""

    @FocusState private var isInputFocused: Bool
    @State private var showImagePlayground = false
    @State private var imagePromptCache: String = ""
    @StateObject private var speech = SpeechRecognizer()
    @State private var isListening = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                themeBackground

                // Main content
                VStack(spacing: 0) {
                    // Place your chat view content here
                    chatView
                }
            }
            .toolbar {
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
                        HStack(spacing: 6) {
                            Text(viewModel.selectedMode?.name ?? "Khione")
                                .font(.headline)
                                .accessibilityLabel("Modus auswählen")
                                .accessibilityHint(
                                    "Tippe, um den Chat-Modus zu wechseln"
                                )

                            if viewModel.modes.count > 1 {
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AccountView()
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
        .imagePlaygroundSheet(
            isPresented: $showImagePlayground,
            onCompletion: { _ in
                // Optional: Result speichern / ignorieren
            }
        )
        .sheet(isPresented: $showImagePicker) {
            if subscription.canUseVision {
                ImagePicker(image: $selectedImage)
            }
        }
        .onChange(of: speech.transcript) { _, newValue in
            if isListening {
                inputText = newValue
            }
        }

        .onAppear {
            if viewModel.selectedMode == nil {
                viewModel.setMode(KhioneModeRegistry.all.first!)
            }
        }
    }

    // MARK: - Background
    private var themeBackground: some View {
        themeManager.backgroundColor.ignoresSafeArea()
    }

    // MARK: - Chat View
    private var chatView: some View {
        VStack(spacing: 0) {

            messagesList

            attachmentPreview
            statusHintBar
            footerBar
        }
    }

    // MARK: - Messages
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }

                    if viewModel.isProcessing {
                        ProgressView("Khione is thinking…")
                            .padding(.top)
                            .id("typing")
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

    private func autoSendIfPossible() {
        guard canSend else { return }
        handleSend()
    }

    private var isImageMode: Bool {
        viewModel.selectedMode?.id == "image"
    }

    private var imageFooter: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                isInputFocused = false
                showImagePlayground = true
            } label: {
                Label("Image Playground öffnen", systemImage: "photo.artframe")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private var chatFooter: some View {
        HStack(spacing: 10) {

            attachmentButton

            speechButton
                .disabled(viewModel.isProcessing)
                .animatedRainbowBorder(
                    active: isListening,
                    lineWidth: 2,
                    radius: 14
                )

            TextField(
                "Message Khione…",
                text: $inputText,
                prompt: Text("Message Khione…"),
                axis: .vertical
            )
            .focused($isInputFocused)
            .lineLimit(1...4)
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .animation(.easeOut(duration: 0.2), value: isInputFocused)

            if viewModel.isProcessing {
                stopButton
            } else {
                sendButton
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var speechButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()

            if isListening {
                // 🛑 Stop listening
                speech.stop()
            } else {
                // 🎙 Start listening
                Task {
                    let allowed = await speech.requestPermission()
                    guard allowed else { return }

                    do {
                        try speech.start()
                        isListening = true
                    } catch {
                        print("Speech start failed:", error)
                    }
                }
            }
        } label: {
            Image(systemName: isListening ? "stop.fill" : "mic.fill")
                .font(.title3)
                .foregroundStyle(isListening ? .red : .primary)
        }
        .accessibilityLabel(
            isListening ? "Sprachaufnahme stoppen" : "Sprachaufnahme starten"
        )
    }

    // MARK: - Footer
    private var footerBar: some View {
        HStack(spacing: 10) {

            attachmentButton

            speechButton
                .disabled(viewModel.isProcessing)

            TextField(
                isImageMode
                    ? "Bild über Image Playground erstellen"
                    : "Message Khione…",
                text: $inputText,
                axis: .vertical
            )
            .disabled(isImageMode)  // 👈 WICHTIG
            .opacity(isImageMode ? 0.6 : 1)
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if viewModel.isProcessing {
                stopButton
            } else {
                sendButton
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var attachmentButton: some View {
        Button {
            subscription.canUseVision
                ? (showImagePicker = true)
                : (showUpgradeSheet = true)
        } label: {
            Image(systemName: "plus")
                .font(.title3)
        }
        .disabled(!subscription.canUseVision)
        .opacity(subscription.canUseVision ? 1 : 0.35)
    }

    // MARK: - Buttons
    private var sendButton: some View {
        Button(action: handleSend) {
            Image(systemName: "paperplane.fill")
                .font(.title3)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!canSend)
        .opacity(canSend ? 1.0 : 0.4)
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

    // MARK: - Status Hint
    private var statusHintBar: some View {
        Group {
            if subscription.tier == .free
                && (isInputFocused || subscription.remainingMessagesToday == 0)
            {

                HStack(spacing: 6) {

                    if subscription.remainingMessagesToday > 0 {
                        Text("\(subscription.remainingMessagesToday)")
                            .font(.caption.bold())
                        Text("Nachrichten verfügbar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "clock")
                            .font(.caption2)
                        RefillCountdownView(
                            nextRefillDate: subscription.nextRefillDate
                        )
                    }

                    Spacer()

                    Label("Vision", systemImage: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .transition(.opacity)
                .animation(
                    .easeInOut(duration: 0.2),
                    value: subscription.remainingMessagesToday
                )
            }
        }
    }

    // MARK: - Attachment Preview
    private var attachmentPreview: some View {
        Group {
            if subscription.canUseVision, let image = selectedImage {
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .clipped()

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
    }

    // MARK: - Logic
    private var canSend: Bool {
        !viewModel.isProcessing && viewModel.selectedMode != nil
            && !inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
    }

    private func handleSend() {

        guard let mode = viewModel.selectedMode else { return }

        // 🖼 IMAGE MODE
        if mode.id == "image" {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            isInputFocused = false
            imagePromptCache = inputText
            inputText = ""
            showImagePlayground = true
            return
        }

        // 🔒 Subscription Check
        guard subscription.canSendMessage else {
            showUpgradeSheet = true
            return
        }

        // 📎 Vision Check
        if selectedImage != nil && !subscription.canUseVision {
            showUpgradeSheet = true
            return
        }

        // ✅ SEND
        isInputFocused = false
        viewModel.send(text: inputText, image: selectedImage)
        subscription.consumeMessageIfNeeded()

        inputText = ""
        selectedImage = nil
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let lastID = viewModel.messages.last?.id {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        }
    }
}

struct RefillCountdownView: View {
    let nextRefillDate: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(
                nextRefillDate.timeIntervalSince(context.date),
                0
            )

            Text("Nächste Nachricht in \(format(remaining))")
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

#Preview {
    let storeKit = StoreKitManager()
    let subscription = SubscriptionManager(storeKit: storeKit)

    KhioneView()
        .environmentObject(storeKit)
        .environmentObject(subscription)
        .environmentObject(ThemeManager())
}
