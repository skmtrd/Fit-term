//
//  ProfileListView.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData

struct ProfileListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionManager.self) private var sessionManager
    @Query(sort: \ConnectionProfile.updatedAt, order: .reverse) private var profiles: [ConnectionProfile]

    @State private var showNewProfile = false
    @State private var editingProfile: ConnectionProfile?
    @State private var connectingProfile: ConnectionProfile?
    @State private var password: String = ""
    @State private var showPasswordPrompt = false
    @State private var navigateToSessions = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            // アクティブセッションがあれば表示
            if sessionManager.hasActiveSessions {
                Section {
                    Button {
                        navigateToSessions = true
                    } label: {
                        HStack {
                            Image(systemName: "terminal")
                                .foregroundStyle(.green)
                            Text("アクティブセッション (\(sessionManager.sessions.count))")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if profiles.isEmpty {
                ContentUnavailableView(
                    "プロファイルがありません",
                    systemImage: "server.rack",
                    description: Text("＋ボタンから接続先を追加してください")
                )
            }

            Section("プロファイル") {
                ForEach(profiles) { profile in
                    Button {
                        startConnection(profile: profile)
                    } label: {
                        HStack {
                            ProfileRow(profile: profile)
                            Spacer()
                            if connectingProfile?.id == profile.id {
                                ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(ImmediateFeedbackButtonStyle())
                    .disabled(connectingProfile?.id == profile.id)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteProfile(profile)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }

                            Button {
                                editingProfile = profile
                            } label: {
                                Label("編集", systemImage: "pencil")
                            }
                            .tint(.blue)

                            Button {
                                duplicateProfile(profile)
                            } label: {
                                Label("複製", systemImage: "doc.on.doc")
                            }
                            .tint(.green)
                        }
                }
            }
        }
        .navigationTitle("CC term")
        .navigationDestination(for: String.self) { destination in
            switch destination {
            case "snippets": SnippetListView()
            case "settings": TerminalSettingsView()
            case "keyboard": LayoutEditorView()
            default: EmptyView()
            }
        }
        .navigationDestination(isPresented: $navigateToSessions) {
            SessionContainerView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 16) {
                    NavigationLink(value: "keyboard") {
                        Image(systemName: "keyboard")
                    }
                    NavigationLink(value: "snippets") {
                        Image(systemName: "text.badge.star")
                    }
                    NavigationLink(value: "settings") {
                        Image(systemName: "gearshape")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewProfile = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewProfile) {
            NavigationStack {
                ProfileFormView(mode: .new) { profile in
                    modelContext.insert(profile)
                    showNewProfile = false
                }
            }
        }
        .sheet(item: $editingProfile) { profile in
            NavigationStack {
                ProfileFormView(mode: .edit(profile)) { _ in
                    profile.updatedAt = Date()
                    editingProfile = nil
                }
            }
        }
        .alert("パスワード", isPresented: $showPasswordPrompt) {
            SecureField("パスワード", text: $password)
            Button("接続") {
                performConnection()
            }
            Button("キャンセル", role: .cancel) {
                connectingProfile = nil
                password = ""
            }
        } message: {
            if let profile = connectingProfile {
                Text("\(profile.displayName) に接続")
            }
        }
        .alert("接続エラー", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func startConnection(profile: ConnectionProfile) {
        connectingProfile = profile

        if let saved = KeychainHelper.load(forKey: profile.keychainPasswordKey) {
            password = saved
            performConnection()
        } else {
            password = ""
            showPasswordPrompt = true
        }
    }

    private func performConnection() {
        guard let profile = connectingProfile else { return }
        let session = sessionManager.addSession(profile: profile, password: password)

        // 接続完了を待ってからナビゲーション
        Task {
            // 少し待ってから接続状態を確認
            try? await Task.sleep(for: .milliseconds(500))
            if session.viewModel.isConnected || session.viewModel.isConnecting {
                navigateToSessions = true
            } else {
                errorMessage = session.sshService.lastError ?? "接続に失敗しました。"
                sessionManager.removeSession(session)
            }
            connectingProfile = nil
            password = ""
        }
    }

    private func deleteProfile(_ profile: ConnectionProfile) {
        KeychainHelper.delete(forKey: profile.keychainPasswordKey)
        modelContext.delete(profile)
    }

    private func duplicateProfile(_ profile: ConnectionProfile) {
        let copy = profile.duplicate()
        if let pw = KeychainHelper.load(forKey: profile.keychainPasswordKey) {
            KeychainHelper.save(password: pw, forKey: copy.keychainPasswordKey)
        }
        modelContext.insert(copy)
        // 複製したプロファイルの編集画面を開く
        editingProfile = copy
    }
}

// MARK: - Profile Row

private struct ProfileRow: View {
    let profile: ConnectionProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(profile.displayName)
                .font(.headline)
            Text("\(profile.username)@\(profile.host):\(profile.port)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Immediate Feedback Button Style

private struct ImmediateFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(.systemGray4) : Color.clear)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .onChange(of: configuration.isPressed) {
                if configuration.isPressed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}
