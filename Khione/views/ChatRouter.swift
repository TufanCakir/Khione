//
//  ChatRouter.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

@MainActor
struct ChatRouter: View {

    @ObservedObject var store: ChatStore
    @Binding var pendingSharedPrompt: String?

    var body: some View {

        NavigationStack {

            if store.activeID != nil {

                ChatView(
                    chatStore: store,
                    pendingSharedPrompt: $pendingSharedPrompt
                )
                .id(store.activeID)
            }
        }
    }
}
