// UploadGate.swift
// Clio
//
// Evaluates all preconditions for uploading an anonymized transcript to Teams.
// Returns a `UploadReadiness` value that drives `TeamsUploadSection` rendering.
//
// Precondition chain (in order of priority):
//   1. Transcript exists and is done
//   2. Researcher has signed off that the transcript is de-identified
//      (researcherConfirmedAt != nil — independent of ARM tool status)
//   3. Neutral code is set on the recording
//   4. Recording is assigned to a project (projectId set)
//   5. That project has a Teams study channel configured
//   6. That project has the compliance checklist confirmed

import Foundation

// MARK: - UploadReadiness

enum UploadReadiness {
    /// All preconditions met — ready to show confirmation sheet and upload.
    case ready(project: ProjectConfig, remoteName: String)

    /// Transcript has not been produced yet.
    case blockedNoTranscript

    /// Transcript exists but the researcher has not yet signed off that it
    /// is de-identified. `armToolRan` is true if the ARM anonymization tool
    /// completed — used by the UI to tailor its message (informational only).
    case blockedNotConfirmed(armToolRan: Bool)

    /// Neutral participant code has not been set on this recording.
    case blockedNoNeutralCode

    /// Recording is not assigned to any project.
    /// Includes all configured projects so the UI can offer a picker.
    case blockedNoProjectAssigned(availableProjects: [ProjectConfig])

    /// Recording references a project ID that no longer exists (edge case).
    case blockedProjectNotFound

    /// The assigned project exists but doesn't have a Teams channel configured.
    case blockedNoProjectConfig(project: ProjectConfig)

    /// The assigned project is configured but the compliance checklist
    /// has not been confirmed for it yet.
    case blockedComplianceNotConfirmed(project: ProjectConfig)

    /// Transcript has already been uploaded successfully.
    case alreadyUploaded(uploadedAt: Date, remoteName: String)

    /// A previous upload attempt failed. Retryable.
    case uploadFailed(project: ProjectConfig, remoteName: String)

    /// Upload is currently in progress.
    case uploading
}

// MARK: - UploadGate

struct UploadGate {

    /// Evaluates all preconditions for `recording` against the provided project list.
    static func evaluate(recording: RecordingMeta, projects: [ProjectConfig]) -> UploadReadiness {

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

        // 3. Previous upload failed — surface as retryable
        if recording.upload.anonymizedTranscript.status == .failed {
            if let project = projects.first(where: { $0.id == recording.projectId }),
               let remoteName = recording.upload.anonymizedTranscript.remoteName {
                return .uploadFailed(project: project, remoteName: remoteName)
            }
        }

        // 4. Transcript must exist
        guard recording.transcript.status == .done else {
            return .blockedNoTranscript
        }

        // 5. Researcher must have explicitly signed off on de-identification
        guard recording.anonymization.researcherConfirmedAt != nil else {
            let armToolRan = recording.anonymization.status == .done
            return .blockedNotConfirmed(armToolRan: armToolRan)
        }

        // 6. Neutral code required
        guard let neutralCode = recording.neutralCode, !neutralCode.isEmpty else {
            return .blockedNoNeutralCode
        }

        // 7. Must be assigned to a project
        guard let projectId = recording.projectId else {
            let configured = projects.filter { $0.isConfigured }
            return .blockedNoProjectAssigned(availableProjects: configured)
        }

        // 8. Referenced project must exist
        guard let project = projects.first(where: { $0.id == projectId }) else {
            return .blockedProjectNotFound
        }

        // 9. Project must have a study channel configured
        guard project.isConfigured else {
            return .blockedNoProjectConfig(project: project)
        }

        // 10. Compliance checklist must be confirmed
        guard project.isComplianceConfirmed else {
            return .blockedComplianceNotConfirmed(project: project)
        }

        // All gates passed
        let remoteName = Self.remoteName(neutralCode: neutralCode, createdAt: recording.createdAt)
        return .ready(project: project, remoteName: remoteName)
    }

    /// Generates the Teams filename for an anonymized transcript.
    /// Format: `<neutralCode>_<YYYYMMDD>_transcript_anonymized.txt`
    /// Never includes personal data or the local UUID.
    static func remoteName(neutralCode: String, createdAt: Date) -> String {
        let dateString = Self.dateFormatter.string(from: createdAt)
        return "\(neutralCode)_\(dateString)_transcript_anonymized.txt"
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
