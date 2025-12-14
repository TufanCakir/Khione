//
//  SubscriptionPlan.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import Foundation

struct SubscriptionPlan: Identifiable, Decodable {
    let id: String        // ✅ RICHTIG
    let name: String
    let dailyMessageLimit: Int
    let features: [String]
}




extension Bundle {
    func loadPlans(language: String) -> [SubscriptionPlan] {
        let file = "plans_\(language)"

        guard
            let url = url(forResource: file, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let plans = try? JSONDecoder().decode(
                [SubscriptionPlan].self,
                from: data
            )
        else {
            fatalError("❌ Missing plans file: \(file).json")
        }

        return plans
    }
}
