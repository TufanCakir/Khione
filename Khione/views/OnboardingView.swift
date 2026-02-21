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
        VStack {

            TabView(selection: $page) {

                OnboardingPage(
                    icon: .system("snowflake"),
                    title: "Khione",
                    text:
                        """
                        On-device AI.
                        Fast. Private. Natural.

                        Runs entirely on your iPhone.
                        No cloud. No servers.
                        Your data stays with you.
                        """
                )
                .tag(0)

                OnboardingPage(
                    icon: .system("sparkles"),
                    title: "Fast & Natural",
                    text:
                        """
                        Designed for clarity and speed.

                        Ask questions, explore ideas,
                        and get helpful answers instantly —
                        even offline.
                        """
                )
                .tag(1)

                OnboardingPage(
                    icon: .system("hand.raised.fill"),
                    title: "Privacy & Accessibility",
                    text:
                        """
                        Privacy comes first.

                        Simple language, voice interaction,
                        and an accessible design make
                        Khione easy for everyone.
                        """
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .animation(.easeInOut, value: page)

            Button(action: advance) {

                Text(
                    page < 2
                        ? "Continue"
                        : "Start using Khione"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 8)
        }
    }

    private func advance() {
        if page < 2 {
            page += 1
        } else {
            onFinish()
        }
    }
}
