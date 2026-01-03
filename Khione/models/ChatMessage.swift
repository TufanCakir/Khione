//
//  ChatMessage.swift
//  Khione
//

import Foundation
import UIKit

enum MessageKind: String, Codable {
    case normal
    case greeting
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: Role
    let kind: MessageKind
    let text: String?
    let imageData: Data?
    let emoji: String?
    let leadingSymbol: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        role: Role,
        kind: MessageKind = .normal,
        text: String? = nil,
        image: UIImage? = nil,
        emoji: String? = nil,
        leadingSymbol: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.role = role
        self.kind = kind
        self.text = text
        self.imageData = image?.jpegData(compressionQuality: 0.8)
        self.emoji = emoji
        self.leadingSymbol = leadingSymbol
        self.createdAt = createdAt
    }

    // MARK: - Helpers

    var image: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }

    var isCode: Bool {
        text?.contains("```") ?? false
    }

    var isEmpty: Bool {
        (text?.isEmpty ?? true) && imageData == nil
    }

    var isGreeting: Bool {
        kind == .greeting && role == .assistant
    }
}

enum Role: String, Codable {
    case user
    case assistant
    case system
}
