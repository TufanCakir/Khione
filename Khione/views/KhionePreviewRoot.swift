//
//  KhionePreviewRoot.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

import SwiftUI

struct KhionePreviewRoot<Content: View>: View {
    let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let sk = StoreKitManager()
        let sub = SubscriptionManager(storeKit: sk)
        let theme = ThemeManager()
        let net = InternetMonitor()

        content
            .environmentObject(sk)
            .environmentObject(sub)
            .environmentObject(theme)
            .environmentObject(net)
    }
}
