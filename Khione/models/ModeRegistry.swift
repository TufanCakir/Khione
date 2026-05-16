//
//  ModeRegistry.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation

enum ModeRegistry {

    static let all: [Mode] = {
        Bundle.main.loadKhioneModes()
    }()
}
