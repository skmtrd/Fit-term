//
//  KeyCombo.swift
//  Fit term
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

    // ナビゲーション
    case pageUp = "Page Up"
    case pageDown = "Page Down"
    case home = "Home"
    case end = "End"

    // ファンクションキー
    case f1 = "F1"
    case f2 = "F2"
    case f3 = "F3"
    case f4 = "F4"
    case f5 = "F5"
    case f6 = "F6"
    case f7 = "F7"
    case f8 = "F8"
    case f9 = "F9"
    case f10 = "F10"
    case f11 = "F11"
    case f12 = "F12"

    // Ctrl 組み合わせ
    case ctrlA = "Ctrl+A"
    case ctrlB = "Ctrl+B"
    case ctrlC = "Ctrl+C"
    case ctrlD = "Ctrl+D"
    case ctrlE = "Ctrl+E"
    case ctrlF = "Ctrl+F"
    case ctrlG = "Ctrl+G"
    case ctrlH = "Ctrl+H"
    case ctrlJ = "Ctrl+J"
    case ctrlK = "Ctrl+K"
    case ctrlL = "Ctrl+L"
    case ctrlN = "Ctrl+N"
    case ctrlO = "Ctrl+O"
    case ctrlP = "Ctrl+P"
    case ctrlR = "Ctrl+R"
    case ctrlT = "Ctrl+T"
    case ctrlU = "Ctrl+U"
    case ctrlV = "Ctrl+V"
    case ctrlW = "Ctrl+W"
    case ctrlX = "Ctrl+X"
    case ctrlY = "Ctrl+Y"
    case ctrlZ = "Ctrl+Z"
    case ctrlBackslash = "Ctrl+\\"

    // Alt (Meta) 組み合わせ
    case altB = "Alt+B"
    case altF = "Alt+F"
    case altD = "Alt+D"
    case altBackspace = "Alt+⌫"
    case altDot = "Alt+."

    // Shift 組み合わせ
    case shiftTab = "Shift+Tab"

    // 記号
    case ctrlLeftBracket = "Ctrl+["
    case pipe = "|"
    case tilde = "~"
    case slash = "/"
    case hyphen = "-"
    case underscore = "_"
    case dollar = "$"
    case greaterThan = ">"
    case lessThan = "<"
    case ampersand = "&"

    // UI 操作
    case toggleKeyboard = "KB開閉"
    case closeTab = "タブ閉じる"
    case newTab = "新規タブ"
    case paste = "ペースト"
    case prevTab = "前のタブ"
    case nextTab = "次のタブ"
    case attachImage = "画像添付"

    /// SSH に送信するバイト列
    var bytes: Data {
        switch self {
        // 特殊キー
        case .escape:           Data([0x1B])
        case .tab:              Data([0x09])
        case .enter:            Data([0x0D])
        case .backspace:        Data([0x7F])
        case .delete:           Data([0x1B, 0x5B, 0x33, 0x7E])
        case .space:            Data([0x20])
        // 矢印キー
        case .arrowUp:          Data([0x1B, 0x5B, 0x41])
        case .arrowDown:        Data([0x1B, 0x5B, 0x42])
        case .arrowRight:       Data([0x1B, 0x5B, 0x43])
        case .arrowLeft:        Data([0x1B, 0x5B, 0x44])
        // ナビゲーション
        case .pageUp:           Data([0x1B, 0x5B, 0x35, 0x7E])
        case .pageDown:         Data([0x1B, 0x5B, 0x36, 0x7E])
        case .home:             Data([0x1B, 0x5B, 0x48])
        case .end:              Data([0x1B, 0x5B, 0x46])
        // ファンクションキー
        case .f1:               Data([0x1B, 0x4F, 0x50])
        case .f2:               Data([0x1B, 0x4F, 0x51])
        case .f3:               Data([0x1B, 0x4F, 0x52])
        case .f4:               Data([0x1B, 0x4F, 0x53])
        case .f5:               Data([0x1B, 0x5B, 0x31, 0x35, 0x7E])
        case .f6:               Data([0x1B, 0x5B, 0x31, 0x37, 0x7E])
        case .f7:               Data([0x1B, 0x5B, 0x31, 0x38, 0x7E])
        case .f8:               Data([0x1B, 0x5B, 0x31, 0x39, 0x7E])
        case .f9:               Data([0x1B, 0x5B, 0x32, 0x30, 0x7E])
        case .f10:              Data([0x1B, 0x5B, 0x32, 0x31, 0x7E])
        case .f11:              Data([0x1B, 0x5B, 0x32, 0x33, 0x7E])
        case .f12:              Data([0x1B, 0x5B, 0x32, 0x34, 0x7E])
        // Ctrl 組み合わせ
        case .ctrlA:            Data([0x01])
        case .ctrlB:            Data([0x02])
        case .ctrlC:            Data([0x03])
        case .ctrlD:            Data([0x04])
        case .ctrlE:            Data([0x05])
        case .ctrlF:            Data([0x06])
        case .ctrlG:            Data([0x07])
        case .ctrlH:            Data([0x08])
        case .ctrlJ:            Data([0x0A])
        case .ctrlK:            Data([0x0B])
        case .ctrlL:            Data([0x0C])
        case .ctrlN:            Data([0x0E])
        case .ctrlO:            Data([0x0F])
        case .ctrlP:            Data([0x10])
        case .ctrlR:            Data([0x12])
        case .ctrlT:            Data([0x14])
        case .ctrlU:            Data([0x15])
        case .ctrlV:            Data([0x16])
        case .ctrlW:            Data([0x17])
        case .ctrlX:            Data([0x18])
        case .ctrlY:            Data([0x19])
        case .ctrlZ:            Data([0x1A])
        case .ctrlBackslash:    Data([0x1C])
        // Alt 組み合わせ
        case .altB:             Data([0x1B, 0x62])
        case .altF:             Data([0x1B, 0x66])
        case .altD:             Data([0x1B, 0x64])
        case .altBackspace:     Data([0x1B, 0x7F])
        case .altDot:           Data([0x1B, 0x2E])
        // Shift 組み合わせ
        case .shiftTab:         Data([0x1B, 0x5B, 0x5A])
        // 記号
        case .ctrlLeftBracket:  Data([0x1B])
        case .pipe:             Data([0x7C])
        case .tilde:            Data([0x7E])
        case .slash:            Data([0x2F])
        case .hyphen:           Data([0x2D])
        case .underscore:       Data([0x5F])
        case .dollar:           Data([0x24])
        case .greaterThan:      Data([0x3E])
        case .lessThan:         Data([0x3C])
        case .ampersand:        Data([0x26])
        // UI 操作
        case .toggleKeyboard:   Data()
        case .closeTab:         Data()
        case .newTab:           Data()
        case .paste:            Data()
        case .prevTab:          Data()
        case .nextTab:          Data()
        case .attachImage:      Data()
        }
    }

    /// デフォルトのボタンラベル
    var defaultLabel: String {
        switch self {
        case .escape:           "Esc"
        case .tab:              "Tab"
        case .enter:            "⏎"
        case .backspace:        "⌫"
        case .delete:           "Del"
        case .space:            "␣"
        case .arrowUp:          "↑"
        case .arrowDown:        "↓"
        case .arrowLeft:        "←"
        case .arrowRight:       "→"
        case .pageUp:           "PgUp"
        case .pageDown:         "PgDn"
        case .home:             "Home"
        case .end:              "End"
        case .ctrlC:            "C-c"
        case .ctrlD:            "C-d"
        case .ctrlZ:            "C-z"
        case .ctrlL:            "C-l"
        case .ctrlR:            "C-r"
        case .ctrlBackslash:    "C-\\"
        case .shiftTab:         "S-Tab"
        case .altB:             "M-b"
        case .altF:             "M-f"
        case .altD:             "M-d"
        case .altBackspace:     "M-⌫"
        case .altDot:           "M-."
        case .pipe:             "|"
        case .tilde:            "~"
        case .slash:            "/"
        case .hyphen:           "-"
        case .underscore:       "_"
        case .dollar:           "$"
        case .greaterThan:      ">"
        case .lessThan:         "<"
        case .ampersand:        "&"
        case .toggleKeyboard:   "⌨"
        case .closeTab:         "✕"
        case .newTab:           "+"
        case .paste:            "Paste"
        case .prevTab:          "◀"
        case .nextTab:          "▶"
        case .attachImage:      "📷"
        default:                rawValue
        }
    }

    /// デフォルトの SF Symbol アイコン名（なければ空文字）
    var defaultIconName: String {
        switch self {
        // 特殊キー
        case .escape:           "escape"
        case .tab:              "arrow.right.to.line"
        case .enter:            "return"
        case .backspace:        "delete.left"
        case .delete:           "delete.right"
        // 矢印キー
        case .arrowUp:          "chevron.up"
        case .arrowDown:        "chevron.down"
        case .arrowLeft:        "chevron.left"
        case .arrowRight:       "chevron.right"
        // ナビゲーション
        case .pageUp:           "arrow.up.doc"
        case .pageDown:         "arrow.down.doc"
        case .home:             "arrow.left.to.line"
        case .end:              "arrow.right.to.line"
        // Ctrl 組み合わせ
        case .ctrlC:            "stop.circle"
        case .ctrlD:            "eject"
        case .ctrlZ:            "pause.circle"
        case .ctrlL:            "arrow.counterclockwise"
        case .ctrlR:            "magnifyingglass"
        case .ctrlY:            "doc.on.clipboard"
        case .ctrlBackslash:    "xmark.octagon"
        // Alt 組み合わせ
        case .altB:             "arrow.left.to.line"
        case .altF:             "arrow.right.to.line"
        case .altD:             "delete.right"
        case .altBackspace:     "delete.left"
        // Shift 組み合わせ
        case .shiftTab:         "arrow.left.to.line"
        // 記号
        case .tilde:            "house"
        case .slash:            "slash.circle"
        case .hyphen:           "minus"
        case .dollar:           "dollarsign"
        case .greaterThan:      "greaterthan"
        case .lessThan:         "lessthan"
        // UI 操作
        case .toggleKeyboard:   "keyboard.chevron.compact.down"
        case .closeTab:         "xmark.square"
        case .newTab:           "plus.square"
        case .paste:            "doc.on.clipboard"
        case .prevTab:          "arrow.left.square"
        case .nextTab:          "arrow.right.square"
        case .attachImage:      "photo"
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
        case .pageUp, .pageDown, .home, .end:
            "ナビゲーション"
        case .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10, .f11, .f12:
            "ファンクションキー"
        case .ctrlA, .ctrlB, .ctrlC, .ctrlD, .ctrlE, .ctrlF, .ctrlG, .ctrlH,
             .ctrlJ, .ctrlK, .ctrlL, .ctrlN, .ctrlO, .ctrlP, .ctrlR, .ctrlT,
             .ctrlU, .ctrlV, .ctrlW, .ctrlX, .ctrlY, .ctrlZ, .ctrlBackslash:
            "Ctrl 組み合わせ"
        case .altB, .altF, .altD, .altBackspace, .altDot:
            "Alt 組み合わせ"
        case .shiftTab:
            "Shift 組み合わせ"
        case .ctrlLeftBracket, .pipe, .tilde, .slash, .hyphen, .underscore,
             .dollar, .greaterThan, .lessThan, .ampersand:
            "記号"
        case .toggleKeyboard, .closeTab, .newTab, .paste, .prevTab, .nextTab, .attachImage:
            "UI 操作"
        }
    }
}
