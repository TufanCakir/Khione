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

    var body: some View {

        NavigationStack {

            if store.activeID != nil {

                ChatView(chatStore: store)
                    .id(store.activeID)

            }
        }
    }
}
