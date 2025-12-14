//
//  KhioneView.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import SwiftUI
import StoreKit

struct KhioneView: View {

    @StateObject private var viewModel = ViewModel()
    @EnvironmentObject private var subscription: SubscriptionManager   // ✅
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showUpgradeSheet = false                        // ✅
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var inputText: String = ""

    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                themeBackground
                
                VStack(spacing: 0) {
                    modeSelector
                        .padding(.horizontal)
                        .padding(.top)
                    
                    chatView
                }
            }
            .navigationTitle("Khione")
          
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AccountView()
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
    

    
    private var themeBackground: some View {
        themeManager.backgroundColor
            .ignoresSafeArea()
    }
    
    // MARK: - Mode Selector
    private var modeSelector: some View {
        Menu {
            ForEach(viewModel.modes.filter { mode in
                // Programming nur anzeigen, wenn nicht Free
                mode.id != "programming" || subscription.canUseProgrammingMode
            }) { mode in
                Button {
                    viewModel.setMode(mode)
                } label: {
                    Label(mode.name, systemImage: mode.icon)
                }
            }
        } label: {
            HStack {
                Label(
                    viewModel.selectedMode?.name ?? "Select Mode",
                    systemImage: viewModel.selectedMode?.icon ?? "slider.horizontal.3"
                )
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Message Khione…", text: $inputText)
                .autocorrectionDisabled(false)
                .textInputAutocapitalization(.sentences)

            .focused($isInputFocused)
            .lineLimit(1...4)
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            if viewModel.isProcessing {
                stopButton
            } else {
                sendButton
            }
        }
    }
    
    private var sendButton: some View {
        Button(action: handleSend) {
            if subscription.canSendMessage {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .frame(width: 36, height: 36)
            } else {
                Text("Limit erreicht")
                    .font(.footnote.bold())
                    .padding(.horizontal, 10)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!canSend)
    }


    private func handleSend() {
        guard canSend else { return }

        // 🚫 Limit erreicht → Upgrade
        guard subscription.canSendMessage else {
            DispatchQueue.main.async {
                showUpgradeSheet = true
            }
            return
        }

        // 🚫 Vision benötigt
        if selectedImage != nil && !subscription.canUseVision {
            DispatchQueue.main.async {
                showUpgradeSheet = true
            }
            return
        }

        isInputFocused = false

        viewModel.send(
            text: inputText,
            image: selectedImage
        )

        // ⚠️ Auch @Published → async!
        DispatchQueue.main.async {
            subscription.consumeMessageIfNeeded()
        }

        inputText = ""
        selectedImage = nil
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
    
    
    
    
    private var footerBar: some View {
        HStack(spacing: 10) {
            
            // ➕ Attachment Button
            Button {
                showImagePicker = true
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
            }
            
            // Text Input
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

            if subscription.tier == .free {
                if subscription.remainingMessagesToday > 0 {
                    Text("\(subscription.remainingMessagesToday) Nachrichten verfügbar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                } else {
                    Text("Nächste Nachricht in \(formatTime(subscription.nextRefillIn))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }
            }



            // Send / Stop
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
    
    
    // MARK: - chatView
    private var chatView: some View {
        VStack(spacing: 0) {

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id) // 👈 WICHTIG
                        }

                        if viewModel.isProcessing {
                            ProgressView("Khione is thinking…")
                                .padding(.top)
                                .id("typing") // 👈 extra Anchor
                        }
                    }
                    .padding(.vertical)
                }
                // 🔥 AUTO-SCROLL
                .onChange(of: viewModel.messages.count) {
                    scrollToBottom(proxy)
                }
                .onChange(of: viewModel.isProcessing) {
                    scrollToBottom(proxy)
                }
            }

            attachmentPreview
            footerBar
        }
    }

    
    private var attachmentPreview: some View {
        Group {
            if let image = selectedImage {
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

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            if let lastID = viewModel.messages.last?.id {
                withAnimation(.easeOut(duration: 0.25)) {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }


    
    // MARK: - Helpers
    private var canSend: Bool {
        !viewModel.isProcessing &&
        viewModel.selectedMode != nil &&
        (
            !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedImage != nil
        )
    }

    
    private func runIfPossible() {
        guard canSend else { return }

        // 🔒 Message Limit
        guard subscription.canSendMessage else {
            showUpgradeSheet = true
            return
        }

        // 🔒 Vision Lock
        if selectedImage != nil && !subscription.canUseVision {
            showUpgradeSheet = true
            return
        }

        isInputFocused = false

        viewModel.send(
            text: inputText,
            image: selectedImage
        )

        subscription.consumeMessageIfNeeded()

        inputText = ""
        selectedImage = nil
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
