//
//  EmptyChatPlaceholder.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

import SwiftUI

struct EmptyChatPlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 42))
                .foregroundColor(.secondary)

            Text("Select a chat")
                .foregroundColor(.secondary)
        }
    }
}
