//
//  KhioneView.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import SwiftUI
import StoreKit
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
                        ForEach(viewModel.modes.filter { $0.id != "programming" || subscription.canUseProgrammingMode }) { mode in
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                                .accessibilityHint("Tippe, um den Chat-Modus zu wechseln")
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
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ImagePlaygroundLauncher()
                    } label: {
                        Image(systemName: "apple.image.playground")
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            if subscription.canUseVision {
                ImagePicker(image: $selectedImage)
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
    
    // MARK: - Footer
    private var footerBar: some View {
        HStack(spacing: 10) {
            
            attachmentButton
            
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
        .disabled(!canSend || !subscription.canSendMessage)
        .opacity(subscription.canSendMessage ? 1.0 : 0.4)
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
            if subscription.tier == .free &&
                (isInputFocused || subscription.remainingMessagesToday == 0) {

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
                .animation(.easeInOut(duration: 0.2),
                           value: subscription.remainingMessagesToday)
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
        !viewModel.isProcessing &&
        viewModel.selectedMode != nil &&
        (
            !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            (selectedImage != nil && subscription.canUseVision)
        )
    }

    private func handleSend() {
        guard canSend else { return }

        guard subscription.canSendMessage else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            showUpgradeSheet = true
            return
        }

        // If an image is attached but Vision is locked, prompt upgrade
        if selectedImage != nil && !subscription.canUseVision {
            showUpgradeSheet = true
            return
        }

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
