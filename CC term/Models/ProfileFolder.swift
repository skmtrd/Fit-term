//
//  ProfileFolder.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation
import SwiftData

@Model
final class ProfileFolder {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \ConnectionProfile.folder)
    var profiles: [ConnectionProfile] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
