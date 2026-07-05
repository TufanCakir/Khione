//
//  ChatInputBarView.swift
//  Khione
//
//  Created by Tufan Cakir on 28.06.26.
//

import SwiftUI

struct ChatInputBarView: View {
    @Binding var inputText: String
    let isInputFocused: FocusState<Bool>.Binding

    let placeholder: String
    let replyStyles: [ReplyStyle]
    let selectedReplyStyle: ReplyStyle?
    let isProcessing: Bool
    let canSend: Bool
    let canAttachImages: Bool
    let canUseReplyStyles: Bool
    let canUseVoiceInput: Bool
    let alwaysShowSendButton: Bool
    let largeChatText: Bool
    let colorSchemeContrast: ColorSchemeContrast
    let accentColor: Color
    let isSpeechRecording: Bool
    let speechIconName: String
    let accessibility: ChatInputAccessibility
    let onAttach: () -> Void
    let onReplyStyle: (ReplyStyle) -> Void
    let onSpeech: () -> Void
    let onUpgrade: () -> Void
    let onSend: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            iconButton("plus", action: onAttach)
                .opacity(canAttachImages ? 1 : 0.35)
                .accessibilityLabel(accessibility.attachmentLabel)
                .accessibilityHint(accessibility.attachmentHint)

            TextField(placeholder, text: $inputText, axis: .vertical)
                .focused(isInputFocused)
                .lineLimit(1...5)
                .font(largeChatText ? .title3 : .body)
                .padding(.vertical, 11)
                .padding(.horizontal, 4)
                .accessibilityLabel(accessibility.messageFieldLabel)
                .accessibilityHint(accessibility.messageFieldHint)

            replyStyleButton
                .opacity(canUseReplyStyles ? 1 : 0.35)

            iconButton(
                speechIconName,
                action: canUseVoiceInput ? onSpeech : onUpgrade
            )
            .foregroundStyle(isSpeechRecording ? .red : .primary)
            .opacity(canUseVoiceInput ? 1 : 0.35)
            .accessibilityLabel(accessibility.speechLabel)
            .accessibilityHint(accessibility.speechHint)

            trailingButton
        }
        .padding(.leading, 8)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .background(inputBackground)
        .overlay(inputBorder)
        .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
    }

    private var replyStyleButton: some View {
        Menu {
            if canUseReplyStyles {
                ForEach(replyStyles) { style in
                    Button {
                        onReplyStyle(style)
                    } label: {
                        Label(style.name, systemImage: style.icon)
                    }
                }
            } else {
                Button(action: onUpgrade) {
                    Label(
                        accessibility.replyStyleHint,
                        systemImage: "lock.fill"
                    )
                }
            }
        } label: {
            Image(
                systemName: canUseReplyStyles
                    ? selectedReplyStyle?.icon ?? "wand.and.stars"
                    : "wand.and.stars"
            )
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 38, height: 38)
                .contentShape(Circle())
        }
        .accessibilityLabel(accessibility.replyStyleLabel)
        .accessibilityHint(accessibility.replyStyleHint)
        .accessibilityValue(selectedReplyStyle?.name ?? "")
    }

    @ViewBuilder
    private var trailingButton: some View {
        if isProcessing {
            iconButton("xmark", action: onStop)
                .foregroundStyle(.red)
                .accessibilityLabel(accessibility.stopLabel)
                .accessibilityHint(accessibility.stopHint)
        } else if canSend || alwaysShowSendButton {
            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 34, height: 34)
                    .background(sendButtonBackground)
                    .foregroundStyle(sendButtonForeground)
                    .clipShape(Circle())
            }
            .frame(width: 40, height: 40)
            .disabled(!canSend)
            .accessibilityLabel(accessibility.sendLabel)
            .accessibilityHint(accessibility.sendHint)
        }
    }

    private func iconButton(_ systemName: String, action: @escaping () -> Void)
        -> some View
    {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 38, height: 38)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
    }

    private var inputBorder: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
    }

    private var sendButtonBackground: Color {
        if !canSend {
            return Color.secondary.opacity(0.22)
        }

        return colorSchemeContrast == .increased ? .primary : accentColor
    }

    private var sendButtonForeground: Color {
        if !canSend {
            return .secondary
        }

        return colorSchemeContrast == .increased
            ? Color(.systemBackground)
            : .white
    }
}

struct ChatInputAccessibility {
    let attachmentLabel: String
    let attachmentHint: String
    let replyStyleLabel: String
    let replyStyleHint: String
    let speechLabel: String
    let speechHint: String
    let sendLabel: String
    let sendHint: String
    let stopLabel: String
    let stopHint: String
    let messageFieldLabel: String
    let messageFieldHint: String
}
