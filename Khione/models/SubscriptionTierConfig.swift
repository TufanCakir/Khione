//
//  SubscriptionTierConfig.swift
//  Khione
//
//  Created by Tufan Cakir on 16.12.25.
//

import Foundation

struct SubscriptionTierConfig: Decodable, Identifiable {
    let id: String
    let name: String
    let dailyMessageLimit: Int
    let allowedModes: AllowedModes
    let features: [String]
}

enum AllowedModes: Decodable {
    case all
    case list([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self),
            value.lowercased() == "all"
        {
            self = .all
        } else if let list = try? container.decode([String].self) {
            self = .list(list)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "allowedModes must be \"all\" or [String]"
            )
        }
    }
}

extension Bundle {

    func loadPlans(language: String) -> [SubscriptionPlan] {
        let file = "plans_\(language)"  // plans_en / plans_de

        guard let url = url(forResource: file, withExtension: "json") else {
            fatalError("❌ Missing \(file).json in bundle")
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(
                [SubscriptionPlan].self,
                from: data
            )
        } catch {
            fatalError("❌ Failed to decode \(file).json: \(error)")
        }
    }
}
