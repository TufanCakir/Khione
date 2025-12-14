//
//  SettingsTab.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

enum SettingsTab: String, CaseIterable, Identifiable {
    case appearance
    case behavior
    case subscription
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance: return "Appearance"
        case .behavior: return "Behavior"
        case .subscription: return "Subscription"
        case .about: return "About"
        }
    }
}
