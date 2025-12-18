//
//  StoreKit+Extensions.swift.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import StoreKit

extension Product.SubscriptionPeriod {

    var displayText: String {
        switch unit {
        case .day:
            return value == 1 ? "Daily" : "Every \(value) days"
        case .week:
            return value == 1 ? "Weekly" : "Every \(value) weeks"
        case .month:
            return value == 1 ? "Monthly" : "Every \(value) months"
        case .year:
            return value == 1 ? "Yearly" : "Every \(value) years"
        @unknown default:
            return ""
        }
    }
}
