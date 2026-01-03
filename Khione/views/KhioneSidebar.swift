//
//  KhioneSidebar.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

import SwiftUI

struct KhioneSidebar: View {

    @ObservedObject var store: ChatStore
    var onOpenChat: (() -> Void)?

    @State private var editMode: EditMode = .inactive
    @State private var renamingChat: ChatSession?
    @State private var renameText: String = ""

    var body: some View {
        List {
            ForEach(store.sessions) { chat in
                Button {
                    if editMode == .inactive {
                        store.activeID = chat.id
                        onOpenChat?()
                    }
                } label: {
                    HStack {
                        Text(chat.title)
                            .lineLimit(1)

                        Spacer()

                        if editMode == .inactive {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .contextMenu {
                    Button("Rename") {
                        renamingChat = chat
                        renameText = chat.title
                    }

                    Button(role: .destructive) {
                        store.delete(chat)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onDelete(perform: delete)
            .onMove(perform: move)
        }
        .environment(\.editMode, $editMode)
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $renamingChat) { chat in
            NavigationStack {
                VStack(spacing: 20) {
                    TextField("Chat name", text: $renameText)
                        .textFieldStyle(.roundedBorder)
                        .padding()

                    Button("Save") {
                        store.rename(chat, to: renameText)
                        renamingChat = nil
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
                .navigationTitle("Rename Chat")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { renamingChat = nil }
                    }
                }
            }
        }
    }

    // MARK: - Actions
    private func delete(at offsets: IndexSet) {
        store.deleteChats(at: offsets)
    }

    private func move(from source: IndexSet, to destination: Int) {
        store.moveChats(from: source, to: destination)
    }
}
