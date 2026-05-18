import Combine
import Foundation
import SwiftUI

@MainActor
final class TranscriptionRunner: ObservableObject {
    static let shared = TranscriptionRunner()

    @Published private(set) var inFlight: Set<UUID> = []
    @Published private(set) var progress: [UUID: Double] = [:]

    private var tasks: [UUID: Task<Void, Never>] = [:]
    private var progressSubscription: AnyCancellable?

    private init() {}

    func start(recordingId: UUID) {
        guard tasks[recordingId] == nil else { return }

        let defaults = UserDefaults.standard
        let modelRaw = defaults.string(forKey: "transcription.defaultModel")
            ?? TranscriptionModel.large.rawValue
        let model = TranscriptionModel(rawValue: modelRaw) ?? .medium
        let speakers: Int = {
            let v = defaults.integer(forKey: "transcription.defaultSpeakers")
            return v == 0 ? 2 : v
        }()
        let verbatim = defaults.bool(forKey: "transcription.verbatim")
        let language = defaults.string(forKey: "transcription.language") ?? "no"

        inFlight.insert(recordingId)
        progress[recordingId] = 0

        // The service is a singleton with a single `activeProcess`; mirror
        // its published `progress` to this recording's slot while in-flight.
        progressSubscription?.cancel()
        progressSubscription = TranscriptionService.shared.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.progress[recordingId] = max(0, min(1, value))
            }

        let task = Task { @MainActor [weak self] in
            defer {
                self?.tasks[recordingId] = nil
                self?.inFlight.remove(recordingId)
                self?.progress[recordingId] = nil
                self?.progressSubscription?.cancel()
                self?.progressSubscription = nil
            }

            let audioURL = StorageLayout.audioURL(id: recordingId)

            do {
                let result = try await TranscriptionService.shared.transcribe(
                    audioFile: audioURL,
                    speakers: speakers,
                    model: model,
                    verbatim: verbatim,
                    language: language
                )
                guard !Task.isCancelled else { return }

                TranscriptionCache.shared.store(result, for: audioURL.path)
                TranscriptionService.shared.saveTranscriptJSONPublic(
                    result, recordingId: recordingId)
                ProcessingStateCache.shared.setStep(
                    .transcription, status: .completed, for: audioURL.path)

                let plainText = result.segments
                    .map { $0.text.trimmingCharacters(in: .whitespaces) }
                    .joined(separator: "\n\n")
                let transcriptURL = StorageLayout.transcriptURL(id: recordingId)
                try? plainText.write(to: transcriptURL, atomically: true, encoding: .utf8)
                _ = try? RecordingStore.shared.updateMeta(id: recordingId) { meta in
                    meta.transcript.status = .done
                    meta.transcript.completedAt = Date()
                    meta.transcript.engine = model.rawValue
                }

                AuditLogger.shared.log(.transcriptCompleted, payload: [
                    "recordingId": .string(recordingId.uuidString),
                    "engine": .string(model.rawValue),
                    "segmentCount": .int(result.segments.count),
                ])
            } catch {
                guard !Task.isCancelled else { return }
                _ = try? RecordingStore.shared.updateMeta(id: recordingId) { meta in
                    meta.transcript.status = .failed
                }
                let msg = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
                AuditLogger.shared.log(.transcriptFailed, payload: [
                    "recordingId": .string(recordingId.uuidString),
                    "error": .string(msg),
                ])
            }
        }
        tasks[recordingId] = task
    }

    func cancel(recordingId: UUID) {
        tasks[recordingId]?.cancel()
        // Swift Task cancellation doesn't propagate into the polling loop
        // inside TranscriptionService.transcribe(), so kill the subprocess
        // directly. The polling loop notices, transcribe() throws, and the
        // catch in start()'s Task body short-circuits via `Task.isCancelled`.
        TranscriptionService.shared.cancel()
        tasks[recordingId] = nil
        inFlight.remove(recordingId)
        progress[recordingId] = nil
        progressSubscription?.cancel()
        progressSubscription = nil

        // Clear any prior `.failed` marker so the row offers "Transkriber"
        // (a clean restart) instead of "Prøv igjen" (which implies the run
        // errored on its own).
        _ = try? RecordingStore.shared.updateMeta(id: recordingId) { meta in
            if meta.transcript.status == .failed {
                meta.transcript.status = .pending
            }
        }
    }
}
