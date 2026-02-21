//
//  Greeting.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

import Foundation

struct Greeting: Codable, Identifiable {

    let id: String
    let text: String
    let sfSymbol: String?

    let fromHour: Int?
    let toHour: Int?

    func isValidNow() -> Bool {

        guard let from = fromHour,
            let to = toHour
        else { return true }

        let hour = Calendar.current.component(.hour, from: Date())

        // normal range
        if from <= to {
            return hour >= from && hour < to
        }

        // overnight range (21 -> 5)
        return hour >= from || hour < to
    }

    static func fallback() -> Greeting {

        Greeting(
            id: "fallback",
            text: "Welcome",
            sfSymbol: "snowflake",
            fromHour: nil,
            toHour: nil
        )
    }
}
