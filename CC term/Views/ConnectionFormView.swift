//
//  ConnectionFormView.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI

struct ConnectionFormView: View {
    @Environment(SSHService.self) private var sshService

    @State private var host: String = "192.168.0.78"
    @State private var port: String = "22"
    @State private var username: String = "skmtrd"
    @State private var password: String = ""
    @State private var isConnecting = false
    @State private var navigateToTerminal = false
    @State private var viewModel: TerminalViewModel?
    @State private var errorMessage: String?

    private var isFormValid: Bool {
        !host.trimmingCharacters(in: .whitespaces).isEmpty
            && !username.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty
            && (Int(port) ?? 0) > 0
            && (Int(port) ?? 0) <= 65535
    }

    var body: some View {
        Form {
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
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    connect()
                } label: {
                    if isConnecting {
                        HStack {
                            ProgressView()
                            Text("接続中...")
                        }
                    } else {
                        Text("接続")
                    }
                }
                .disabled(!isFormValid || isConnecting)
            }
        }
        .navigationTitle("SSH 接続")
        .navigationDestination(isPresented: $navigateToTerminal) {
            if let viewModel {
                TerminalScreen(viewModel: viewModel)
            }
        }
    }

    private func connect() {
        let config = SSHConnectionConfig(
            host: host.trimmingCharacters(in: .whitespaces),
            port: Int(port) ?? 22,
            username: username.trimmingCharacters(in: .whitespaces),
            authMethod: .password(password)
        )

        let vm = TerminalViewModel(sshService: sshService)
        self.viewModel = vm
        isConnecting = true
        errorMessage = nil

        Task {
            await vm.connect(config: config)
            isConnecting = false

            if vm.isConnected {
                navigateToTerminal = true
            } else {
                errorMessage = sshService.lastError ?? "接続に失敗しました。"
            }
        }
    }
}
