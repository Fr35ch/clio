// StatusChipView.swift
// AudioRecordingManager
//
// ⚠️ DESIGN SURFACE — read `Design/README.md` before editing.
//
// Renders a `StatusChip` (label + tone) as a capsule with the canonical
// tone-to-colour mapping. Replaces the inline `chipView()` /
// `chipForegroundColor` / `chipBackgroundColor` helpers that lived inside
// BibliotekView.
//
// `ChipTone` and `StatusChip` themselves are defined in
// `Library/RecordingStatusBundle.swift` (they're domain values, not
// design-surface). This file owns the rendering of those values.

import SwiftUI

/// A capsule rendering of a `StatusChip`. Pure presentation — pass it a
/// model and it draws.
struct StatusChipView: View {
    let chip: StatusChip

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(StatusChipView.foreground(chip.tone))
                .frame(width: 6, height: 6)
            Text(chip.label)
                .font(.system(size: 11))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(StatusChipView.background(chip.tone, active: false))
        )
        .overlay(
            Capsule().strokeBorder(
                StatusChipView.foreground(chip.tone).opacity(0.4),
                lineWidth: 1
            )
        )
        .foregroundStyle(StatusChipView.foreground(chip.tone))
    }

    // MARK: - Tone → colour mapping (single source of truth)

    /// Foreground colour for a tone (text, dot, border).
    static func foreground(_ tone: ChipTone) -> Color {
        switch tone {
        case .neutral: return .secondary
        case .info:    return AppColors.accent
        case .success: return AppColors.success
        case .warning: return AppColors.warning
        case .danger:  return AppColors.destructive
        }
    }

    /// Background fill for a tone. `active = true` is the
    /// pressed/selected variant used by filter chips.
    static func background(_ tone: ChipTone, active: Bool) -> Color {
        let base = foreground(tone)
        return active ? base.opacity(0.15) : base.opacity(0.08)
    }
}
