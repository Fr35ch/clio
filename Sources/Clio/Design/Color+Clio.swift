// Color+Clio.swift
// Clio — Audio Recording Manager
// Design token layer · Brand Guide v1.0 · Nav Innsikt · Mai 2026
//
// Bruk:
//   Text("Hei").foregroundStyle(.clioPurple)
//   Rectangle().fill(.clioWindowBackground)
//   Circle().fill(.clioRec)               // Kun opptakspunktet
//
// Alle farger er definert i sRGB-fargerom.
// Adaptive farger (clioWindowBackground, clioTextPrimary osv.)
// oppdateres automatisk når bruker bytter mellom lys og mørk modus.

import SwiftUI
import AppKit

// MARK: - Private: Hex-initialisering

private extension Color {

    /// Initialiserer en Color fra en UInt32 hex-verdi, f.eks. 0x7C3AED.
    init(_ hex: UInt32, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red:     Double((hex >> 16) & 0xFF) / 255,
            green:   Double((hex >>  8) & 0xFF) / 255,
            blue:    Double( hex        & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Private: Adaptiv lys/mørk-initialisering

private extension Color {

    /// Returnerer én Color som bytter mellom lys- og mørk-variant
    /// basert på gjeldende NSAppearance. Fungerer korrekt i alle
    /// SwiftUI-kontekster på macOS 11+.
    init(light lightHex: UInt32, dark darkHex: UInt32) {
        let lr = Double((lightHex >> 16) & 0xFF) / 255
        let lg = Double((lightHex >>  8) & 0xFF) / 255
        let lb = Double( lightHex        & 0xFF) / 255
        let dr = Double((darkHex  >> 16) & 0xFF) / 255
        let dg = Double((darkHex  >>  8) & 0xFF) / 255
        let db = Double( darkHex         & 0xFF) / 255

        self.init(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(srgbRed: dr, green: dg, blue: db, alpha: 1)
            } else {
                return NSColor(srgbRed: lr, green: lg, blue: lb, alpha: 1)
            }
        })
    }
}

// MARK: - Clio Design Tokens

extension Color {

    // ── Brand · Primærfarger ──────────────────────────────────────────────
    //
    // Disse to fargene er Clios kjerneidentitet.
    // clioPurple er alltid primæraksent.
    // clioRec brukes utelukkende som opptakspunkt — aldri som generell aksent.

    /// Lilla primær.
    /// Bruk: knapper, fokusringer, aktive sidebar-rader, Analyser-knapp,
    /// temaoverskrifter i analysevisning, fremdriftslinje.
    static let clioPurple   = Color(0x7C3AED)

    /// Rosa opptak.
    /// Bruk: opptakspunktet i merket, UI-tilstanden «Tar opp», badge-dot
    /// på aktive filer. Aldri som generell aksent eller hover-farge.
    static let clioRec      = Color(0xE91E63)

    // ── Brand · Varmt spekter ─────────────────────────────────────────────

    /// Korall.
    /// Bruk: smertepunkt-kort i analysevisning, varm sekundæraksent,
    /// highlight på sitater med høy analytisk verdi.
    static let clioCoral    = Color(0xFF9A8B)

    /// Fersken.
    /// Bruk: sekundær varm aksent, hover-tilstand på korall-elementer,
    /// gradient-par med clioCoral i illustrasjoner og onboarding.
    static let clioPeach    = Color(0xFFA8A1)

    /// Lavendel.
    /// Bruk: bakgrunn bak lilla elementer i lys modus, tint-overflater
    /// (f.eks. bak lilla badges og chips), hover-bakgrunn på lilla rader.
    static let clioLavender = Color(0xF5F3FF)

    // ── Bakgrunner · Mørk modus ───────────────────────────────────────────

    /// Primær mørk bakgrunn.
    /// Bruk: vindusbakgrunn, sidebar, ytre overflater i mørk modus.
    static let clioBackground = Color(0x1A1A1F)

    /// Sekundær mørk overflate.
    /// Bruk: tittelbar, mørke kort, felt-bakgrunner, divider-flater.
    static let clioSurface    = Color(0x2A2A2F)

    /// Tertiær mørk innhold.
    /// Bruk: transkripsjonspanel, analyse-kort, innholdsflater
    /// som er ett nivå lysere enn clioBackground.
    static let clioContent    = Color(0x1E1E24)

