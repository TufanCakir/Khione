//
//  ChatRouter.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

import SwiftUI

@MainActor
struct ChatRouter: View {

    @ObservedObject var store: ChatStore
    @EnvironmentObject private var internet: InternetMonitor

    var body: some View {
        NavigationStack {
            Group {
                if !internet.isConnected {
                    NoInternetView()
                } else if store.activeChat != nil {
                    KhioneView(chatStore: store)
                } else {
                    EmptyChatPlaceholder()
                }
            }
        }
    }
}
