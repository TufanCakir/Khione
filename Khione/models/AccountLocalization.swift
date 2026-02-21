//
//  AccountLocalization.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
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
    let appSection: String
    let appearance: String
    let aboutSection: String
    let version: String
    let builtWith: String

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case title
        case profileNamePlaceholder = "profile_name_placeholder"
        case profileLocal = "profile_local"
        case languageSection = "language_section"
        case languagePicker = "language_picker"
        case languageDE = "language_de"
        case languageEN = "language_en"
        case appSection = "app_section"
        case appearance
        case aboutSection = "about_section"
        case version
        case builtWith = "built_with"
    }
}

extension AccountLocalization {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let f = AccountLocalization.fallback

        title = try c.decodeIfPresent(String.self, forKey: .title) ?? f.title

        profileNamePlaceholder =
            try c.decodeIfPresent(String.self, forKey: .profileNamePlaceholder)
            ?? f.profileNamePlaceholder
        profileLocal =
            try c.decodeIfPresent(String.self, forKey: .profileLocal)
            ?? f.profileLocal

        languageSection =
            try c.decodeIfPresent(String.self, forKey: .languageSection)
            ?? f.languageSection
        languagePicker =
            try c.decodeIfPresent(String.self, forKey: .languagePicker)
            ?? f.languagePicker
        languageDE =
            try c.decodeIfPresent(String.self, forKey: .languageDE)
            ?? f.languageDE
        languageEN =
            try c.decodeIfPresent(String.self, forKey: .languageEN)
            ?? f.languageEN

        appSection =
            try c.decodeIfPresent(String.self, forKey: .appSection)
            ?? f.appSection
        appearance =
            try c.decodeIfPresent(String.self, forKey: .appearance)
            ?? f.appearance

        aboutSection =
            try c.decodeIfPresent(String.self, forKey: .aboutSection)
            ?? f.aboutSection
        version =
            try c.decodeIfPresent(String.self, forKey: .version) ?? f.version
        builtWith =
            try c.decodeIfPresent(String.self, forKey: .builtWith)
            ?? f.builtWith
    }
}

extension AccountLocalization {

    static let fallback = AccountLocalization(
        title: "Account",
        profileNamePlaceholder: "Name",
        profileLocal: "Local profile",
        languageSection: "Language",
        languagePicker: "Select language",
        languageDE: "German",
        languageEN: "English",
        appSection: "App",
        appearance: "Appearance",
        aboutSection: "About",
        version: "Version",
        builtWith: "Built with",
    )
}

extension Bundle {

    func loadAccountLocalization(language: String, fallback: String = "en")
        -> AccountLocalization
    {

        if let loc = loadLocalizationFile(language) {
            return loc
        }

        if let fallbackLoc = loadLocalizationFile(fallback) {
            print("⚠️ Using fallback localization: \(fallback)")
            return fallbackLoc
        }

        print("❌ No localization found – using hard fallback")
        return .fallback
    }

    private func loadLocalizationFile(_ language: String)
        -> AccountLocalization?
    {
        let file = "account_\(language)"
        guard let url = url(forResource: file, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }

        return try? JSONDecoder().decode(AccountLocalization.self, from: data)
    }
}
