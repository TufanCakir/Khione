//
//  AttachmentPreviewView.swift
//  Khione
//
//  Created by Tufan Cakir on 28.06.26.
//

import SwiftUI
import UIKit

struct AttachmentPreviewView: View {
    @Binding var image: UIImage?
    let removeLabel: String
    let removeHint: String

    var body: some View {
        if let image {
            HStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    self.image = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel(removeLabel)
                .accessibilityHint(removeHint)

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 12)
        }
    }
}
