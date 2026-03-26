//
//  Session.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation

@Observable
final class Session: Identifiable {
    let id = UUID()
    let sshService = SSHService()
    let viewModel: TerminalViewModel
    let profileName: String
    let initialCommand: String

    init(profileName: String, initialCommand: String = "") {
        self.profileName = profileName
        self.initialCommand = initialCommand
        self.viewModel = TerminalViewModel(sshService: sshService)
    }

    var displayName: String {
        profileName.isEmpty ? "Terminal" : profileName
    }

    var isConnected: Bool {
        viewModel.isConnected
    }
}
