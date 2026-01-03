//
//  ChatStore.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

internal import Combine
import Foundation
import SwiftUI

@MainActor
final class ChatStore: ObservableObject {

    @Published var sessions: [ChatSession] = []
    @Published var activeID: UUID?

    private let key = "khione_chat_sessions"

    init() {
        load()

        if sessions.isEmpty {
            createNewChat()
        }
    }

    func deleteChats(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)

        if let first = sessions.first {
            activeID = first.id
        } else {
            createNewChat()  // ← 🔥 AUTO-REGENERATION
            return
        }

        save()
    }

    func moveChats(from source: IndexSet, to destination: Int) {
        sessions.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func renameActiveChat(to title: String) {
        guard let id = activeID,
            let i = sessions.firstIndex(where: { $0.id == id })
        else { return }
        sessions[i].title = title
        save()
    }

    func createNewChat() {
        if activeChat?.messages.isEmpty == true { return }  // verhindert Spam

        let chat = ChatSession(title: "New Chat")
        sessions.insert(chat, at: 0)
        activeID = chat.id
        save()
    }

    func rename(_ chat: ChatSession, to newTitle: String) {
        guard let index = sessions.firstIndex(where: { $0.id == chat.id })
        else { return }

        sessions[index].title = newTitle.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        save()
    }

    func delete(_ chat: ChatSession) {
        sessions.removeAll { $0.id == chat.id }

        if sessions.isEmpty {
            createNewChat()
        } else if activeID == chat.id {
            activeID = sessions.first?.id
        }

        save()
    }

    var activeChat: ChatSession? {
        sessions.first { $0.id == activeID }
    }

    func update(messages: [ChatMessage]) {
        guard let id = activeID,
            let i = sessions.firstIndex(where: { $0.id == id })
        else { return }
        sessions[i].messages = messages
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: key)
            UserDefaults.standard.set(
                activeID?.uuidString,
                forKey: "\(key)_active"
            )
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
            let chats = try? JSONDecoder().decode(
                [ChatSession].self,
                from: data
            )
        {

            sessions = chats

            if let id = UserDefaults.standard.string(forKey: "\(key)_active"),
                let uuid = UUID(uuidString: id),
                sessions.contains(where: { $0.id == uuid })
            {

                activeID = uuid
            } else {
                activeID = sessions.first?.id
            }
        }
    }
}
