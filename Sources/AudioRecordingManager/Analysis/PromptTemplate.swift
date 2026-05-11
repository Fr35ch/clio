// PromptTemplate.swift
// AudioRecordingManager
//
// In-app prompt templates that drive ARM's analysis subprocess. Templates
// are versioned, language-tagged, and applicable to single or group
// analyses (or both). The composer surfaces the relevant subset to the
// researcher based on how many transcripts they have selected.
//
// Spec: docs/prd/analysis/PROMPT_RESEARCH.md
// Template markdown source-of-truth: docs/prd/analysis/templates/*.md
//
// Bundled templates are defined as Swift statics in
// `PromptTemplateLibrary.swift`. User-defined templates live on disk
// under `<dataRoot>/analyses/_templates/<id>.json` and are decoded by the
// same library.
//
// Template rendering is a tiny Mustache-lite implementation in
// `render(context:)` — supports `{{name}}` substitutions and
// `{{#section}}...{{/section}}` conditional blocks. Not a full Mustache
// implementation; just what the ARM templates need.

import Foundation

// MARK: - Applicability

/// Which analysis kinds a template makes sense for. The composer groups
/// templates by applicability based on the current transcript selection,
/// so a researcher with one transcript only sees `single` and `both`
/// templates in the dropdown.
enum TemplateApplicability: String, Codable {
    case single
    case group
    case both

    func includes(_ kind: AnalysisKind) -> Bool {
        switch self {
        case .single: return kind == .single
        case .group:  return kind == .group
        case .both:   return true
        }
    }
}

// MARK: - PromptTemplate

/// A named, versioned prompt template. The `body` is a Mustache-lite
/// template string with `{{placeholders}}` and optional
/// `{{#section}}...{{/section}}` conditional blocks. Substitutions are
/// applied in `render(context:)`; the result is what gets handed to
/// `TranscriptionService.analyze(...)` (or, in the group case, to the
/// concatenated-input path described in B7).
struct PromptTemplate: Codable, Identifiable, Equatable {

    /// Stable identifier, e.g. `"single-interview-themes-v1"`. This is
    /// what `Analysis.promptTemplateId` stores so the result view can
    /// look up the originating template.
    let id: String

    /// Human-readable label shown in the composer dropdown.
    let displayName: String

    /// One-sentence description for the composer dropdown's secondary text.
    let summary: String

    /// Which analysis kinds this template applies to.
    let appliesTo: TemplateApplicability

    /// BCP-47 language tag. Currently always `"no"`; reserved for future
    /// English-language templates if NAV ever runs English interviews.
    let language: String

    /// Body of the prompt with Mustache-lite placeholders. See top-of-file
    /// for the supported syntax.
    let body: String

    /// Bumped when the template's body changes. Existing analyses keep
    /// the version they were run with so re-running an old analysis
    /// against an updated template is an explicit user choice.
    let version: Int

    /// `true` for the four ARM-bundled templates, `false` for templates
    /// the researcher has created or edited. The composer uses this to
    /// label and to gate edit affordances (bundled templates are
    /// read-only; editing forks to a user template).
    let isBundled: Bool
}

// MARK: - Render context

/// Inputs to the template renderer. The composer assembles this from the
/// researcher's choices and the selected transcripts.
struct PromptRenderContext {
    /// What the researcher typed in the "Forskningskontekst" field of the
    /// composer, or a sensible default if they left it blank.
    let researchContext: String

    /// Resulting analysis kind, derived from the source count.
    let kind: AnalysisKind

    /// For `.single`: the one transcript's body.
    /// For `.group`: empty — see `concatenatedTranscripts` instead.
    let transcript: String

    /// For `.group`: all transcripts concatenated with `### Intervju N — <displayName>` headers (B7a synthesis path).
    /// For `.single`: empty.
    let concatenatedTranscripts: String

    /// Total source count. Surfaced to the model as
    /// `{{interviewCount}}` in group templates.
    let interviewCount: Int

