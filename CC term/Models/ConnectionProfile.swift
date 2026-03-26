//
//  ConnectionProfile.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation
import SwiftData

@Model
final class ConnectionProfile {
    var id: UUID
    var nickname: String
    var host: String
    var port: Int
    var username: String
    var initialCommand: String = ""
    var createdAt: Date
    var updatedAt: Date

    /// パスワードは Keychain に保存するため、このキーで紐づける
    var keychainPasswordKey: String {
        "cc-term-password-\(id.uuidString)"
    }

    init(
        nickname: String,
        host: String,
        port: Int = 22,
        username: String,
        initialCommand: String = ""
    ) {
        self.id = UUID()
        self.nickname = nickname
        self.host = host
        self.port = port
        self.username = username
        self.initialCommand = initialCommand
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var displayName: String {
        nickname.isEmpty ? "\(username)@\(host)" : nickname
    }

    func toSSHConfig(password: String) -> SSHConnectionConfig {
        SSHConnectionConfig(
            host: host,
            port: port,
            username: username,
            authMethod: .password(password)
        )
    }

    func duplicate() -> ConnectionProfile {
        ConnectionProfile(
            nickname: "\(nickname) (コピー)",
            host: host,
            port: port,
            username: username,
            initialCommand: initialCommand
        )
    }
}
