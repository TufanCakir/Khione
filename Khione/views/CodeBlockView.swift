//
//  CodeBlockView.swift
//  Khione
//

import SwiftUI

struct CodeBlockView: View {

    let code: String
    let canCopy: Bool

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            header

            codeArea
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Label("Code", systemImage: "chevron.left.slash.chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if canCopy {
                Button(action: copy) {
                    Label(
                        copied ? "Copied" : "Copy",
                        systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc"
                    )
                }
                .font(.caption)
                .foregroundColor(copied ? .green : .secondary)
                .animation(.easeInOut(duration: 0.2), value: copied)
            }
        }
    }

    // MARK: - Code Area
    private var codeArea: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .padding(12)
                .textSelection(.enabled)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .accessibilityLabel("Code block")
    }

    // MARK: - Copy Logic
    private func copy() {
        UIPasteboard.general.string = code
        copied = true

        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            copied = false
        }
    }
}
