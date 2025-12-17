//
//  RainbowBorder.swift
//  Khione
//
//  Created by Tufan Cakir on 16.12.25.
//

import SwiftUI

struct RainbowBorder: ViewModifier {
    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 18)
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
                        lineWidth: 2
                    )
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 6)
                        .repeatForever(autoreverses: false)
                ) {
                    angle = 360
                }
            }
    }
}

extension View {
    func rainbowBorder() -> some View {
        modifier(RainbowBorder())
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
