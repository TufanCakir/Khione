//
//  RootView.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

struct RootView: View {

    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var chatStore = ChatStore()

    @State private var selectedTab = 0
    @State private var pendingSharedPrompt: String?
    @AppStorage("language")
    private var language =
        Locale.current.language.languageCode?.identifier ?? "en"

    var body: some View {
        TabView(selection: $selectedTab) {

            ChatRouter(
                store: chatStore,
                pendingSharedPrompt: $pendingSharedPrompt
            )
            .tabItem {
                Label(
                    "Chat",
                    systemImage: "bubble.left.and.bubble.right.fill"
                )
            }
            .tag(0)

            Sidebar(
                store: chatStore,
                onOpenChat: {
                    selectedTab = 0
                }
            )
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
        .onAppear(perform: consumePendingSharedContent)
        .onOpenURL(perform: handleIncomingURL)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                consumePendingSharedContent()
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard let content = SharedContentManager.consumeSharedContent(from: url)
        else { return }

        openSharedContent(content)
    }

    private func consumePendingSharedContent() {
        guard let content = SharedContentManager.consumeSharedContent() else {
            return
        }

        openSharedContent(content)
    }

    private func openSharedContent(_ content: SharedContent) {
        chatStore.createNewChat()
        pendingSharedPrompt = SharedContentManager.prompt(
            for: content,
            language: language
        )
        selectedTab = 0
    }
}
