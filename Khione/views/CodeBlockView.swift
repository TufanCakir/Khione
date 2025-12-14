//
//  CodeBlockView.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import SwiftUI

struct CodeBlockView: View {
    
    let code: String
    let canCopy: Bool
    
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack {
                Text("Code")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if canCopy {
                    Button {
                        UIPasteboard.general.string = code
                        copied = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            copied = false
                        }
                    } label: {
                        Label(copied ? "Copied" : "Copy",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                    .font(.caption)
                }
            }
            
            ScrollView(.horizontal) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .background(Color.black.opacity(0.85))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