    // ── Bakgrunner · Lys modus ────────────────────────────────────────────

    /// Primær lys bakgrunn.
    /// Bruk: vindusbakgrunn og ytre overflater i lys modus.
    static let clioLight      = Color(0xFAF9FF)

    // ── Tekst · Mørk modus ────────────────────────────────────────────────

    /// Primær tekst på mørk bakgrunn.
    static let clioWhite      = Color(0xFFFFFF)

    /// Dempet tekst på mørk bakgrunn.
    /// Bruk: metadata, filnavn (inaktive), tidsstempler, sekundær info.
    static let clioMuted      = Color(0xB0B0B5)

    /// Subtil tekst og inaktive elementer.
    /// Bruk: placeholder-tekst, deaktiverte labels, svært lav-prioritet info.
    static let clioSubtle     = Color(0x5A5A62)

    // ── Semantiske tokens · Adaptive (lys/mørk) ───────────────────────────
    //
    // Disse tilpasser seg automatisk brukerens systemvalg.
    // Bruk disse fremfor de rå bakgrunnsfargene overalt det er mulig.

    /// Tilpasset vindusbakgrunn.
    static let clioWindowBackground = Color(
        light: 0xFAF9FF,
        dark:  0x1A1A1F
    )

    /// Tilpasset overflate (kort, paneler, skuffer).
    static let clioSurfaceAdaptive = Color(
        light: 0xFFFFFF,
        dark:  0x2A2A2F
    )

    /// Tilpasset innholdsflate (ett nivå dypere enn overflate).
    static let clioContentAdaptive = Color(
        light: 0xF5F3FF,
        dark:  0x1E1E24
    )

    /// Tilpasset primærtekst.
    static let clioTextPrimary = Color(
        light: 0x1A1A1F,
        dark:  0xFFFFFF
    )

    /// Tilpasset sekundærtekst.
    static let clioTextSecondary = Color(
        light: 0x5A5A62,
        dark:  0xB0B0B5
    )

    /// Tilpasset kant/skillelinje.
    static let clioBorderColor = Color(
        light: 0xE0DCF5,
        dark:  0x2A2A2F
    )

    // ── Status · Arkivindikatorer (sidebar) ───────────────────────────────
    //
    // Brukes utelukkende som dot-indikatorer på filer i sidebar.
    // Tilsvarer UI-tilstandene i brand guide, seksjon 8.3.

    /// Fil er fullt analysert (Transkribert + Analysert).
    static let clioStatusAnalysed    = Color(0x7C3AED)   // = clioPurple

    /// Fil er transkribert, men ikke analysert ennå.
    static let clioStatusTranscribed = Color(0x28C840)   // macOS system green

    /// Fil venter på behandling eller behandles nå.
    static let clioStatusPending     = Color(0xFEBC2E)   // macOS system yellow

    /// Fil er importert, ingen behandling startet.
    static let clioStatusImported    = Color(0x3A3A42)   // nøytral grå

    // ── UI · Tint-overflater (faste gjennomsiktighetsverdier) ────────────
    //
    // Forhåndsdefinerte opacity-varianter for de hyppigst brukte fargene.
    // Unngår spredning av .opacity(0.20)-kall gjennom kodebasen.

    /// Lilla overflate-tint — aktiv sidebar-rad, fokusert inntastingsfelt.
    static let clioPurpleTint   = Color(0x7C3AED, opacity: 0.20)

    /// Lilla kant-tint — ramme rundt aktive og fokuserte elementer.
    static let clioPurpleBorder = Color(0x7C3AED, opacity: 0.35)

    /// Rosa opptak-tint — bakgrunn bak opptaks-badge og rec-indikatorer.
    static let clioRecTint      = Color(0xE91E63, opacity: 0.15)

    /// Korall smertepunkt-tint — bakgrunn for smertepunkt-kort i analyse.
    static let clioCoralTint    = Color(0xFF9A8B, opacity: 0.15)

    /// Hvit overflate, lav synlighet — transkripsjonspanel på mørk bakgrunn.
    static let clioWhiteDim     = Color(0xFFFFFF, opacity: 0.07)

    /// Hvit kant, lav synlighet — subtile skillelinjer på mørk bakgrunn.
    static let clioWhiteBorder  = Color(0xFFFFFF, opacity: 0.10)
}
