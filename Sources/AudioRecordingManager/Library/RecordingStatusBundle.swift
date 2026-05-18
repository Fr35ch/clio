// RecordingStatusBundle.swift
// AudioRecordingManager
//
// Pure-value derivation of every status chip and filter predicate the
// Bibliotek table needs (US-R13–R18). One place to change the
// definitions; the view layer reads `bundle.transcript`, `.avident`,
// `.analyse`, `.teams`, `.slettes` and renders chips from them.
//
// Built from `RecordingMeta` plus the subset of `Analysis` manifests
// that reference this recording's id. Pure function — easy to test
// without spinning up the storage layer.

import Foundation

// MARK: - Chip tones (mapped to colour in the view layer)

/// Five tones the Bibliotek table uses for status chips. Mapping to
/// concrete colours lives in `BibliotekView` so the design tokens stay
/// in one place.
enum ChipTone: String {
    case neutral   // — / Ikke avid. / Ikke transkribert (grey)
    case info      // Klar (blue/accent)
    case success   // Ferdig / Avid. ✓ (green)
    case warning   // Venter / Påbegynt / 4–7 days left (yellow/orange)
    case danger    // Feilet / ≤3 days left (red)
}

/// One status chip — label plus tone. The view layer renders this.
struct StatusChip: Equatable {
    let label: String
    let tone: ChipTone
}

// MARK: - Bundle

/// Everything the Bibliotek table needs about one recording in one
/// place. Build via `RecordingStatusBundle.make(meta:analyses:now:)`.
///
/// `analyses` should be pre-filtered to *only* the analyses that
/// reference this recording's id (`AnalysisSource.recordingId == meta.id`).
/// The caller is responsible for that filter so the bundle factory stays
/// O(1) per recording.
struct RecordingStatusBundle: Identifiable, Equatable {
    let id: UUID
    let displayName: String
    let createdAt: Date
    let durationSeconds: Double?

    // Display chips
    let transcript: StatusChip
    let avident: StatusChip
    let analyse: StatusChip
    let teams: StatusChip
    let slettes: StatusChip

    // Filter predicates — true if this recording matches that filter chip
    let isTranscribed: Bool
    let venterAvident: Bool
    let klarForTeams: Bool
    let utløperSnart: Bool

    // Numeric handles used by sort and banner
    let daysUntilExpiry: Int
}

extension RecordingStatusBundle {

    /// Days from now until the recording's 30-day auto-deletion window
    /// closes. Negative means already past the threshold (expiry manager
    /// should have removed it; treat as 0 for display).
    static let autoDeleteWindowDays: Int = 30
    static let utløperSnartThresholdDays: Int = 5
    static let bannerThresholdDays: Int = 3
    static let bannerYellowThresholdDays: Int = 7

    /// Build the bundle from raw inputs. Pure; no side effects.
    static func make(
        meta: RecordingMeta,
        analyses: [Analysis],
        now: Date = Date(),
        projectConfigured: Bool
    ) -> RecordingStatusBundle {
        let days = daysUntilExpiry(createdAt: meta.createdAt, now: now)

        // Predicates
        let isTranscribed = meta.transcript.status == .done
        let venterAvident = (meta.transcript.status == .done)
            && (meta.anonymization.status == .none)
        let klarForTeams = predicateKlarForTeams(
            meta: meta,
            projectConfigured: projectConfigured
        )
        let utløperSnart = days <= utløperSnartThresholdDays

        return RecordingStatusBundle(
            id: meta.id,
            displayName: meta.displayName,
            createdAt: meta.createdAt,
            durationSeconds: meta.durationSeconds,
            transcript: transcriptChip(meta.transcript.status),
            avident: avidentChip(meta.anonymization.status),
            analyse: analyseChip(analyses),
            teams: teamsChip(klarForTeams: klarForTeams),
            slettes: slettesChip(daysRemaining: days),
            isTranscribed: isTranscribed,
            venterAvident: venterAvident,
            klarForTeams: klarForTeams,
            utløperSnart: utløperSnart,
            daysUntilExpiry: max(0, days)
        )
    }

    // MARK: - Predicate helpers (single place to change definitions)

