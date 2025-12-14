//
//  ThemeManager.swift
//  Khione
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
final class ThemeManager: ObservableObject {

    // MARK: - Data
    @Published private(set) var themes: [AppTheme] = Bundle.main.loadThemes()

    @AppStorage("selectedThemeID")
    private var selectedThemeID: String = "system"

    // MARK: - Selected Theme
    var selectedTheme: AppTheme {
        themes.first { $0.id == selectedThemeID }
        ?? themes.first { $0.id == "system" }
        ?? themes.first!
    }

    var backgroundColor: Color {
        let bg = selectedTheme.backgroundColor?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // System oder leer → System Background
        guard !bg.isEmpty, selectedTheme.id != "system" else {
            return Color(.systemBackground)
        }

        return Color(hex: bg)
    }

    // MARK: - Color Scheme
    var colorScheme: ColorScheme? {
        switch selectedTheme.preferredScheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // system
        }
    }

    // MARK: - Accent Color
    var accentColor: Color {
        let hex = selectedTheme.accentColor.trimmingCharacters(in: .whitespacesAndNewlines)

        // System theme or empty color → use system accent
        guard !hex.isEmpty, selectedTheme.id != "system" else {
            return .accentColor
        }

        return Color(hex: hex)
    }

    // MARK: - Public API
    func selectTheme(_ theme: AppTheme) {
        selectedThemeID = theme.id
    }
}
