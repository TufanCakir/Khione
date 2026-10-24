//
//  PreviewRoot.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

struct PreviewRoot<Content: View>: View {
    let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let theme = ThemeManager()
        let subscriptions = SubscriptionManager()

        content
            .environmentObject(theme)
            .environment(subscriptions)
    }
}
