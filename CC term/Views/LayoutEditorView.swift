//
//  LayoutEditorView.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData

struct LayoutEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var layouts: [KeyboardLayout]

    @State private var editingButton: KeyboardButton?
    @State private var addingAt: (row: Int, col: Int)?
    @State private var movingButton: KeyboardButton?

    /// エディタ用セルサイズ（パディング込み）
    private var editorCellSize: CGFloat {
        let cols = layouts.first?.columns ?? 4
        let availableWidth = UIScreen.main.bounds.width - 32 // padding分
        return availableWidth / CGFloat(cols)
    }

    private var layout: KeyboardLayout {
        if let existing = layouts.first {
            return existing
        }
        let newLayout = KeyboardLayout.createDefault()
        modelContext.insert(newLayout)
        return newLayout
    }

    private var isMoving: Bool { movingButton != nil }

    var body: some View {
        VStack(spacing: 16) {
            // グリッドサイズ調整
            Section {
                HStack {
                    Text("列数: \(layout.columns)")
                    Stepper("", value: Binding(
                        get: { layout.columns },
                        set: { layout.columns = $0 }
                    ), in: 2...8)

                    Spacer()

                    Text("段数: \(layout.rows)")
                    Stepper("", value: Binding(
                        get: { layout.rows },
                        set: { layout.rows = $0 }
                    ), in: 1...5)
                }
                .padding(.horizontal)
            }

            // 操作ヒント
            if isMoving {
                HStack {
                    Text("移動先をタップ（ボタン同士でスワップ）")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Spacer()
                    Button("キャンセル") {
                        movingButton = nil
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
            } else {
                Text("タップで編集 / 長押しで移動モード")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // グリッドプレビュー
            GeometryReader { geo in
                let cellSize = geo.size.width / CGFloat(layout.columns)
                let cellWidth = cellSize
                let cellHeight = cellSize

                ZStack(alignment: .topLeading) {
                    // 空セル
                    ForEach(0..<layout.rows, id: \.self) { row in
                        ForEach(0..<layout.columns, id: \.self) { col in
                            if !isCellOccupied(row: row, col: col) {
                                emptyCellView(row: row, col: col, cellWidth: cellWidth, cellHeight: cellHeight)
                            }
                        }
                    }

                    // 配置済みボタン
                    ForEach(layout.buttons) { button in
                        buttonView(button: button, cellWidth: cellWidth, cellHeight: cellHeight)
                    }
                }
                .frame(height: cellHeight * CGFloat(layout.rows))
            }
            .frame(height: editorCellSize * CGFloat(layout.rows))
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("キーボードレイアウト")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("リセット") {
                    resetToDefault()
                }
            }
        }
        .sheet(item: $editingButton) { button in
            NavigationStack {
                ButtonEditorView(
                    row: button.row,
                    col: button.col,
                    existingButton: button,
                    onSave: { _ in editingButton = nil },
                    onDelete: {
                        layout.buttons.removeAll { $0.id == button.id }
                        modelContext.delete(button)
                        editingButton = nil
                    }
                )
            }
        }
        .sheet(isPresented: Binding(
            get: { addingAt != nil },
            set: { if !$0 { addingAt = nil } }
        )) {
            if let pos = addingAt {
                NavigationStack {
                    ButtonEditorView(
                        row: pos.row,
                        col: pos.col,
                        existingButton: nil,
                        onSave: { button in
                            layout.buttons.append(button)
                            addingAt = nil
                        },
                        onDelete: nil
                    )
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func emptyCellView(row: Int, col: Int, cellWidth: CGFloat, cellHeight: CGFloat) -> some View {
        Rectangle()
            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
            .foregroundStyle(isMoving ? .orange.opacity(0.4) : .secondary.opacity(0.3))
            .frame(width: cellWidth - 6, height: cellHeight - 6)
            .position(
                x: cellWidth * (CGFloat(col) + 0.5),
                y: cellHeight * (CGFloat(row) + 0.5)
            )
            .overlay(
                Image(systemName: isMoving ? "arrow.down.right" : "plus")
                    .font(.caption2)
                    .foregroundStyle(isMoving ? .orange : .secondary)
                    .position(
                        x: cellWidth * (CGFloat(col) + 0.5),
                        y: cellHeight * (CGFloat(row) + 0.5)
                    )
            )
            .onTapGesture {
                if let moving = movingButton {
                    // 移動モード: 空セルに移動
                    moving.row = row
                    moving.col = col
                    movingButton = nil
                } else {
                    addingAt = (row, col)
                }
            }
    }

    @ViewBuilder
    private func buttonView(button: KeyboardButton, cellWidth: CGFloat, cellHeight: CGFloat) -> some View {
        let isSelected = movingButton?.id == button.id

        Group {
            if button.hasIcon {
                Image(systemName: button.iconName)
                    .font(.system(size: 16))
            } else {
                Text(button.label)
                    .font(.system(.caption, design: .monospaced))
            }
        }
        .frame(
            width: cellWidth * CGFloat(button.colSpan) - 6,
            height: cellHeight * CGFloat(button.rowSpan) - 6
        )
        .background(Color(.systemGray5))
        .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.orange, lineWidth: isSelected ? 3 : 0)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            .position(
                x: cellWidth * (CGFloat(button.col) + CGFloat(button.colSpan) / 2),
                y: cellHeight * (CGFloat(button.row) + CGFloat(button.rowSpan) / 2)
            )
            .onTapGesture {
                if let moving = movingButton {
                    if moving.id == button.id {
                        // 自分自身をタップ → 移動キャンセル
                        movingButton = nil
                    } else {
                        // 別ボタンをタップ → スワップ
                        let oldRow = moving.row
                        let oldCol = moving.col
                        moving.row = button.row
                        moving.col = button.col
                        button.row = oldRow
                        button.col = oldCol
                        movingButton = nil
                    }
                } else {
                    editingButton = button
                }
            }
            .onLongPressGesture {
                movingButton = button
            }
    }

    // MARK: - Logic

    private func isCellOccupied(row: Int, col: Int) -> Bool {
        layout.buttons.contains { button in
            button.occupiedCells.contains { $0.row == row && $0.col == col }
        }
    }

    private func resetToDefault() {
        for button in layout.buttons {
            modelContext.delete(button)
        }
        layout.buttons.removeAll()
        movingButton = nil

        layout.rows = 2
        layout.columns = 4

        let defaults: [(Int, Int, KeyAction)] = [
            (0, 0, .escape),
            (0, 1, .tab),
            (0, 2, .ctrlC),
            (0, 3, .ctrlD),
            (1, 0, .arrowLeft),
            (1, 1, .arrowDown),
            (1, 2, .arrowUp),
            (1, 3, .arrowRight),
        ]

        for (row, col, action) in defaults {
            let button = KeyboardButton(
                row: row,
                col: col,
                label: action.defaultLabel,
                iconName: action.defaultIconName,
                actionType: "key",
                keyActionRawValue: action.rawValue
            )
            layout.buttons.append(button)
        }
    }
}
