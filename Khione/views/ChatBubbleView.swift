//
//  ChatBubbleView.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI
import UIKit

struct ChatBubbleView: View {

    let message: ChatMessage

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @AppStorage("language") private var language = "en"
    @AppStorage("accessibilityLargeChatText") private var largeChatText = false

    @ScaledMetric(relativeTo: .body) private var bubbleMaxWidth: CGFloat = 320
    @ScaledMetric(relativeTo: .body) private var imageMaxWidth: CGFloat = 260
    @ScaledMetric(relativeTo: .body) private var imageMaxHeight: CGFloat = 220
    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var verticalPadding: CGFloat = 10

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Bubble
    private var bubble: some View {
        VStack(alignment: .leading, spacing: 10) {

            // 🖼 Image
            if let image = message.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: imageMaxWidth, maxHeight: imageMaxHeight)
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
                    .font(largeChatText ? .title3 : .body)
                    .foregroundStyle(textForeground)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(
            bubbleBackground
        )
        .overlay(bubbleBorder)
        .clipShape(bubbleShape)
        .shadow(color: shadowColor, radius: 6, y: 2)
        .frame(
            maxWidth: largeChatText ? .infinity : bubbleMaxWidth,
            alignment: message.role == .user ? .trailing : .leading
        )
    }

    private var bubbleShape: some Shape {
        UnevenRoundedRectangle(
            cornerRadii: message.role == .user
                ? .init(
                    topLeading: 18,
                    bottomLeading: 18,
                    bottomTrailing: 4,
                    topTrailing: 18
                )
                : .init(
                    topLeading: 18,
                    bottomLeading: 4,
                    bottomTrailing: 18,
                    topTrailing: 18
                )
        )
    }

    // MARK: - Background (system-first)
    private var bubbleBackground: some ShapeStyle {
        if colorSchemeContrast == .increased {
            if message.role == .user {
                return AnyShapeStyle(Color.primary)
            }

            return AnyShapeStyle(Color(UIColor.secondarySystemBackground))
        }

        if message.role == .user {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.accentColor,
                        Color.accentColor.opacity(0.8),
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
                .stroke(
                    colorSchemeContrast == .increased
                        ? Color.primary.opacity(0.35)
                        : Color.white.opacity(0.06),
                    lineWidth: colorSchemeContrast == .increased ? 1.5 : 1
                )
        }
    }

    private var shadowColor: Color {
        message.role == .user
            ? Color.accentColor.opacity(0.25)
            : Color.black.opacity(0.08)
    }

    // MARK: - Styling
    private var textForeground: some ShapeStyle {
        if colorSchemeContrast == .increased && message.role == .user {
            return AnyShapeStyle(Color(UIColor.systemBackground))
        }

        return message.role == .user
            ? AnyShapeStyle(.white)
            : AnyShapeStyle(.primary)
    }

    private var accessibilityLabel: String {
        let sender = message.role == .user ? userLabel : "Khione"

        if message.image != nil, let text = message.text, !text.isEmpty {
            return "\(sender), \(imageLabel), \(text)"
        }

        if message.image != nil {
            return "\(sender), \(imageLabel)"
        }

        return "\(sender), \(message.text ?? "")"
    }

    private var userLabel: String {
        language == "de" ? "Du" : "You"
    }

    private var imageLabel: String {
        language == "de" ? "Bild" : "Image"
    }

    // MARK: - Helpers
    private func extractCode(from text: String) -> String {
        text
            .replacingOccurrences(of: "```swift", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