    /// US-R14 "Klar for Teams" predicate — TBD per the user story. v1
    /// definition: transcript done + avident done + neutralCode set
    /// + project configured. Refine here without touching anything else.
    static func predicateKlarForTeams(
        meta: RecordingMeta,
        projectConfigured: Bool
    ) -> Bool {
        guard meta.transcript.status == .done else { return false }
        guard meta.anonymization.status == .done else { return false }
        guard let code = meta.neutralCode, !code.isEmpty else { return false }
        guard projectConfigured else { return false }
        return true
    }

    private static func daysUntilExpiry(createdAt: Date, now: Date) -> Int {
        let deadline = createdAt.addingTimeInterval(
            Double(autoDeleteWindowDays) * 24 * 60 * 60
        )
        let interval = deadline.timeIntervalSince(now)
        return Int(ceil(interval / (24 * 60 * 60)))
    }

    // MARK: - Chip builders

    private static func transcriptChip(_ status: ArtifactStatus) -> StatusChip {
        switch status {
        case .done:
            return StatusChip(label: "Ferdig", tone: .success)
        case .processing:
            return StatusChip(label: "Venter", tone: .warning)
        case .failed:
            return StatusChip(label: "Feilet", tone: .danger)
        case .pending, .missing:
            return StatusChip(label: "Ikke transkr.", tone: .neutral)
        }
    }

    private static func avidentChip(_ status: AnonymizationStatus) -> StatusChip {
        switch status {
        case .done:
            return StatusChip(label: "Avid. ✓", tone: .success)
        case .draft:
            return StatusChip(label: "Påbegynt", tone: .warning)
        case .failed:
            return StatusChip(label: "Feilet", tone: .danger)
        case .none:
            return StatusChip(label: "Ikke avid.", tone: .neutral)
        }
    }

    private static func analyseChip(_ analyses: [Analysis]) -> StatusChip {
        if analyses.contains(where: { $0.status == .completed }) {
            return StatusChip(label: "Ferdig", tone: .success)
        }
        if analyses.contains(where: { $0.status == .running || $0.status == .pending }) {
            return StatusChip(label: "Venter", tone: .warning)
        }
        if analyses.contains(where: { $0.status == .failed }) {
            return StatusChip(label: "Feilet", tone: .danger)
        }
        return StatusChip(label: "—", tone: .neutral)
    }

    /// TEAMS column shows only readiness (Klar / låst). No "Teams ✓"
    /// state because we can't reliably track actual uploads — researchers
    /// upload manually via Finder / the Teams app outside ARM (see
    /// USER_STORIES.md US-R14 + US-R17 notes 2026-05-11).
    private static func teamsChip(klarForTeams: Bool) -> StatusChip {
        if klarForTeams {
            return StatusChip(label: "Klar", tone: .info)
        }
        return StatusChip(label: "låst", tone: .neutral)
    }

    private static func slettesChip(daysRemaining: Int) -> StatusChip {
        let clamped = max(0, daysRemaining)
        if clamped <= bannerThresholdDays {
            return StatusChip(label: "\(clamped) d", tone: .danger)
        }
        if clamped <= bannerYellowThresholdDays {
            return StatusChip(label: "\(clamped) d", tone: .warning)
        }
        return StatusChip(label: "\(clamped) d", tone: .neutral)
    }
}

// MARK: - Filter / sort

/// Single source of truth for filter chip identity, label, and predicate.
/// Add a new filter by adding a case + extending `matches(_:)`.
enum BibliotekFilter: String, CaseIterable, Identifiable {
    case alle
    case ikkeTranskribert
    case utløperSnart

    var id: String { rawValue }

    var label: String {
        switch self {
        case .alle:              return "Alle"
        case .ikkeTranskribert:  return "Ikke transkribert"
        case .utløperSnart:      return "Utløper snart"
        }
    }

    /// Tone the filter chip uses when active. Inactive chips use neutral
    /// regardless of this value.
    var tone: ChipTone {
        switch self {
        case .alle:              return .info
        case .ikkeTranskribert:  return .neutral
        case .utløperSnart:      return .danger
        }
    }

    func matches(_ bundle: RecordingStatusBundle) -> Bool {
        switch self {
        case .alle:              return true
        case .ikkeTranskribert:  return !bundle.isTranscribed
        case .utløperSnart:      return bundle.utløperSnart
        }
    }
}
