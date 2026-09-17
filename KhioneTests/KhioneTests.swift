import Foundation
import Testing
@testable import Khione

struct ChatPersistenceTests {
    @Test func `Archive survives a file round trip`() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }

        var session = ChatSession(title: "Persisted")
        session.messages = [
            ChatMessage(
                role: .user,
                text: "Hallo",
                createdAt: Date(timeIntervalSince1970: 1_000)
            )
        ]
        let archive = ChatArchive(
            sessions: [session],
            activeID: session.id
        )

        try fixture.persistence.save(archive)
        let loadedArchive = try #require(try fixture.persistence.load())

        #expect(loadedArchive == archive)
    }

    @Test @MainActor
    func `Store restores the active chat`() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }

        let first = ChatSession(title: "First")
        let second = ChatSession(title: "Second")
        try fixture.persistence.save(
            ChatArchive(sessions: [first, second], activeID: second.id)
        )

        let store = ChatStore(
            persistence: fixture.persistence,
            legacyDefaults: nil
        )

        #expect(store.sessions == [first, second])
        #expect(store.activeID == second.id)
        #expect(store.activeChat == second)
    }

    @Test @MainActor
    func `Legacy UserDefaults archive migrates once`() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }

        let suiteName = "ChatPersistenceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let session = ChatSession(title: "Legacy")
        defaults.set(
            try JSONEncoder().encode([session]),
            forKey: "chat_sessions"
        )
        defaults.set(
            session.id.uuidString,
            forKey: "chat_sessions_active"
        )

        let store = ChatStore(
            persistence: fixture.persistence,
            legacyDefaults: defaults
        )

        #expect(store.activeChat == session)
        #expect(defaults.data(forKey: "chat_sessions") == nil)
        #expect(try fixture.persistence.load()?.sessions == [session])
    }

    @Test @MainActor
    func `Mutations are persisted`() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }

        let store = ChatStore(
            persistence: fixture.persistence,
            legacyDefaults: nil
        )
        store.renameActiveChat(to: "  Renamed chat  ")
        store.update(messages: [
            ChatMessage(role: .user, text: "Saved message")
        ])

        let archive = try #require(try fixture.persistence.load())

        #expect(archive.sessions.count == 1)
        #expect(archive.sessions.first?.title == "Renamed chat")
        #expect(archive.sessions.first?.messages.first?.text == "Saved message")
        #expect(archive.activeID == store.activeID)
    }
}

private struct Fixture {
    let directoryURL: URL
    let persistence: FileChatPersistence

    init() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        persistence = FileChatPersistence(
            fileURL: directoryURL.appendingPathComponent("chats.json")
        )
    }

    func remove() {
        try? FileManager.default.removeItem(at: directoryURL)
    }
}
