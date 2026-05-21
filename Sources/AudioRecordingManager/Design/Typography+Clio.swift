// Typography+Clio.swift
// Clio — Audio Recording Manager
// Design token layer · Brand Guide v1.0 · Nav Innsikt · Mai 2026
//
// Bruk:
//   Text("Clio").clioWordmark(size: 38)
//   Text("Nøkkeltemaer").font(.clioH2)
//   Text("ARKIV").clioSectionLabel()
//   Text("[00:01:12] SPEAKER_00: ...").clioTranscript()
//
// Fontvalg:
//   Display/ordmerke → New York (system serif, forhåndsinstallert på macOS 11+)
//   UI/grensesnitt   → SF Pro   (system sans, standard på macOS)
//   Transkripsjon    → SF Mono  (system monospace)
//
// Tracking (letter-spacing):
//   SwiftUI .tracking(_:) tar verdier i points.
//   Konvertering: points = em × fontstørrelse
//   Eksempel: +0.04em ved 34pt = 0.04 × 34 = 1.36 pt

import SwiftUI

// MARK: - Font · Typeskala

extension Font {

    // ── Display ────────────────────────────────────────────────────────────

    /// Display · 34pt · New York Regular (system serif, opprett — ikke kursiv)
    /// Bruk: ordmerket «Clio», splash screen, tomme tilstander, onboarding.
    /// Kombiner alltid med .tracking(ClioTracking.wordmark(size: 34)).
    static let clioDisplay = Font.system(size: 34, design: .serif)

    // ── Headlines ──────────────────────────────────────────────────────────

    /// Headline 1 · 22pt · SF Pro Medium
    /// Bruk: vindustitler, primære seksjonstitler i hovedinnhold.
    static let clioH1 = Font.system(size: 22, weight: .medium)

    /// Headline 2 · 17pt · SF Pro Medium
    /// Bruk: analyseoverskrifter (Sammendrag, Nøkkeltemaer, Viktige sitater).
    static let clioH2 = Font.system(size: 17, weight: .medium)

    /// Headline 3 · 15pt · SF Pro Medium
    /// Bruk: temaoverskrifter inni Nøkkeltemaer, kortoverskrifter.
    static let clioH3 = Font.system(size: 15, weight: .medium)

    // ── Body ───────────────────────────────────────────────────────────────

    /// Body Regular · 15pt · SF Pro Regular
    /// Bruk: brødtekst i analysevisning, beskrivelsestekst, sammendrag.
    static let clioBody = Font.system(size: 15)

    /// Body Medium · 15pt · SF Pro Medium
    /// Bruk: filnavn i innholdsvisning, fremhevet brødtekst.
    static let clioBodyMedium = Font.system(size: 15, weight: .medium)

    // ── Subheadline ────────────────────────────────────────────────────────

    /// Subheadline Regular · 13pt · SF Pro Regular
    /// Bruk: sidepanel-tekst, sekundær innholdstekst.
    static let clioSub = Font.system(size: 13)

    /// Subheadline Medium · 13pt · SF Pro Medium
    /// Bruk: status-labels, chip-innhold, sidebar-filnavn (aktiv).
    static let clioSubMedium = Font.system(size: 13, weight: .medium)

    // ── Caption ────────────────────────────────────────────────────────────

    /// Caption · 12pt · SF Pro Regular
    /// Bruk: filmetadata (varighet, ordtelling, dato), sekundær info.
    static let clioCaption = Font.system(size: 12)

    /// Caption Medium · 12pt · SF Pro Medium
    /// Bruk: status-chip-tekst (Transkribert, Analysert).
    static let clioCaptionMedium = Font.system(size: 12, weight: .medium)

    // ── Label ──────────────────────────────────────────────────────────────

    /// Label · 11pt · SF Pro Medium
    /// Bruk: seksjonsoverskrifter i sidebar (ARKIV, SYSTEM), badge-tekst.
    /// Kombiner alltid med .tracking(ClioTracking.label()).
    static let clioLabel = Font.system(size: 11, weight: .medium)

