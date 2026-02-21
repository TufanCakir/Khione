//
//  ViewLocalization.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation

struct ViewLocalization: Decodable {

    let thinking: String
    let messagePlaceholder: String
    let imageInfo: String
    let openImagePlayground: String
    let welcomeNoName: String
    let welcomeWithName: String

    enum CodingKeys: String, CodingKey {
        case thinking
        case messagePlaceholder = "message_placeholder"
        case imageInfo = "image_info"
        case openImagePlayground = "open_image_playground"
        case welcomeNoName = "welcome_no_name"
        case welcomeWithName = "welcome_with_name"
    }
}

extension ViewLocalization {

    static let fallback = ViewLocalization(
        thinking: "Thinking…",
        messagePlaceholder: "Message…",
        imageInfo: "Images via Image Playground",
        openImagePlayground: "Open Image Playground",
        welcomeNoName: "Welcome to Teanttra",
        welcomeWithName: "Welcome, %@"
    )
}

extension Bundle {

    func loadKhioneViewLocalization(
        language: String = Locale.current.language.languageCode?.identifier
            ?? "en",
        fallback: String = "en"
    ) -> ViewLocalization {

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
        -> ViewLocalization?
    {
        let file = "view_\(language)"
        guard
            let url = url(forResource: file, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }

        return try? JSONDecoder().decode(
            ViewLocalization.self,
            from: data
        )
    }
}