    fileprivate var sectionFlags: [String: Bool] {
        switch kind {
        case .single: return ["single": true, "group": false]
        case .group:  return ["single": false, "group": true]
        }
    }

    fileprivate var values: [String: String] {
        [
            "researchContext": researchContext.isEmpty
                ? "Ingen forskningskontekst oppgitt. Analyser materialet på sine egne premisser."
                : researchContext,
            "transcript": transcript,
            "transcripts": concatenatedTranscripts,
            "interviewCount": String(interviewCount),
        ]
    }
}

// MARK: - Rendering

extension PromptTemplate {

    /// Substitute placeholders and resolve conditional sections in `body`.
    /// Always returns a string; unknown placeholders are dropped silently
    /// (the self-check inside the prompt itself is the second safety net).
    func render(context: PromptRenderContext) -> String {
        var out = body
        out = resolveSections(out, flags: context.sectionFlags)
        out = substituteVariables(out, values: context.values)
        return out
    }

    /// Mustache-lite conditional sections.
    ///
    /// `{{#section}}...{{/section}}` blocks are kept verbatim if
    /// `flags[section] == true`, otherwise the entire block is removed.
    /// Nested sections are not supported — none of the ARM templates
    /// need them and supporting them complicates the implementation
    /// disproportionately.
    private func resolveSections(_ text: String, flags: [String: Bool]) -> String {
        var out = text
        for (name, isActive) in flags {
            let opener = "{{#\(name)}}"
            let closer = "{{/\(name)}}"
            while let openRange = out.range(of: opener),
                  let closeRange = out.range(of: closer, range: openRange.upperBound..<out.endIndex)
            {
                let inner = out[openRange.upperBound..<closeRange.lowerBound]
                let replacement = isActive ? String(inner) : ""
                out.replaceSubrange(openRange.lowerBound..<closeRange.upperBound, with: replacement)
            }
        }
        return out
    }

    /// Substitute `{{name}}` placeholders with their values. Unknown
    /// placeholders are replaced with the empty string rather than left
    /// in place — leaving a literal `{{foo}}` in the LLM input would be
    /// distracting noise for the model.
    private func substituteVariables(_ text: String, values: [String: String]) -> String {
        var out = text
        // Match every {{name}} that doesn't contain a section marker
        // (those have already been processed above). Looking for the
        // simple variable form keeps this regex-free.
        var searchStart = out.startIndex
        while let openRange = out.range(of: "{{", range: searchStart..<out.endIndex) {
            guard let closeRange = out.range(of: "}}", range: openRange.upperBound..<out.endIndex) else {
                break
            }
            let nameRange = openRange.upperBound..<closeRange.lowerBound
            let name = String(out[nameRange]).trimmingCharacters(in: .whitespaces)
            // Skip section markers (defensive — should have been removed).
            if name.hasPrefix("#") || name.hasPrefix("/") {
                searchStart = closeRange.upperBound
                continue
            }
            let value = values[name] ?? ""
            out.replaceSubrange(openRange.lowerBound..<closeRange.upperBound, with: value)
            searchStart = out.index(openRange.lowerBound, offsetBy: value.count)
            if searchStart > out.endIndex { break }
        }
        return out
    }
}

// MARK: - Group transcript concatenation helper

/// Builds the `### Intervju N — <displayName>` header layout that group
/// templates expect. Used by the composer to assemble
/// `PromptRenderContext.concatenatedTranscripts` for a group run.
enum GroupTranscriptAssembly {

    /// Each element is `(displayName, transcriptText)` for one source,
    /// in the order the researcher selected.
    static func concatenate(_ sources: [(displayName: String, text: String)]) -> String {
        var parts: [String] = []
        for (index, source) in sources.enumerated() {
            let header = "### Intervju \(index + 1) — \(source.displayName)"
            parts.append(header)
            parts.append("")
            parts.append(source.text.trimmingCharacters(in: .whitespacesAndNewlines))
            parts.append("")
        }
        return parts.joined(separator: "\n")
    }
}
