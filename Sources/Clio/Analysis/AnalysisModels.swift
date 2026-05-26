// AnalysisModels.swift
// Clio
//
// The first-class Analysis entity. An Analysis is independent of any single
// recording — it references 1..N recordings via `sources` and carries enough
// metadata (model, prompt template, transcript hashes, timestamps) to be
// reproducible and to detect when its inputs have drifted.
//
// On-disk layout (see StorageLayout.analysisFolder(id:)):
//
//   <dataRoot>/analyses/<analysisId>/
//     manifest.json    ← Analysis (this file's primary type)
//     result.json      ← AnalysisResult (existing type, LLM output)
//     prompt.txt       ← the literal prompt that was sent to the LLM

import Foundation

// MARK: - Enums

/// Whether the analysis was produced from a single transcript or by
/// synthesizing across multiple transcripts.
enum AnalysisKind: String, Codable {
    case single
    case group
}

/// Lifecycle status of an analysis. `pending` is the brief moment between
/// manifest creation and the run starting; `running` covers the LLM call;
/// terminal states are `completed` and `failed`.
enum AnalysisStatus: String, Codable {
    case pending
    case running
    case completed
    case failed
}

// MARK: - Source reference

/// One transcript that fed into an analysis. The hash is captured at run
/// time so the result view can detect drift (current transcript no longer
/// matches what the LLM saw). `displayName` is cached for UI purposes —
/// the source recording may be deleted before the analysis is read again.
struct AnalysisSource: Codable, Equatable {
    let recordingId: UUID
    let transcriptHash: String
    let displayName: String
}

// MARK: - Analysis manifest

/// The manifest written as `manifest.json` inside each analysis folder.
/// Read-modify-write through `AnalysisStore`. Unknown fields are tolerated
/// on decode (standard Codable behaviour) and `schemaVersion` lets future
/// changes migrate rather than break.
struct Analysis: Codable, Identifiable, Equatable {

    /// Bumped when backwards-incompatible changes are made to this schema.
    static let currentSchemaVersion: Int = 1

    var schemaVersion: Int
    let id: UUID
    var title: String
    let kind: AnalysisKind
    let sources: [AnalysisSource]
    /// `nil` when the researcher composed a custom prompt instead of picking
    /// a template. The prompt text itself is always persisted to `prompt.txt`
    /// regardless of whether it came from a template or was custom.
    let promptTemplateId: String?
    let model: String
    let createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var status: AnalysisStatus
    var errorMessage: String?

    // MARK: Factory

    /// Freshly-minted manifest for a new analysis. Status starts at `.pending`
    /// and is bumped to `.running` when the LLM call begins.
    static func new(
        id: UUID = UUID(),
        title: String? = nil,
        kind: AnalysisKind,
        sources: [AnalysisSource],
        promptTemplateId: String?,
        model: String,
        createdAt: Date = Date()
    ) -> Analysis {
        Analysis(
            schemaVersion: currentSchemaVersion,
            id: id,
            title: title ?? Analysis.defaultTitle(for: createdAt, kind: kind, sourceCount: sources.count),
            kind: kind,
            sources: sources,
            promptTemplateId: promptTemplateId,
            model: model,
            createdAt: createdAt,
            startedAt: nil,
            completedAt: nil,
            status: .pending,
            errorMessage: nil
        )
    }

    static func defaultTitle(for date: Date, kind: AnalysisKind, sourceCount: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let stamp = formatter.string(from: date)
        switch kind {
        case .single:
            return "Analyse \(stamp)"
        case .group:
            return "Gruppeanalyse (\(sourceCount) intervjuer) \(stamp)"
        }
    }

    // MARK: Codable (explicit for forward-compat tolerance)

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case id
        case title
        case kind
        case sources
        case promptTemplateId
        case model
        case createdAt
        case startedAt
        case completedAt
        case status
        case errorMessage
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title)
            ?? Analysis.defaultTitle(for: Date(), kind: .single, sourceCount: 0)
        kind = try c.decodeIfPresent(AnalysisKind.self, forKey: .kind) ?? .single
        sources = try c.decodeIfPresent([AnalysisSource].self, forKey: .sources) ?? []
        promptTemplateId = try c.decodeIfPresent(String.self, forKey: .promptTemplateId)
        model = try c.decodeIfPresent(String.self, forKey: .model) ?? "unknown"
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        startedAt = try c.decodeIfPresent(Date.self, forKey: .startedAt)
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        status = try c.decodeIfPresent(AnalysisStatus.self, forKey: .status) ?? .pending
        errorMessage = try c.decodeIfPresent(String.self, forKey: .errorMessage)
    }

    init(
        schemaVersion: Int,
        id: UUID,
        title: String,
        kind: AnalysisKind,
        sources: [AnalysisSource],
        promptTemplateId: String?,
        model: String,
        createdAt: Date,
        startedAt: Date?,
        completedAt: Date?,
        status: AnalysisStatus,
        errorMessage: String?
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.title = title
        self.kind = kind
        self.sources = sources
        self.promptTemplateId = promptTemplateId
        self.model = model
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.status = status
        self.errorMessage = errorMessage
    }
}
