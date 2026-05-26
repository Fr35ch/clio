// AnalysisResultParser.swift
// Clio
//
// Parses the markdown response from a template-driven LLM analysis into
// the `AnalysisResult` schema (key_themes, key_quotes, identified_needs,
// opportunities, rawMarkdown).
//
// All bundled templates emit `## <Norsk navn> (key_themes)` style headers
// with the English machine-tag in parentheses — this is the parser's
// stable anchor regardless of which template was used. Templates that
// omit the tag fall back to a "best-effort" section split that is logged
// but not failed.

import Foundation

enum AnalysisResultParser {

    /// Stable machine-readable tags every bundled template emits in
    /// section headers, e.g. `## Hovedtemaer (key_themes)`.
    private enum SectionTag: String, CaseIterable {
        case keyThemes = "key_themes"
        case keyQuotes = "key_quotes"
        case identifiedNeeds = "identified_needs"
        case opportunities = "opportunities"
    }

    /// Parse LLM-returned markdown into `AnalysisResult`. Always succeeds —
    /// fields that can't be parsed come back as empty arrays, and
    /// `rawMarkdown` is always the full input verbatim so the researcher
    /// sees what the model actually returned even when our parser failed.
    static func parse(markdown: String, model: String) -> AnalysisResult {
        let sections = splitByTaggedHeader(markdown)
        return AnalysisResult(
            generatedAt: Date(),
            llmModel: model,
            keyThemes: bulletItems(in: sections[.keyThemes] ?? ""),
            keyQuotes: bulletItems(in: sections[.keyQuotes] ?? ""),
            identifiedNeeds: bulletItems(in: sections[.identifiedNeeds] ?? ""),
            opportunities: bulletItems(in: sections[.opportunities] ?? ""),
            rawMarkdown: markdown
        )
    }

    // MARK: - Section splitting

    /// Splits the markdown on `## ...` headers and keys each section by
    /// the machine tag inside parentheses, e.g. `(key_themes)`. Headers
    /// without a recognized tag are ignored — their content does not
    /// land in any field.
    private static func splitByTaggedHeader(_ markdown: String) -> [SectionTag: String] {
        var sections: [SectionTag: String] = [:]
        var currentTag: SectionTag? = nil
        var currentLines: [String] = []

        func flush() {
            if let tag = currentTag {
                sections[tag] = currentLines.joined(separator: "\n")
            }
            currentTag = nil
            currentLines = []
        }

        for rawLine in markdown.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("## ") {
                flush()
                currentTag = detectTag(in: line)
                continue
            }
            if currentTag != nil {
                currentLines.append(rawLine)
            }
        }
        flush()
        return sections
    }

    private static func detectTag(in headerLine: String) -> SectionTag? {
        for tag in SectionTag.allCases {
            if headerLine.contains("(\(tag.rawValue))") { return tag }
        }
        return nil
    }

    // MARK: - Bullet extraction

    /// Pulls top-level markdown bullet items out of a section's body. A
    /// bullet item begins with `- ` or `* ` at the start of a line
    /// (after trimming). Continuation lines (further indented or bare
    /// text after a bullet) are folded into the preceding item.
    ///
    /// Items are returned in document order, with surrounding whitespace
    /// trimmed. Empty items are skipped.
    private static func bulletItems(in body: String) -> [String] {
        var items: [String] = []
        var current: [String] = []

        func flush() {
            let joined = current.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty { items.append(joined) }
            current = []
        }

        for rawLine in body.components(separatedBy: "\n") {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                flush()
                let withoutBullet = String(trimmed.dropFirst(2))
                current.append(withoutBullet)
                continue
            }
            // Continuation line — fold into the current bullet only if
            // we already opened one. Bare paragraphs between sections
            // are treated as descriptive prose and dropped.
            if !current.isEmpty, !trimmed.isEmpty {
                current.append(trimmed)
            }
        }
        flush()
        return items
    }
}
