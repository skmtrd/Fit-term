//
//  ButtonEditorView.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData

struct ButtonEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var snippets: [Snippet]

    let row: Int
    let col: Int
    let existingButton: KeyboardButton?
    let onSave: (KeyboardButton) -> Void
    let onDelete: (() -> Void)?

    @State private var label: String = ""
    @State private var colorHex: String = "#007AFF"
    @State private var buttonColor: Color = .blue
    @State private var actionType: String = "key"
    @State private var selectedKeyAction: KeyAction = .escape
    @State private var selectedSnippetId: UUID?
    @State private var colSpan: Int = 1
    @State private var rowSpan: Int = 1
    @State private var useIcon: Bool = false
    @State private var iconName: String = ""

    private struct IconCategory {
        let name: String
        let symbols: [String]
    }

    private static let iconCategories: [IconCategory] = [
        IconCategory(name: "キーボード", symbols: [
            "escape", "return", "delete.left", "delete.right",
            "arrow.right.to.line", "arrow.left.to.line",
            "keyboard.chevron.compact.down", "command", "control", "option", "shift",
        ]),
        IconCategory(name: "矢印・方向", symbols: [
            "chevron.up", "chevron.down", "chevron.left", "chevron.right",
            "arrow.up", "arrow.down", "arrow.left", "arrow.right",
            "arrow.uturn.left", "arrow.uturn.right",
            "arrow.up.arrow.down", "arrow.left.arrow.right",
            "arrow.up.doc", "arrow.down.doc",
            "arrow.up.to.line", "arrow.down.to.line",
            "arrow.left.to.line", "arrow.right.to.line",
        ]),
        IconCategory(name: "サーバー・ネットワーク", symbols: [
            "server.rack", "network", "wifi", "globe",
            "antenna.radiowaves.left.and.right", "link",
        ]),
        IconCategory(name: "ファイル・フォルダ", symbols: [
            "folder", "folder.fill", "doc", "doc.text",
            "doc.on.clipboard", "trash",
            "square.and.arrow.up", "square.and.arrow.down",
        ]),
        IconCategory(name: "ツール・操作", symbols: [
            "wrench", "hammer", "gearshape", "terminal",
            "power", "bolt", "play", "stop",
            "arrow.clockwise", "arrow.counterclockwise",
            "arrow.triangle.2.circlepath",
            "scissors", "magnifyingglass",
        ]),
        IconCategory(name: "開発", symbols: [
            "chevron.left.forwardslash.chevron.right",
            "ladybug", "ant", "cube", "shippingbox", "externaldrive",
        ]),
        IconCategory(name: "状態・フィードバック", symbols: [
            "checkmark", "xmark", "exclamationmark.triangle", "info.circle",
            "bell", "eye", "eye.slash", "lock", "lock.open",
            "stop.circle", "pause.circle", "xmark.octagon",
        ]),
        IconCategory(name: "ブックマーク", symbols: [
            "star", "star.fill", "bookmark", "pin", "flag", "heart", "tag",
            "house",
        ]),
        IconCategory(name: "テキスト", symbols: [
            "textformat", "character.cursor.ibeam",
            "text.alignleft", "list.bullet", "number",
        ]),
        IconCategory(name: "記号", symbols: [
            "slash.circle", "minus", "plus", "dollarsign",
            "greaterthan", "lessthan", "equal",
            "plus.square", "xmark.square",
        ]),
    ]

    var body: some View {
        Form {
            Section("表示") {
                Picker("種類", selection: $useIcon) {
                    Text("テキスト").tag(false)
                    Text("アイコン").tag(true)
                }
                .pickerStyle(.segmented)

                if useIcon {
                    iconPicker
                } else {
                    TextField("表示テキスト", text: $label)
                        .font(.system(.body, design: .monospaced))
                }
            }

            Section("アクション") {
                Picker("種類", selection: $actionType) {
                    Text("キーアクション").tag("key")
                    Text("スニペット").tag("snippet")
                }
                .pickerStyle(.segmented)

                if actionType == "key" {
                    keyActionPicker
                } else {
                    snippetPicker
                }
            }

            Section("サイズ") {
                Stepper("横幅: \(colSpan) セル", value: $colSpan, in: 1...4)
                Stepper("高さ: \(rowSpan) セル", value: $rowSpan, in: 1...3)
            }

            if onDelete != nil {
                Section {
                    Button("このボタンを削除", role: .destructive) {
                        onDelete?()
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(existingButton != nil ? "ボタン編集" : "ボタン追加")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
                    .disabled(!useIcon && label.isEmpty)
            }
        }
        .onAppear { loadExisting() }
    }

    @ViewBuilder
    private var keyActionPicker: some View {
        let categories = Dictionary(grouping: KeyAction.allCases, by: { $0.category })
        let sortedKeys = ["特殊キー", "矢印キー", "ナビゲーション", "ファンクションキー", "Ctrl 組み合わせ", "Alt 組み合わせ", "Shift 組み合わせ", "記号", "UI 操作"]

        ForEach(sortedKeys, id: \.self) { category in
            if let actions = categories[category] {
                DisclosureGroup(category) {
                    ForEach(actions, id: \.rawValue) { action in
                        HStack {
                            Text(action.defaultLabel)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Text(action.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if selectedKeyAction == action {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedKeyAction = action
                            if label.isEmpty || KeyAction.allCases.contains(where: { $0.defaultLabel == label }) {
                                label = action.defaultLabel
                            }
                            if !action.defaultIconName.isEmpty {
                                iconName = action.defaultIconName
                                useIcon = true
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var snippetPicker: some View {
        if snippets.isEmpty {
            Text("スニペットがありません")
                .foregroundStyle(.secondary)
        } else {
            ForEach(snippets) { snippet in
                HStack {
                    VStack(alignment: .leading) {
                        Text(snippet.label)
                            .font(.headline)
                        Text(snippet.command)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if selectedSnippetId == snippet.id {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSnippetId = snippet.id
                    if label.isEmpty {
                        label = snippet.label
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var iconPicker: some View {
        ForEach(Self.iconCategories, id: \.name) { category in
            DisclosureGroup(category.name) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(category.symbols, id: \.self) { symbol in
                        Button {
                            iconName = symbol
                        } label: {
                            Image(systemName: symbol)
                                .font(.system(size: 18))
                                .frame(width: 38, height: 38)
                                .background(iconName == symbol ? Color.blue.opacity(0.2) : Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(.blue, lineWidth: iconName == symbol ? 2 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func loadExisting() {
        guard let button = existingButton else { return }
        label = button.label
        iconName = button.iconName
        useIcon = button.hasIcon
        colorHex = button.colorHex
        buttonColor = button.color
        actionType = button.actionType
        colSpan = button.colSpan
        rowSpan = button.rowSpan
        if let raw = button.keyActionRawValue, let action = KeyAction(rawValue: raw) {
            selectedKeyAction = action
        }
        selectedSnippetId = button.snippetId
    }

    private func save() {
        let hex = buttonColor.hexString
        let resolvedIcon = useIcon ? iconName : ""
        let button: KeyboardButton
        if let existing = existingButton {
            existing.label = label
            existing.iconName = resolvedIcon
            existing.colorHex = hex
            existing.actionType = actionType
            existing.colSpan = colSpan
            existing.rowSpan = rowSpan
            existing.keyActionRawValue = actionType == "key" ? selectedKeyAction.rawValue : nil
            existing.snippetId = actionType == "snippet" ? selectedSnippetId : nil
            button = existing
        } else {
            button = KeyboardButton(
                row: row,
                col: col,
                rowSpan: rowSpan,
                colSpan: colSpan,
                label: label,
                iconName: resolvedIcon,
                colorHex: hex,
                actionType: actionType,
                keyActionRawValue: actionType == "key" ? selectedKeyAction.rawValue : nil,
                snippetId: actionType == "snippet" ? selectedSnippetId : nil
            )
        }
        onSave(button)
        dismiss()
    }
}
