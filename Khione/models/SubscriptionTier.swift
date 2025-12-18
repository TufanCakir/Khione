//
//  SubscriptionTier.swift
//  Khione
//

import Foundation

enum SubscriptionTier: String, CaseIterable, Comparable {

    case free
    case pro
    case vision
    case infinity

    // MARK: - Rank (for comparison & UI logic)
    var rank: Int {
        switch self {
        case .free: return 0
        case .pro: return 1
        case .vision: return 2
        case .infinity: return 3
        }
    }

    // MARK: - Comparable
    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        lhs.rank < rhs.rank
    }

    // MARK: - StoreKit Product IDs
    var productID: String? {
        switch self {
        case .pro:
            return "khione.pro.monthly"
        case .vision:
            return "khione.vision.monthly"
        case .infinity:
            return "khione.infinity.monthly"
        case .free:
            return nil
        }
    }

    // MARK: - Init from Product ID
    init?(productID: String) {
        switch productID {
        case "khione.pro.monthly":
            self = .pro
        case "khione.vision.monthly":
            self = .vision
        case "khione.infinity.monthly":
            self = .infinity
        default:
            return nil
        }
    }

    // MARK: - Display
    var displayName: String {
        rawValue.capitalized
    }
}
