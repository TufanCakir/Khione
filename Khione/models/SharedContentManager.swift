//
//  SharedContentManager.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation

struct SharedContent: Equatable {
    let text: String?
    let url: URL?

    var isEmpty: Bool {
        cleanText == nil && url == nil
    }

    var prompt: String {
        var parts: [String] = []

        if let cleanText {
            parts.append(cleanText)
        }

        if let url {
            parts.append(url.absoluteString)
        }

        return parts.joined(separator: "\n\n")
    }

    private var cleanText: String? {
        guard let text else { return nil }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

enum SharedContentManager {
    static let urlScheme = "khione"
    static let shareHost = "share"

    // Use the same value in the Share Extension App Group entitlement.
    static let appGroupIdentifier = "group.khione.shared"

    private static let pendingTextKey = "pendingSharedText"
    private static let pendingURLKey = "pendingSharedURL"

    static func consumeSharedContent(from url: URL? = nil) -> SharedContent? {
        let urlContent = content(from: url)
        let storedContent = consumeStoredContent()

        let content = SharedContent(
            text: urlContent.text ?? storedContent.text,
            url: urlContent.url ?? storedContent.url
        )

        return content.isEmpty ? nil : content
    }

    static func prompt(for content: SharedContent, language: String) -> String {
        if language == "de" {
            return "Hilf mir mit diesem Inhalt:\n\n\(content.prompt)"
        }

        return "Help me with this content:\n\n\(content.prompt)"
    }
}

extension SharedContentManager {
    fileprivate static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    fileprivate static func consumeStoredContent() -> SharedContent {
        guard let defaults = sharedDefaults else {
            return SharedContent(text: nil, url: nil)
        }

        let text = defaults.string(forKey: pendingTextKey)
        let url = defaults.string(forKey: pendingURLKey).flatMap(
            URL.init(string:)
        )

        defaults.removeObject(forKey: pendingTextKey)
        defaults.removeObject(forKey: pendingURLKey)

        return SharedContent(text: text, url: url)
    }

    fileprivate static func content(from url: URL?) -> SharedContent {
        guard let url else {
            return SharedContent(text: nil, url: nil)
        }

        guard url.scheme == urlScheme, url.host == shareHost else {
            return SharedContent(text: nil, url: nil)
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let text = components?.queryItems?.first { $0.name == "text" }?.value
        let sharedURL = components?.queryItems?
            .first { $0.name == "url" }?
            .value
            .flatMap(URL.init(string:))

        return SharedContent(text: text, url: sharedURL)
    }
}
