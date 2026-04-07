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

    // MARK: - Model Management

    func ensureModelLoaded() async throws {
        guard !isModelLoaded else { return }

        isModelDownloading = true
        defer { isModelDownloading = false }

        let config = WhisperKitConfig(
            model: "large-v3-v20240930_547MB",
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
            // 音声バッファのコールバック（UI の波形表示等に使える）
        }

        isRecording = true
    }

    func stopRecordingAndTranscribe() async throws -> String {
        guard let whisperKit else {
            throw SpeechError.modelNotLoaded
        }

        // 録音停止
        whisperKit.audioProcessor.stopRecording()
        isRecording = false

        // 音声データを取得
        let audioSamples = whisperKit.audioProcessor.audioSamples
        guard audioSamples.count > Int(WhisperKit.sampleRate) / 2 else {
            // 0.5秒未満の録音は無視
            return ""
        }

        isTranscribing = true
        defer { isTranscribing = false }

        let options = DecodingOptions(
            language: "ja",
            usePrefillPrompt: true,
            wordTimestamps: false
        )

        let results = try await whisperKit.transcribe(
            audioArray: Array(audioSamples),
            decodeOptions: options
        )

        let text = results.map { $0.text }.joined().trimmingCharacters(in: .whitespacesAndNewlines)
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
