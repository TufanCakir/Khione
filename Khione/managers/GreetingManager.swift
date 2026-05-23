//
//  GreetingManager.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
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
}
