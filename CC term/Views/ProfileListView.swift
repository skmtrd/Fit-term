//
//  ProfileListView.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData

struct ProfileListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionManager.self) private var sessionManager
    @Query(sort: \ConnectionProfile.updatedAt, order: .reverse) private var allProfiles: [ConnectionProfile]
    @Query(sort: \ProfileFolder.createdAt) private var folders: [ProfileFolder]

    @State private var showNewProfile = false
    @State private var showNewFolder = false
    @State private var newFolderName = ""
    @State private var editingProfile: ConnectionProfile?
    @State private var connectingProfile: ConnectionProfile?
    @State private var password: String = ""
    @State private var showPasswordPrompt = false
    @State private var navigateToSessions = false
    @State private var errorMessage: String?

    /// フォルダに属していないプロファイル
    private var rootProfiles: [ConnectionProfile] {
        allProfiles.filter { $0.folder == nil }
    }

    var body: some View {
        List {
// フォルダ
            if !folders.isEmpty {
                Section("フォルダ") {
                    ForEach(folders) { folder in
                        FolderRow(
                            folder: folder,
                            onLaunchAll: { launchAllInFolder(folder) }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteFolder(folder)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                launchAllInFolder(folder)
                            } label: {
                                Label("一括起動", systemImage: "play.fill")
                            }
                            .tint(.green)
                        }
                    }
                }
            }

            // ルートプロファイル
            if allProfiles.isEmpty && folders.isEmpty {
                ContentUnavailableView(
                    "プロファイルがありません",
                    systemImage: "server.rack",
                    description: Text("＋ボタンから接続先を追加してください")
                )
            }

            if !rootProfiles.isEmpty {
                Section("プロファイル") {
                    ForEach(rootProfiles) { profile in
                        profileRow(profile)
                    }
                }
            }
        }
        .navigationTitle("Fit term")
        .navigationDestination(for: ProfileFolder.ID.self) { folderId in
            if let folder = folders.first(where: { $0.id == folderId }) {
                FolderDetailView(folder: folder)
            }
        }
        .navigationDestination(isPresented: $navigateToSessions) {
            SessionContainerView()
                .toolbar(.hidden, for: .tabBar)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showNewProfile = true
                    } label: {
                        Label("新規プロファイル", systemImage: "plus")
                    }
                    Button {
                        showNewFolder = true
                    } label: {
                        Label("新規フォルダ", systemImage: "folder.badge.plus")
                    }
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
        .alert("新規フォルダ", isPresented: $showNewFolder) {
            TextField("フォルダ名", text: $newFolderName)
            Button("作成") {
                if !newFolderName.isEmpty {
                    let folder = ProfileFolder(name: newFolderName)
                    modelContext.insert(folder)
                    newFolderName = ""
                }
            }
            Button("キャンセル", role: .cancel) { newFolderName = "" }
        }
        .alert("パスワード", isPresented: $showPasswordPrompt) {
            SecureField("パスワード", text: $password)
            Button("接続") { performConnection() }
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

    // MARK: - Profile Row

    @ViewBuilder
    private func profileRow(_ profile: ConnectionProfile) -> some View {
        Button {
            startConnection(profile: profile)
        } label: {
            HStack {
                ProfileRowContent(profile: profile)
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

    // MARK: - Actions

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

        Task {
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

    private func launchAllInFolder(_ folder: ProfileFolder) {
        var needsPassword = false
        for profile in folder.profiles {
            if let saved = KeychainHelper.load(forKey: profile.keychainPasswordKey) {
                _ = sessionManager.addSession(profile: profile, password: saved)
            } else {
                needsPassword = true
            }
        }
        if needsPassword {
            errorMessage = "パスワードが保存されていないプロファイルはスキップされました。"
        }
        if sessionManager.hasActiveSessions {
            navigateToSessions = true
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
        editingProfile = copy
    }

    private func deleteFolder(_ folder: ProfileFolder) {
        // フォルダ内のプロファイルはルートに移動（削除しない）
        for profile in folder.profiles {
            profile.folder = nil
        }
        modelContext.delete(folder)
    }
}

// MARK: - Folder Row

private struct FolderRow: View {
    let folder: ProfileFolder
    let onLaunchAll: () -> Void

    var body: some View {
        NavigationLink(value: folder.id) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(folder.name)
                        .font(.headline)
                    Text("\(folder.profiles.count) プロファイル")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Folder Detail View

struct FolderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionManager.self) private var sessionManager
    @Bindable var folder: ProfileFolder
    @Query(sort: \ConnectionProfile.updatedAt, order: .reverse) private var allProfiles: [ConnectionProfile]

    @State private var showAddSheet = false
    @State private var showNewProfile = false
    @State private var editingProfile: ConnectionProfile?
    @State private var connectingProfile: ConnectionProfile?
    @State private var password = ""
    @State private var showPasswordPrompt = false
    @State private var navigateToSessions = false
    @State private var errorMessage: String?
    @State private var isEditingName = false
    @State private var editedName = ""

    private var availableProfiles: [ConnectionProfile] {
        allProfiles.filter { $0.folder == nil }
    }

    var body: some View {
        List {
            // 一括起動ボタン
            if !folder.profiles.isEmpty {
                Section {
                    Button {
                        launchAll()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                                .foregroundStyle(.green)
                            Text("すべて起動 (\(folder.profiles.count))")
                        }
                    }
                }
            }

            // フォルダ内プロファイル
            Section("プロファイル") {
                if folder.profiles.isEmpty {
                    Text("プロファイルがありません")
                        .foregroundStyle(.secondary)
                }
                ForEach(folder.profiles) { profile in
                    Button {
                        startConnection(profile: profile)
                    } label: {
                        HStack {
                            ProfileRowContent(profile: profile)
                            Spacer()
                            if connectingProfile?.id == profile.id {
                                ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(ImmediateFeedbackButtonStyle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            profile.folder = nil
                        } label: {
                            Label("フォルダから外す", systemImage: "folder.badge.minus")
                        }
                        .tint(.orange)

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
        .navigationTitle(folder.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showNewProfile = true
                    } label: {
                        Label("新規プロファイル作成", systemImage: "plus.circle")
                    }
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("既存プロファイルを追加", systemImage: "folder.badge.plus")
                    }
                    Divider()
                    Button {
                        editedName = folder.name
                        isEditingName = true
                    } label: {
                        Label("フォルダ名を変更", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                List {
                    if availableProfiles.isEmpty {
                        Text("追加できるプロファイルがありません")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(availableProfiles) { profile in
                        Button {
                            profile.folder = folder
                            showAddSheet = false
                        } label: {
                            ProfileRowContent(profile: profile)
                        }
                        .tint(.primary)
                    }
                }
                .navigationTitle("プロファイルを追加")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") { showAddSheet = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showNewProfile) {
            NavigationStack {
                ProfileFormView(mode: .new) { profile in
                    profile.folder = folder
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
        .alert("フォルダ名を変更", isPresented: $isEditingName) {
            TextField("フォルダ名", text: $editedName)
            Button("保存") {
                if !editedName.isEmpty {
                    folder.name = editedName
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .alert("パスワード", isPresented: $showPasswordPrompt) {
            SecureField("パスワード", text: $password)
            Button("接続") { performConnection() }
            Button("キャンセル", role: .cancel) {
                connectingProfile = nil
                password = ""
            }
        } message: {
            if let profile = connectingProfile {
                Text("\(profile.displayName) に接続")
            }
        }
        .navigationDestination(isPresented: $navigateToSessions) {
            SessionContainerView()
                .toolbar(.hidden, for: .tabBar)
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
        Task {
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

    private func duplicateProfile(_ profile: ConnectionProfile) {
        let copy = profile.duplicate()
        copy.folder = folder
        if let pw = KeychainHelper.load(forKey: profile.keychainPasswordKey) {
            KeychainHelper.save(password: pw, forKey: copy.keychainPasswordKey)
        }
        modelContext.insert(copy)
        editingProfile = copy
    }

    private func launchAll() {
        var skipped = false
        for profile in folder.profiles {
            if let saved = KeychainHelper.load(forKey: profile.keychainPasswordKey) {
                _ = sessionManager.addSession(profile: profile, password: saved)
            } else {
                skipped = true
            }
        }
        if skipped {
            errorMessage = "パスワードが保存されていないプロファイルはスキップされました。"
        }
        if sessionManager.hasActiveSessions {
            navigateToSessions = true
        }
    }
}

// MARK: - Shared Components

struct ProfileRowContent: View {
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

struct ImmediateFeedbackButtonStyle: ButtonStyle {
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
