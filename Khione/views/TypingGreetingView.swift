//
//  TypingGreetingView.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

import SwiftUI

struct TypingGreetingView: View {
    let text: String
    @State private var shown = ""

    var body: some View {
        Text(shown)
            .font(.body)
            .onAppear {
                Task {
                    for c in text {
                        try? await Task.sleep(nanoseconds: 35_000_000)
                        shown.append(c)
                    }
                }
            }
    }
}
