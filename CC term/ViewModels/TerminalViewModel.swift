//
//  TerminalViewModel.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation

@Observable @MainActor
final class TerminalViewModel {
    let sshService: SSHService

    var commandInput: String = ""
    var outputLines: [OutputLine] = []

    var isConnected: Bool {
        if case .connected = sshService.connectionState { return true }
        return false
    }

    var isConnecting: Bool {
        if case .connecting = sshService.connectionState { return true }
        return false
    }

    struct OutputLine: Identifiable {
        let id = UUID()
        let text: String
        let type: LineType
    }

    enum LineType {
        case command
        case stdout
        case stderr
        case system
    }

    init(sshService: SSHService) {
        self.sshService = sshService
    }

    func connect(config: SSHConnectionConfig) async {
        appendSystem("接続中... \(config.displayName)")
        do {
            try await sshService.connect(config: config)
            appendSystem("接続しました。")
        } catch {
            appendSystem("接続失敗: \(sshService.lastError ?? error.localizedDescription)")
        }
    }

    func disconnect() async {
        await sshService.disconnect()
        appendSystem("切断しました。")
    }

    func sendCommand() async {
        let command = commandInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return }

        outputLines.append(OutputLine(text: "$ \(command)", type: .command))
        commandInput = ""

        do {
            let result = try await sshService.executeCommand(command)
            let stripped = Self.stripANSI(result)
            if !stripped.isEmpty {
                for line in stripped.components(separatedBy: "\n") {
                    outputLines.append(OutputLine(text: line, type: .stdout))
                }
            }
        } catch {
            outputLines.append(OutputLine(text: error.localizedDescription, type: .stderr))
        }
    }

    private func appendSystem(_ text: String) {
        outputLines.append(OutputLine(text: text, type: .system))
    }

    private static func stripANSI(_ string: String) -> String {
        string.replacingOccurrences(
            of: "\\x1B\\[[0-9;]*[a-zA-Z]",
            with: "",
            options: .regularExpression
        )
    }
}
