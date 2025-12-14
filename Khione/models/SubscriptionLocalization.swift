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
}

extension Bundle {
    func loadSubscriptionLocalization() -> SubscriptionLocalization {
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        let file = "subscription_\(language)"

        guard
            let url = url(forResource: file, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(
                SubscriptionLocalization.self,
                from: data
            )
        else {
            fatalError("❌ Missing localization JSON: \(file).json")
        }

        return decoded
    }
}

