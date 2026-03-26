//
//  TerminalSettingsView.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData

struct TerminalSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [TerminalSettings]

    private var settings: TerminalSettings {
        if let existing = settingsList.first {
            return existing
        }
        let newSettings = TerminalSettings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        Form {
            // カラープリセット
            Section("カラープリセット") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(TerminalSettings.colorPresets) { preset in
                            Button {
                                settings.applyPreset(preset)
                            } label: {
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(preset.backgroundColor)
                                        .frame(width: 50, height: 36)
                                        .overlay(
                                            Text("A")
                                                .font(.system(.body, design: .monospaced))
                                                .fontWeight(.bold)
                                                .foregroundStyle(preset.foregroundColor)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(isCurrentPreset(preset) ? .blue : .clear, lineWidth: 2)
                                        )
                                    Text(preset.name)
                                        .font(.system(size: 9))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }
                                .frame(width: 70)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }

            // カスタムカラー
            Section("カスタムカラー") {
                ColorPicker(
                    "背景色",
                    selection: Binding(
                        get: { settings.backgroundColor },
                        set: { newColor in
                            if let c = UIColor(newColor).rgbComponents {
                                settings.backgroundColorRed = c.red
                                settings.backgroundColorGreen = c.green
                                settings.backgroundColorBlue = c.blue
                            }
                        }
                    )
                )

                ColorPicker(
                    "文字色",
                    selection: Binding(
                        get: { settings.foregroundColor },
                        set: { newColor in
                            if let c = UIColor(newColor).rgbComponents {
                                settings.foregroundColorRed = c.red
                                settings.foregroundColorGreen = c.green
                                settings.foregroundColorBlue = c.blue
                            }
                        }
                    )
                )
            }

            // フォント
            Section("フォント") {
                Picker("フォント", selection: Binding(
                    get: { settings.fontName },
                    set: { settings.fontName = $0 }
                )) {
                    ForEach(TerminalSettings.availableFonts, id: \.self) { font in
                        Text(font)
                            .tag(font)
                    }
                }
            }

            Section("フォントサイズ") {
                Stepper(
                    "\(Int(settings.fontSize)) pt",
                    value: Binding(
                        get: { settings.fontSize },
                        set: { settings.fontSize = $0 }
                    ),
                    in: 8...32,
                    step: 1
                )
            }

            // プレビュー
            Section("プレビュー") {
                Text("user@server:~$ ls -la\ndrwxr-xr-x  5 user  staff  160\n-rw-r--r--  1 user  staff  256")
                    .font(previewFont)
                    .foregroundStyle(settings.foregroundColor)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(settings.backgroundColor)
                    .cornerRadius(8)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .navigationTitle("ターミナル表示設定")
    }

    private var previewFont: Font {
        if settings.fontName == "SF Mono" {
            return .system(size: settings.fontSize, design: .monospaced)
        }
        return .custom(settings.fontName, size: settings.fontSize)
    }

    private func isCurrentPreset(_ preset: TerminalSettings.ColorPreset) -> Bool {
        abs(settings.backgroundColorRed - preset.bgR) < 0.01 &&
        abs(settings.backgroundColorGreen - preset.bgG) < 0.01 &&
        abs(settings.backgroundColorBlue - preset.bgB) < 0.01 &&
        abs(settings.foregroundColorRed - preset.fgR) < 0.01 &&
        abs(settings.foregroundColorGreen - preset.fgG) < 0.01 &&
        abs(settings.foregroundColorBlue - preset.fgB) < 0.01
    }
}

// MARK: - UIColor RGB ヘルパー

private extension UIColor {
    var rgbComponents: (red: Double, green: Double, blue: Double)? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return (Double(r), Double(g), Double(b))
    }
}
