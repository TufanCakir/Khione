//
//  OnboardingPage.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

struct OnboardingPage: View {

    let icon: String
    let title: String
    let text: String

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 40)

            iconView

            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(text)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding(.horizontal)
    }
}

extension OnboardingPage {

    fileprivate var iconView: some View {
        Image(systemName: icon)
            .font(.system(size: 60, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(24)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.primary.opacity(0.15),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    }
}
