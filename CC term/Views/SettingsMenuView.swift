//
//  SettingsMenuView.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI

struct SettingsMenuView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    LayoutEditorView()
                } label: {
                    Label("キーボードレイアウト", systemImage: "keyboard")
                }

                NavigationLink {
                    SnippetListView()
                } label: {
                    Label("スニペット管理", systemImage: "text.badge.star")
                }

                NavigationLink {
                    TerminalSettingsView()
                } label: {
                    Label("ターミナル表示設定", systemImage: "paintbrush")
                }

                NavigationLink {
                    SpeechSettingsView()
                } label: {
                    Label("音声認識", systemImage: "mic.fill")
                }
            }
        }
        .navigationTitle("設定")
    }
}
