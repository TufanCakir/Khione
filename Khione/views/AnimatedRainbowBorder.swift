//
//  AnimatedFocusBorder.swift
//  Khione
//
//  Created by Tufan Cakir on 16.12.25.
//

import SwiftUI

struct AnimatedFocusBorder: ViewModifier {

    let lineWidth: CGFloat
    let cornerRadius: CGFloat
    let isActive: Bool

    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(borderOverlay)
            .onAppear {
                startIfNeeded()
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startIfNeeded()
                } else {
                    stop()
                }
            }
    }

    // MARK: - Overlay
    @ViewBuilder
    private var borderOverlay: some View {
        if isActive {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.2),
                            Color.accentColor.opacity(0.8),
                            Color.accentColor.opacity(0.2),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: lineWidth
                )
                .opacity(0.9)
                .animation(nil, value: isActive)
        }
    }

    // MARK: - Animation Control
    private func startIfNeeded() {
        phase = 0
        withAnimation(
            .easeInOut(duration: 1.6)
                .repeatForever(autoreverses: true)
        ) {
            phase = 1
        }
    }

    private func stop() {
        phase = 0
    }
}

extension View {

    func animatedFocusBorder(
        active: Bool,
        lineWidth: CGFloat = 2,
        radius: CGFloat = 14
    ) -> some View {
        modifier(
            AnimatedFocusBorder(
                lineWidth: lineWidth,
                cornerRadius: radius,
                isActive: active
            )
        )
    }
}
