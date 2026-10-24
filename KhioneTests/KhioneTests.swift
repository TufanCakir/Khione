//
//  KhioneTests.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation
import Testing

@testable import Khione

struct SubscriptionCatalogTests {
    private let catalog = Bundle.main.loadSubscriptionCatalog()

    @Test func `No entitlement resolves to the free plan`() {
        #expect(catalog.planID(for: []) == "free")
    }

    @Test func `A verified product resolves to its plan`() {
        #expect(catalog.planID(for: ["khione.plus.monthly"]) == "plus")
    }

    @Test func `An annual product resolves to the same plan`() {
        #expect(catalog.planID(for: ["khione.plus.annual"]) == "plus")
    }

    @Test func `Highest entitled plan wins`() {
        let productIDs: Set<String> = [
            "khione.standard.monthly",
            "khione.studio.monthly",
        ]

        #expect(catalog.planID(for: productIDs) == "studio")
    }
}

struct DocumentReviewTests {
    @Test @MainActor
    func `Review export contains findings and source`() {
        let report = DocumentReviewReport(
            id: UUID(),
            generatedAt: Date(timeIntervalSince1970: 1_000),
            summary: "A concise summary.",
            findings: [
                DocumentReviewFinding(
                    id: UUID(),
                    severity: .warning,
                    title: "Notice period",
                    explanation: "The deadline deserves attention.",
                    sourceLabel: "Contract.pdf, page 2",
                    evidence: "Three months before renewal"
                )
            ]
        )

        let export = report.markdown(fileName: "Contract.pdf")

        #expect(export.contains("A concise summary."))
        #expect(export.contains("Notice period"))
        #expect(export.contains("Contract.pdf, page 2"))
    }

    @Test @MainActor
    func `Older document archives decode without a review`() throws {
        let json = """
            {
              "id": "00000000-0000-0000-0000-000000000001",
              "fileName": "Legacy.txt",
              "storedFileName": "legacy.txt",
              "contentTypeIdentifier": "public.plain-text",
              "importedAt": 0,
              "extractedSources": [],
              "insights": []
            }
            """

        let document = try JSONDecoder().decode(
            ProjectDocument.self,
            from: Data(json.utf8)
        )

        #expect(document.review == nil)
    }
}

struct ChatPersistenceTests {
    @Test @MainActor
    func `Archive survives a file round trip`() throws {
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
