import SwiftUI

struct ChatBubbleView: View {

    let message: ChatMessage
    @EnvironmentObject private var subscription: SubscriptionManager

    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 48)
            } else {
                Spacer(minLength: 48)
                bubble
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    // MARK: - Bubble
    private var bubble: some View {
        VStack(alignment: .leading, spacing: 10) {

            // 🖼 Image
            if let image = message.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: 220, maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // 💻 Code Block
            if message.isCode {
                CodeBlockView(
                    code: extractCode(from: message.text ?? ""),
                    canCopy: subscription.tier != .free
                )
            }

            // 💬 Text
            else if let text = message.text {
                Text(.init(text))
                    .font(.body)
                    .foregroundColor(textColor)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(bubbleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(assistantBorder)
        .frame(maxWidth: 300, alignment: alignment)
        .animation(.easeInOut(duration: 0.15), value: message.id)
    }

    // MARK: - Background
    @ViewBuilder
    private var bubbleBackground: some View {
        if message.role == .user {
            Color.accentColor.opacity(0.95)
        } else {
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Assistant Border
    @ViewBuilder
    private var assistantBorder: some View {
        if message.role == .assistant {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [.cyan.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    // MARK: - Styling
    private var textColor: Color {
        message.role == .user ? .white : .primary
    }

    private var alignment: Alignment {
        message.role == .user ? .trailing : .leading
    }

    // MARK: - Helpers
    private func extractCode(from text: String) -> String {
        text
            .replacingOccurrences(of: "```swift", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
