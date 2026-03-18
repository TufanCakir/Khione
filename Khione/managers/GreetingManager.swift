//
//  GreetingManager.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

import Foundation

enum GreetingManager {

    private static let key = "did_greet_this_session"

    // MARK: - Session Handling

    static func shouldGreet() -> Bool {
        !UserDefaults.standard.bool(forKey: key)
    }

    static func markGreeted() {
        UserDefaults.standard.set(true, forKey: key)
    }

    static func resetSession() {
        UserDefaults.standard.removeObject(forKey: key)
    }


    // MARK: - Greeting Logic

    static func currentGreeting(language: String) -> Greeting {

        let normalized = String(language.prefix(2)) // 🔥 wichtig

        let greetings = Bundle.main.loadGreetings(language: normalized)

        let valid = greetings.filter { $0.isValidNow() }

        if let match = valid.first {
            return match
        }

        if let generic = greetings.first(where: { $0.id == "GENERIC" }) {
            return generic
        }

        return Greeting.fallback()
    }

    // MARK: - Optional Random (safe)

    static func randomGreeting(language: String) -> Greeting {

        let normalized = String(language.prefix(2))

        let greetings = Bundle.main.loadGreetings(language: normalized)

        let valid = greetings.filter { $0.isValidNow() }

        // Wenn mehrere gültig → random
        if !valid.isEmpty {
            return valid.randomElement()!
        }

        // fallback chain
        if let generic = greetings.first(where: { $0.id == "GENERIC" }) {
            return generic
        }

        return Greeting.fallback()
    }
}
