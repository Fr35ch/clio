// TeamsUploadService.swift
// AudioRecordingManager
//
// Manages the upload of anonymized transcripts to Teams/SharePoint via the
// Microsoft Graph API.
//
// ⚠️  STUB: The Graph API call is not implemented — Azure AD app registration
//     with NAV IT is pending. The stub immediately marks the upload as
//     successful so the full UI flow is testable end-to-end.
//     Replace `performGraphUpload(...)` with the real implementation when
//     credentials are available. See FILE_MANAGEMENT_AND_TEAMS_SYNC.md §Egress.
//
// Responsibilities:
//   - Read anonymized transcript from RecordingStore
//   - Update sidecar upload state via RecordingStore.updateMeta()
//   - Emit audit events: uploadQueued, uploadCompleted, uploadFailed

import Foundation
import Combine

@MainActor
final class TeamsUploadService: ObservableObject {

    static let shared = TeamsUploadService()

    private init() {}

    // MARK: - Upload

    /// Starts upload of the anonymized transcript for `recording` to `project`'s study channel.
    /// Updates the recording's sidecar and emits audit events.
    ///
    /// - Parameters:
    ///   - recording: the recording whose anonymized transcript to upload
    ///   - project: the destination project (must have a configured study channel)
    ///   - remoteName: filename to use on Teams (from `UploadGate.remoteName(...)`)
    func upload(recording: RecordingMeta, project: ProjectConfig, remoteName: String) async {
        guard let studyChannel = project.studyChannel else {
            // Should not happen — UploadGate checks isConfigured before calling.
            return
        }

        let recordingId = recording.id

        // Mark as uploading
        updateSidecar(recordingId: recordingId) { $0.upload.anonymizedTranscript.status = .uploading }
        AuditLogger.shared.logUploadQueued(
            recordingId: recordingId,
            projectId: project.id,
            remoteName: remoteName
        )

        do {
            let fileURL = anonymizedTranscriptURL(recording: recording)
            try await performGraphUpload(
                fileURL: fileURL,
                remoteName: remoteName,
                channel: studyChannel
            )

            updateSidecar(recordingId: recordingId) { meta in
                meta.upload.anonymizedTranscript.status = .uploaded
                meta.upload.anonymizedTranscript.uploadedAt = Date()
                meta.upload.anonymizedTranscript.remoteName = remoteName
            }
            AuditLogger.shared.logUploadCompleted(
                recordingId: recordingId,
                projectId: project.id,
                remoteName: remoteName
            )

        } catch {
            updateSidecar(recordingId: recordingId) { meta in
                meta.upload.anonymizedTranscript.status = .failed
                meta.upload.anonymizedTranscript.remoteName = remoteName
            }
            AuditLogger.shared.logUploadFailed(
                recordingId: recordingId,
                projectId: project.id,
                reason: error.localizedDescription
            )
        }
    }

    // MARK: - Graph API (STUB)

    /// ⚠️  STUB: Simulates a successful Graph API upload with a short delay.
    ///
    /// Real implementation will:
    ///  - Authenticate via OAuth 2.0 / PKCE against Entra ID
    ///  - For files < 4 MB: PUT /sites/{site-id}/drive/items/{parent}:/{filename}:/content
    ///  - For files ≥ 4 MB: createUploadSession + chunked PUT (10 MB chunks)
    ///    with session URL persisted in sidecar for resumable uploads
    private func performGraphUpload(
        fileURL: URL,
        remoteName: String,
        channel: TeamsChannelRef
    ) async throws {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 800_000_000)
        // TODO: Replace with real Graph API implementation when Entra ID app
        // registration (NAV IT) is approved. Scopes needed:
        //   Files.ReadWrite, Sites.ReadWrite.All, User.Read
    }

    // MARK: - Helpers

    private func anonymizedTranscriptURL(recording: RecordingMeta) -> URL {
        StorageLayout.recordingFolder(id: recording.id)
            .appendingPathComponent(recording.anonymization.filename ?? "transcript_anonymized.txt")
    }

    private func updateSidecar(recordingId: UUID, transform: @escaping (inout RecordingMeta) -> Void) {
        do {
            try RecordingStore.shared.updateMeta(id: recordingId, transform: transform)
        } catch {
            print("⚠️ TeamsUploadService: could not update sidecar for \(recordingId): \(error)")
        }
    }
}
