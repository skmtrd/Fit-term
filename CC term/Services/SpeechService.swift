//
//  SpeechService.swift
//  Fit term
//
//  Created by 坂本蒼哉 on 2026/03/26.
//

import Foundation
import WhisperKit
import AVFoundation

@Observable
final class SpeechService {
    var isRecording = false
    var isTranscribing = false
    var isModelLoaded = false
    var isModelDownloading = false
    var modelDownloadProgress: Double = 0
    var errorMessage: String?

    private var whisperKit: WhisperKit?
    private var loadTask: Task<Void, Error>?

    static let modelName = "large-v3-v20240930_547MB"
    static let modelRepo = "argmaxinc/whisperkit-coreml"

    // MARK: - Model Storage

    /// モデル保存先（Application Support/WhisperKitModels）
    /// - Library/Caches: iOS が自動削除する → NG
    /// - Documents: iCloud バックアップに含まれ 500MB で枠を圧迫 → NG
    /// - Application Support + isExcludedFromBackup: 永続化 & バックアップ除外 → OK
    static var modelBaseURL: URL {
        let fm = FileManager.default
        let appSupport = (try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fm.urls(for: .documentDirectory, in: .userDomainMask)[0]

        var url = appSupport.appendingPathComponent("WhisperKitModels", isDirectory: true)

        // ディレクトリ作成
        if !fm.fileExists(atPath: url.path) {
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        }

        // iCloud バックアップ除外（iCloud 容量圧迫を防ぐ）
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)

        return url
    }

    /// 保存済みのモデルフォルダパス（UserDefaults に永続化）
    private static let savedModelFolderKey = "WhisperKitSavedModelFolder"

