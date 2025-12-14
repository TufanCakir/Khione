//
//  SubscriptionTier.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import Foundation

enum SubscriptionTier: String, Codable, Identifiable {
    case free
    case pro
    case vision

    var id: String { rawValue }

    var productID: String? {
        switch self {
        case .free:
            return nil
        case .pro:
            return "khione.pro.monthly"
        case .vision:
            return "khione.vision.monthly"
        }
    }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .vision: return "Vision"
        }
    }
}

