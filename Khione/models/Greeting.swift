//
//  Greeting.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

import Foundation

struct Greeting: Codable, Identifiable {
    let id: UUID
    let text: String
    let sfSymbol: String?
    let fromHour: Int?
    let toHour: Int?

    func isValidNow() -> Bool {
        guard let from = fromHour, let to = toHour else { return true }

        let hour = Calendar.current.component(.hour, from: Date())

        // Normaler Bereich (z.B. 5–11)
        if from <= to {
            return (from...to).contains(hour)
        }

        // Über-Mitternacht-Bereich (z.B. 22–4)
        return hour >= from || hour <= to
    }

    static func fallback() -> Greeting {
        Greeting(
            id: UUID(),
            text: "Welcome to Khione",
            sfSymbol: "sparkles",
            fromHour: nil,
            toHour: nil
        )
    }
}

extension Bundle {
    func loadGreetings() -> [Greeting] {
        // Try to locate the greetings.json file in this bundle
        guard
            let url = self.url(forResource: "greetings", withExtension: "json")
        else {
            // If not found, return a sensible fallback
            return [Greeting.fallback()]
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            // If the JSON contains dates or needs custom strategies, configure decoder here
            let greetings = try decoder.decode([Greeting].self, from: data)
            return greetings
        } catch {
            // If decoding fails, return fallback and consider logging
            return [Greeting.fallback()]
        }
    }
}
