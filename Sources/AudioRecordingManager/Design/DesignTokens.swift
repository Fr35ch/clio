// DesignTokens.swift
// AudioRecordingManager
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

/// Custom colour palette — purple/pink accent, dark and light theme variants.
/// See Design/README.md and the colour palette reference image before editing.
struct AppColors {

    // -------------------------------------------------------------------------
    // MARK: Palette primitives
    // -------------------------------------------------------------------------

    // Dark theme backgrounds
    /// #1a1a1f — darkest background layer
    static let darkBackground   = Color(red: 26/255,  green: 26/255,  blue: 31/255)
    /// #2a2a2f — raised surface in dark mode
    static let darkSurface      = Color(red: 42/255,  green: 42/255,  blue: 47/255)

    // Light theme backgrounds
    /// #faf9ff — page background in light mode
    static let lightBackground  = Color(red: 250/255, green: 249/255, blue: 255/255)
    /// #f5f3ff — lavender-tinted surface in light mode
    static let lavenderTint     = Color(red: 245/255, green: 243/255, blue: 255/255)

    // Accent colours
    /// #7c3aed — purple primary accent (both themes)
    static let purpleAccent     = Color(red: 124/255, green: 58/255,  blue: 237/255)
    /// #e91e63 — pink accent (dark theme primary, light theme secondary)
    static let pinkAccent       = Color(red: 233/255, green: 30/255,  blue: 99/255)

    // Text
    /// #ffffff — primary text on dark backgrounds
    static let lightText        = Color.white
    /// #b0b0b5 — muted / secondary text on dark backgrounds
    static let mutedText        = Color(red: 176/255, green: 176/255, blue: 181/255)
    /// #1a1a1f — primary text on light backgrounds
    static let darkText         = Color(red: 26/255,  green: 26/255,  blue: 31/255)

    // Gradient stops
    /// #ff9a8b — coral gradient start
    static let coralGradient    = Color(red: 255/255, green: 154/255, blue: 139/255)
    /// #ffa8a1 — peach gradient end
    static let peachGradient    = Color(red: 255/255, green: 168/255, blue: 161/255)

    // -------------------------------------------------------------------------
    // MARK: Semantic tokens (used throughout the app — do not remove)
    // -------------------------------------------------------------------------

    // Brand accent — adaptive: purple in light mode, pink in dark mode.
    // All .borderedProminent buttons, pills, and highlights use this.
    static let accent: Color = Color(NSColor(name: "ARMAccent", dynamicProvider: { appearance in
        switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
        case .darkAqua: return NSColor(pinkAccent)
        default:        return NSColor(purpleAccent)
        }
    }))
    static var accentSubtle: Color     { accent.opacity(0.2) }
    static var accentTint: Color       { accent.opacity(0.08) }
    static var accentFill: Color       { accent.opacity(0.35) }

    // Status
    static let destructive      = pinkAccent
    static let success          = Color.green
    /// Coral — used for warnings and messages.
    static let warning          = coralGradient

    // Anonymizer surfaces
    /// Lavender page tint when anonymized mode is active.
    static let anonymizerBackground     = lavenderTint.opacity(0.5)
    /// Slightly darker lavender for [Token] box backgrounds.
    static let anonymizerTokenBackground = Color(red: 210/255, green: 205/255, blue: 245/255)
    /// Stronger version for highlighted/active token boxes.
    static let anonymizerTokenBackgroundStrong = Color(red: 185/255, green: 175/255, blue: 235/255)

    // Neutral surfaces — for outlined pills, chip backgrounds, dividers.
    static let neutralSurface           = Color.gray.opacity(0.08)
    static let neutralSurfaceStrong     = Color.gray.opacity(0.12)
    static let neutralBorder            = Color.gray.opacity(0.25)
    static let neutralBorderStrong      = Color.gray.opacity(0.5)
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
