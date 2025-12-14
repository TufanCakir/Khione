//
//  KhioneApp.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import SwiftUI

@main
struct KhioneApp: App {

    @StateObject private var storeKit: StoreKitManager
    @StateObject private var subscription: SubscriptionManager
    @StateObject private var themeManager: ThemeManager
    @StateObject private var internet: InternetMonitor

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
            RootView()
                .environmentObject(internet)
                .environmentObject(storeKit)
                .environmentObject(subscription)
                .environmentObject(themeManager)
        }
    }
}


