//
//  SidebarViewModel.swift
//  Khione
//
//  Created by Tufan Cakir on 28.06.26.
//

internal import Combine
import Foundation

@MainActor
final class SidebarViewModel: ObservableObject {

    @Published var renamingChat: ChatSession?
    @Published var renameText = ""

    var canSaveRename: Bool {
        !renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func open(
        _ chat: ChatSession,
        in store: ChatStore,
        onOpenChat: (() -> Void)?
    ) {
        store.activeID = chat.id
        onOpenChat?()
    }

    func startRename(_ chat: ChatSession) {
        renamingChat = chat
        renameText = chat.title
    }

    func cancelRename() {
        renamingChat = nil
        renameText = ""
    }

    func saveRename(_ chat: ChatSession, in store: ChatStore) {
        guard canSaveRename else { return }
        store.rename(chat, to: renameText)
        cancelRename()
    }

    func delete(_ chat: ChatSession, in store: ChatStore) {
        store.delete(chat)
    }

    func delete(at offsets: IndexSet, in store: ChatStore) {
        store.deleteChats(at: offsets)
    }

    func move(from source: IndexSet, to destination: Int, in store: ChatStore) {
        store.moveChats(from: source, to: destination)
    }
}
