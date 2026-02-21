//
//  ReplyStylesLocalization.swift
//  Khione
//
//  Created by Tufan Cakir on 21.02.26.
//

import Foundation

extension Bundle {

    func loadReplyStyles(

        language: String =
            Locale.current.language.languageCode?.identifier ?? "en",

        fallback: String = "en"

    ) -> [ReplyStyle] {

        // Primary language

        if let styles = loadReplyStylesFile(language) {

            return styles
        }

        // fallback

        if let fallbackStyles = loadReplyStylesFile(fallback) {

            print("⚠️ Using fallback reply_styles:", fallback)

            return fallbackStyles
        }

        print("❌ Missing reply_styles localization")

        return []
    }

    private func loadReplyStylesFile(
        _ language: String
    ) -> [ReplyStyle]? {

        let file = "reply_styles_\(language)"

        guard
            let url = url(
                forResource: file,
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url)
        else {

            return nil
        }

        return try? JSONDecoder().decode(
            [ReplyStyle].self,
            from: data
        )
    }
}
