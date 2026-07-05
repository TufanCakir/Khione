//
//  GreetingsLocalization.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation

extension Bundle {

    func loadGreetings(language: String, fallback: String = "en") -> [Greeting]
    {
        if let cached = GreetingsCache.values[language] {
            return cached
        }

        if let greetings = loadGreetingsFile(language) {
            GreetingsCache.values[language] = greetings
            return greetings
        }

        if let fallbackGreetings = loadGreetingsFile(fallback) {
            GreetingsCache.values[language] = fallbackGreetings
            return fallbackGreetings
        }

        return []
    }

    private func loadGreetingsFile(_ language: String) -> [Greeting]? {

        let file = "greetings_\(language)"

        guard
            let url = url(
                forResource: file,
                withExtension: "json"
            )
        else {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        do {
            return try JSONDecoder().decode([Greeting].self, from: data)
        } catch {
            return nil
        }
    }
}

private enum GreetingsCache {
    static var values: [String: [Greeting]] = [:]
}
