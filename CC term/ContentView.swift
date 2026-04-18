//
//  ContentView.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(SessionManager.self) private var sessionManager

    var body: some View {
        TabView {
            NavigationStack {
                ProfileListView()
            }
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }

            NavigationStack {
                ActiveSessionsView()
            }
            .tabItem {
                Label("セッション", systemImage: "terminal.fill")
            }
            .badge(sessionManager.sessions.count > 0 ? sessionManager.sessions.count : 0)

            NavigationStack {
                SettingsMenuView()
            }
            .tabItem {
                Label("設定", systemImage: "gearshape.fill")
            }
        }
    }
}
