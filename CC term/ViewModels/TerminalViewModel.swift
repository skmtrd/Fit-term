//
//  TerminalViewModel.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation
import UIKit
@preconcurrency import SwiftTerm

@Observable @MainActor
final class TerminalViewModel {
    let sshService: SSHService

    /// 強参照で保持 — 画面遷移で破棄されないようにする
    private(set) var terminalView: TerminalView?
    var title: String = "Terminal"

    private var shellTask: Task<Void, Never>?
    private var shellStarted = false
    private var initialCommand: String = ""

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

    func connect(config: SSHConnectionConfig, initialCommand: String = "") async {
        title = config.displayName
        self.initialCommand = initialCommand
        do {
            try await sshService.connect(config: config)
        } catch {
            // Error state is managed by sshService
        }
    }

    /// TerminalView を取得（既存があれば再利用）
    func getOrCreateTerminalView(coordinator: SwiftTerminalView.Coordinator) -> TerminalView {
        if let existing = terminalView {
            existing.terminalDelegate = coordinator
            return existing
        }
        let tv = TerminalView(frame: .zero)
        tv.terminalDelegate = coordinator
        tv.isScrollEnabled = true
        self.terminalView = tv
        return tv
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
        shellTask = Task { [weak self] in
            guard let self else { return }

            // 接続完了を待つ
            while !isConnected {
                if Task.isCancelled { return }
                try? await Task.sleep(for: .milliseconds(100))
            }

            // 接続完了後に initialCommand を取得（connect() で設定済み）
            let cmdToRun = initialCommand

            do {
                try await sshService.startShell(cols: cols, rows: rows) { [weak self] data in
                    let bytes = [UInt8](data)
                    DispatchQueue.main.async {
                        self?.terminalView?.feed(byteArray: ArraySlice(bytes))
                    }
                }
            } catch {
                // Shell ended with error
            }
        }

        // 初期コマンドの送信も Task 内で接続後に実行
        Task { [weak self] in
            guard let self else { return }

            // シェル起動を待つ
            try? await Task.sleep(for: .milliseconds(1000))

            let cmdToRun = initialCommand
            if !cmdToRun.isEmpty {
                let lines = cmdToRun.components(separatedBy: .newlines).filter { !$0.isEmpty }
                for line in lines {
                    let cmd = line + "\n"
                    sshService.sendToShell(Data(cmd.utf8))
                    try? await Task.sleep(for: .milliseconds(100))
                }
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

    func focusTerminal() {
        terminalView?.becomeFirstResponder()
        refreshDisplay()
    }

    func refreshDisplay() {
        guard let tv = terminalView else { return }
        tv.setNeedsLayout()
        tv.layoutIfNeeded()
        tv.setNeedsDisplay()
        // 現在のサイズでリサイズを再送信して表示を同期
        let cols = tv.getTerminal().cols
        let rows = tv.getTerminal().rows
        if cols > 0, rows > 0 {
            sshService.resizeShell(cols: cols, rows: rows)
        }
    }
}
