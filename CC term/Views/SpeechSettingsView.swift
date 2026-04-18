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
    @State private var isDeleting = false

    private var isDownloading: Bool { sessionManager.speechService.isModelDownloading }

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
                        Text("\(Int(sessionManager.speechService.modelDownloadProgress * 100))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    } else if SpeechService.isModelDownloaded {
                        Text("ダウンロード済み")
                            .foregroundStyle(.green)
                    } else {
                        Text("未ダウンロード")
                            .foregroundStyle(.secondary)
                    }
                }

                if isDownloading {
                    ProgressView(value: sessionManager.speechService.modelDownloadProgress)
                        .progressViewStyle(.linear)
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
                if isDownloading {
                    Text("ダウンロード中はアプリを開いたままにしてください。バックグラウンドに移動すると中断される可能性があります。")
                } else {
                    Text("モデルはアプリ内に保存されます。iCloud バックアップには含まれません。")
                }
            }

            if !SpeechService.isModelDownloaded {
                Section {
                    if sessionManager.speechService.isModelDownloading {
                        Button("キャンセル", role: .destructive) {
                            sessionManager.speechService.cancelDownload()
                        }
                    } else {
                        Button("今すぐダウンロード") {
                            Task { await downloadModel() }
                        }
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
                            Text("モデルを削除")
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
        defer { updateSize() }
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
