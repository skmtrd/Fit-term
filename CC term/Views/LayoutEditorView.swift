//
//  LayoutEditorView.swift
//  Fit term
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

    private var editorColumns: Int { 8 }

    private var editorRows: Int {
        layouts.first?.rows ?? 2
    }

    private var layout: KeyboardLayout {
        if let existing = layouts.first {
            return existing
        }
        let newLayout = KeyboardLayout.createDefault()
        modelContext.insert(newLayout)
        return newLayout
    }

    var body: some View {
        VStack(spacing: 16) {
            Section {
                HStack {
                    Text("段数: \(layout.rows)")
                    Stepper("", value: Binding(
                        get: { layout.rows },
                        set: { layout.rows = $0 }
                    ), in: 1...5)
                }
                .padding(.horizontal)
            }
            .onAppear { layout.columns = 8 }

            Text("タップで編集 / ドラッグで移動")
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                let cellSize = geo.size.width / CGFloat(layout.columns)

                ZStack(alignment: .topLeading) {
                    // 空セル
                    ForEach(0..<layout.rows, id: \.self) { row in
                        ForEach(0..<layout.columns, id: \.self) { col in
                            if !isCellOccupied(row: row, col: col) {
                                Rectangle()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                    .foregroundStyle(.secondary.opacity(0.3))
                                    .frame(width: cellSize - 6, height: cellSize - 6)
                                    .position(
                                        x: cellSize * (CGFloat(col) + 0.5),
                                        y: cellSize * (CGFloat(row) + 0.5)
                                    )
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .position(
                                                x: cellSize * (CGFloat(col) + 0.5),
                                                y: cellSize * (CGFloat(row) + 0.5)
                                            )
                                    )
                                    .onTapGesture {
                                        addingAt = (row, col)
                                    }
                            }
                        }
                    }

                    // ボタン
                    ForEach(layout.buttons) { button in
                        DraggableEditorButton(
                            button: button,
                            cellSize: cellSize,
                            onTap: { editingButton = button },
                            onDrop: { translation in
                                dropButton(button, translation: translation, cellSize: cellSize)
                            }
                        )
                    }
                }
                .frame(height: cellSize * CGFloat(layout.rows))
            }
            .aspectRatio(CGFloat(editorColumns) / CGFloat(editorRows), contentMode: .fit)
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("キーボードレイアウト")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("リセット") { resetToDefault() }
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

    // MARK: - Logic

    private func dropButton(_ button: KeyboardButton, translation: CGSize, cellSize: CGFloat) {
        let currentX = cellSize * (CGFloat(button.col) + 0.5)
        let currentY = cellSize * (CGFloat(button.row) + 0.5)
        let newX = currentX + translation.width
        let newY = currentY + translation.height

        let newCol = max(0, min(layout.columns - button.colSpan, Int(newX / cellSize)))
        let newRow = max(0, min(layout.rows - button.rowSpan, Int(newY / cellSize)))

        if newRow == button.row && newCol == button.col { return }

        if let target = layout.buttons.first(where: { other in
            other.id != button.id &&
            other.occupiedCells.contains { $0.row == newRow && $0.col == newCol }
        }) {
            let oldRow = button.row
            let oldCol = button.col
            button.row = target.row
            button.col = target.col
            target.row = oldRow
            target.col = oldCol
        } else {
            button.row = newRow
            button.col = newCol
        }
    }

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

        layout.rows = 2
        layout.columns = 8

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

// MARK: - Draggable Button (独立ビュー — 親を再描画しない)

private struct DraggableEditorButton: View {
    let button: KeyboardButton
    let cellSize: CGFloat
    let onTap: () -> Void
    let onDrop: (CGSize) -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
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
            width: cellSize * CGFloat(button.colSpan) - 6,
            height: cellSize * CGFloat(button.rowSpan) - 6
        )
        .background(Color(.systemGray5))
        .cornerRadius(6)
        .shadow(radius: isDragging ? 6 : 0)
        .scaleEffect(isDragging ? 1.08 : 1.0)
        .zIndex(isDragging ? 100 : 0)
        .position(
            x: cellSize * (CGFloat(button.col) + CGFloat(button.colSpan) / 2),
            y: cellSize * (CGFloat(button.row) + CGFloat(button.rowSpan) / 2)
        )
        .offset(dragOffset)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($dragOffset) { value, state, _ in
                    let dist = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    if dist > 8 {
                        state = value.translation
                    }
                }
                .onChanged { value in
                    let dist = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    if dist > 8 {
                        isDragging = true
                    }
                }
                .onEnded { value in
                    let dist = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                    if dist <= 8 {
                        onTap()
                    } else {
                        onDrop(value.translation)
                    }
                    isDragging = false
                }
        )
        .animation(.easeOut(duration: 0.15), value: isDragging)
    }
}
