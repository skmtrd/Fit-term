//
//  ActiveSessionsView.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI

struct ActiveSessionsView: View {
    @Environment(SessionManager.self) private var sessionManager
    @State private var navigateToTerminal = false

    var body: some View {
        Group {
            if sessionManager.hasActiveSessions {
                List {
                    ForEach(sessionManager.sessions) { session in
                        Button {
                            sessionManager.activeSessionId = session.id
                            navigateToTerminal = true
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(session.isConnected ? .green : .red)
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.displayName)
                                        .font(.headline)
                                    Text(session.isConnected ? "接続中" : "切断")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .tint(.primary)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                sessionManager.removeSession(session)
                            } label: {
                                Label("切断", systemImage: "xmark")
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "アクティブなセッションがありません",
                    systemImage: "terminal",
                    description: Text("ホームタブからプロファイルを選んで接続してください")
                )
            }
        }
        .navigationTitle("セッション")
        .navigationDestination(isPresented: $navigateToTerminal) {
            SessionContainerView()
                .toolbar(.hidden, for: .tabBar)
        }
    }
}
