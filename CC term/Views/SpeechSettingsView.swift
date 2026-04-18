//
//  SpeechSettingsView.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import SwiftUI

struct SpeechSettingsView: View {
    @Environment(SessionManager.self) private var sessionManager
    @State private var modelSize: Double?
    @State private var showDeleteConfirm = false
    @State private var isDownloading = false
    @State private var isDeleting = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("モデル名")
                    Spacer()
                    Text("Whisper Large V3 Turbo")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("状態")
                    Spacer()
                    if isDownloading {
                        HStack(spacing: 4) {
                            ProgressView().controlSize(.small)
                            Text("ダウンロード中")
                                .foregroundStyle(.secondary)
                        }
                    } else if SpeechService.isModelDownloaded {
                        Label("ダウンロード済み", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("未ダウンロード", systemImage: "xmark.circle")
                            .foregroundStyle(.secondary)
                    }
                }

                if let size = modelSize {
                    HStack {
                        Text("サイズ")
                        Spacer()
                        Text("\(String(format: "%.1f", size)) MB")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("音声認識モデル")
            } footer: {
                Text("モデルは Documents フォルダに保存されます。アプリ削除時のみ一緒に削除されます。")
            }

            if !SpeechService.isModelDownloaded && !isDownloading {
                Section {
                    Button {
                        Task { await downloadModel() }
                    } label: {
                        Label("今すぐダウンロード", systemImage: "arrow.down.circle")
                    }
                }
            }

            if SpeechService.isModelDownloaded {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        if isDeleting {
                            HStack {
                                ProgressView().controlSize(.small)
                                Text("削除中...")
                            }
                        } else {
                            Label("モデルを削除", systemImage: "trash")
                        }
                    }
                    .disabled(isDeleting)
                } footer: {
                    Text("削除すると次回音声入力時に再ダウンロードされます。")
                }
            }
        }
        .navigationTitle("音声認識")
        .onAppear { updateSize() }
        .alert("モデルを削除しますか？", isPresented: $showDeleteConfirm) {
            Button("削除", role: .destructive) {
                Task { await deleteModel() }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("次回音声入力時に再ダウンロードが必要になります。")
        }
    }

    private func updateSize() {
        modelSize = SpeechService.modelSizeMB
    }

    private func downloadModel() async {
        isDownloading = true
        defer {
            isDownloading = false
            updateSize()
        }
        do {
            try await sessionManager.speechService.ensureModelLoaded()
        } catch {
            // エラーは無視
        }
    }

    private func deleteModel() async {
        isDeleting = true
        defer {
            isDeleting = false
            updateSize()
        }
        do {
            try await sessionManager.speechService.deleteModel()
        } catch {
            // エラーは無視
        }
    }
}
