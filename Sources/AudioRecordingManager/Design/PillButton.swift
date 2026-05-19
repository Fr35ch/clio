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

/// Indeterminate in-flight pill with elapsed-time label. Tap to cancel.
/// Sized to match `PillButtonStyle` so it slots into the same column without jitter.
struct RunningPill: View {
    let startTime: Date?
    let audioDuration: Double?
    let onCancel: () -> Void

    init(
        startTime: Date? = nil,
        audioDuration: Double? = nil,
        onCancel: @escaping () -> Void
    ) {
        self.startTime = startTime
        self.audioDuration = audioDuration
        self.onCancel = onCancel
    }

    var body: some View {
        Button(action: onCancel) {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                ZStack {
                    AppColors.accentTint
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(AppFont.pillLabel)
                        Text(pillLabel)
                            .font(AppFont.pillLabel)
                            .monospacedDigit()
                    }
                    .foregroundStyle(.primary)
                }
            }
            .frame(width: AppSize.pillWidth, height: AppSize.pillHeight)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(AppColors.accent.opacity(0.4), lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .hoverCursor()
    }

    private var pillLabel: String {
        guard let start = startTime else { return "Avbryt …" }
        let elapsed = Int(-start.timeIntervalSinceNow)
        let mm = elapsed / 60
        let ss = elapsed % 60
        return String(format: "Avbryt · %d:%02d", mm, ss)
    }
}

// MARK: - TranscriptionProgressView

/// Indeterminate progress block shown in the detail pane during transcription.
/// Shows a spinner, stage label, elapsed time, and an estimated remaining time
/// derived from audio duration × a per-model speed factor.
struct TranscriptionProgressView: View {
    let stageName: String
    let startTime: Date?
    let audioDuration: Double?

    // Approximate realtime factor for NB-Whisper on Apple Silicon MPS (float32).
    // Large ≈ 0.25×, Medium ≈ 0.35×, Small ≈ 0.5×. We use 0.3 as a safe middle.
    private let realtimeFactor: Double = 0.3

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.75)
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(statusLine)
                        .font(.body)
                        .monospacedDigit()
                }
            }
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                if let est = estimateLine {
                    Text(est)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
    }

    private var elapsed: Int {
        guard let start = startTime else { return 0 }
        return max(0, Int(-start.timeIntervalSinceNow))
    }

    private var statusLine: String {
        let e = elapsed
        if e == 0 { return stageName.isEmpty ? "Forbereder…" : stageName }
        let mm = e / 60, ss = e % 60
        let label = stageName.isEmpty ? "Transkriberer" : stageName.replacingOccurrences(of: "…", with: "").trimmingCharacters(in: .whitespaces)
        return String(format: "%@ · %d:%02d", label, mm, ss)
    }

    private var estimateLine: String? {
        guard let dur = audioDuration, dur > 0, let start = startTime else { return nil }
        let e = -start.timeIntervalSinceNow
        guard e > 5 else { return nil } // don't show estimate until 5s in
        let totalEstimate = dur * realtimeFactor
        let remaining = max(0, totalEstimate - e)
        if remaining < 10 { return "Fullfører snart…" }
        let mins = Int(remaining / 60) + 1
        return "ca. \(mins) min gjenstår"
    }
}
