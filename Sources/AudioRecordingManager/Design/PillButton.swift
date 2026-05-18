// PillButton.swift
// AudioRecordingManager
//
// ⚠️ DESIGN SURFACE — read `Design/README.md` before editing.
//
// Pill button styles + a running-progress pill view. Every action that
// renders as a capsule of fixed `AppSize.pillWidth` × `pillHeight`
// (Bibliotek's TRANSKRIBERING column, future row actions) should go
// through these. Keeps cursor affordance, font, frame, and shape
// consistent across the app.

import SwiftUI

// MARK: - Visual variants

/// Visual variants for `PillButtonStyle`. Pick by semantic intent rather
/// than colour — "destructive" is for irreversible actions, not anything
/// that happens to want a red pill.
enum PillVariant {
    /// Filled accent. Use for the primary action in a context.
    case primary
    /// Outlined neutral (dark grey on a faint grey fill). Use for
    /// secondary actions or for affordances that open something
    /// (e.g. "Åpne").
    case secondary
    /// Outlined accent — running/in-progress state. Use only with
    /// `RunningPill`, not as a generic button style.
    case running
}

// MARK: - PillButtonStyle

/// A `ButtonStyle` that renders the label inside a fixed pill frame
/// (`AppSize.pillWidth` × `pillHeight`) styled per `PillVariant`. Adds a
/// pointing-hand hover cursor automatically.
struct PillButtonStyle: ButtonStyle {
    let variant: PillVariant

    func makeBody(configuration: Configuration) -> some View {
        let opacity: Double = configuration.isPressed ? 0.7 : 1.0
        return configuration.label
            .font(variant == .primary ? AppFont.pillPrimary : AppFont.pillLabel)
            .foregroundStyle(foreground)
            .frame(width: AppSize.pillWidth, height: AppSize.pillHeight)
            .background(Capsule().fill(fill))
            .overlay(stroke)
            .contentShape(Capsule())
            .opacity(opacity)
            .hoverCursor()
    }

    private var foreground: Color {
        switch variant {
        case .primary:   return .white
        case .secondary: return .secondary
        case .running:   return .primary
        }
    }

    private var fill: Color {
        switch variant {
        case .primary:   return AppColors.accent
        case .secondary: return AppColors.neutralSurfaceStrong
        case .running:   return AppColors.accentTint
        }
    }

    @ViewBuilder
    private var stroke: some View {
        switch variant {
        case .primary:
            EmptyView()
        case .secondary:
            Capsule().strokeBorder(AppColors.neutralBorderStrong, lineWidth: 1)
        case .running:
            Capsule().strokeBorder(AppColors.accent.opacity(0.4), lineWidth: 1)
        }
    }
}

// MARK: - RunningPill

/// A pill that visually fills from 0 → 1 along the leading edge to
/// indicate determinate progress. Tap to invoke `onCancel`.
///
/// Use this for any "in-flight, cancel by tap" affordance — e.g. the
/// "Avbryt · 42 %" pill in the Bibliotek TRANSKRIBERING column.
///
/// Sized to match `PillButtonStyle` (`AppSize.pillWidth × pillHeight`)
/// so it slots into the same column without layout jitter.
struct RunningPill: View {
    let progress: Double
    let labelWhileRunning: String
    let labelWaiting: String
    let onCancel: () -> Void

    /// Convenience initialiser with the default Norwegian copy used by
    /// the Bibliotek transcription column.
    init(
        progress: Double,
        labelWhileRunning: String? = nil,
        labelWaiting: String = "Avbryt …",
        onCancel: @escaping () -> Void
    ) {
        self.progress = progress
        self.labelWhileRunning = labelWhileRunning
            ?? "Avbryt · \(Int((progress * 100).rounded())) %"
        self.labelWaiting = labelWaiting
        self.onCancel = onCancel
    }

    var body: some View {
        Button(action: onCancel) {
            ZStack(alignment: .leading) {
                AppColors.accentTint
                GeometryReader { geo in
                    Rectangle()
                        .fill(AppColors.accentFill)
                        .frame(width: max(0, geo.size.width * progress))
                        .animation(.easeInOut(duration: 0.25), value: progress)
                }
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(AppFont.pillLabel)
                    Text(progress > 0 ? labelWhileRunning : labelWaiting)
                        .font(AppFont.pillLabel)
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
            }
            .frame(width: AppSize.pillWidth, height: AppSize.pillHeight)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(AppColors.accent.opacity(0.4), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .hoverCursor()
    }
}
