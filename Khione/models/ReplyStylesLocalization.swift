//
//  ReplyStylesLocalization.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation

extension Bundle {

    func loadReplyStyles(

        language: String =
            Locale.current.language.languageCode?.identifier ?? "en",

        fallback: String = "en"

    ) -> [ReplyStyle] {
        if let cached = ReplyStylesCache.values[language] {
            return cached
        }

        if let styles = loadReplyStylesFile(language) {
            ReplyStylesCache.values[language] = styles
            return styles
        }

        if let fallbackStyles = loadReplyStylesFile(fallback) {
            ReplyStylesCache.values[language] = fallbackStyles
            return fallbackStyles
        }

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

private enum ReplyStylesCache {
    static var values: [String: [ReplyStyle]] = [:]
}
