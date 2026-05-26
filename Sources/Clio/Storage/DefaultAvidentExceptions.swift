// DefaultAvidentExceptions.swift
// Clio
//
// Curated default seed list for `AppState.avidentExceptions`.
//
// Background: the upstream `no-anonymizer` library (currently v0.5.0
// NbAiLab BERT NER) over-redacts on Norwegian homographs and short
// common words. The stress-test transcript in
// `tests/fixtures/anonymizer_stress_test.md` documents the typical
// failure modes against a realistic NAV-interview corpus.
//
// The list below holds only words that:
//   1. v0.5.0 demonstrably false-positives as NAVN in the stress test
//   2. are *essentially never* personal names in Norwegian NAV-research
//      contexts (so blanket-unredacting them does not create a privacy
//      regression — see CAVEAT below)
//
// **CAVEAT:** the exception list is case-insensitive *blanket* match —
// once added, the span will *never* be redacted for any recording. v2's
// context-aware `protected_common` bucket (see
// `docs/no_anonymizer_v2_implementasjon.md` §4) is the proper fix.
// Until v2 lands, this list is the pragmatic stop-gap.
//
// Researchers can add to / remove from this list freely via
// `AvidentExceptionsView`. The defaults are seeded *once* per install
// (gated by `AppState.hasSeededDefaultExceptions`); subsequent launches
// don't touch the user's customisations.

import Foundation

enum DefaultAvidentExceptions {

    /// Curated seed list. Each entry is paired with a one-line rationale
    /// in the inline comment so reviewers can audit the safety claim.
    /// Norwegian, lower-cased — `applying(exceptions:to:)` matches
    /// case-insensitively so capitalisation here is purely cosmetic.
    static let curated: [String] = [
        "andre",      // Norwegian pronoun "others"; the personal name "André" is rare in NAV interviews
        "ha",         // Norwegian verb "to have"; a name "Ha" is essentially unseen in Norwegian
        "noen",       // Norwegian pronoun "some/any"
        "ingen",      // Norwegian pronoun "no one"
        "alle",       // Norwegian pronoun "all"
        "ene",        // Norwegian pronoun "one"
        "selv",       // Norwegian "self"
        "stad",       // Place-name fragment ("Stadlandet") — v0.5.0 caught the prefix as NAVN
        "storgata",   // Norwegian street name; never a personal name
        "lillegata",  // Same family
        "kongsgata",  // Same family
        "kirkegata",  // Same family
        "postboks",   // Postal-box marker; was already mis-categorised once in the stress test
    ]

    /// Returns the curated list merged with any existing custom entries.
    /// Used by both first-launch seeding and the manual "reset to
    /// defaults" action — both paths must dedupe case-insensitively to
    /// preserve the invariant the rest of the code relies on.
    static func mergedWith(_ existing: [String]) -> [String] {
        var seen: Set<String> = []
        var out: [String] = []
        for entry in curated + existing {
            let key = entry.lowercased()
            if seen.insert(key).inserted {
                out.append(entry)
            }
        }
        return out
    }
}
