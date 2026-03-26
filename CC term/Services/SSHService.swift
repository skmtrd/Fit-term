//
//  SSHService.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation
import Citadel
import NIOCore

@Observable
final class SSHService: @unchecked Sendable {

    // MARK: - State (read from UI on MainActor)

    @MainActor var connectionState: ConnectionState = .disconnected
    @MainActor var lastError: String?

    enum ConnectionState: Sendable {
        case disconnected
        case connecting
        case connected
        case error(String)
    }

    // MARK: - Private

    nonisolated(unsafe) private var client: SSHClient?

    // MARK: - Connection

    nonisolated func connect(config: SSHConnectionConfig) async throws {
        await MainActor.run {
            self.connectionState = .connecting
            self.lastError = nil
        }

        do {
            let authMethod: SSHAuthenticationMethod
            switch config.authMethod {
            case .password(let pw):
                authMethod = .passwordBased(username: config.username, password: pw)
            }

            let sshClient = try await SSHClient.connect(
                host: config.host,
                port: config.port,
                authenticationMethod: authMethod,
                hostKeyValidator: .acceptAnything(),
                reconnect: .never
            )

            self.client = sshClient

            await MainActor.run {
                self.connectionState = .connected
            }

            sshClient.onDisconnect { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    self.connectionState = .disconnected
                    self.client = nil
                }
            }
        } catch {
            let message = Self.userFriendlyMessage(for: error)
            await MainActor.run {
                self.connectionState = .error(message)
                self.lastError = message
            }
            throw error
        }
    }

    nonisolated func disconnect() async {
        if let client = self.client {
            try? await client.close()
        }
        self.client = nil
        await MainActor.run {
            self.connectionState = .disconnected
        }
    }

    // MARK: - Command Execution

    nonisolated func executeCommand(_ command: String) async throws -> String {
        guard let client else {
            throw SSHServiceError.notConnected
        }

        let buffer = try await client.executeCommand(command)
        let output = String(buffer: buffer)
        return output
    }

    // MARK: - Error Mapping

    private nonisolated static func userFriendlyMessage(for error: Error) -> String {
        let description = String(describing: error)

        if description.contains("authenticationFailed") || description.contains("allAuthenticationOptionsFailed") {
            return "認証に失敗しました。ユーザー名とパスワードを確認してください。"
        }
        if description.contains("channelCreationFailed") {
            return "チャンネルの作成に失敗しました。接続が切断された可能性があります。"
        }
        if description.contains("connectionRefused") || description.contains("connect") {
            return "接続できませんでした。ホストとポートを確認してください。"
        }

        return "エラーが発生しました: \(error.localizedDescription)"
    }

    enum SSHServiceError: LocalizedError {
        case notConnected

        var errorDescription: String? {
            switch self {
            case .notConnected:
                return "SSH サーバーに接続されていません。"
            }
        }
    }
}
