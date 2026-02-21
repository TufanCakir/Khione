//
//  CodeBlockView.swift
//  Khione
//
//  Created by Tufan Cakir on 16.12.25.
//

import SwiftUI

struct CodeBlockView: View {

    let code: String
    let canCopy: Bool

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            codeArea
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 8) {
            Label("Code", systemImage: "chevron.left.slash.chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if canCopy {
                Button(action: copy) {
                    Label(
                        copied ? "Copied" : "Copy",
                        systemImage: copied
                            ? "checkmark.circle.fill"
                            : "doc.on.doc"
                    )
                }
                .font(.caption)
                .foregroundStyle(copied ? Color.accentColor : Color.secondary)
                .animation(.easeInOut(duration: 0.2), value: copied)
                .accessibilityLabel(copied ? "Code copied" : "Copy code")
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Code Area
    private var codeArea: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(12)
                .textSelection(.enabled)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.separator.opacity(0.6), lineWidth: 1)
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
