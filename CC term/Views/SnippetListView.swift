//
//  SnippetListView.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData

struct SnippetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var snippets: [Snippet]

    @State private var selectedSnippet: Snippet?
    @State private var showingAddSheet = false

    var body: some View {
        Group {
            if snippets.isEmpty {
                ContentUnavailableView(
                    "スニペットがありません",
                    systemImage: "text.badge.plus",
                    description: Text("よく使うコマンドをスニペットとして登録すると、ワンタップで送信できます。")
                )
            } else {
                List {
                    ForEach(snippets) { snippet in
                        SnippetRow(snippet: snippet)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedSnippet = snippet
                            }
                    }
                    .onDelete(perform: deleteSnippets)
                }
            }
        }
        .navigationTitle("スニペット")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                SnippetEditView()
            }
        }
        .sheet(item: $selectedSnippet) { snippet in
            NavigationStack {
                SnippetEditView(snippet: snippet)
            }
        }
    }

    private func deleteSnippets(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(snippets[index])
        }
    }
}

// MARK: - Row

private struct SnippetRow: View {
    let snippet: Snippet

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(snippet.label)
                .font(.headline)

            Text(snippet.command)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        SnippetListView()
    }
    .modelContainer(for: Snippet.self, inMemory: true)
}
