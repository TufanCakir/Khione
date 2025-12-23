//
//  SubscriptionLocalization.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import Foundation

struct SubscriptionLocalization: Decodable {

    let title: String
    let subtitle: String
    let subscribe: String
    let restore: String
    let active: String
    let included: String

    // ⏱ Periods
    let daily: String
    let weekly: String
    let monthly: String
    let yearly: String

    let everyXDays: String
    let everyXWeeks: String
    let everyXMonths: String
    let everyXYears: String

    // Plans
    let planFree: String
    let planPro: String
    let planVision: String
    let planInfinity: String

    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case subscribe
        case restore
        case active
        case included  // ✅

        case planFree = "plan_free"
        case planPro = "plan_pro"
        case planVision = "plan_vision"
        case planInfinity = "plan_infinity"

        case daily
        case weekly
        case monthly
        case yearly
        case everyXDays = "every_x_days"
        case everyXWeeks = "every_x_weeks"
        case everyXMonths = "every_x_months"
        case everyXYears = "every_x_years"
    }
}

extension SubscriptionLocalization {

    static let fallback = SubscriptionLocalization(
        title: "Upgrade Khione",
        subtitle: "Unlock advanced modes and features",
        subscribe: "Subscribe",
        restore: "Restore Purchases",
        active: "Active",
        included: "Included",

        // ⏱ Periods
        daily: "Daily",
        weekly: "Weekly",
        monthly: "Monthly",
        yearly: "Yearly",

        everyXDays: "Every %d days",
        everyXWeeks: "Every %d weeks",
        everyXMonths: "Every %d months",
        everyXYears: "Every %d years",

        // Plans
        planFree: "Free",
        planPro: "Pro",
        planVision: "Vision",
        planInfinity: "Infinity"
    )
}

extension SubscriptionLocalization {

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let f = SubscriptionLocalization.fallback

        title = try c.decodeIfPresent(String.self, forKey: .title) ?? f.title
        subtitle =
            try c.decodeIfPresent(String.self, forKey: .subtitle) ?? f.subtitle
        subscribe =
            try c.decodeIfPresent(String.self, forKey: .subscribe)
            ?? f.subscribe
        restore =
            try c.decodeIfPresent(String.self, forKey: .restore) ?? f.restore
        active = try c.decodeIfPresent(String.self, forKey: .active) ?? f.active
        included =
            try c.decodeIfPresent(String.self, forKey: .included) ?? f.included

        daily =
            try c.decodeIfPresent(String.self, forKey: .daily) ?? f.daily
        weekly =
            try c.decodeIfPresent(String.self, forKey: .weekly) ?? f.weekly
        monthly =
            try c.decodeIfPresent(String.self, forKey: .monthly) ?? f.monthly
        yearly =
            try c.decodeIfPresent(String.self, forKey: .yearly) ?? f.yearly

        everyXDays =
            try c.decodeIfPresent(String.self, forKey: .everyXDays)
            ?? f.everyXDays
        everyXWeeks =
            try c.decodeIfPresent(String.self, forKey: .everyXWeeks)
            ?? f.everyXWeeks
        everyXMonths =
            try c.decodeIfPresent(String.self, forKey: .everyXMonths)
            ?? f.everyXMonths
        everyXYears =
            try c.decodeIfPresent(String.self, forKey: .everyXYears)
            ?? f.everyXYears

        planFree =
            try c.decodeIfPresent(String.self, forKey: .planFree) ?? f.planFree
        planPro =
            try c.decodeIfPresent(String.self, forKey: .planPro) ?? f.planPro
        planVision =
            try c.decodeIfPresent(String.self, forKey: .planVision)
            ?? f.planVision
        planInfinity =
            try c.decodeIfPresent(String.self, forKey: .planInfinity)
            ?? f.planInfinity
    }
}

extension Bundle {

    func loadSubscriptionLocalization(
        language: String = Locale.current.language.languageCode?.identifier
            ?? "en",
        fallback: String = "en"
    ) -> SubscriptionLocalization {

        if let loc = loadSubscriptionFile(language) {
            return loc
        }

        if let fallbackLoc = loadSubscriptionFile(fallback) {
            print("⚠️ Using fallback subscription localization: \(fallback)")
            return fallbackLoc
        }

        print("❌ No subscription localization found – using hard fallback")
        return .fallback
    }

    private func loadSubscriptionFile(_ language: String)
        -> SubscriptionLocalization?
    {
        let file = "subscription_\(language)"
        guard let url = url(forResource: file, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }

        return try? JSONDecoder().decode(
            SubscriptionLocalization.self,
            from: data
        )
    }
}