    /// Label Small · 10pt · SF Pro Medium
    /// Bruk: overskrifter inni kort (NØKKELTEMA, SMERTEPUNKT, TRANSKRIPSJON).
    /// Kombiner alltid med .tracking(ClioTracking.cardHeader()).
    static let clioLabelSmall = Font.system(size: 10, weight: .medium)

    // ── Monospace ──────────────────────────────────────────────────────────

    /// Monospace · 13pt · SF Mono Regular
    /// Bruk: transkripsjonslinjer med tidsstempel og speaker-label.
    static let clioMono = Font.system(size: 13, design: .monospaced)

    /// Monospace Small · 11pt · SF Mono Regular
    /// Bruk: tidsstempler i analysevisning, forankringspunkter under sitater.
    static let clioMonoSmall = Font.system(size: 11, design: .monospaced)
}

// MARK: - Tracking · Letter-spacing

/// Forhåndsdefinerte letter-spacing-verdier for Clio-skalaen.
///
/// SwiftUI sitt `.tracking(_:)` tar verdier i points.
/// Alle funksjoner her konverterer fra em til points for riktig størrelse.
///
/// Bruk:
///   Text("Clio")
///       .font(.clioDisplay)
///       .tracking(ClioTracking.wordmark(size: 34))
enum ClioTracking {

    /// +0.04em · Ordmerket og display-serif.
    /// Gir den monumentale, rolige bredden som skiller Clio fra Lyra-kandidatens kursivstil.
    static func wordmark(size: CGFloat = 34) -> CGFloat { 0.04 * size }

    /// +0.10em · Sidebar-seksjonsoverskrifter (ARKIV, SYSTEM).
    /// Etterligner small-caps-virkning på 11pt-tekst.
    static func label(size: CGFloat = 11) -> CGFloat { 0.10 * size }

    /// +0.08em · Chip- og badge-tekst (Transkribert, Analysert).
    static func chip(size: CGFloat = 11) -> CGFloat { 0.08 * size }

    /// +0.06em · Korttitler (NØKKELTEMA, SMERTEPUNKT, TRANSKRIPSJON).
    static func cardHeader(size: CGFloat = 10) -> CGFloat { 0.06 * size }

    /// +0.12em · Tjeneste-labels og footer-tekst med stor tetthet.
    static func dense(size: CGFloat = 9) -> CGFloat { 0.12 * size }
}

// MARK: - ViewModifiers · Ferdigkomponerte tekststiler

// ── Ordmerke ───────────────────────────────────────────────────────────────

/// New York Regular + tracking. Brukes på ordmerket «Clio» i alle størrelser.
public struct ClioWordmarkStyle: ViewModifier {

    /// Fontstørrelse i points. Standard: 38pt (primær plassering).
    var size: CGFloat

    public func body(content: Content) -> some View {
        content
            .font(.system(size: size, design: .serif))
            .tracking(ClioTracking.wordmark(size: size))
    }
}

// ── Sidebar ────────────────────────────────────────────────────────────────

/// Seksjonsoverskrift i sidebar — 11pt Medium, +0.10em tracking, clioSubtle.
public struct ClioSectionLabelStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.clioLabel)
            .tracking(ClioTracking.label())
            .foregroundStyle(Color.clioSubtle)
    }
}

/// Filnavn i sidebar (aktiv rad) — 12pt Regular, hvit.
public struct ClioSidebarActiveStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.clioCaption)
            .foregroundStyle(Color.clioWhite)
            .lineLimit(1)
            .truncationMode(.middle)
    }
}

/// Filnavn i sidebar (inaktiv rad) — 12pt Regular, clioMuted.
public struct ClioSidebarInactiveStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.clioCaption)
            .foregroundStyle(Color.clioMuted)
            .lineLimit(1)
            .truncationMode(.middle)
    }
}

// ── Analyse ────────────────────────────────────────────────────────────────

/// Analyseoverskrift (Sammendrag, Nøkkeltemaer) — 14pt Medium, hvit.
public struct ClioAnalysisSectionStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.clioH3)
            .foregroundStyle(Color.clioWhite)
    }
}

/// Temaoverskrift inni Nøkkeltemaer — 13pt Medium, clioPurple-tint.
public struct ClioThemeTitleStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.clioSubMedium)
            .foregroundStyle(Color.clioPurple.opacity(0.85))
    }
}

