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
            RootView()
                // MARK: - Environment
                .environmentObject(storeKit)
                .environmentObject(subscription)
                .environmentObject(themeManager)
                .environmentObject(internet)

                // MARK: - Theme Application
                .preferredColorScheme(themeManager.colorScheme)
                .tint(themeManager.accentColor)
        }
    }
}
