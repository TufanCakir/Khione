//
//  ChatMessage.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import Foundation
import UIKit

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let text: String?
    let image: UIImage?
    
    var isCode: Bool {
        text?.contains("```") == true
    }
}


enum Role {
    case user
    case assistant
}
