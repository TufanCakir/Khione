//
//  KhioneApp.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

@main
struct KhioneApp: App {

    @StateObject private var themeManager: ThemeManager
    @State private var subscriptionManager = SubscriptionManager()

    @AppStorage("hasSeenOnboarding")
    private var hasSeenOnboarding = false
    @AppStorage("language")
    private var language =
        Locale.current.language.languageCode?.identifier ?? "en"

    init() {
        _themeManager = StateObject(wrappedValue: ThemeManager())
    }

    var body: some Scene {
        WindowGroup {
            rootContent
                .environmentObject(themeManager)
                .environment(subscriptionManager)
                .environment(\.locale, Locale(identifier: language))
                .preferredColorScheme(themeManager.colorScheme)
                .tint(themeManager.accentColor)
                .task {
                    await subscriptionManager.monitorTransactions()
                }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        Group {
            if hasSeenOnboarding {
                RootView()
            } else {
                OnboardingView {
                    hasSeenOnboarding = true
                }
            }
        }
    }
}
