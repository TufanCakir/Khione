//
//  StoreKit+Extensions.swift.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import StoreKit

extension Product.SubscriptionPeriod {

    func displayText(using text: SubscriptionLocalization) -> String {
        switch unit {

        case .day:
            return value == 1
                ? text.daily
                : String(format: text.everyXDays, value)

        case .week:
            return value == 1
                ? text.weekly
                : String(format: text.everyXWeeks, value)

        case .month:
            return value == 1
                ? text.monthly
                : String(format: text.everyXMonths, value)

        case .year:
            return value == 1
                ? text.yearly
                : String(format: text.everyXYears, value)

        @unknown default:
            return ""
        }
    }
}
