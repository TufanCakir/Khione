//
//  SubscriptionPlan.swift
//  Khione
//
//  Created by Tufan Cakir on 16.12.25.
//

import Foundation

struct SubscriptionPlan: Identifiable, Decodable {
    let id: String
    let name: String
    let dailyMessageLimit: Int
    let allowedModes: AllowedModes   // ✅ HIER FEHLTE ES
    let features: [String]
}
