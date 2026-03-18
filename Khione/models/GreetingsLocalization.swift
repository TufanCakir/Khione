//
//  GreetingsLocalization.swift
//  Khione
//
//  Created by Tufan Cakir on 21.02.26.
//

import Foundation

extension Bundle {
    
    func loadGreetings(language: String, fallback: String = "en") -> [Greeting] {

        print("🌍 Requested language:", language)

        if let greetings = loadGreetingsFile(language) {
            print("✅ Using language:", language)
            return greetings
        }

        print("⚠️ Falling back to:", fallback)

        if let fallbackGreetings = loadGreetingsFile(fallback) {
            return fallbackGreetings
        }

        print("❌ No greetings found at all")
        return []
    }
    
    private func loadGreetingsFile(_ language: String) -> [Greeting]? {
        
        let file = "greetings_\(language)"
        print("🔍 Trying to load greetings file:", file)
        
        guard let url = url(
            forResource: file,
            withExtension: "json"
        ) else {
            print("❌ File NOT found:", file)
            return nil
        }
        
        print("✅ File FOUND:", file)
        
        guard let data = try? Data(contentsOf: url) else {
            print("❌ Could not read data:", file)
            return nil
        }
        
        do {
            let decoded = try JSONDecoder().decode([Greeting].self, from: data)
            print("✅ Decoded greetings count:", decoded.count)
            return decoded
        } catch {
            print("❌ JSON decode error:", error)
            return nil
        }
    }
}
