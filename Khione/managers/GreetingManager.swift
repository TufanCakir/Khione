//
//  GreetingManager.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

import Foundation

enum GreetingManager {

    private static let key = "khione_did_greet_this_session"

    static func shouldGreet() -> Bool {
        !UserDefaults.standard.bool(forKey: key)
    }

    static func markGreeted() {
        UserDefaults.standard.set(true, forKey: key)
    }

    static func resetSession() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    static func randomGreeting() -> Greeting {
        let all = Bundle.main.loadGreetings()
        let valid = all.filter { $0.isValidNow() }
        return valid.randomElement() ?? Greeting.fallback()
    }
}
