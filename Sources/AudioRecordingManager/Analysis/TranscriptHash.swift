// TranscriptHash.swift
// AudioRecordingManager
//
// SHA-256 fingerprint of a transcript's textual content, used to detect when
// an analysis's source transcript has drifted since the run was performed.
//
// We hash the on-disk `transcript.txt` file — not the JSON form — because
// formatting/diarization metadata changes shouldn't invalidate a prior
// analysis. The bytes are normalized first (trim whitespace, collapse
// repeated newlines) so trivial whitespace edits don't produce false drift.

import CryptoKit
import Foundation

enum TranscriptHash {

    /// Returns a hex-encoded SHA-256 hash of the normalized transcript bytes,
    /// or `nil` if the file is missing or unreadable.
    static func hash(of transcriptURL: URL) -> String? {
        guard let raw = try? String(contentsOf: transcriptURL, encoding: .utf8) else {
            return nil
        }
        return hash(text: raw)
    }

    /// Hash a transcript string directly. Exposed so callers can hash the
    /// in-memory text before writing it to disk if they need to.
    static func hash(text: String) -> String {
        let normalized = normalize(text)
        let digest = SHA256.hash(data: Data(normalized.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Normalization

    /// Trim leading/trailing whitespace and collapse runs of 3+ newlines down
    /// to a double newline. This is conservative — researcher edits that
    /// change *content* always flip the hash; trivial reformatting does not.
    private static func normalize(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        var result: [String] = []
        var blankRun = 0
        for line in lines {
            if line.isEmpty {
                blankRun += 1
                if blankRun <= 1 { result.append(line) }
            } else {
                blankRun = 0
                result.append(line)
            }
        }
        return result.joined(separator: "\n")
    }
}
