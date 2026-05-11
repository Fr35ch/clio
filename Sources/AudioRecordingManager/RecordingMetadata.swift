import Foundation

// MARK: - Anonymization Result (mirrors no-anonymizer Python model)
//
// Terminology note: the UI surfaces this as "avidentifisering"
// (de-identification). The legal distinction matters — true GDPR
// anonymisation would mean the data is no longer personal data and
// cannot be re-linked. We retain the audio and a deterministic mapping
// internally, so what we ship is de-identification. Swift type names
// stay as `Anonymization*` for back-compat with audit logs and
// existing call sites; only the UI strings flip to "avidentifisering".

struct Redaction: Codable, Equatable {
    let position: Int
    let length: Int
    let category: String
    let replacement: String
}

struct AnonymizationResult: Codable, Equatable {
    let anonymizedText: String
    let redactions: [Redaction]
    let stats: [String: Int]
    let processingTimeMs: Double
}

extension AnonymizationResult {
    /// Apply a global exception list to a freshly-returned anonymization
    /// result. Any redaction whose original substring (looked up in
    /// `sourceText` via `position`/`length`) matches an exception is
    /// dropped and the corresponding span is restored in
    /// `anonymizedText`. Matching is case-insensitive equality on the
    /// full redacted span — the upstream NER returns discrete spans, so
    /// equality is appropriate and word-boundary checks are unnecessary.
    ///
    /// Stats are recomputed from the surviving redaction set so the UI
    /// reflects what was actually redacted, not what the model proposed.
    ///
    /// Returns a fresh `AnonymizationResult`; the input is unchanged.
    func applying(exceptions: [String], to sourceText: String) -> AnonymizationResult {
        guard !exceptions.isEmpty, !redactions.isEmpty else { return self }

        let normalisedExceptions = Set(exceptions.map { $0.lowercased() })

        // Reconstruct the de-identified text by walking the source and
        // applying only the surviving redactions in order.
        let sourceChars = Array(sourceText)
        var survivors: [Redaction] = []
        for redaction in redactions.sorted(by: { $0.position < $1.position }) {
            let start = max(0, redaction.position)
            let end = min(sourceChars.count, redaction.position + redaction.length)
            guard start < end else {
                // Defensive: out-of-range redaction. Keep it; trust upstream.
                survivors.append(redaction)
                continue
            }
            let original = String(sourceChars[start..<end])
            if normalisedExceptions.contains(original.lowercased()) {
                // Dropped — the original span stays intact in the output.
                continue
            }
            survivors.append(redaction)
        }

        // Rebuild the output text from `sourceText` with `survivors`
        // applied. This is more robust than trying to mutate
        // `anonymizedText` (whose offsets shift when redactions are
        // dropped).
        var out = ""
        var cursor = 0
        for redaction in survivors {
            let start = max(0, redaction.position)
            let end = min(sourceChars.count, redaction.position + redaction.length)
            if cursor < start {
                out.append(contentsOf: sourceChars[cursor..<start])
            }
            out.append(redaction.replacement)
            cursor = end
        }
        if cursor < sourceChars.count {
            out.append(contentsOf: sourceChars[cursor..<sourceChars.count])
        }

        var newStats: [String: Int] = [:]
        for redaction in survivors {
            newStats[redaction.category, default: 0] += 1
        }

        return AnonymizationResult(
            anonymizedText: out,
            redactions: survivors,
            stats: newStats,
            processingTimeMs: processingTimeMs
        )
    }
}

// MARK: - Recording Metadata (persisted alongside .m4a as .metadata.json)

struct RecordingMetadata: Codable {
    /// Stable identifier derived from the recording filename (without extension).
    let recordingId: String

    /// Original transcript — immutable after first write.
    /// Only RecordingMetadataManager.setOriginalTranscript() may populate this field,
    /// and it refuses to overwrite a non-nil value.
    var originalTranscript: String?

    /// Anonymized version — nil until user triggers anonymization.
    var anonymizedTranscript: String?

    /// When anonymization last completed successfully.
    var anonymizationDate: Date?

    /// Redaction counts per category from the last successful run.
    var anonymizationStats: [String: Int]?
}
