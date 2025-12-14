//
//  KhioneMode.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import Foundation

struct KhioneMode: Identifiable, Decodable {
    let id: String
    let name: String
    let icon: String
    let systemPrompt: String
}

extension Bundle {
    func loadKhioneModes() -> [KhioneMode] {
        guard let url = url(forResource: "khione_modes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let modes = try? JSONDecoder().decode([KhioneMode].self, from: data)
        else {
            return []
        }
        return modes
    }
}

