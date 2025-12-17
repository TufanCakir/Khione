//
//  AppTheme.swift
//  Khione
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
        default: return nil // system
        }
    }
}


extension Bundle {

    func loadThemes() -> [AppTheme] {
        guard let url = url(forResource: "themes", withExtension: "json") else {
            assertionFailure("❌ themes.json not found")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([AppTheme].self, from: data)
        } catch {
            print("❌ Failed to load themes:", error)
            return []
        }
    }
}
