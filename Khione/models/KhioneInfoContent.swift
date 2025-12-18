//
//  KhioneInfoContent.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation

struct KhioneInfoContent: Decodable {
    let title: String
    let subtitle: String
    let sections: [KhioneInfoSection]
}

struct KhioneInfoSection: Decodable, Identifiable {
    let id: UUID
    let title: String
    let text: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()  // 👈 lokal generiert
        self.title = try container.decode(String.self, forKey: .title)
        self.text = try container.decode(String.self, forKey: .text)
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case text
    }
}

extension Bundle {
    func loadKhioneInfo(language: String) -> KhioneInfoContent {
        let files = ["info_\(language)", "info_en"]

        for file in files {
            if let url = url(forResource: file, withExtension: "json"),
                let data = try? Data(contentsOf: url),
                let decoded = try? JSONDecoder().decode(
                    KhioneInfoContent.self,
                    from: data
                )
            {
                return decoded
            }
        }

        fatalError("❌ Missing info JSON files")
    }
}
