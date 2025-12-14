//
//  AppTheme.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import Foundation

struct AppTheme: Identifiable, Decodable {
    let id: String
    let name: String
    let icon: String
    let accentColor: String
    let preferredScheme: String? // "light", "dark", "system"
    let backgroundColor: String?   // 👈 neu
}


extension Bundle {
    func loadThemes() -> [AppTheme] {
        guard let url = url(forResource: "themes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let themes = try? JSONDecoder().decode([AppTheme].self, from: data)
        else {
            return []
        }
        return themes
    }
}

