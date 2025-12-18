//
//  OnboardingView.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

struct OnboardingView: View {

    var onFinish: () -> Void
    @State private var page = 0

    var body: some View {
        VStack(spacing: 32) {

            TabView(selection: $page) {

                OnboardingPage(
                    icon: "snowflake",
                    title: "Khione",
                    text:
                        "Your native AI assistant for clarity, creativity and productivity."
                )
                .tag(0)

                OnboardingPage(
                    icon: "sparkles",
                    title: "Powerful & Private",
                    text:
                        "Chat, Vision and Apple Intelligence — designed for speed and privacy."
                )
                .tag(1)

                OnboardingPage(
                    icon: "checkmark.seal",
                    title: "Ready to Start",
                    text:
                        "Start for free. Upgrade anytime to unlock advanced features."
                )
                .tag(2)
            }
            .tabViewStyle(.page)

            Button {
                if page < 2 {
                    withAnimation { page += 1 }
                } else {
                    onFinish()
                }
            } label: {
                Text(page < 2 ? "Continue" : "Start using Khione")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
}
