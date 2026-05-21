// AppFont.swift
// AudioRecordingManager
//
// ⚠️ DESIGN SURFACE — read `Design/README.md` before editing.
//
// Semantic typography tokens. Use these instead of `.font(.system(size: 11))`
// etc. at the callsite. Underlying values are sourced from the Clio type scale
// in `Typography+Clio.swift` wherever the size/weight aligns — remaining
// tokens keep bespoke values that have no Clio equivalent yet.

import SwiftUI

/// Semantic typography tokens for the app.
///
/// **Adding a new role:** if a callsite needs a font size/weight combo
/// that doesn't fit any existing role, add a new role here rather than
/// hardcoding. Renaming or deleting roles is a breaking change — grep
/// before touching.
struct AppFont {
    // Chip / pill scale (11–12pt) — sourced from Clio label/caption scale
    /// Chip labels, pill button text — small but readable.
    static let pillLabel         = Font.clioLabel          // 11pt medium
    /// Pill primary action ("Transkriber") — slightly heavier.
    static let pillPrimary       = Font.system(size: 11, weight: .semibold)
    /// Filter-chip label (interactive but not button-like).
    static let chipLabel         = Font.clioCaption        // 12pt regular
    /// Active filter-chip label.
    static let chipLabelActive   = Font.clioCaptionMedium  // 12pt medium
    /// Table column header ("NAVN", "DATO", "TRANSKRIBERING").
    static let tableColumnHeader = Font.system(size: 11, weight: .semibold)

    // Body scale (12–13pt) — sourced from Clio sub/caption scale
    /// Default table-cell text.
    static let tableCell         = Font.clioSub            // 13pt regular
    /// Secondary metadata in cells (dates, durations).
    static let tableMetaCell     = Font.clioCaption        // 12pt regular
    /// Monospaced numeric cells (duration, file sizes).
    static let tableMonoCell     = Font.system(size: 12, design: .monospaced)
    /// Body copy across the app.
    static let body              = Font.clioSub            // 13pt regular
    static let bodyMedium        = Font.clioSubMedium      // 13pt medium
    /// Caption text (timestamps, helper hints).
    static let caption           = Font.clioCaption        // 12pt regular

    // Heading scale — bespoke sizes; no Clio equivalent at these weights yet
    /// Section title ("Bibliotek").
    static let screenTitle  = Font.system(size: 28, weight: .semibold)
    /// Inline subtitle (modal headers, secondary sections).
    static let sectionTitle = Font.system(size: 18, weight: .semibold)
    /// Smaller heading (dialog rows, group labels).
    static let groupTitle   = Font.system(size: 15, weight: .semibold)

    // Icon-as-font (SF Symbols scale via font size)
    /// Standard inline icon in a table row (play button, info badge).
    static let iconRow        = Font.system(size: 18)
    /// Large hero icon used in centered empty-state panels.
    static let iconEmptyState = Font.system(size: 40, weight: .light)
}
