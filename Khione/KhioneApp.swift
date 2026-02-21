//
//  KhioneApp.swift
//  Khione
//

import SwiftUI

@main
struct KhioneApp: App {

    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var themeManager: ThemeManager

    @AppStorage("hasSeenOnboarding")
    private var hasSeenOnboarding = false

    init() {
        _themeManager = StateObject(wrappedValue: ThemeManager())
    }

    var body: some Scene {
        WindowGroup {
            rootContent
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .tint(themeManager.accentColor)
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
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue == .background {
                GreetingManager.resetSession()
            }
        }
    }
}
