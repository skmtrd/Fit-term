//
//  SessionTabBar.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SessionTabBar: View {
    @Environment(SessionManager.self) private var sessionManager
    @Query private var settingsList: [TerminalSettings]
    let onAddTap: () -> Void

    @State private var draggingSessionId: UUID?

    private var terminalBgColor: Color {
        settingsList.first?.backgroundColor ?? .black
    }

    private var terminalFgColor: Color {
        settingsList.first?.foregroundColor ?? .white
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(sessionManager.sessions) { session in
                    TabItem(
                        session: session,
                        isActive: session.id == sessionManager.activeSessionId,
                        activeColor: terminalBgColor,
                        activeFgColor: terminalFgColor,
                        isDragging: draggingSessionId == session.id,
                        onTap: { sessionManager.switchTo(session) },
                        onClose: { sessionManager.removeSession(session) }
                    )
                    .draggable(session.id.uuidString) {
                        // ドラッグプレビュー
                        Text(session.displayName)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray4))
                            .cornerRadius(6)
                            .onAppear { draggingSessionId = session.id }
                    }
                    .onDrop(of: [.text], delegate: TabDropDelegate(
                        session: session,
                        sessionManager: sessionManager,
                        draggingSessionId: $draggingSessionId
                    ))
                }

                // ＋ボタン
                Button {
                    onAddTap()
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .background(Color(.systemGray6))
        .onChange(of: draggingSessionId) {
            // ドラッグ終了検知のフォールバック（3秒後に強制リセット）
            if draggingSessionId != nil {
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    draggingSessionId = nil
                }
            }
        }
    }
}

// MARK: - Drop Delegate

private struct TabDropDelegate: DropDelegate {
    let session: Session
    let sessionManager: SessionManager
    @Binding var draggingSessionId: UUID?

    func performDrop(info: DropInfo) -> Bool {
        draggingSessionId = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragId = draggingSessionId,
              dragId != session.id,
              let fromIndex = sessionManager.sessions.firstIndex(where: { $0.id == dragId }),
              let toIndex = sessionManager.sessions.firstIndex(where: { $0.id == session.id })
        else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            sessionManager.moveSession(
                from: IndexSet(integer: fromIndex),
                to: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropExited(info: DropInfo) {
        // ドラッグがこのタブから離れた時（最終的にリセット）
    }

    func validateDrop(info: DropInfo) -> Bool {
        true
    }
}

// MARK: - Tab Item

private struct TabItem: View {
    let session: Session
    let isActive: Bool
    let activeColor: Color
    let activeFgColor: Color
    let isDragging: Bool
    let onTap: () -> Void
    let onClose: () -> Void

    @State private var showCloseConfirm = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(session.isConnected ? .green : .red)
                .frame(width: 6, height: 6)

            Text(session.displayName)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(isActive ? activeFgColor : .primary)

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
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            isActive
                ? activeColor
                : Color.clear,
            in: UnevenRoundedRectangle(
                topLeadingRadius: 8,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 8
            )
        )
        .opacity(isDragging ? 0.5 : 1.0)
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
