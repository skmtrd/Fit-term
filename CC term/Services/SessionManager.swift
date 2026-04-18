//
//  SessionManager.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation
import SwiftUI

@Observable
final class SessionManager {
    private(set) var sessions: [Session] = []
    var activeSessionId: UUID?
    let backgroundLocation = BackgroundLocationManager()
    let speechService = SpeechService()

    var activeSession: Session? {
        guard let id = activeSessionId else { return sessions.first }
        return sessions.first { $0.id == id }
    }

    var hasActiveSessions: Bool {
        !sessions.isEmpty
    }

    /// バックグラウンド維持が有効で、位置情報が許可されているか
    var isBackgroundKeepAliveEnabled: Bool {
        backgroundLocation.isRunning
    }

    @discardableResult
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

        // セッションが追加されたらバックグラウンド維持を開始
        updateBackgroundLocation()

        return session
    }

    func removeSession(_ session: Session) {
        Task {
            await session.viewModel.disconnect()
        }
        sessions.removeAll { $0.id == session.id }

        if activeSessionId == session.id {
            activeSessionId = sessions.last?.id
        }

        // セッションが0になったらバックグラウンド維持を停止
        updateBackgroundLocation()
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

    func moveSession(from source: IndexSet, to destination: Int) {
        sessions.move(fromOffsets: source, toOffset: destination)
    }

    private func updateBackgroundLocation() {
        let enabled = UserDefaults.standard.bool(forKey: "backgroundKeepAlive")
        if enabled && !sessions.isEmpty {
            backgroundLocation.start()
        } else {
            backgroundLocation.stop()
        }
    }
}
