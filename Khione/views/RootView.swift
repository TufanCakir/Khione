//
//  RootView.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

struct RootView: View {

    @StateObject private var chatStore = ChatStore()

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            ChatRouter(store: chatStore)
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
    }
}
