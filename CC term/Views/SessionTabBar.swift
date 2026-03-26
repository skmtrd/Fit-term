//
//  SessionTabBar.swift
//  CC term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI

struct SessionTabBar: View {
    @Environment(SessionManager.self) private var sessionManager
    let onAddTap: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(sessionManager.sessions) { session in
                    TabItem(
                        session: session,
                        isActive: session.id == sessionManager.activeSessionId,
                        onTap: { sessionManager.switchTo(session) },
                        onClose: { sessionManager.removeSession(session) }
                    )
                }

                // ＋ボタン
                Button {
                    onAddTap()
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .background(Color(.systemGray6))
    }
}

private struct TabItem: View {
    let session: Session
    let isActive: Bool
    let onTap: () -> Void
    let onClose: () -> Void

    @State private var showCloseConfirm = false

    var body: some View {
        HStack(spacing: 4) {
            // 接続状態インジケーター
            Circle()
                .fill(session.isConnected ? .green : .red)
                .frame(width: 6, height: 6)

            Text(session.displayName)
                .font(.caption)
                .lineLimit(1)

            Button {
                if session.isConnected {
                    showCloseConfirm = true
                } else {
                    onClose()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? Color(.systemBackground) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .alert("切断しますか？", isPresented: $showCloseConfirm) {
            Button("切断", role: .destructive) { onClose() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(session.displayName) のセッションを閉じます")
        }
    }
}
