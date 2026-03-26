//
//  KeyboardLayout.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - KeyboardLayout

@Model
final class KeyboardLayout {
    var rows: Int = 2
    var columns: Int = 4
    @Relationship(deleteRule: .cascade, inverse: \KeyboardButton.layout)
    var buttons: [KeyboardButton] = []

    init(rows: Int = 2, columns: Int = 4) {
        self.rows = rows
        self.columns = columns
    }

    /// デフォルトレイアウトを生成
    static func createDefault() -> KeyboardLayout {
        let layout = KeyboardLayout(rows: 2, columns: 4)

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

        return layout
    }
}

// MARK: - KeyboardButton

@Model
final class KeyboardButton {
    var id: UUID = UUID()
    var row: Int = 0
    var col: Int = 0
    var rowSpan: Int = 1
    var colSpan: Int = 1
    var label: String = ""
    var iconName: String = "" // SF Symbol name（空ならテキストラベル）
    var colorHex: String = "#007AFF"
    var actionType: String = "key" // "key" or "snippet"
    var keyActionRawValue: String? // KeyAction.rawValue
    var snippetId: UUID?

    var layout: KeyboardLayout?

    /// アイコンが設定されているか
    var hasIcon: Bool { !iconName.isEmpty }

    init(
        row: Int,
        col: Int,
        rowSpan: Int = 1,
        colSpan: Int = 1,
        label: String,
        iconName: String = "",
        colorHex: String = "#007AFF",
        actionType: String = "key",
        keyActionRawValue: String? = nil,
        snippetId: UUID? = nil
    ) {
        self.id = UUID()
        self.row = row
        self.col = col
        self.rowSpan = rowSpan
        self.colSpan = colSpan
        self.label = label
        self.iconName = iconName
        self.colorHex = colorHex
        self.actionType = actionType
        self.keyActionRawValue = keyActionRawValue
        self.snippetId = snippetId
    }

    /// キーアクションのバイト列を取得
    var keyBytes: Data? {
        guard actionType == "key",
              let raw = keyActionRawValue,
              let action = KeyAction(rawValue: raw) else { return nil }
        return action.bytes
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    /// グリッド上で占有するセル範囲
    var occupiedCells: [(row: Int, col: Int)] {
        var cells: [(Int, Int)] = []
        for r in row..<(row + rowSpan) {
            for c in col..<(col + colSpan) {
                cells.append((r, c))
            }
        }
        return cells
    }
}

// MARK: - Color Hex Extension

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let int = UInt64(h, radix: 16) else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
