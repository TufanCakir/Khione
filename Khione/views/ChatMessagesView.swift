//
//  ChatMessagesView.swift
//  Khione
//
//  Created by Tufan Cakir on 28.06.26.
//

import SwiftUI

struct ChatMessagesView: View {
    let messages: [ChatMessage]
    let isProcessing: Bool
    let thinkingText: String
    let messageSpacing: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let shouldReduceMotion: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: messageSpacing) {
                    ForEach(messages) { message in
                        ChatBubbleView(message: message).id(message.id)
                    }

                    if isProcessing {
                        ProgressView(thinkingText)
                            .padding(.top, 6)
                            .id("typing")
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: isProcessing) { _, _ in
                scrollToBottom(proxy)
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = messages.last {
            withAnimation(shouldReduceMotion ? nil : .easeOut(duration: 0.25)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}
