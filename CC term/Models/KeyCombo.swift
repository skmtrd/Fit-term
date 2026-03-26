//
//  KeyCombo.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation

/// 定義済みキーアクション
enum KeyAction: String, CaseIterable, Sendable {
    // 特殊キー
    case escape = "Escape"
    case tab = "Tab"
    case enter = "Enter"
    case backspace = "Backspace"
    case delete = "Delete"
    case space = "Space"

    // 矢印キー
    case arrowUp = "↑"
    case arrowDown = "↓"
    case arrowLeft = "←"
    case arrowRight = "→"

    // Ctrl 組み合わせ
    case ctrlA = "Ctrl+A"
    case ctrlB = "Ctrl+B"
    case ctrlC = "Ctrl+C"
    case ctrlD = "Ctrl+D"
    case ctrlE = "Ctrl+E"
    case ctrlF = "Ctrl+F"
    case ctrlK = "Ctrl+K"
    case ctrlL = "Ctrl+L"
    case ctrlN = "Ctrl+N"
    case ctrlP = "Ctrl+P"
    case ctrlR = "Ctrl+R"
    case ctrlU = "Ctrl+U"
    case ctrlW = "Ctrl+W"
    case ctrlZ = "Ctrl+Z"

    // その他
    case shiftTab = "Shift+Tab"
    case ctrlLeftBracket = "Ctrl+["
    case pipe = "|"
    case tilde = "~"

    // UI 操作
    case toggleKeyboard = "KB開閉"
    case closeTab = "タブ閉じる"
    case newTab = "新規タブ"

    /// SSH に送信するバイト列
    var bytes: Data {
        switch self {
        case .escape:           Data([0x1B])
        case .tab:              Data([0x09])
        case .enter:            Data([0x0D])
        case .backspace:        Data([0x7F])
        case .delete:           Data([0x1B, 0x5B, 0x33, 0x7E]) // \e[3~
        case .space:            Data([0x20])
        case .arrowUp:          Data([0x1B, 0x5B, 0x41]) // \e[A
        case .arrowDown:        Data([0x1B, 0x5B, 0x42]) // \e[B
        case .arrowRight:       Data([0x1B, 0x5B, 0x43]) // \e[C
        case .arrowLeft:        Data([0x1B, 0x5B, 0x44]) // \e[D
        case .ctrlA:            Data([0x01])
        case .ctrlB:            Data([0x02])
        case .ctrlC:            Data([0x03])
        case .ctrlD:            Data([0x04])
        case .ctrlE:            Data([0x05])
        case .ctrlF:            Data([0x06])
        case .ctrlK:            Data([0x0B])
        case .ctrlL:            Data([0x0C])
        case .ctrlN:            Data([0x0E])
        case .ctrlP:            Data([0x10])
        case .ctrlR:            Data([0x12])
        case .ctrlU:            Data([0x15])
        case .ctrlW:            Data([0x17])
        case .ctrlZ:            Data([0x1A])
        case .shiftTab:         Data([0x1B, 0x5B, 0x5A]) // \e[Z
        case .ctrlLeftBracket:  Data([0x1B])
        case .pipe:             Data([0x7C])
        case .tilde:            Data([0x7E])
        case .toggleKeyboard:   Data() // 特殊: バイト送信ではなくキーボード開閉
        case .closeTab:         Data() // 特殊: アクティブタブを閉じる
        case .newTab:           Data() // 特殊: 新規タブ追加
        }
    }

    /// デフォルトのボタンラベル
    var defaultLabel: String {
        switch self {
        case .escape:       "Esc"
        case .tab:          "Tab"
        case .enter:        "⏎"
        case .backspace:    "⌫"
        case .delete:       "Del"
        case .space:        "␣"
        case .arrowUp:      "↑"
        case .arrowDown:    "↓"
        case .arrowLeft:    "←"
        case .arrowRight:   "→"
        case .ctrlC:        "C-c"
        case .ctrlD:        "C-d"
        case .ctrlZ:        "C-z"
        case .ctrlL:        "C-l"
        case .ctrlR:        "C-r"
        case .shiftTab:     "S-Tab"
        case .pipe:         "|"
        case .tilde:            "~"
        case .toggleKeyboard:   "⌨"
        case .closeTab:         "✕"
        case .newTab:           "+"
        default:                rawValue
        }
    }

    /// デフォルトの SF Symbol アイコン名（なければ空文字）
    var defaultIconName: String {
        switch self {
        case .arrowUp:          "chevron.up"
        case .arrowDown:        "chevron.down"
        case .arrowLeft:        "chevron.left"
        case .arrowRight:       "chevron.right"
        case .escape:           "escape"
        case .tab:              "arrow.right.to.line"
        case .enter:            "return"
        case .backspace:        "delete.left"
        case .delete:           "delete.right"
        case .toggleKeyboard:   "keyboard.chevron.compact.down"
        case .closeTab:         "xmark.square"
        case .newTab:           "plus.square"
        default:                ""
        }
    }

    /// カテゴリ分け
    var category: String {
        switch self {
        case .escape, .tab, .enter, .backspace, .delete, .space:
            "特殊キー"
        case .arrowUp, .arrowDown, .arrowLeft, .arrowRight:
            "矢印キー"
        case .shiftTab:
            "Shift 組み合わせ"
        case .pipe, .tilde, .ctrlLeftBracket:
            "記号"
        case .toggleKeyboard, .closeTab, .newTab:
            "UI 操作"
        default:
            "Ctrl 組み合わせ"
        }
    }
}
