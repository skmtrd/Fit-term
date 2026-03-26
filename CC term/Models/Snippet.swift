//
//  Snippet.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation
import SwiftData

@Model
final class Snippet {
    var id: UUID
    var label: String
    var command: String
    var appendNewline: Bool

    init(label: String = "", command: String = "", appendNewline: Bool = true) {
        self.id = UUID()
        self.label = label
        self.command = command
        self.appendNewline = appendNewline
    }

    /// 実際に送信される文字列
    var commandToSend: String {
        appendNewline ? command + "\n" : command
    }
}
