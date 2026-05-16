//
//  ReplyStyle.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation

struct ReplyStyle: Identifiable, Decodable, Equatable {
    let id: String
    let name: String
    let icon: String
    let prompt: String
}
