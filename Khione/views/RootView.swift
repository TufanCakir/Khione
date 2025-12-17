//
//  RootView.swift
//  Khione
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject private var internet: InternetMonitor

    var body: some View {
        ZStack {
            content
        }
        .animation(.easeInOut(duration: 0.25), value: internet.isConnected)
    }

    @ViewBuilder
    private var content: some View {
        if internet.isConnected {
            KhioneView()
        } else {
            NoInternetView()
                .transition(.opacity)
        }
    }
}
