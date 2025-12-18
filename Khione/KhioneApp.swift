//
//  KhioneApp.swift
//  Khione
//

import SwiftUI

@main
struct KhioneApp: App {

    // MARK: - Global State
    @StateObject private var storeKit: StoreKitManager
    @StateObject private var subscription: SubscriptionManager
    @StateObject private var themeManager: ThemeManager
    @StateObject private var internet: InternetMonitor

    @AppStorage("hasSeenOnboarding")
    private var hasSeenOnboarding = false

    // MARK: - Init
    init() {
        let storeKitManager = StoreKitManager()

        _storeKit = StateObject(wrappedValue: storeKitManager)
        _subscription = StateObject(
            wrappedValue: SubscriptionManager(storeKit: storeKitManager)
        )
        _themeManager = StateObject(wrappedValue: ThemeManager())
        _internet = StateObject(wrappedValue: InternetMonitor())
    }

    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    KhioneView()
                } else {
                    OnboardingView {
                        hasSeenOnboarding = true
                    }
                }
            }
            // ✅ ENV FÜR ALLE
            .environmentObject(storeKit)
            .environmentObject(subscription)
            .environmentObject(themeManager)
            .environmentObject(internet)

            // ✅ THEME GLOBAL
            .preferredColorScheme(themeManager.colorScheme)
            .tint(themeManager.accentColor)

            .onAppear {
                print("🧾 Active tier:", subscription.tier)
            }
        }
    }
}