/// Brødtekst i analysevisning — 12pt Regular, clioMuted, line-height 1.65.
public struct ClioAnalysisBodyStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.clioCaption)
            .foregroundStyle(Color.clioMuted)
            .lineSpacing(4)           // tilsvarer ~line-height 1.65 ved 12pt
    }
}

// ── Transkripsjon ──────────────────────────────────────────────────────────

/// Transkripsjonslinje — 12pt SF Mono, clioTextPrimary (adaptiv: mørk i lys modus, hvit i mørk).
public struct ClioTranscriptStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.clioMono)
            .foregroundStyle(Color.clioTextPrimary)
    }
}

/// Tidsstempel i analysevisning — 11pt SF Mono, clioSubtle.
public struct ClioTimestampStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.clioMonoSmall)
            .foregroundStyle(Color.clioSubtle)
    }
}

// ── Kortoverskrift ─────────────────────────────────────────────────────────

/// Korttittel med tracking (NØKKELTEMA, SMERTEPUNKT, TRANSKRIPSJON).
public struct ClioCardHeaderStyle: ViewModifier {
    var color: Color

    public func body(content: Content) -> some View {
        content
            .font(.clioLabelSmall)
            .tracking(ClioTracking.cardHeader())
            .foregroundStyle(color)
    }
}

// ── Chip / Badge ───────────────────────────────────────────────────────────

/// Chip-tekst (Transkribert, Analysert) — 11pt Medium, +0.08em tracking.
public struct ClioChipLabelStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.clioLabel)
            .tracking(ClioTracking.chip())
    }
}

// MARK: - View extension · Convenience

extension View {

    // ── Display ──────────────────────────────────────────────────────────

    /// Stiler innholdet som Clio-ordmerket (New York Regular + tracking).
    /// - Parameter size: Fontstørrelse i points. Standard: 38pt.
    func clioWordmark(size: CGFloat = 38) -> some View {
        modifier(ClioWordmarkStyle(size: size))
    }

    // ── Sidebar ──────────────────────────────────────────────────────────

    /// Seksjonsoverskrift i sidebar (ARKIV, SYSTEM).
    func clioSectionLabel() -> some View {
        modifier(ClioSectionLabelStyle())
    }

    /// Filnavn i sidebar, aktiv rad.
    func clioSidebarActive() -> some View {
        modifier(ClioSidebarActiveStyle())
    }

    /// Filnavn i sidebar, inaktiv rad.
    func clioSidebarInactive() -> some View {
        modifier(ClioSidebarInactiveStyle())
    }

    // ── Analyse ──────────────────────────────────────────────────────────

    /// Analyseoverskrift (Sammendrag, Nøkkeltemaer, Viktige sitater).
    func clioAnalysisSection() -> some View {
        modifier(ClioAnalysisSectionStyle())
    }

    /// Temaoverskrift inni Nøkkeltemaer.
    func clioThemeTitle() -> some View {
        modifier(ClioThemeTitleStyle())
    }

    /// Brødtekst i analysevisning.
    func clioAnalysisBody() -> some View {
        modifier(ClioAnalysisBodyStyle())
    }

    // ── Transkripsjon ─────────────────────────────────────────────────────

    /// Transkripsjonslinje (inkl. tidsstempel og speaker-label).
    func clioTranscript() -> some View {
        modifier(ClioTranscriptStyle())
    }

    /// Tidsstempel alene i analysevisning.
    func clioTimestamp() -> some View {
        modifier(ClioTimestampStyle())
    }

    // ── Kort ─────────────────────────────────────────────────────────────

    /// Korttittel med tracking — gi foregroundColor som argument.
    /// Eksempel: Text("NØKKELTEMA").clioCardHeader(color: .clioPurple)
    func clioCardHeader(color: Color = .clioMuted) -> some View {
        modifier(ClioCardHeaderStyle(color: color))
    }

    // ── Chip / Badge ──────────────────────────────────────────────────────

    /// Chip-tekst med tracking.
    func clioChipLabel() -> some View {
        modifier(ClioChipLabelStyle())
    }
}
