//
//  SnippetEditView.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData

struct SnippetEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let existingSnippet: Snippet?

    @State private var label: String
    @State private var command: String
    @State private var appendNewline: Bool

    private var isNew: Bool { existingSnippet == nil }

    private var isFormValid: Bool {
        !label.trimmingCharacters(in: .whitespaces).isEmpty
            && !command.isEmpty
    }

    /// 新規作成
    init() {
        self.existingSnippet = nil
        _label = State(initialValue: "")
        _command = State(initialValue: "")
        _appendNewline = State(initialValue: true)
    }

    /// 編集
    init(snippet: Snippet) {
        self.existingSnippet = snippet
        _label = State(initialValue: snippet.label)
        _command = State(initialValue: snippet.command)
        _appendNewline = State(initialValue: snippet.appendNewline)
    }

    var body: some View {
        Form {
            Section("基本設定") {
                TextField("ラベル", text: $label)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("コマンド", text: $command)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("オプション") {
                Toggle("末尾に改行を付与", isOn: $appendNewline)
            }

            Section("プレビュー") {
                Text(previewText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(isNew ? "スニペット追加" : "スニペット編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                    dismiss()
                }
                .disabled(!isFormValid)
            }
        }
    }

    private var previewText: String {
        guard !command.isEmpty else { return "（コマンドを入力してください）" }
        let sent = appendNewline ? command + "↵" : command
        return sent
    }

    private func save() {
        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)

        if let existing = existingSnippet {
            existing.label = trimmedLabel
            existing.command = command
            existing.appendNewline = appendNewline
        } else {
            let snippet = Snippet(
                label: trimmedLabel,
                command: command,
                appendNewline: appendNewline
            )
            modelContext.insert(snippet)
        }
    }
}

#Preview("新規作成") {
    NavigationStack {
        SnippetEditView()
    }
    .modelContainer(for: Snippet.self, inMemory: true)
}

#Preview("編集") {
    NavigationStack {
        SnippetEditView(snippet: Snippet(label: "Claude Code", command: "claude", appendNewline: true))
    }
    .modelContainer(for: Snippet.self, inMemory: true)
}
