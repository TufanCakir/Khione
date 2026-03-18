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
            
            // 🖼 Image
            if let image = message.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: 260, maxHeight: 220)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            // ✨ Optional Header
            if message.emoji != nil || message.leadingSymbol != nil {
                HStack(spacing: 6) {
                    if let emoji = message.emoji {
                        Text(emoji)
                    }
                    
                    if let symbol = message.leadingSymbol {
                        Image(systemName: symbol)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }
            
            // 👋 Greeting
            if message.kind == .greeting {
                TypingGreetingView(text: message.text ?? "")
            }
            
            // 💻 Code
            else if message.isCode {
                CodeBlockView(
                    code: extractCode(from: message.text ?? ""),
                    canCopy: true
                )
            }
            
            // 💬 Text
            else if let text = message.text {
                Text(.init(text))
                    .font(.body)
                    .foregroundStyle(textForeground)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            bubbleBackground
        )
        .overlay(bubbleBorder)
        .clipShape(bubbleShape)
        .shadow(color: shadowColor, radius: 6, y: 2)
        .frame(
            maxWidth: 320,
            alignment: message.role == .user ? .trailing : .leading
        )
    }
    
    private var bubbleShape: some Shape {
        UnevenRoundedRectangle(
            cornerRadii: message.role == .user
            ? .init(topLeading: 18, bottomLeading: 18, bottomTrailing: 4, topTrailing: 18)
            : .init(topLeading: 18, bottomLeading: 4, bottomTrailing: 18, topTrailing: 18)
        )
    }

    // MARK: - Background (system-first)
    private var bubbleBackground: some ShapeStyle {
        if message.role == .user {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.accentColor,
                        Color.accentColor.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(.ultraThinMaterial)
        }
    }

    // MARK: - Border (subtle, no neon)
    @ViewBuilder
    private var bubbleBorder: some View {
        if message.role == .assistant {
            bubbleShape
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }
    
    private var shadowColor: Color {
        message.role == .user
        ? Color.accentColor.opacity(0.25)
        : Color.black.opacity(0.08)
    }

    // MARK: - Styling
    private var textForeground: some ShapeStyle {
        message.role == .user
            ? AnyShapeStyle(.white)
            : AnyShapeStyle(.primary)
    }

    // MARK: - Helpers
    private func extractCode(from text: String) -> String {
        text
            .replacingOccurrences(of: "```swift", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
