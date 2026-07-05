//
//  Mode.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation

struct Mode: Identifiable, Decodable, Equatable {
    let id: String
    let name: String
    let icon: String
    let systemPrompt: String
}

extension Mode {

    static let fallbackModes: [Mode] = [
        Mode(
            id: "chat",
            name: "Chat",
            icon: "bubble.left.and.bubble.right",
            systemPrompt: "You are a helpful assistant."
        )
    ]
}

extension Bundle {

    func loadKhioneModes() -> [Mode] {
        if let cached = ModeCache.values {
            return cached
        }

        guard let url = url(forResource: "modes", withExtension: "json")
        else {
            assertionFailure("❌ modes.json not found")
            ModeCache.values = Mode.fallbackModes
            return Mode.fallbackModes
        }

        do {
            let data = try Data(contentsOf: url)
            let modes = try JSONDecoder().decode([Mode].self, from: data)
            let result = modes.isEmpty ? Mode.fallbackModes : modes
            ModeCache.values = result
            return result
        } catch {
            ModeCache.values = Mode.fallbackModes
            return Mode.fallbackModes
        }
    }
}

private enum ModeCache {
    static var values: [Mode]?
}
