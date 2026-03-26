//
//  SSHConnectionConfig.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation

struct SSHConnectionConfig: Sendable, Codable, Identifiable {
    var id = UUID()
    var host: String
    var port: Int = 22
    var username: String
    var authMethod: AuthMethod

    var displayName: String {
        "\(username)@\(host):\(port)"
    }

    enum AuthMethod: Sendable, Codable {
        case password(String)
    }
}
