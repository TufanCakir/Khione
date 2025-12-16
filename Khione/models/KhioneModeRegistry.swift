//
//  KhioneModeRegistry.swift
//  Khione
//
//  Created by Tufan Cakir on 16.12.25.
//

import Foundation

enum KhioneModeRegistry {

    static let all: [KhioneMode] = {
        Bundle.main.loadKhioneModes()
    }()
}
