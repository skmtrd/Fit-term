//
//  CC_termApp.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData
import CoreText

@main
struct CC_termApp: App {
    @State private var sessionManager = SessionManager()

    init() {
        Self.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sessionManager)
        }
        .modelContainer(for: [ConnectionProfile.self, Snippet.self, TerminalSettings.self, KeyboardLayout.self, KeyboardButton.self])
    }

    private static func registerBundledFonts() {
        let fontFiles = [
            "JetBrainsMono-Regular",
            "FiraCode-Regular",
            "SourceCodePro-Regular",
            "IBMPlexMono-Regular",
        ]
        for file in fontFiles {
            guard let url = Bundle.main.url(forResource: file, withExtension: "ttf", subdirectory: "Fonts") else {
                // サブディレクトリなしでも試す
                if let url = Bundle.main.url(forResource: file, withExtension: "ttf") {
                    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                }
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
