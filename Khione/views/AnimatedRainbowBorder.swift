//
//  AnimatedRainbowBorder.swift
//  Khione
//
//  Created by Tufan Cakir on 16.12.25.
//

import SwiftUI

struct AnimatedRainbowBorder: ViewModifier {
    @State private var angle: Double = 0
    let lineWidth: CGFloat
    let cornerRadius: CGFloat
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            colors: [
                                                      .cyan,
                                                      .blue,
                                                      .purple,
                                                      .pink,
                                                      .orange,
                                                      .cyan
                                                  ],
                            center: .center,
                            angle: .degrees(angle)
                        ),
                        lineWidth: isActive ? lineWidth : 0
                    )
            )
            .onAppear {
                guard isActive else { return }
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
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
