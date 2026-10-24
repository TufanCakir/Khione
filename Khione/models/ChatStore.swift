//
//  ChatStore.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

internal import Combine
import Foundation
import OSLog
import SwiftUI

@MainActor
final class ChatStore: ObservableObject {
    @Published private(set) var sessions: [ChatSession] = []
    @Published var activeID: UUID?

    static let newChatTitle = "New Chat"

    private enum LegacyKey {
        static let sessions = "chat_sessions"
        static let activeID = "chat_sessions_active"
    }

    private let persistence: any ChatPersisting
    private let legacyDefaults: UserDefaults?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Khione",
        category: "ChatPersistence"
    )

    convenience init() {
        self.init(
            persistence: FileChatPersistence(),
            legacyDefaults: .standard
        )
    }

    init(
        persistence: any ChatPersisting,
        legacyDefaults: UserDefaults?
    ) {
        self.persistence = persistence
        self.legacyDefaults = legacyDefaults
        load()

        if sessions.isEmpty {
            createNewChat()
        }
    }

    var activeChatIndex: Int? {
        guard let activeID else { return nil }
        return sessions.firstIndex { $0.id == activeID }
    }

    var activeChat: ChatSession? {
        guard let activeChatIndex else { return nil }
        return sessions[activeChatIndex]
    }

    func updateActiveChat(_ update: (inout ChatSession) -> Void) {
        guard let activeChatIndex else { return }
        update(&sessions[activeChatIndex])
        save()
    }

    func createNewChat() {
        if activeChat?.messages.isEmpty == true {
            return
        }

        let chat = ChatSession(title: Self.newChatTitle)
        sessions.insert(chat, at: 0)
        activeID = chat.id
        save()
    }

    func renameActiveChat(to title: String) {
        updateActiveChat {
            $0.title = Self.normalizedTitle(title)
        }
    }

    func rename(_ chat: ChatSession, to newTitle: String) {
        guard let index = sessions.firstIndex(where: { $0.id == chat.id })
        else {
            return
        }

        sessions[index].title = Self.normalizedTitle(newTitle)
        save()
    }

    func delete(_ chat: ChatSession) {
        sessions.removeAll { $0.id == chat.id }

        if sessions.isEmpty {
            insertEmptyChat()
        } else if activeID == chat.id {
            activeID = sessions.first?.id
        }

        save()
    }

    func deleteChats(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)

        if sessions.isEmpty {
            insertEmptyChat()
        } else {
            activeID = sessions.first?.id
        }

        save()
    }

    func moveChats(from source: IndexSet, to destination: Int) {
        sessions.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func update(messages: [ChatMessage]) {
        updateActiveChat {
            $0.messages = messages
        }
    }

    private func save() {
        do {
            try persistence.save(
                ChatArchive(sessions: sessions, activeID: activeID)
            )
        } catch {
            logger.error(
                "Could not save chat history: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func load() {
        do {
            if let archive = try persistence.load() {
                apply(archive)
                return
            }

            try migrateLegacyArchiveIfAvailable()
        } catch {
            logger.error(
                "Could not load chat history: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func apply(_ archive: ChatArchive) {
        sessions = archive.sessions

        if let activeID = archive.activeID,
            sessions.contains(where: { $0.id == activeID })
        {
            self.activeID = activeID
        } else {
            activeID = sessions.first?.id
        }
    }

    private func migrateLegacyArchiveIfAvailable() throws {
        guard
            let legacyDefaults,
            let data = legacyDefaults.data(forKey: LegacyKey.sessions),
            let legacySessions = try? JSONDecoder().decode(
                [ChatSession].self,
                from: data
            )
        else {
            return
        }

        let storedActiveID =
            legacyDefaults
            .string(forKey: LegacyKey.activeID)
            .flatMap(UUID.init(uuidString:))

        let archive = ChatArchive(
            sessions: legacySessions,
            activeID: storedActiveID
        )
        try persistence.save(archive)
        apply(archive)

        legacyDefaults.removeObject(forKey: LegacyKey.sessions)
        legacyDefaults.removeObject(forKey: LegacyKey.activeID)
    }

    private func insertEmptyChat() {
        let chat = ChatSession(title: Self.newChatTitle)
        sessions.insert(chat, at: 0)
        activeID = chat.id
    }

    private static func normalizedTitle(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? newChatTitle : trimmed
    }
}
