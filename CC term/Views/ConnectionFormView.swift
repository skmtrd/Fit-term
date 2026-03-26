//
//  ProfileFormView.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI

enum ProfileFormMode {
    case new
    case edit(ConnectionProfile)
}

struct ProfileFormView: View {
    let mode: ProfileFormMode
    let onSave: (ConnectionProfile) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var nickname: String = ""
    @State private var host: String = ""
    @State private var port: String = "22"
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var savePassword: Bool = true
    @State private var initialCommand: String = ""

    private var isFormValid: Bool {
        !host.trimmingCharacters(in: .whitespaces).isEmpty
            && !username.trimmingCharacters(in: .whitespaces).isEmpty
            && (Int(port) ?? 0) > 0
            && (Int(port) ?? 0) <= 65535
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        Form {
            Section("プロファイル") {
                TextField("ニックネーム", text: $nickname)
                    .textInputAutocapitalization(.never)
            }

            Section("サーバー") {
                TextField("ホスト", text: $host)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("ポート", text: $port)
                    .keyboardType(.numberPad)
            }

            Section("認証") {
                TextField("ユーザー名", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("パスワード", text: $password)
                    .textContentType(.password)

                Toggle("パスワードを保存", isOn: $savePassword)
            }

            Section {
                TextEditor(text: $initialCommand)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(minHeight: 80)
            } header: {
                Text("初期コマンド")
            } footer: {
                Text("接続直後に実行されます。複数行で複数コマンドを指定できます。")
            }
        }
        .navigationTitle(isEditing ? "プロファイル編集" : "新規プロファイル")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
                    .disabled(!isFormValid)
            }
        }
        .onAppear {
            if case .edit(let profile) = mode {
                nickname = profile.nickname
                host = profile.host
                port = String(profile.port)
                username = profile.username
                initialCommand = profile.initialCommand
                if let saved = KeychainHelper.load(forKey: profile.keychainPasswordKey) {
                    password = saved
                    savePassword = true
                } else {
                    savePassword = false
                }
            }
        }
    }

    private func save() {
        let profile: ConnectionProfile
        if case .edit(let existing) = mode {
            existing.nickname = nickname
            existing.host = host.trimmingCharacters(in: .whitespaces)
            existing.port = Int(port) ?? 22
            existing.username = username.trimmingCharacters(in: .whitespaces)
            existing.initialCommand = initialCommand
            existing.updatedAt = Date()
            profile = existing
        } else {
            profile = ConnectionProfile(
                nickname: nickname,
                host: host.trimmingCharacters(in: .whitespaces),
                port: Int(port) ?? 22,
                username: username.trimmingCharacters(in: .whitespaces),
                initialCommand: initialCommand
            )
        }

        if savePassword && !password.isEmpty {
            KeychainHelper.save(password: password, forKey: profile.keychainPasswordKey)
        } else {
            KeychainHelper.delete(forKey: profile.keychainPasswordKey)
        }

        onSave(profile)
        dismiss()
    }
}
