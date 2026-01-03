//
//  KhioneApp.swift
//  Khione
//

import SwiftUI

@main
struct KhioneApp: App {

    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var storeKit: StoreKitManager
    @StateObject private var subscription: SubscriptionManager
    @StateObject private var themeManager: ThemeManager
    @StateObject private var internet: InternetMonitor

    @AppStorage("hasSeenOnboarding")
    private var hasSeenOnboarding = false

    init() {
        let sk = StoreKitManager()

        _storeKit = StateObject(wrappedValue: sk)
        _subscription = StateObject(
            wrappedValue: SubscriptionManager(storeKit: sk)
        )
        _themeManager = StateObject(wrappedValue: ThemeManager())
        _internet = StateObject(wrappedValue: InternetMonitor())
    }

    var body: some Scene {
        WindowGroup {
            rootContent
                .environmentObject(storeKit)
                .environmentObject(subscription)
                .environmentObject(themeManager)
                .environmentObject(internet)
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
