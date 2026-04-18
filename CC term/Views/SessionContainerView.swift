//
//  SessionContainerView.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData
import PhotosUI
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
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploading = false
    private var speechService: SpeechService { sessionManager.speechService }
    @State private var showTranscriptionConfirm = false
    @State private var transcribedText = ""

    private var gridCols: Int { 8 }
    private var gridRows: Int { layouts.first?.rows ?? 2 }

    /// キーボードエリアの縦横比（戻るボタン1列分 + グリッド列数 : 行数）
    private var keyboardAspectRatio: CGFloat {
        CGFloat(gridCols + 1) / CGFloat(gridRows)
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
                        let totalUnits = CGFloat(gridCols + 1)
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
                                            _ = tv.resignFirstResponder()
                                        } else {
                                            _ = tv.becomeFirstResponder()
                                        }
                                    }
                                },
                                closeTab: {
                                    sessionManager.removeSession(session)
                                },
                                newTab: {
                                    showProfilePicker = true
                                },
                                prevTab: {
                                    sessionManager.switchToPrevious()
                                },
                                nextTab: {
                                    sessionManager.switchToNext()
                                },
                                attachImage: {
                                    showPhotoPicker = true
                                },
                                captureVoice: {
                                    toggleVoiceRecording(for: session)
                                }
                            )
                            .frame(width: geo.size.width - backWidth)
                        }
                    }
                    .aspectRatio(keyboardAspectRatio, contentMode: .fit)
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
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) {
            guard let item = selectedPhoto else { return }
            selectedPhoto = nil
            Task {
                await uploadSelectedPhoto(item: item)
            }
        }
        .overlay {
            if isUploading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("画像をアップロード中...")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                    }
            }
            if speechService.isTranscribing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("文字起こし中...")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                    }
            }
            if speechService.isModelDownloading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("音声認識モデルをダウンロード中...")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                    }
            }
            if speechService.isRecording {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        stopVoiceRecording()
                    }
                    .overlay {
                        VStack(spacing: 16) {
                            Circle()
                                .fill(.red)
                                .frame(width: 16, height: 16)
                                .opacity(0.8)

                            Text("録音中")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)

                            Text("タップして停止")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
            }
        }
        .sheet(isPresented: $showTranscriptionConfirm) {
            TranscriptionConfirmView(
                text: $transcribedText,
                onSend: { text in
                    if let session = sessionManager.activeSession {
                        session.viewModel.sendToShell(Data(text.utf8))
                    }
                    showTranscriptionConfirm = false
                    transcribedText = ""
                },
                onCancel: {
                    showTranscriptionConfirm = false
                    transcribedText = ""
                }
            )
            .presentationDetents([.medium])
        }
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
                    _ = sessionManager.addSession(profile: profile, password: password)
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
            _ = sessionManager.addSession(profile: profile, password: saved)
        } else {
            passwordForProfile = profile
        }
    }

    private func uploadSelectedPhoto(item: PhotosPickerItem) async {
        guard let session = sessionManager.activeSession else { return }

        isUploading = true
        defer { isUploading = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }

            let filename = "fit-term-\(UUID().uuidString.prefix(8)).png"
            let remotePath = "/tmp/\(filename)"

            try await session.sshService.uploadFile(data: data, remotePath: remotePath)

            // パスをターミナルに入力
            session.viewModel.sendToShell(Data(remotePath.utf8))
        } catch {
            // アップロード失敗時は何もしない
        }
    }

    private func toggleVoiceRecording(for session: Session) {
        if speechService.isRecording {
            stopVoiceRecording()
        } else {
            Task {
                do {
                    try await speechService.ensureModelLoaded()
                    try await speechService.startRecording()
                } catch {
                    // エラー時は何もしない
                }
            }
        }
    }

    private func stopVoiceRecording() {
        Task {
            do {
                let text = try await speechService.stopRecordingAndTranscribe()
                if !text.isEmpty, let session = sessionManager.activeSession {
                    session.viewModel.sendToShell(Data(text.utf8))
                }
            } catch {
                // エラー時は録音を破棄
            }
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
