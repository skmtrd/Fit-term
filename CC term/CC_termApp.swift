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
    @State private var sshService = SSHService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sshService)
        }
        .modelContainer(for: [ConnectionProfile.self, Snippet.self])
    }
}
