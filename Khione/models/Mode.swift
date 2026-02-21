//
//  Mode.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
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

        guard let url = url(forResource: "modes", withExtension: "json")
        else {
            assertionFailure("❌ modes.json not found")
            return Mode.fallbackModes
        }

        do {
            let data = try Data(contentsOf: url)
            let modes = try JSONDecoder().decode([Mode].self, from: data)
            return modes.isEmpty ? Mode.fallbackModes : modes
        } catch {
            print("❌ Failed to load modes:", error)
            return Mode.fallbackModes
        }
    }
}
