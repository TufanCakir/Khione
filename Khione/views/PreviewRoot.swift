//
//  PreviewRoot.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

import SwiftUI

struct PreviewRoot<Content: View>: View {
    let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let theme = ThemeManager()

        content
            .environmentObject(theme)
    }
}
