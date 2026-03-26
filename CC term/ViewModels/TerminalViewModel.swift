//
//  TerminalViewModel.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation
@preconcurrency import SwiftTerm

@Observable @MainActor
final class TerminalViewModel {
    let sshService: SSHService

    private(set) weak var terminalView: TerminalView?
    var title: String = "Terminal"

    private var shellTask: Task<Void, Never>?
    private var shellStarted = false

    var isConnected: Bool {
        if case .connected = sshService.connectionState { return true }
        return false
    }

    var isConnecting: Bool {
        if case .connecting = sshService.connectionState { return true }
        return false
    }

    init(sshService: SSHService) {
        self.sshService = sshService
    }

    func connect(config: SSHConnectionConfig) async {
        title = config.displayName
        do {
            try await sshService.connect(config: config)
        } catch {
            // Error state is managed by sshService
        }
    }

    func attachTerminalView(_ tv: TerminalView) {
        self.terminalView = tv
        // Don't start shell yet — wait for sizeChanged with actual dimensions
    }

    func resizeShell(cols: Int, rows: Int) {
        guard cols > 0, rows > 0 else { return }

        if !shellStarted {
            shellStarted = true
            startShell(cols: cols, rows: rows)
        } else {
            sshService.resizeShell(cols: cols, rows: rows)
        }
    }

    private func startShell(cols: Int, rows: Int) {
        guard let tv = terminalView else { return }

        shellTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await sshService.startShell(cols: cols, rows: rows) { [weak tv] data in
                    let bytes = [UInt8](data)
                    DispatchQueue.main.async {
                        tv?.feed(byteArray: ArraySlice(bytes))
                    }
                }
            } catch {
                // Shell ended with error
            }
        }
    }

    func disconnect() async {
        shellTask?.cancel()
        shellTask = nil
        await sshService.disconnect()
    }

    func sendToShell(_ data: Data) {
        sshService.sendToShell(data)
    }
}
