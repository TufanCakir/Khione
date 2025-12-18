//
//  KhioneMode.swift
//  Khione
//

import Foundation

struct KhioneMode: Identifiable, Decodable, Equatable {
    let id: String
    let name: String
    let icon: String
    let systemPrompt: String
}

extension KhioneMode {

    static let fallbackModes: [KhioneMode] = [
        KhioneMode(
            id: "chat",
            name: "Chat",
            icon: "bubble.left.and.bubble.right",
            systemPrompt: "You are a helpful assistant."
        )
    ]
}

extension Bundle {

    func loadKhioneModes() -> [KhioneMode] {

        guard let url = url(forResource: "khione_modes", withExtension: "json")
        else {
            assertionFailure("❌ khione_modes.json not found")
            return KhioneMode.fallbackModes
        }

        do {
            let data = try Data(contentsOf: url)
            let modes = try JSONDecoder().decode([KhioneMode].self, from: data)
            return modes.isEmpty ? KhioneMode.fallbackModes : modes
        } catch {
            print("❌ Failed to load Khione modes:", error)
            return KhioneMode.fallbackModes
        }
    }
}
