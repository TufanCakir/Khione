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

    // MARK: - Published

    @Published private(set) var sessions: [ChatSession] = []
    @Published var activeID: UUID?

    // MARK: - Storage

    private let key = "chat_sessions"

    // MARK: - Init

    init() {

        load()

        if sessions.isEmpty {
            createNewChat()
        }
    }

    // MARK: - Active Chat

    var activeChatIndex: Int? {

        guard let id = activeID else { return nil }

        return sessions.firstIndex { $0.id == id }
    }

    var activeChat: ChatSession? {

        guard let index = activeChatIndex else { return nil }

        return sessions[index]
    }

    // MARK: - Mutation Helper ⭐ (WICHTIG)

    func updateActiveChat(
        _ update: (inout ChatSession) -> Void
    ) {

        guard let index = activeChatIndex else { return }

        update(&sessions[index])

        save()
    }

    // MARK: - Chats

    func createNewChat() {

        // verhindert Spam New Chats
        if activeChat?.messages.isEmpty == true {
            return
        }

        let chat = ChatSession(title: "New Chat")

        sessions.insert(chat, at: 0)

        activeID = chat.id

        save()
    }

    func renameActiveChat(to title: String) {

        updateActiveChat {

            $0.title =
                title
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
        }
    }

    func rename(_ chat: ChatSession, to newTitle: String) {

        guard
            let index = sessions.firstIndex(
                where: { $0.id == chat.id }
            )
        else { return }

        sessions[index].title =
            newTitle.trimmingCharacters(
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

    func deleteChats(at offsets: IndexSet) {

        sessions.remove(atOffsets: offsets)

        if sessions.isEmpty {

            createNewChat()

        } else {

            activeID = sessions.first?.id
        }

        save()
    }

    func moveChats(
        from source: IndexSet,
        to destination: Int
    ) {

        sessions.move(
            fromOffsets: source,
            toOffset: destination
        )

        save()
    }

    // MARK: - Messages ⭐

    func update(messages: [ChatMessage]) {

        updateActiveChat {

            $0.messages = messages
        }
    }

    // MARK: - Persistence

    private func save() {

        guard
            let data = try? JSONEncoder().encode(
                sessions
            )
        else { return }

        UserDefaults.standard.set(
            data,
            forKey: key
        )

        UserDefaults.standard.set(
            activeID?.uuidString,
            forKey: "\(key)_active"
        )
    }

    private func load() {

        guard
            let data = UserDefaults.standard.data(
                forKey: key
            ),
            let chats = try? JSONDecoder().decode(
                [ChatSession].self,
                from: data
            )
        else {
            return
        }

        sessions = chats

        if let id = UserDefaults.standard.string(
            forKey: "\(key)_active"
        ),
            let uuid = UUID(uuidString: id),
            sessions.contains(where: { $0.id == uuid })
        {

            activeID = uuid

        } else {

            activeID = sessions.first?.id
        }
    }
}
