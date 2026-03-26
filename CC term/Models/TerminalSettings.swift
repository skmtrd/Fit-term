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
    var foregroundColorRed: Double = 1
    var foregroundColorGreen: Double = 1
    var foregroundColorBlue: Double = 1

    init(
        fontName: String = "SF Mono",
        fontSize: Double = 14,
        backgroundColorRed: Double = 0,
        backgroundColorGreen: Double = 0,
        backgroundColorBlue: Double = 0,
        foregroundColorRed: Double = 1,
        foregroundColorGreen: Double = 1,
        foregroundColorBlue: Double = 1
    ) {
        self.fontName = fontName
        self.fontSize = fontSize
        self.backgroundColorRed = backgroundColorRed
        self.backgroundColorGreen = backgroundColorGreen
        self.backgroundColorBlue = backgroundColorBlue
        self.foregroundColorRed = foregroundColorRed
        self.foregroundColorGreen = foregroundColorGreen
        self.foregroundColorBlue = foregroundColorBlue
    }

    // MARK: - Fonts

    static let availableFonts: [String] = [
        "SF Mono",
        "Menlo",
        "JetBrains Mono",
        "Fira Code",
        "Source Code Pro",
        "IBM Plex Mono",
        "Courier New",
        "Monaco",
        "Courier",
    ]

    var uiFont: UIFont {
        if fontName == "SF Mono" {
            return UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
        // バンドルフォントの PostScript 名マッピング
        let postScriptName: String? = switch fontName {
        case "JetBrains Mono": "JetBrainsMono-Regular"
        case "Fira Code": "FiraCode-Regular"
        case "Source Code Pro": "SourceCodePro-Regular"
        case "IBM Plex Mono": "IBMPlexMono-Regular"
        default: fontName
        }
        if let name = postScriptName, let font = UIFont(name: name, size: fontSize) {
            return font
        }
        return UIFont(name: fontName, size: fontSize)
            ?? UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }

    // MARK: - Colors

    var uiBackgroundColor: UIColor {
        UIColor(red: backgroundColorRed, green: backgroundColorGreen, blue: backgroundColorBlue, alpha: 1)
    }

    var uiForegroundColor: UIColor {
        UIColor(red: foregroundColorRed, green: foregroundColorGreen, blue: foregroundColorBlue, alpha: 1)
    }

    var backgroundColor: Color {
        Color(red: backgroundColorRed, green: backgroundColorGreen, blue: backgroundColorBlue)
    }

    var foregroundColor: Color {
        Color(red: foregroundColorRed, green: foregroundColorGreen, blue: foregroundColorBlue)
    }

    func applyPreset(_ preset: ColorPreset) {
        backgroundColorRed = preset.bgR
        backgroundColorGreen = preset.bgG
        backgroundColorBlue = preset.bgB
        foregroundColorRed = preset.fgR
        foregroundColorGreen = preset.fgG
        foregroundColorBlue = preset.fgB
    }

    // MARK: - Color Presets

    struct ColorPreset: Identifiable {
        let id: String
        let name: String
        let bgR: Double, bgG: Double, bgB: Double
        let fgR: Double, fgG: Double, fgB: Double

        var backgroundColor: Color { Color(red: bgR, green: bgG, blue: bgB) }
        var foregroundColor: Color { Color(red: fgR, green: fgG, blue: fgB) }
    }

    static let colorPresets: [ColorPreset] = [
        ColorPreset(id: "black",      name: "Default (Black)",   bgR: 0/255, bgG: 0/255, bgB: 0/255,       fgR: 255/255, fgG: 255/255, fgB: 255/255),
        ColorPreset(id: "dracula",    name: "Dracula",           bgR: 40/255, bgG: 42/255, bgB: 54/255,     fgR: 248/255, fgG: 248/255, fgB: 242/255),
        ColorPreset(id: "onedark",    name: "One Dark",          bgR: 40/255, bgG: 44/255, bgB: 52/255,     fgR: 171/255, fgG: 178/255, fgB: 191/255),
        ColorPreset(id: "nord",       name: "Nord",              bgR: 46/255, bgG: 52/255, bgB: 64/255,     fgR: 216/255, fgG: 222/255, fgB: 233/255),
        ColorPreset(id: "tokyonight", name: "Tokyo Night",       bgR: 26/255, bgG: 27/255, bgB: 38/255,     fgR: 192/255, fgG: 202/255, fgB: 245/255),
        ColorPreset(id: "catppuccin", name: "Catppuccin Mocha",  bgR: 30/255, bgG: 30/255, bgB: 46/255,     fgR: 205/255, fgG: 214/255, fgB: 244/255),
        ColorPreset(id: "gruvbox",    name: "Gruvbox Dark",      bgR: 40/255, bgG: 40/255, bgB: 40/255,     fgR: 235/255, fgG: 219/255, fgB: 178/255),
        ColorPreset(id: "soldark",    name: "Solarized Dark",    bgR: 0/255, bgG: 43/255, bgB: 54/255,      fgR: 131/255, fgG: 148/255, fgB: 150/255),
        ColorPreset(id: "sollight",   name: "Solarized Light",   bgR: 253/255, bgG: 246/255, bgB: 227/255,  fgR: 88/255, fgG: 110/255, fgB: 117/255),
        ColorPreset(id: "monokai",    name: "Monokai",           bgR: 39/255, bgG: 40/255, bgB: 34/255,     fgR: 248/255, fgG: 248/255, fgB: 242/255),
    ]
}
