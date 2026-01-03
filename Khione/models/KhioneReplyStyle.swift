//
//  KhioneReplyStyle.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

import Foundation

struct KhioneReplyStyle: Identifiable, Decodable {
    let id: String
    let name: String
    let icon: String
    let prompt: String
}

extension Bundle {

    func loadReplyStyles() -> [KhioneReplyStyle] {
        guard
            let url = self.url(
                forResource: "reply_styles",
                withExtension: "json"
            )
        else {
            print("❌ reply_styles.json not found")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([KhioneReplyStyle].self, from: data)
        } catch {
            print("❌ Failed to load reply styles:", error)
            return []
        }
    }
}
