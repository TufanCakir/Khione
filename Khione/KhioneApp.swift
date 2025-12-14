//
//  KhioneApp.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import SwiftUI

@main
struct KhioneApp: App {

    @StateObject private var storeKit = StoreKitManager()
    @StateObject private var subscription: SubscriptionManager
    @StateObject private var themeManager = ThemeManager()

    init() {
        let sk = StoreKitManager()
        _storeKit = StateObject(wrappedValue: sk)
        _subscription = StateObject(wrappedValue: SubscriptionManager(storeKit: sk))
    }

    var body: some Scene {
        WindowGroup {
            KhioneView()
                .environmentObject(storeKit)
                .environmentObject(subscription)
                .environmentObject(themeManager)
        }
    }
}
