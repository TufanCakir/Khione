//
//  ChatPersistence.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation

struct ChatArchive: Codable, Equatable {
    var sessions: [ChatSession]
    var activeID: UUID?
}

protocol ChatPersisting {
    func load() throws -> ChatArchive?
    func save(_ archive: ChatArchive) throws
}

struct FileChatPersistence: ChatPersisting {
    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        fileURL: URL = Self.defaultFileURL,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        self.decoder = JSONDecoder()
    }

    func load() throws -> ChatArchive? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(ChatArchive.self, from: data)
    }

    func save(_ archive: ChatArchive) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(archive)
        try data.write(
            to: fileURL,
            options: [.atomic, .completeFileProtectionUnlessOpen]
        )
    }

    private static var defaultFileURL: URL {
        let baseURL =
            FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
            ?? FileManager.default.temporaryDirectory

        return
            baseURL
            .appendingPathComponent("Khione", isDirectory: true)
            .appendingPathComponent("chat-history.json", isDirectory: false)
    }
}
