//
//  CC_termApp.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData

@main
struct CC_termApp: App {
    @State private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sessionManager)
        }
        .modelContainer(for: [ConnectionProfile.self, Snippet.self, TerminalSettings.self, KeyboardLayout.self, KeyboardButton.self])
    }
}
