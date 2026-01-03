//
//  KhioneViewLocalization.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation

struct KhioneViewLocalization: Decodable {

    let thinking: String
    let messagePlaceholder: String
    let imageInfo: String
    let openImagePlayground: String
    let messagesAvailable: String
    let nextMessageIn: String
    let visionLocked: String

    // 🧊 Greeting
    let welcomeNoName: String
    let welcomeWithName: String

    enum CodingKeys: String, CodingKey {
        case thinking
        case messagePlaceholder = "message_placeholder"
        case imageInfo = "image_info"
        case openImagePlayground = "open_image_playground"
        case messagesAvailable = "messages_available"
        case nextMessageIn = "next_message_in"
        case visionLocked = "vision_locked"
        case welcomeNoName = "welcome_no_name"
        case welcomeWithName = "welcome_with_name"
    }
}

extension KhioneViewLocalization {

    static let fallback = KhioneViewLocalization(
        thinking: "Thinking…",
        messagePlaceholder: "Message…",
        imageInfo: "Images via Image Playground",
        openImagePlayground: "Open Image Playground",
        messagesAvailable: "Messages available",
        nextMessageIn: "Next message in %@",
        visionLocked: "Vision",
        welcomeNoName: "Welcome to Khione",
        welcomeWithName: "Welcome, %@"
    )
}

extension Bundle {

    func loadKhioneViewLocalization(
        language: String = Locale.current.language.languageCode?.identifier
            ?? "en",
        fallback: String = "en"
    ) -> KhioneViewLocalization {

        if let loc = loadKhioneViewFile(language) {
            return loc
        }

        if let fallbackLoc = loadKhioneViewFile(fallback) {
            print("⚠️ Using fallback khione_view localization:", fallback)
            return fallbackLoc
        }

        print("❌ Missing khione_view localization – using hard fallback")
        return .fallback
    }

    private func loadKhioneViewFile(_ language: String)
        -> KhioneViewLocalization?
    {
        let file = "khione_view_\(language)"
        guard
            let url = url(forResource: file, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }

        return try? JSONDecoder().decode(
            KhioneViewLocalization.self,
            from: data
        )
    }
}
