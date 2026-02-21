//
//  GreetingsLocalization.swift
//  Khione
//
//  Created by Tufan Cakir on 21.02.26.
//

import Foundation

extension Bundle {

    func loadGreetings(

        language: String =
            Locale.current.language.languageCode?.identifier ?? "en",

        fallback: String = "en"

    ) -> [Greeting] {

        // Primary language

        if let greetings = loadGreetingsFile(language) {

            return greetings
        }

        // fallback

        if let fallbackGreetings =
            loadGreetingsFile(fallback)
        {

            print("⚠️ Using fallback greetings:", fallback)

            return fallbackGreetings
        }

        print("❌ Missing greetings localization")

        return []
    }

    private func loadGreetingsFile(
        _ language: String
    ) -> [Greeting]? {

        let file = "greetings_\(language)"

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
            [Greeting].self,
            from: data
        )
    }
}
