//
//  RootView.swift
//  Khione
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject private var internet: InternetMonitor

    var body: some View {
        NavigationStack {
            ZStack {
                content
            }
            .animation(
                .easeInOut(duration: 0.25),
                value: internet.isConnected
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        if internet.isConnected {
            KhioneView()
                .transition(.opacity)
        } else {
            NoInternetView()
                .transition(.opacity)
        }
    }
}
