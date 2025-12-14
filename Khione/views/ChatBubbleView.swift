import SwiftUI

struct ChatBubbleView: View {
    
    let message: ChatMessage
    @EnvironmentObject var subscription: SubscriptionManager
    
    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Bubble Content
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
            // 💬 Normal Text
            else if let text = message.text {
                Text(.init(text))
                    .foregroundColor(textColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(bubbleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .frame(maxWidth: 280, alignment: alignment)
    }
    
    // MARK: - Styles
    @ViewBuilder
    private var bubbleBackground: some View {
        if message.role == .user {
            Color.accentColor.opacity(0.9)
        } else {
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        }
    }
    
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
