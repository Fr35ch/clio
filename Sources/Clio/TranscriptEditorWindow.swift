import Foundation
import SwiftUI

struct TranscriptEditorWindow: View {
    let recordingId: UUID

    @State private var loadState: LoadState = .loading

    private enum LoadState {
        case loading
        case ready(TranscriptionResult, URL, String)
        case missingJSON(String)
        case missingAudio(String)
    }

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                ProgressView("Laster transkripsjon …")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case let .ready(result, audioURL, displayName):
                TranscriptEditorView(
                    recordingId: recordingId,
                    audioURL: audioURL,
                    transcriptionResult: result
                )
                .navigationTitle(displayName)

            case let .missingJSON(displayName):
                fallback(
                    title: "Transkripsjon ikke funnet",
                    message: "Ingen transkripsjon funnet for dette opptaket. Kjør transkripsjon på nytt for å bruke editoren.",
                    displayName: displayName
                )

            case let .missingAudio(displayName):
                fallback(
                    title: "Lydfil mangler",
                    message: "Lydopptaket finnes ikke lenger på disken. Editoren kan ikke åpnes.",
                    displayName: displayName
                )
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .onAppear(perform: load)
    }

    private func fallback(title: String, message: String, displayName: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
        .navigationTitle(displayName)
    }

    private func load() {
        let audioURL = StorageLayout.audioURL(id: recordingId)
        let displayName: String = {
            if let meta = try? RecordingStore.shared.load(id: recordingId) {
                return meta.displayName
            }
            return recordingId.uuidString
        }()

        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            loadState = .missingAudio(displayName)
            return
        }

        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        // TODO(ADR-1014 Phase 0D): This path is legacy — pre-Phase-0 layout.
        // Should be StorageLayout.transcriptURL(id: recordingId) once D2 is complete.
        let jsonURL = support.appendingPathComponent(
            "AudioRecordingManager/transcripts/\(recordingId.uuidString).json"
        )

        guard let data = try? Data(contentsOf: jsonURL) else {
            loadState = .missingJSON(displayName)
            return
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let result = try? decoder.decode(TranscriptionResult.self, from: data) else {
            loadState = .missingJSON(displayName)
            return
        }

        loadState = .ready(result, audioURL, displayName)
    }
}
