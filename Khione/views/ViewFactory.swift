//
//  ViewFactory.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

enum AppRoute {
    case account
}

@MainActor
struct ViewFactory {

    @ViewBuilder
    static func view(for route: AppRoute) -> some View {
        switch route {
        case .account:
            AccountView()
        }
    }
}
