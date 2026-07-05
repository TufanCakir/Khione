//
//  AppTheme.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation
import SwiftUI

struct AppTheme: Identifiable, Decodable {

    let id: String
    let name: String
    let icon: String

    /// Hex oder System-Farbname
    let accentColor: String

    /// "light" | "dark" | "system"
    let preferredScheme: String?

    /// Hex / Asset / special keyword
    let backgroundColor: String?

    // MARK: - Convenience

    var resolvedScheme: ColorScheme? {
        switch preferredScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil  // system
        }
    }
}

extension Bundle {

    func loadThemes() -> [AppTheme] {
        if let cached = ThemeCache.values {
            return cached
        }

        guard let url = url(forResource: "themes", withExtension: "json") else {
            assertionFailure("❌ themes.json not found")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let themes = try JSONDecoder().decode([AppTheme].self, from: data)
            ThemeCache.values = themes
            return themes
        } catch {
            return []
        }
    }
}

private enum ThemeCache {
    static var values: [AppTheme]?
}
