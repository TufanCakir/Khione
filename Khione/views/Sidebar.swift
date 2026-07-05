//
//  Sidebar.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

struct Sidebar: View {

    @ObservedObject var store: ChatStore
    var onOpenChat: (() -> Void)?

    @StateObject private var viewModel = SidebarViewModel()

    var body: some View {
        List {
            Section {
                ForEach(store.sessions) { chat in
                    Button {
                        viewModel.open(chat, in: store, onOpenChat: onOpenChat)
                    } label: {
                        Text(chat.title)
                            .lineLimit(1)
                    }
                    .contextMenu {
                        renameButton(for: chat)
                        deleteButton(for: chat)
                    }
                }
                .onDelete(perform: delete)
                .onMove(perform: move)
            }
        }
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $viewModel.renamingChat) { chat in
            renameSheet(for: chat)
        }
    }

    // MARK: - Context Menu Actions

    private func renameButton(for chat: ChatSession) -> some View {
        Button {
            viewModel.startRename(chat)
        } label: {
            Label("Rename", systemImage: "pencil")
        }
    }

    private func deleteButton(for chat: ChatSession) -> some View {
        Button(role: .destructive) {
            viewModel.delete(chat, in: store)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Rename Sheet

    private func renameSheet(for chat: ChatSession) -> some View {
        NavigationStack {
            Form {
                TextField("Chat name", text: $viewModel.renameText)
            }
            .navigationTitle("Rename Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelRename()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveRename(chat, in: store)
                    }
                    .disabled(!viewModel.canSaveRename)
                }
            }
        }
    }

    // MARK: - List Actions

    private func delete(at offsets: IndexSet) {
        viewModel.delete(at: offsets, in: store)
    }

    private func move(from source: IndexSet, to destination: Int) {
        viewModel.move(from: source, to: destination, in: store)
    }
}
