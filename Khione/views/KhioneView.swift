//
//  KhioneView.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import SwiftUI
import StoreKit
import ImagePlayground

struct KhioneView: View {

    // MARK: - State & Environment
    @StateObject private var viewModel = ViewModel()
    @StateObject private var speech = SpeechRecognizer()

    @EnvironmentObject private var subscription: SubscriptionManager
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var inputText = ""
    @State private var selectedImage: UIImage?

    @State private var showUpgradeSheet = false
    @State private var showImagePicker = false
    @State private var showImagePlayground = false

    @FocusState private var isInputFocused: Bool


    // MARK: - Computed
    private var isImageMode: Bool {
        viewModel.selectedMode?.id == "image"
    }

    private var canSend: Bool {
        guard !viewModel.isProcessing,
              let mode = viewModel.selectedMode else { return false }

        if mode.id == "image" { return true }

        return !inputText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissInput()
                    }

                VStack(spacing: 0) {
                    messagesList
                    attachmentPreview
                    statusHintBar
                    footerBar
                }
            }
            .simultaneousGesture(
                TapGesture().onEnded { }
            )
            .toolbar { toolbarContent }
        }
        .imagePlaygroundSheet(
            isPresented: $showImagePlayground
        ) { url in
            print("Image Playground result:", url)
            // z.B. speichern, analysieren, anzeigen
        }
        .sheet(isPresented: $showImagePicker) {
            if subscription.canUseVision {
                ImagePicker(image: $selectedImage)
            }
        }
        .onChange(of: speech.transcript) { _, newValue in
            if speech.isRecording {
                inputText = newValue
            }
        }
        .onAppear {
            // Set a default mode if none is selected
            if viewModel.selectedMode == nil {
                viewModel.setMode(KhioneModeRegistry.all.first!)
            }

            // Apply start mode from UserDefaults once, if present
            if let modeID = UserDefaults.standard.string(forKey: "khione_start_mode") {
                viewModel.setModeByID(modeID)
                UserDefaults.standard.removeObject(forKey: "khione_start_mode")
            }
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
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
        .scrollDismissesKeyboard(.interactively)
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

    @ViewBuilder
    private var actionButton: some View {
        if viewModel.isProcessing {
            stopButton
        } else {
            sendButton
        }
    }

    // MARK: - Chat Footer
    private var chatFooter: some View {
        HStack(spacing: 10) {
            
            attachmentButton
            speechButton
            
            TextField(
                "Message Khione…",
                text: $inputText,
                axis: .vertical
            )
            .focused($isInputFocused)
            .lineLimit(1...4)
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            actionButton
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private func dismissInput(animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
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
        VStack(spacing: 16) {

            VStack(spacing: 12) {
                Image(systemName: "photo.artframe")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)

                Text("Bilder werden über Apple Image Playground erstellt")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                dismissInput()
                showImagePlayground = true
            } label: {
                Label("Image Playground öffnen", systemImage: "photo.artframe")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Buttons
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

    private var sendButton: some View {
        Button(action: handleSend) {
            Image(systemName: "paperplane.fill")
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
            Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                .font(.title3)
                .foregroundStyle(speech.isRecording ? .red : .primary)
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .animatedRainbowBorder(
            active: speech.isRecording,
            lineWidth: 2,
            radius: 14
        )
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


    // MARK: - Status Hint
    @ViewBuilder
    private var statusHintBar: some View {
        if subscription.tier == .free &&
            (isInputFocused || subscription.remainingMessagesToday == 0) {

            HStack {
                if subscription.remainingMessagesToday > 0 {
                    Text("\(subscription.remainingMessagesToday)")
                        .font(.caption.bold())
                    Text("Nachrichten verfügbar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
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

        inputText = ""
        selectedImage = nil
    }


    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = viewModel.messages.last {
            withAnimation {
                proxy.scrollTo(last.id, anchor: .bottom)
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
    let storeKit = StoreKitManager()
    let subscription = SubscriptionManager(storeKit: storeKit)

    KhioneView()
        .environmentObject(storeKit)
        .environmentObject(subscription)
        .environmentObject(ThemeManager())
}

