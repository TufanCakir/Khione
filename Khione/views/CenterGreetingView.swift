//
//  CenterGreetingView.swift
//  Khione
//
//  Created by Tufan Cakir on 28.06.26.
//

import SwiftUI

struct CenterGreetingView: View {
    let greeting: Greeting
    let title: String
    let accentColor: Color
    let compactMode: Bool
    let largeChatText: Bool

    var body: some View {
        VStack(spacing: compactMode ? 10 : 14) {
            Image(systemName: greeting.sfSymbol ?? "snowflake")
                .font(greetingFont)
                .foregroundStyle(accentColor)
                .transition(.scale.combined(with: .opacity))

            Text(title)
                .font(greetingFont)
                .foregroundStyle(accentColor)
        }
    }

    private var greetingFont: Font {
        .system(
            size: largeChatText ? 30 : 26,
            weight: .semibold,
            design: .rounded
        )
    }
}
