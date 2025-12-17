//
//  AnimatedRainbowBorder.swift
//  Khione
//

import SwiftUI

struct AnimatedRainbowBorder: ViewModifier {

    let lineWidth: CGFloat
    let cornerRadius: CGFloat
    let isActive: Bool

    @State private var angle: Double = 0

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
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    AngularGradient(
                        colors: rainbowColors,
                        center: .center,
                        angle: .degrees(angle)
                    ),
                    lineWidth: lineWidth
                )
        }
    }

    // MARK: - Animation Control
    private func startIfNeeded() {
        angle = 0
        withAnimation(
            .linear(duration: 2.8)
            .repeatForever(autoreverses: false)
        ) {
            angle = 360
        }
    }

    private func stop() {
        angle = 0
    }

    // MARK: - Colors
    private var rainbowColors: [Color] {
        [
            .cyan,
            .blue,
            .purple,
            .pink,
            .orange,
            .yellow,
            .cyan
        ]
    }
}

extension View {

    func animatedRainbowBorder(
        active: Bool,
        lineWidth: CGFloat = 3,
        radius: CGFloat = 14
    ) -> some View {
        modifier(
            AnimatedRainbowBorder(
                lineWidth: lineWidth,
                cornerRadius: radius,
                isActive: active
            )
        )
    }
}
