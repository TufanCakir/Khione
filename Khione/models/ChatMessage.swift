//
//  ChatMessage.swift
//  Khione
//

import Foundation
import UIKit

struct ChatMessage: Identifiable, Equatable {

    let id: UUID
    let role: Role
    let text: String?
    let image: UIImage?
    let createdAt: Date

    // MARK: - Init
    init(
        id: UUID = UUID(),
        role: Role,
        text: String? = nil,
        image: UIImage? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.image = image
        self.createdAt = createdAt
    }

    // MARK: - Helpers
    var isCode: Bool {
        guard let text else { return false }
        return text.contains("```")
    }

    var isEmpty: Bool {
        (text?.isEmpty ?? true) && image == nil
    }
}

enum Role: String, Codable {
    case user
    case assistant
}
