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

    static let modelName = "large-v3-v20240930_547MB"
    static let modelRepo = "argmaxinc/whisperkit-coreml"

    // MARK: - Model Storage

    /// モデル保存先（Documents/WhisperKitModels）
    /// Library/Caches は iOS にストレージ不足時削除されるため Documents を使用
    static var modelBaseURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("WhisperKitModels", isDirectory: true)
    }

    /// モデルフォルダのフルパス
    static var modelFolderURL: URL {
        modelBaseURL
            .appendingPathComponent(modelRepo, isDirectory: true)
            .appendingPathComponent("openai_whisper-\(modelName)", isDirectory: true)
    }

    /// モデルがダウンロード済みか
    static var isModelDownloaded: Bool {
        FileManager.default.fileExists(atPath: modelFolderURL.path)
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

        isModelDownloading = true
        defer { isModelDownloading = false }

        // Documents 配下に保存するように downloadBase を指定
        let config = WhisperKitConfig(
            model: Self.modelName,
            downloadBase: Self.modelBaseURL,
            modelRepo: Self.modelRepo,
            prewarm: true,
            download: true,
            useBackgroundDownloadSession: false
        )

        whisperKit = try await WhisperKit(config)
        isModelLoaded = true
    }

    func unloadModel() async {
        await whisperKit?.unloadModels()
        whisperKit = nil
        isModelLoaded = false
    }

    /// モデルファイルを削除（次回使用時に再ダウンロード）
    func deleteModel() async throws {
        await unloadModel()
        if FileManager.default.fileExists(atPath: Self.modelFolderURL.path) {
            try FileManager.default.removeItem(at: Self.modelFolderURL)
        }
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
