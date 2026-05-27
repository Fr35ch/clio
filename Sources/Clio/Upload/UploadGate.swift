// UploadGate.swift
// Clio
//
// Evaluates preconditions for uploading an anonymized transcript to Teams.
// Returns an `UploadReadiness` value that drives `TeamsUploadSection` rendering.
//
// Gate order:
//   1. Already uploading / uploaded / failed — surface current upload state
//   2. Transcript must exist and be done
//   3. Researcher must have confirmed de-identification (researcherConfirmedAt != nil)
//
// Project assignment, compliance checklist, and Teams channel configuration
// are deferred to the Azure AD integration phase.

import Foundation

// MARK: - UploadReadiness

enum UploadReadiness {
    /// All preconditions met — ready to upload.
    case ready(remoteName: String)

    /// Transcript has not been produced yet.
    case blockedNoTranscript

    /// Transcript exists but the researcher has not yet confirmed de-identification.
    case blockedNotConfirmed

    /// Transcript has already been uploaded successfully.
    case alreadyUploaded(uploadedAt: Date, remoteName: String)

    /// A previous upload attempt failed. Retryable.
    case uploadFailed(remoteName: String)

    /// Upload is currently in progress.
    case uploading
}

// MARK: - UploadGate

struct UploadGate {

    static func evaluate(recording: RecordingMeta) -> UploadReadiness {

        // 1. Already uploading
        if recording.upload.anonymizedTranscript.status == .uploading {
            return .uploading
        }

        // 2. Already uploaded
        if recording.upload.anonymizedTranscript.status == .uploaded,
           let uploadedAt = recording.upload.anonymizedTranscript.uploadedAt {
            let remoteName = recording.upload.anonymizedTranscript.remoteName ?? ""
            return .alreadyUploaded(uploadedAt: uploadedAt, remoteName: remoteName)
        }

        // 3. Previous upload failed
        if recording.upload.anonymizedTranscript.status == .failed,
           let remoteName = recording.upload.anonymizedTranscript.remoteName {
            return .uploadFailed(remoteName: remoteName)
        }

        // 4. Transcript must exist
        guard recording.transcript.status == .done else {
            return .blockedNoTranscript
        }

        // 5. Researcher must have confirmed de-identification
        guard recording.anonymization.researcherConfirmedAt != nil else {
            return .blockedNotConfirmed
        }

        // All gates passed
        return .ready(remoteName: Self.remoteName(displayName: recording.displayName, createdAt: recording.createdAt))
    }

    /// Generates the Teams filename for an anonymized transcript.
    /// Format: `<displayName>_<YYYYMMDD>_avidentifisert.txt`
    static func remoteName(displayName: String, createdAt: Date) -> String {
        let dateString = Self.dateFormatter.string(from: createdAt)
        return "\(displayName)_\(dateString)_avidentifisert.txt"
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
