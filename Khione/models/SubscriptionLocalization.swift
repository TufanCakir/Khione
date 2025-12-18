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

    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case subscribe
        case restore
        case active
    }
}

extension SubscriptionLocalization {

    static let fallback = SubscriptionLocalization(
        title: "Upgrade Khione",
        subtitle: "Unlock advanced modes and features",
        subscribe: "Subscribe",
        restore: "Restore Purchases",
        active: "Active"
    )
}

extension SubscriptionLocalization {

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let f = SubscriptionLocalization.fallback

        title = try c.decodeIfPresent(String.self, forKey: .title) ?? f.title
        subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle) ?? f.subtitle
        subscribe = try c.decodeIfPresent(String.self, forKey: .subscribe) ?? f.subscribe
        restore = try c.decodeIfPresent(String.self, forKey: .restore) ?? f.restore
        active = try c.decodeIfPresent(String.self, forKey: .active) ?? f.active
    }
}


extension Bundle {

    func loadSubscriptionLocalization(
        language: String = Locale.current.language.languageCode?.identifier ?? "en",
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

    private func loadSubscriptionFile(_ language: String) -> SubscriptionLocalization? {
        let file = "subscription_\(language)"
        guard let url = url(forResource: file, withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }

        return try? JSONDecoder().decode(SubscriptionLocalization.self, from: data)
    }
}
