//
//  TerminalSettings.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation
import SwiftData
import SwiftUI
import UIKit

@Model
final class TerminalSettings {
    var fontName: String = "SF Mono"
    var fontSize: Double = 14
    var backgroundColorRed: Double = 0
    var backgroundColorGreen: Double = 0
    var backgroundColorBlue: Double = 0

    init(
        fontName: String = "SF Mono",
        fontSize: Double = 14,
        backgroundColorRed: Double = 0,
        backgroundColorGreen: Double = 0,
        backgroundColorBlue: Double = 0
    ) {
        self.fontName = fontName
        self.fontSize = fontSize
        self.backgroundColorRed = backgroundColorRed
        self.backgroundColorGreen = backgroundColorGreen
        self.backgroundColorBlue = backgroundColorBlue
    }

    /// 等幅フォントの候補リスト
    static let availableFonts: [String] = [
        "SF Mono",
        "Menlo",
        "Courier New",
        "Monaco",
        "Courier",
    ]

    /// UIFont を生成
    var uiFont: UIFont {
        if fontName == "SF Mono" {
            return UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
        return UIFont(name: fontName, size: fontSize)
            ?? UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }

    /// 背景色の UIColor を生成
    var uiBackgroundColor: UIColor {
        UIColor(red: backgroundColorRed, green: backgroundColorGreen, blue: backgroundColorBlue, alpha: 1)
    }

    /// 背景色の SwiftUI Color を生成
    var backgroundColor: Color {
        Color(red: backgroundColorRed, green: backgroundColorGreen, blue: backgroundColorBlue)
    }
}
