//
//  ChatBubbleView.swift
//  Khione
//
//  Created by Tufan Cakir on 16.12.25.
//

import SwiftUI

struct ChatBubbleView: View {

    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                bubble
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .frame(
            maxWidth: .infinity,
            alignment: message.role == .user ? .trailing : .leading
        )
    }

    // MARK: - Bubble
    private var bubble: some View {
        VStack(alignment: .leading, spacing: 10) {

            // 🖼 Image (adaptive, no hard max)
            if let image = message.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: 280, maxHeight: 240)
                    .clipped()
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .accessibilityLabel(Text("Attached image"))
            }

            // ✨ Emoji / Symbol Header (subtle)
            if message.emoji != nil || message.leadingSymbol != nil {
                HStack(spacing: 6) {
                    if let emoji = message.emoji {
                        Text(emoji)
                            .font(.body)
                    }

                    if let symbol = message.leadingSymbol {
                        Image(systemName: symbol)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(.bottom, 2)
            }

            // 👋 Greeting (kept as-is)
            if message.kind == .greeting {
                TypingGreetingView(text: message.text ?? "")
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }

            // 💻 Code Block
            if message.isCode {
                CodeBlockView(
                    code: extractCode(from: message.text ?? ""),
                    canCopy: true
                )
            }
            // 💬 Text (Dynamic Type friendly)
            else if let text = message.text {
                Text(.init(text))
                    .font(.body)
                    .foregroundStyle(textForeground)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(Text(text))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            bubbleBackground,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(bubbleBorder)
        .frame(
            maxWidth: 360,
            alignment: message.role == .user ? .trailing : .leading
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Background (system-first)
    private var bubbleBackground: some ShapeStyle {
        if message.role == .user {
            return AnyShapeStyle(Color.accentColor)
        } else {
            return AnyShapeStyle(.thinMaterial)
        }
    }

    // MARK: - Border (subtle, no neon)
    @ViewBuilder
    private var bubbleBorder: some View {
        if message.role == .assistant {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.separator.opacity(0.6), lineWidth: 1)
        }
    }

    // MARK: - Styling
    private var textForeground: some ShapeStyle {
        message.role == .user ? AnyShapeStyle(.white) : AnyShapeStyle(.primary)
    }

    // MARK: - Helpers
    private func extractCode(from text: String) -> String {
        text
            .replacingOccurrences(of: "```swift", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
