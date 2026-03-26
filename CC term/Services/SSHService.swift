//
//  SSHService.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation
import Citadel
import NIOCore
import NIOSSH

@Observable
final class SSHService {

    // MARK: - State

    var connectionState: ConnectionState = .disconnected
    var lastError: String?

    enum ConnectionState: Sendable {
        case disconnected
        case connecting
        case connected
        case error(String)
    }

    // MARK: - Private

    private var client: SSHClient?
    private var shellInputContinuation: AsyncStream<ShellInput>.Continuation?

    private var keepAliveTask: Task<Void, Never>?

    private enum ShellInput: Sendable {
        case data(Data)
        case resize(cols: Int, rows: Int)
        case keepAlive
    }

    // MARK: - Connection

    func connect(config: SSHConnectionConfig) async throws {
        connectionState = .connecting
        lastError = nil

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
            connectionState = .connected
        } catch {
            let message = Self.userFriendlyMessage(for: error)
            connectionState = .error(message)
            lastError = message
            throw error
        }
    }

    func disconnect() async {
        stopKeepAlive()
        shellInputContinuation?.finish()
        shellInputContinuation = nil
        if let client {
            try? await client.close()
        }
        self.client = nil
        connectionState = .disconnected
    }

    // MARK: - Interactive Shell

    func startShell(
        cols: Int,
        rows: Int,
        onOutput: @escaping @Sendable (Data) -> Void
    ) async throws {
        guard let client else {
            throw SSHServiceError.notConnected
        }

        let (inputStream, inputContinuation) = AsyncStream.makeStream(of: ShellInput.self)
        self.shellInputContinuation = inputContinuation
        startKeepAlive()

        let ptyRequest = SSHChannelRequestEvent.PseudoTerminalRequest(
            wantReply: true,
            term: "xterm-256color",
            terminalCharacterWidth: cols,
            terminalRowHeight: rows,
            terminalPixelWidth: 0,
            terminalPixelHeight: 0,
            terminalModes: .init([:])
        )

        try await client.withPTY(ptyRequest) { inbound, outbound in
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    for try await output in inbound {
                        switch output {
                        case .stdout(let buffer):
                            onOutput(Data(buffer.readableBytesView))
                        case .stderr(let buffer):
                            onOutput(Data(buffer.readableBytesView))
                        }
                    }
                }

                group.addTask {
                    for await input in inputStream {
                        switch input {
                        case .data(let data):
                            var buf = ByteBuffer()
                            buf.writeBytes(data)
                            try await outbound.write(buf)
                        case .resize(let cols, let rows):
                            try await outbound.changeSize(
                                cols: cols,
                                rows: rows,
                                pixelWidth: 0,
                                pixelHeight: 0
                            )
                        case .keepAlive:
                            // SSH チャンネルに空データを送信して接続を維持
                            var buf = ByteBuffer()
                            buf.writeInteger(UInt8(0))
                            try await outbound.write(buf)
                        }
                    }
                }

                try await group.next()
                group.cancelAll()
            }
        }

        stopKeepAlive()
        self.shellInputContinuation = nil
        connectionState = .disconnected
    }

    func sendToShell(_ data: Data) {
        shellInputContinuation?.yield(.data(data))
    }

    func resizeShell(cols: Int, rows: Int) {
        shellInputContinuation?.yield(.resize(cols: cols, rows: rows))
    }

    // MARK: - Keep Alive

    private func startKeepAlive() {
        stopKeepAlive()
        keepAliveTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                if Task.isCancelled { break }
                shellInputContinuation?.yield(.keepAlive)
            }
        }
    }

    private func stopKeepAlive() {
        keepAliveTask?.cancel()
        keepAliveTask = nil
    }

    // MARK: - Error Mapping

    private static func userFriendlyMessage(for error: Error) -> String {
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
