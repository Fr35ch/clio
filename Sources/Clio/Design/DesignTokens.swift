// DesignTokens.swift
// Clio
//
// ⚠️ DESIGN SURFACE — read `Design/README.md` before editing.
//
// Canonical design tokens: colors, spacing, corner radii. These are the
// numeric and colour values the rest of the app composes UIs from.
//
// Rules:
//   - Values here are deliberate. Don't tweak them to "fix" a layout that
//     looks off somewhere — either the layout is using the wrong token,
//     or the design system itself needs updating with the design owner.
//   - Never hardcode a colour or spacing value elsewhere in the app.
//     Always reference `AppColors.*`, `AppSpacing.*`, or `AppRadius.*`.
//   - Adding new tokens is fine; renaming or removing existing ones is a
//     breaking change — grep before deleting.

import SwiftUI

// MARK: - AppColors

/// Custom colour palette — wired to the Clio design token layer in
/// `Color+Clio.swift`. Brand Guide v1.0 · Nav Innsikt · Mai 2026.
/// See Design/README.md and `Color+Clio.swift` before editing.
struct AppColors {

    // -------------------------------------------------------------------------
    // MARK: Palette primitives — sourced from Clio tokens
    // -------------------------------------------------------------------------

    // Dark theme backgrounds
    static let darkBackground   = Color.clioBackground   // #1A1A1F
    static let darkSurface      = Color.clioSurface      // #2A2A2F

    // Light theme backgrounds
    static let lightBackground  = Color.clioLight        // #FAF9FF
    static let lavenderTint     = Color.clioLavender     // #F5F3FF

    // Accent colours
    static let purpleAccent     = Color.clioPurple       // #7C3AED
    static let pinkAccent       = Color.clioRec          // #E91E63

    // Text
    static let lightText        = Color.clioWhite        // #FFFFFF
    static let mutedText        = Color.clioMuted        // #B0B0B5
    static let darkText         = Color.clioBackground   // #1A1A1F (same dark bg)

    // Gradient stops
    static let coralGradient    = Color.clioCoral        // #FF9A8B
    static let peachGradient    = Color.clioPeach        // #FFA8A1

    // -------------------------------------------------------------------------
    // MARK: Semantic tokens (used throughout the app — do not remove)
    // -------------------------------------------------------------------------

    // Brand accent — adaptive: purple in light mode, pink in dark mode.
    // All .borderedProminent buttons, pills, and highlights use this.
    static let accent: Color = Color(NSColor(name: "ClioAccent", dynamicProvider: { appearance in
        switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
        case .darkAqua: return NSColor(Color.clioRec)
        default:        return NSColor(Color.clioPurple)
        }
    }))
    static var accentSubtle: Color     { accent.opacity(0.2) }
    static var accentTint: Color       { accent.opacity(0.08) }
    static var accentFill: Color       { accent.opacity(0.35) }

    // Status
    static let destructive      = Color.clioRec
    static let success          = Color.clioStatusTranscribed  // macOS system green
    /// Coral — used for warnings and messages.
    static let warning          = Color.clioCoral

    // Anonymizer surfaces
    /// Lavender page tint when anonymized mode is active.
    static let anonymizerBackground            = Color.clioLavender.opacity(0.5)
    static let anonymizerTokenBackground       = Color(red: 210/255, green: 205/255, blue: 245/255)
    static let anonymizerTokenBackgroundStrong = Color(red: 185/255, green: 175/255, blue: 235/255)

    // Neutral surfaces — for outlined pills, chip backgrounds, dividers.
    static let neutralSurface       = Color.gray.opacity(0.08)
    static let neutralSurfaceStrong = Color.gray.opacity(0.12)
    static let neutralBorder        = Color.gray.opacity(0.25)
    static let neutralBorderStrong  = Color.gray.opacity(0.5)

    // -------------------------------------------------------------------------
    // MARK: Adaptive semantic tokens — from Clio (auto light/dark)
    // -------------------------------------------------------------------------

    /// Adaptive window background (FAF9FF / 1A1A1F).
    static let windowBackground  = Color.clioWindowBackground
    /// Adaptive surface — cards, panels, drawers (FFF / 2A2A2F).
    static let surfaceAdaptive   = Color.clioSurfaceAdaptive
    /// Adaptive content surface — one level deeper than surfaceAdaptive (F5F3FF / 1E1E24).
    static let contentAdaptive   = Color.clioContentAdaptive
    /// Adaptive primary text (1A1A1F / FFFFFF).
    static let textPrimary       = Color.clioTextPrimary
    /// Adaptive secondary text / metadata (5A5A62 / B0B0B5).
    static let textSecondary     = Color.clioTextSecondary
    /// Adaptive border / divider (E0DCF5 / 2A2A2F).
    static let border            = Color.clioBorderColor
    /// Subtle — placeholder text, disabled labels (5A5A62, fixed).
    static let subtle            = Color.clioSubtle

    // -------------------------------------------------------------------------
    // MARK: Tint surfaces — pre-baked opacity variants
    // -------------------------------------------------------------------------

    static let purpleTint        = Color.clioPurpleTint    // clioPurple @ 20%
    static let purpleBorder      = Color.clioPurpleBorder  // clioPurple @ 35%
    static let recTint           = Color.clioRecTint       // clioRec @ 15%
    static let coralTint         = Color.clioCoralTint     // clioCoral @ 15%
    static let whiteDim          = Color.clioWhiteDim      // white @ 7%
    static let whiteBorder       = Color.clioWhiteBorder   // white @ 10%

    // -------------------------------------------------------------------------
    // MARK: Recording status indicator colours (sidebar dots)
    // -------------------------------------------------------------------------

    /// File fully analysed (Transcribed + Analysed).
    static let statusAnalysed    = Color.clioStatusAnalysed    // = clioPurple
    /// File transcribed, not yet analysed.
    static let statusTranscribed = Color.clioStatusTranscribed // macOS system green
    /// File pending processing or currently processing.
    static let statusPending     = Color.clioStatusPending     // macOS system yellow
    /// File imported, no processing started.
    static let statusImported    = Color.clioStatusImported    // neutral grey
}

// MARK: - AppSpacing

/// Spacing scale used throughout the app. Always prefer one of these over
/// a hard-coded padding value; if a specific place wants a bespoke
/// spacing, that's a signal the scale needs a new step, not that the
/// callsite should invent its own.
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - AppRadius

/// Corner radius scale. Window-level radius is handled by macOS itself
/// (via `.windowStyle(.hiddenTitleBar)` on the `WindowGroup`), so these
/// are for inner elements: buttons, dialog backgrounds, card insets.
struct AppRadius {
    static let small: CGFloat = 6
    static let medium: CGFloat = 8
    static let large: CGFloat = 10
    static let xlarge: CGFloat = 12
}

// MARK: - AppSize

/// Canonical sizes for elements that recur across the app. Add here
/// rather than hard-coding magic numbers at the callsite.
struct AppSize {
    /// Standard pill-button frame. Used for action pills in the
    /// Bibliotek table and anywhere else a compact pill is needed.
    static let pillWidth: CGFloat = 130
    static let pillHeight: CGFloat = 26

    /// Compact nav-panel icon button (NavPanel.navItem, footerIconButton).
    static let navItemWidth: CGFloat = 44
    static let navItemHeight: CGFloat = 36
}
