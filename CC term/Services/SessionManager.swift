//
//  SessionManager.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation

@Observable
final class SessionManager {
    private(set) var sessions: [Session] = []
    var activeSessionId: UUID?

    var activeSession: Session? {
        guard let id = activeSessionId else { return sessions.first }
        return sessions.first { $0.id == id }
    }

    var hasActiveSessions: Bool {
        !sessions.isEmpty
    }

    func addSession(profile: ConnectionProfile, password: String) -> Session {
        let session = Session(
            profileName: profile.displayName,
            initialCommand: profile.initialCommand
        )
        sessions.append(session)
        activeSessionId = session.id

        Task {
            let config = profile.toSSHConfig(password: password)
            await session.viewModel.connect(config: config, initialCommand: profile.initialCommand)
        }

        return session
    }

    func removeSession(_ session: Session) {
        Task {
            await session.viewModel.disconnect()
        }
        sessions.removeAll { $0.id == session.id }

        // アクティブセッションが削除された場合、最後のセッションに切り替え
        if activeSessionId == session.id {
            activeSessionId = sessions.last?.id
        }
    }

    func switchTo(_ session: Session) {
        activeSessionId = session.id
    }

    func switchToNext() {
        guard let currentId = activeSessionId,
              let currentIndex = sessions.firstIndex(where: { $0.id == currentId }),
              currentIndex + 1 < sessions.count else { return }
        activeSessionId = sessions[currentIndex + 1].id
    }

    func switchToPrevious() {
        guard let currentId = activeSessionId,
              let currentIndex = sessions.firstIndex(where: { $0.id == currentId }),
              currentIndex > 0 else { return }
        activeSessionId = sessions[currentIndex - 1].id
    }
}
