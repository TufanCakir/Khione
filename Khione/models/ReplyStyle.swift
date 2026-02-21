//
//  ReplyStyle.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

import Foundation

struct ReplyStyle: Identifiable, Decodable, Equatable {
    let id: String
    let name: String
    let icon: String
    let prompt: String
}
