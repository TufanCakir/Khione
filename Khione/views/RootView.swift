//
//  RootView.swift
//  Khione
//
//  Created by Tufan Cakir on 16.12.25.
//

import SwiftUI

struct RootView: View {

    @StateObject private var chatStore = ChatStore()

    @State private var selectedTab = 0  // 👈 NEU

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
                    selectedTab = 0  // 👈 Wechsel automatisch zum Chat-Tab
                }
            )
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            .tag(1)

            NavigationStack {
                AccountView()
            }
            .tabItem {
                Label("Account", systemImage: "person.crop.circle")
            }
            .tag(4)
        }
    }
}
