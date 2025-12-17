//
//  AccountLocalization.swift
//  Khione
//

import Foundation

struct AccountLocalization: Decodable {

    let title: String

    let profileNamePlaceholder: String
    let profileLocal: String

    let languageSection: String
    let languagePicker: String
    let languageDE: String
    let languageEN: String

    let subscriptionSection: String
    let currentPlan: String
    let upgrade: String
    let manageSubscription: String
    let activeSubscription: String

    let appSection: String
    let appearance: String

    let aboutSection: String
    let version: String
    let builtWith: String
    let tos: String
    let privacy: String

    // MARK: - Coding Keys (JSON bleibt unverändert)
    enum CodingKeys: String, CodingKey {
        case title

        case profileNamePlaceholder = "profile_name_placeholder"
        case profileLocal = "profile_local"

        case languageSection = "language_section"
        case languagePicker = "language_picker"
        case languageDE = "language_de"
        case languageEN = "language_en"

        case subscriptionSection = "subscription_section"
        case currentPlan = "current_plan"
        case upgrade
        case manageSubscription = "manage_subscription"
        case activeSubscription = "active_subscription"

        case appSection = "app_section"
        case appearance

        case aboutSection = "about_section"
        case version
        case builtWith = "built_with"
        case tos
        case privacy
    }
}


extension AccountLocalization {

    static let fallback = AccountLocalization(
        title: "Account",

        profileNamePlaceholder: "Name",
        profileLocal: "Local",

        languageSection: "Language",
        languagePicker: "Select language",
        languageDE: "German",
        languageEN: "English",

        subscriptionSection: "Subscription",
        currentPlan: "Current Plan",
        upgrade: "Upgrade",
        manageSubscription: "Manage Subscription",
        activeSubscription: "Active",

        appSection: "App",
        appearance: "Appearance",

        aboutSection: "About",
        version: "Version",
        builtWith: "Built with",
        tos: "Terms of Service",
        privacy: "Privacy Policy"
    )
}

extension Bundle {

    func loadAccountLocalization(
        language: String,
        fallback: String = "en"
    ) -> AccountLocalization {

        if let localization = loadLocalizationFile(language) {
            return localization
        }

        if let fallbackLocalization = loadLocalizationFile(fallback) {
            print("⚠️ Fallback localization used: \(fallback)")
            return fallbackLocalization
        }

        assertionFailure("❌ No valid AccountLocalization found")
        return .fallback
    }

    private func loadLocalizationFile(_ language: String) -> AccountLocalization? {
        let file = "account_\(language)"

        guard
            let url = url(forResource: file, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(AccountLocalization.self, from: data)
        else {
            return nil
        }

        return decoded
    }
}
