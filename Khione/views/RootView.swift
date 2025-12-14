//
//  RootView.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject private var internet: InternetMonitor

    var body: some View {
        ZStack {
            if internet.isConnected {
                KhioneView()
            } else {
                NoInternetView()
            }
        }
        .animation(.easeInOut, value: internet.isConnected)
    }
}
