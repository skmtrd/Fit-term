//
//  SessionContainerView.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData
@preconcurrency import SwiftTerm

struct SessionContainerView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ConnectionProfile.updatedAt, order: .reverse) private var profiles: [ConnectionProfile]
    @Query private var snippets: [Snippet]
    @Query private var layouts: [KeyboardLayout]
    @AppStorage("showSnippetBar") private var showSnippetBar = true

    @State private var showProfilePicker = false
    @State private var passwordForProfile: ConnectionProfile?
    @State private var password: String = ""

    /// セルサイズ（正方形）= 画面幅 / (列数 + 1)
    private var cellSize: CGFloat {
        let gridCols = layouts.first?.columns ?? 4
        return UIScreen.main.bounds.width / CGFloat(gridCols + 1)
    }

    private var keyboardAreaHeight: CGFloat {
        let gridRows = layouts.first?.rows ?? 2
        return cellSize * CGFloat(gridRows)
    }

    var body: some View {
        VStack(spacing: 0) {
            // タブバー
            SessionTabBar {
                showProfilePicker = true
            }

            if !sessionManager.sessions.isEmpty {
                // ZStack で全セッションを常に保持
                ZStack {
                    ForEach(sessionManager.sessions) { session in
                        SwiftTerminalView(viewModel: session.viewModel)
                            .opacity(session.id == sessionManager.activeSessionId ? 1 : 0)
                            .allowsHitTesting(session.id == sessionManager.activeSessionId)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 60)
                        .onEnded { value in
                            // 水平方向のスワイプのみ（垂直スクロールと干渉しないように）
                            let horizontal = abs(value.translation.width)
                            let vertical = abs(value.translation.height)
                            guard horizontal > vertical else { return }

                            if value.translation.width < 0 {
                                sessionManager.switchToNext()
                            } else {
                                sessionManager.switchToPrevious()
                            }
                        }
                )
                .onAppear {
                    // プロファイル一覧から戻ってきた時
                    Task {
                        try? await Task.sleep(for: .milliseconds(100))
                        sessionManager.activeSession?.viewModel.focusTerminal()
                    }
                }
                .onChange(of: sessionManager.activeSessionId) {
                    Task {
                        try? await Task.sleep(for: .milliseconds(50))
                        sessionManager.activeSession?.viewModel.focusTerminal()
                    }
                }

                if let session = sessionManager.activeSession {
                    // スニペットバー
                    if showSnippetBar && !snippets.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(snippets) { snippet in
                                    Button {
                                        let data = Data(snippet.commandToSend.utf8)
                                        session.viewModel.sendToShell(data)
                                    } label: {
                                        Text(snippet.label)
                                            .font(.system(.caption, design: .monospaced))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color(.systemGray5))
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                        }
                        .background(Color(.systemGray6))
                    }

                    // キーボード拡張エリア + 戻るボタン
                    GeometryReader { geo in
                        let gridCols = layouts.first?.columns ?? 4
                        let totalUnits = CGFloat(gridCols) + 1 // +1 for back button
                        let unitWidth = geo.size.width / totalUnits
                        let backWidth = unitWidth

                        HStack(spacing: 0) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14))
                                    .frame(width: backWidth - 6, height: geo.size.height - 6)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .frame(width: backWidth)

                            KeyboardExtensionView(
                                sendToShell: { data in
                                    session.viewModel.sendToShell(data)
                                },
                                toggleKeyboard: {
                                    if let tv = session.viewModel.terminalView {
                                        if tv.isFirstResponder {
                                            tv.resignFirstResponder()
                                        } else {
                                            tv.becomeFirstResponder()
                                        }
                                    }
                                },
                                closeTab: {
                                    sessionManager.removeSession(session)
                                },
                                newTab: {
                                    showProfilePicker = true
                                }
                            )
                            .frame(width: geo.size.width - backWidth)
                        }
                    }
                    .frame(height: keyboardAreaHeight)
                    .background(Color(.systemGray6))
                }
            } else {
                ContentUnavailableView(
                    "セッションがありません",
                    systemImage: "terminal",
                    description: Text("戻ってプロファイルから接続してください")
                )
                .onAppear { dismiss() }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showProfilePicker) {
            NavigationStack {
                ProfilePickerView(profiles: profiles) { profile in
                    showProfilePicker = false
                    connectProfile(profile)
                }
            }
            .presentationDetents([.medium])
        }
        .alert("パスワード", isPresented: .init(
            get: { passwordForProfile != nil },
            set: { if !$0 { passwordForProfile = nil; password = "" } }
        )) {
            SecureField("パスワード", text: $password)
            Button("接続") {
                if let profile = passwordForProfile {
                    sessionManager.addSession(profile: profile, password: password)
                    passwordForProfile = nil
                    password = ""
                }
            }
            Button("キャンセル", role: .cancel) {
                passwordForProfile = nil
                password = ""
            }
        } message: {
            if let profile = passwordForProfile {
                Text("\(profile.displayName) に接続")
            }
        }
    }

    private func connectProfile(_ profile: ConnectionProfile) {
        if let saved = KeychainHelper.load(forKey: profile.keychainPasswordKey) {
            sessionManager.addSession(profile: profile, password: saved)
        } else {
            passwordForProfile = profile
        }
    }

}

// MARK: - Profile Picker (Sheet)

private struct ProfilePickerView: View {
    let profiles: [ConnectionProfile]
    let onSelect: (ConnectionProfile) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if profiles.isEmpty {
                ContentUnavailableView(
                    "プロファイルがありません",
                    systemImage: "server.rack",
                    description: Text("先にプロファイルを作成してください")
                )
            }

            ForEach(profiles) { profile in
                Button {
                    onSelect(profile)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.displayName)
                            .font(.headline)
                        Text("\(profile.username)@\(profile.host):\(profile.port)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .tint(.primary)
            }
        }
        .navigationTitle("接続先を選択")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
        }
    }
}
