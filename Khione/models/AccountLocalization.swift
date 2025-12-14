//
//  AccountLocalization.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import Foundation

struct AccountLocalization: Decodable {
    let title: String

    let profile_name_placeholder: String
    let profile_local: String

    let language_section: String
    let language_picker: String
    let language_de: String
    let language_en: String

    let subscription_section: String
    let current_plan: String
    let upgrade: String
    let manage_subscription: String
    let active_subscription: String

    let app_section: String
    let appearance: String

    let about_section: String
    let version: String
    let built_with: String
    let tos: String
    let privacy: String
}

extension Bundle {
    func loadAccountLocalization(language: String) -> AccountLocalization {
        let file = "account_\(language)"

        guard
            let url = url(forResource: file, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(
                AccountLocalization.self,
                from: data
            )
        else {
            fatalError("❌ Missing localization: \(file).json")
        }

        return decoded
    }
}

