// AppFont.swift
// AudioRecordingManager
//
// ⚠️ DESIGN SURFACE — read `Design/README.md` before editing.
//
// Typography tokens. Use these instead of `.font(.system(size: 11))` etc.
// at the callsite so future size/weight tweaks happen in one place.
//
// The roles are semantic ("pillButton", "chipLabel", "tableHeader") rather
// than scalar ("size12medium") so callers express intent and the design
// system stays free to retune the underlying values.

import SwiftUI

/// Semantic typography tokens for the app.
///
/// **Adding a new role:** if a callsite needs a font size/weight combo
/// that doesn't fit any existing role, add a new role here rather than
/// hardcoding. Renaming or deleting roles is a breaking change — grep
/// before touching.
struct AppFont {
    // Chip / pill scale (11pt)
    /// Chip labels, pill button text — small but readable.
    static let pillLabel = Font.system(size: 11, weight: .medium)
    /// Pill primary action ("Transkriber") — slightly heavier.
    static let pillPrimary = Font.system(size: 11, weight: .semibold)
    /// Filter-chip label (interactive but not button-like).
    static let chipLabel = Font.system(size: 12)
    /// Active filter-chip label.
    static let chipLabelActive = Font.system(size: 12, weight: .medium)
    /// Table column header ("NAVN", "DATO", "TRANSKRIBERING").
    static let tableColumnHeader = Font.system(size: 11, weight: .semibold)

    // Body scale (12–13pt)
    /// Default table-cell text.
    static let tableCell = Font.system(size: 13)
    /// Secondary metadata in cells (dates, durations).
    static let tableMetaCell = Font.system(size: 12)
    /// Monospaced numeric cells (duration, file sizes).
    static let tableMonoCell = Font.system(size: 12, design: .monospaced)
    /// Body copy across the app.
    static let body = Font.system(size: 13)
    static let bodyMedium = Font.system(size: 13, weight: .medium)
    /// Caption text (timestamps, helper hints).
    static let caption = Font.caption

    // Heading scale
    /// Section title ("Bibliotek").
    static let screenTitle = Font.system(size: 28, weight: .semibold)
    /// Inline subtitle (modal headers, secondary sections).
    static let sectionTitle = Font.system(size: 18, weight: .semibold)
    /// Smaller heading (dialog rows, group labels).
    static let groupTitle = Font.system(size: 15, weight: .semibold)

    // Icon-as-font (SF Symbols scale via font size)
    /// Standard inline icon in a table row (play button, info badge).
    static let iconRow = Font.system(size: 18)
    /// Large hero icon used in centered empty-state panels.
    static let iconEmptyState = Font.system(size: 40, weight: .light)
}
