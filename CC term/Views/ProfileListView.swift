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
    @Environment(SSHService.self) private var sshService
    @Query(sort: \ConnectionProfile.updatedAt, order: .reverse) private var profiles: [ConnectionProfile]

    @State private var showNewProfile = false
    @State private var editingProfile: ConnectionProfile?
    @State private var connectingProfile: ConnectionProfile?
    @State private var password: String = ""
    @State private var showPasswordPrompt = false
    @State private var navigateToTerminal = false
    @State private var viewModel: TerminalViewModel?
    @State private var errorMessage: String?
    @State private var isConnecting = false

    var body: some View {
        List {
            if profiles.isEmpty {
                ContentUnavailableView(
                    "プロファイルがありません",
                    systemImage: "server.rack",
                    description: Text("＋ボタンから接続先を追加してください")
                )
            }

            ForEach(profiles) { profile in
                ProfileRow(profile: profile)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startConnection(profile: profile)
                    }
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
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            duplicateProfile(profile)
                        } label: {
                            Label("複製", systemImage: "doc.on.doc")
                        }
                        .tint(.green)
                    }
            }
        }
        .navigationTitle("CC term")
        .navigationDestination(for: String.self) { destination in
            if destination == "snippets" {
                SnippetListView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(value: "snippets") {
                    Image(systemName: "text.badge.star")
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
        .navigationDestination(isPresented: $navigateToTerminal) {
            if let viewModel {
                TerminalScreen(viewModel: viewModel)
            }
        }
    }

    private func startConnection(profile: ConnectionProfile) {
        connectingProfile = profile

        // Keychain にパスワードがあればそれを使う
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
        let config = profile.toSSHConfig(password: password)
        let vm = TerminalViewModel(sshService: sshService)
        self.viewModel = vm
        isConnecting = true

        Task {
            await vm.connect(config: config, initialCommand: profile.initialCommand)
            isConnecting = false

            if vm.isConnected {
                navigateToTerminal = true
            } else {
                errorMessage = sshService.lastError ?? "接続に失敗しました。"
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
        // パスワードも複製
        if let pw = KeychainHelper.load(forKey: profile.keychainPasswordKey) {
            KeychainHelper.save(password: pw, forKey: copy.keychainPasswordKey)
        }
        modelContext.insert(copy)
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