    static var savedModelFolderURL: URL? {
        get {
            guard let path = UserDefaults.standard.string(forKey: savedModelFolderKey) else { return nil }
            let url = URL(fileURLWithPath: path)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.path, forKey: savedModelFolderKey)
            } else {
                UserDefaults.standard.removeObject(forKey: savedModelFolderKey)
            }
        }
    }

    /// 互換用: 期待されるパス（UserDefaults に無ければここをチェック）
    static var modelFolderURL: URL {
        savedModelFolderURL ?? modelBaseURL
            .appendingPathComponent("models", isDirectory: true)
            .appendingPathComponent(modelRepo, isDirectory: true)
            .appendingPathComponent("openai_whisper-\(modelName)", isDirectory: true)
    }

    /// モデルがダウンロード済みか
    static var isModelDownloaded: Bool {
        if let saved = savedModelFolderURL { return FileManager.default.fileExists(atPath: saved.path) }
        return FileManager.default.fileExists(atPath: modelFolderURL.path)
    }

    /// モデルフォルダのサイズ（MB）
    static var modelSizeMB: Double? {
        guard isModelDownloaded else { return nil }
        let url = modelFolderURL
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        var totalBytes: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize {
                totalBytes += Int64(size)
            }
        }
        return Double(totalBytes) / 1024.0 / 1024.0
    }

    // MARK: - Model Management

    func ensureModelLoaded() async throws {
        guard !isModelLoaded else { return }

        // すでに同じタスクが走ってるならそれを待つ（重複実行防止）
        if let existing = loadTask {
            try await existing.value
            return
        }

        // 永続化する detached Task（View 消滅でもキャンセルされない）
        let task = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            try await self.performModelLoad()
        }
        loadTask = task

        do {
            try await task.value
        } catch {
            loadTask = nil
            throw error
        }
        loadTask = nil
    }

    private func performModelLoad() async throws {
        // 未ダウンロードなら先にDL
        if !Self.isModelDownloaded {
            try await downloadWithRetry()
        }

        // ダウンロード済みのモデルをロード（破損時は削除してリトライ）
        do {
            try await loadModelFromDisk()
        } catch {
            // ロード失敗 = 破損ファイルの可能性 → 削除して1回だけ再DL
            try? FileManager.default.removeItem(at: Self.modelFolderURL)
            try await downloadWithRetry()
            try await loadModelFromDisk()
        }
    }

    private func downloadWithRetry() async throws {
        await MainActor.run {
            isModelDownloading = true
            modelDownloadProgress = 0
        }
        defer {
            Task { @MainActor in
                self.isModelDownloading = false
            }
        }

        let maxAttempts = 3
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                let folder = try await WhisperKit.download(
                    variant: Self.modelName,
                    downloadBase: Self.modelBaseURL,
                    from: Self.modelRepo
                ) { [weak self] progress in
                    Task { @MainActor in
                        self?.modelDownloadProgress = progress.fractionCompleted
                    }
                }
                // 実際の保存先を永続化
                Self.savedModelFolderURL = folder
                print("[SpeechService] Model downloaded to: \(folder.path)")
                return // 成功
            } catch {
                lastError = error
                if Task.isCancelled { throw error }
                if attempt < maxAttempts {
                    // 少し待ってから再試行
                    try? await Task.sleep(for: .seconds(2))
                }
            }
        }

        if let lastError { throw lastError }
    }

    private func loadModelFromDisk() async throws {
        guard let folder = Self.savedModelFolderURL else {
            throw SpeechError.modelNotLoaded
        }
        print("[SpeechService] Loading model from: \(folder.path)")

        let config = WhisperKitConfig(
            model: Self.modelName,
            modelFolder: folder.path,
            prewarm: false,
            load: false,
            download: false
        )

        let kit = try await WhisperKit(config)
        kit.modelFolder = folder
        try await kit.prewarmModels()
        try await kit.loadModels()

        await MainActor.run {
            self.whisperKit = kit
            self.isModelLoaded = true
        }
    }

    /// ダウンロードをキャンセル（明示的に呼ばない限りキャンセルされない）
    func cancelDownload() {
        loadTask?.cancel()
        loadTask = nil
        isModelDownloading = false
    }

    func unloadModel() async {
        await whisperKit?.unloadModels()
        whisperKit = nil
        isModelLoaded = false
    }

    /// モデルファイルを削除（次回使用時に再ダウンロード）
    func deleteModel() async throws {
        await unloadModel()
        if let saved = Self.savedModelFolderURL, FileManager.default.fileExists(atPath: saved.path) {
            try FileManager.default.removeItem(at: saved)
        }
        Self.savedModelFolderURL = nil
    }

    // MARK: - Recording

    func startRecording() async throws {
        guard let whisperKit else {
            throw SpeechError.modelNotLoaded
        }

        let granted = await AudioProcessor.requestRecordPermission()
        guard granted else {
            throw SpeechError.microphonePermissionDenied
        }

        try whisperKit.audioProcessor.startRecordingLive(inputDeviceID: nil) { _ in
            // 音声バッファのコールバック
        }

        isRecording = true
    }

    func stopRecordingAndTranscribe() async throws -> String {
        guard let whisperKit else {
            throw SpeechError.modelNotLoaded
        }

        whisperKit.audioProcessor.stopRecording()
        isRecording = false

        let audioSamples = whisperKit.audioProcessor.audioSamples
        guard audioSamples.count > Int(WhisperKit.sampleRate) / 2 else {
            return ""
        }

        isTranscribing = true
        defer { isTranscribing = false }

        let options = DecodingOptions(
            language: "ja",
            temperature: 0.0,
            temperatureFallbackCount: 3,
            usePrefillPrompt: true,
            usePrefillCache: true,
            wordTimestamps: false,
            compressionRatioThreshold: 2.4,
            logProbThreshold: -1.0,
            noSpeechThreshold: 0.6,
            chunkingStrategy: .vad
        )

        let results = try await whisperKit.transcribe(
            audioArray: Array(audioSamples),
            decodeOptions: options
        )

        let text = results.map { $0.text }.joined().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return text
    }

    func cancelRecording() {
        whisperKit?.audioProcessor.stopRecording()
        isRecording = false
    }

    // MARK: - Errors

    enum SpeechError: LocalizedError {
        case modelNotLoaded
        case microphonePermissionDenied

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded:
                "音声認識モデルがロードされていません。"
            case .microphonePermissionDenied:
                "マイクの使用が許可されていません。設定アプリから許可してください。"
            }
        }
    }
}
