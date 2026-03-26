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
            Section("フォント") {
                Picker("フォント", selection: Binding(
                    get: { settings.fontName },
                    set: { settings.fontName = $0 }
                )) {
                    ForEach(TerminalSettings.availableFonts, id: \.self) { font in
                        Text(font)
                            .font(.custom(font, size: 16))
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

            Section("背景色") {
                ColorPicker(
                    "背景色",
                    selection: Binding(
                        get: {
                            Color(
                                red: settings.backgroundColorRed,
                                green: settings.backgroundColorGreen,
                                blue: settings.backgroundColorBlue
                            )
                        },
                        set: { newColor in
                            if let components = UIColor(newColor).rgbComponents {
                                settings.backgroundColorRed = components.red
                                settings.backgroundColorGreen = components.green
                                settings.backgroundColorBlue = components.blue
                            }
                        }
                    )
                )
            }

            Section("プレビュー") {
                Text("user@server:~$ ls -la\ndrwxr-xr-x  5 user  staff  160 Mar 26 12:00 .\n-rw-r--r--  1 user  staff  256 Mar 26 11:00 README.md")
                    .font(.custom(settings.fontName, size: settings.fontSize))
                    .foregroundStyle(.white)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color(
                            red: settings.backgroundColorRed,
                            green: settings.backgroundColorGreen,
                            blue: settings.backgroundColorBlue
                        )
                    )
                    .cornerRadius(8)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .navigationTitle("ターミナル表示設定")
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

#Preview {
    NavigationStack {
        TerminalSettingsView()
    }
    .modelContainer(for: TerminalSettings.self, inMemory: true)
}
