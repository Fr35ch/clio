// BibliotekView.swift
// AudioRecordingManager
//
// "Bibliotek" — the canonical library view of every recording in the
// app. Replaces the card-row RecordingsListColumn in the recordings
// tab's column 2. Implements US-R13–R18:
//
//   - Title + summary stats (N opptak · M transkribert · K analysert)
//   - Sort menu (newest / oldest / name / expiry soonest)
//   - Filter chip row with counts
//   - Conditional expiry-warning banner
//   - Table with NAVN / VARIGH. / DATO / TRANSKR. / AVIDENT. / ANALYSE
//     / TEAMS / SLETTES status chips
//   - Play button on each row that previews audio without opening
//     column 3
//   - Selecting a row drives column 3 (existing pattern)
//
// Status derivation lives entirely in `RecordingStatusBundle` —
// definitions of "Klar for Teams", "Venter avid.", expiry thresholds,
// etc. live in one place there.

import AppKit
import SwiftUI

struct BibliotekView: View {
    @ObservedObject var recordingsManager: RecordingsManager
    @ObservedObject var audioPlayer: AudioPlayer
    @ObservedObject var analysisStore = AnalysisStore.shared
    @ObservedObject var transcriptionRunner = TranscriptionRunner.shared
    @Binding var selectedRecording: RecordingItem?
    /// `true` when column 3 is visible (a recording is selected); the
    /// table compresses to play + name + date + a single urgency chip.
    /// `false` when column 3 is hidden; the full status pipeline shows.
    let isCompact: Bool

    @State private var activeFilter: BibliotekFilter = .alle
    @State private var bundles: [RecordingStatusBundle] = []
    @State private var projectConfigured: Bool = false

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            header
            filterChipsRow
            expiryBanner
            Divider()
            if filteredBundles.isEmpty {
                emptyState
                    .frame(maxHeight: .infinity)
            } else {
                tableHeader
                Divider()
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredBundles) { bundle in
                            rowView(bundle)
                            Divider().padding(.leading, AppSpacing.lg)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { reload() }
        .onChange(of: recordingsManager.recordings) { _, _ in reload() }
        .onChange(of: analysisStore.changeToken) { _, _ in reload() }
        .onChange(of: transcriptionRunner.inFlight) { _, _ in reload() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bibliotek")
                    .font(AppFont.screenTitle)
                Text(summaryLine)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.lg)
        .padding(.bottom, AppSpacing.md)
    }

    private var summaryLine: String {
        let total = bundles.count
        let transcribed = bundles.filter { $0.isTranscribed }.count
        let analysed = bundles.filter { $0.analyse.label == "Ferdig" }.count
        return "\(total) opptak · \(transcribed) transkribert · \(analysed) analysert"
    }

    // MARK: - Filter chips

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(BibliotekFilter.allCases) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.md)
        }
    }

    private func filterChip(_ filter: BibliotekFilter) -> some View {
        let isActive = activeFilter == filter
        let n = bundles.filter { filter.matches($0) }.count
        let tone = isActive ? filter.tone : ChipTone.neutral

        return Button {
            activeFilter = filter
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(StatusChipView.foreground(tone))
                    .frame(width: 6, height: 6)
                Text("\(filter.label) (\(n))")
                    .font(isActive ? AppFont.chipLabelActive : AppFont.chipLabel)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(StatusChipView.background(tone, active: isActive))
            )
            .overlay(
                Capsule().stroke(
                    StatusChipView.foreground(tone).opacity(isActive ? 0 : 0.3),
                    lineWidth: 1)
            )
            .foregroundStyle(isActive ? StatusChipView.foreground(tone) : .primary)
        }
        .buttonStyle(.plain)
        .hoverCursor()
    }

    // MARK: - Expiry banner (US-R18)

    @ViewBuilder
    private var expiryBanner: some View {
        let urgent = bundles.filter {
            $0.daysUntilExpiry <= RecordingStatusBundle.bannerThresholdDays
        }
        if !urgent.isEmpty {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppColors.warning)
                Text("\(urgent.count) opptak slettes om under \(RecordingStatusBundle.bannerThresholdDays) dager — og transkripsjonene er ikke avidentifisert ennå. Fullfør avid. og last opp til Teams før fristen.")
                    .font(AppFont.tableMetaCell)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button {
                    activeFilter = .utløperSnart
                } label: {
                    HStack(spacing: 4) {
                        Text("Vis dem")
                        Image(systemName: "arrow.right")
                    }
                    .font(AppFont.chipLabelActive)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .hoverCursor()
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .fill(AppColors.warning.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(AppColors.warning.opacity(0.4), lineWidth: 1)
            )
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.md)
        }
    }

    // MARK: - Table

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("").frame(width: 32, alignment: .leading)
            columnHeader("NAVN", width: nil, alignment: .leading)
            if !isCompact {
                columnHeader("VARIGH.", width: 70, alignment: .leading)
            }
            columnHeader("DATO", width: 130, alignment: .leading)
            columnHeader("TRANSKRIBERING", width: 150, alignment: .leading)
            if !isCompact {
                columnHeader("AVIDENT.", width: 110, alignment: .leading)
                columnHeader("ANALYSE", width: 100, alignment: .leading)
                columnHeader("TEAMS", width: 70, alignment: .leading)
            }
            columnHeader("SLETTES", width: 70, alignment: .leading)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    private func columnHeader(_ text: String, width: CGFloat?, alignment: Alignment) -> some View {
        Group {
            if let width {
                Text(text)
                    .font(AppFont.tableColumnHeader)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                    .frame(width: width, alignment: alignment)
            } else {
                Text(text)
                    .font(AppFont.tableColumnHeader)
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                    .frame(maxWidth: .infinity, alignment: alignment)
            }
        }
    }

    private func rowView(_ bundle: RecordingStatusBundle) -> some View {
        let isSelected = selectedRecording?.id == bundle.id

        return HStack(spacing: 0) {
            // Play button (column 1)
            Button {
                playPreview(bundle)
            } label: {
                Image(systemName: playIcon(for: bundle))
                    .font(AppFont.iconRow)
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help("Spill av")
            .hoverCursor()

            Text(bundle.displayName)
                .font(AppFont.tableCell)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !isCompact {
                Text(formatDuration(bundle.durationSeconds))
                    .font(AppFont.tableMonoCell)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: 70, alignment: .leading)
            }

            Text(formatDate(bundle.createdAt))
                .font(AppFont.tableMetaCell)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 130, alignment: .leading)

            transcribeActionButton(for: bundle)
                .frame(width: 150, alignment: .leading)

            if !isCompact {
                StatusChipView(chip: bundle.avident).frame(width: 110, alignment: .leading)
                StatusChipView(chip: bundle.analyse).frame(width: 100, alignment: .leading)
                StatusChipView(chip: bundle.teams).frame(width: 70, alignment: .leading)
            }
            Text(bundle.slettes.label)
                .font(AppFont.tableMetaCell)
                .foregroundStyle(StatusChipView.foreground(bundle.slettes.tone))
                .frame(width: 70, alignment: .leading)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, 6)
        .background(
            isSelected
                ? AppColors.accent.opacity(0.12)
                : Color.clear
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            guard bundle.isTranscribed else { return }
            openWindow(id: "transcript-editor", value: bundle.id)
        }
        .onTapGesture {
            selectedRecording = recordingsManager.recordings.first { $0.id == bundle.id }
        }
        .hoverCursor()
        .help(bundle.isTranscribed ? "Dobbeltklikk for å åpne i editor" : bundle.displayName)
        .contextMenu {
            Button(role: .destructive) {
                if let item = recordingsManager.recordings.first(where: { $0.id == bundle.id }) {
                    recordingsManager.deleteRecording(item)
                    if selectedRecording?.id == bundle.id {
                        selectedRecording = nil
                    }
                }
            } label: {
                Label("Slett opptak", systemImage: "trash")
            }
        }
    }

    // MARK: - Transcription action button

    /// Every pill click selects the row first so the right-pane player
    /// follows whatever the user just acted on (start a transcription,
    /// open the editor, or cancel an in-flight run). Without this, a
    /// click on the pill would start work on a recording that the user
    /// can't see in the detail pane — confusing, and led to users
    /// pressing Transkriber twice from two different surfaces.
    private func selectRow(_ id: UUID) {
        selectedRecording = recordingsManager.recordings.first { $0.id == id }
    }

    @ViewBuilder
    private func transcribeActionButton(for bundle: RecordingStatusBundle) -> some View {
        let isRunning = transcriptionRunner.inFlight.contains(bundle.id)
        let p = transcriptionRunner.progress[bundle.id] ?? 0

        if isRunning {
            RunningPill(progress: p) {
                selectRow(bundle.id)
                transcriptionRunner.cancel(recordingId: bundle.id)
            }
            .help("Avbryt transkripsjon")
        } else if bundle.isTranscribed {
            Button("Åpne") {
                selectRow(bundle.id)
                openWindow(id: "transcript-editor", value: bundle.id)
            }
            .buttonStyle(PillButtonStyle(variant: .secondary))
            .help("Åpne transkripsjon i editor")
        } else {
            Button("Transkriber") {
                selectRow(bundle.id)
                transcriptionRunner.start(recordingId: bundle.id)
            }
            .buttonStyle(PillButtonStyle(variant: .primary))
            .help("Start transkripsjon")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "tray")
                .font(AppFont.iconEmptyState)
                .foregroundStyle(.secondary.opacity(0.6))
            if activeFilter != .alle {
                Text("Ingen opptak i dette filteret")
                    .font(AppFont.bodyMedium)
                Button("Vis alle") { activeFilter = .alle }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .hoverCursor()
            } else {
                Text("Ingen opptak ennå")
                    .font(AppFont.bodyMedium)
                Text("Bruk «Ta opp lyd» for å starte ditt første opptak.")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Derived data

    private var filteredBundles: [RecordingStatusBundle] {
        bundles
            .filter { activeFilter.matches($0) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Reload

    private func reload() {
        projectConfigured = AppStateStore.load().currentProject != nil
        let metas = RecordingStore.shared.loadAll()
        let allAnalyses = AnalysisStore.shared.loadAll()

        bundles = metas.map { meta in
            let mine = allAnalyses.filter { analysis in
                analysis.sources.contains { $0.recordingId == meta.id }
            }
            return RecordingStatusBundle.make(
                meta: meta,
                analyses: mine,
                projectConfigured: projectConfigured
            )
        }
    }

    // MARK: - Helpers

    private func playIcon(for bundle: RecordingStatusBundle) -> String {
        let url = StorageLayout.audioURL(id: bundle.id)
        let isCurrent = audioPlayer.currentPlayingURL == url
        return (isCurrent && audioPlayer.isPlaying) ? "pause.circle.fill" : "play.circle.fill"
    }

    private func playPreview(_ bundle: RecordingStatusBundle) {
        let url = StorageLayout.audioURL(id: bundle.id)
        if audioPlayer.currentPlayingURL == url {
            audioPlayer.togglePlayPause()
        } else {
            audioPlayer.play(url: url)
        }
    }

    private func formatDuration(_ seconds: Double?) -> String {
        guard let s = seconds, s > 0 else { return "—" }
        let total = Int(s)
        let hours = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        }
        return String(format: "%d:%02d", mins, secs)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Placeholder bundle for SwiftUI previews / silence-warning helper

private extension RecordingStatusBundle {
    static var placeholder: RecordingStatusBundle {
        RecordingStatusBundle(
            id: UUID(),
            displayName: "",
            createdAt: Date(),
            durationSeconds: nil,
            transcript: StatusChip(label: "—", tone: .neutral),
            avident: StatusChip(label: "—", tone: .neutral),
            analyse: StatusChip(label: "—", tone: .neutral),
            teams: StatusChip(label: "—", tone: .neutral),
            slettes: StatusChip(label: "—", tone: .neutral),
            isTranscribed: false,
            venterAvident: false,
            klarForTeams: false,
            utløperSnart: false,
            daysUntilExpiry: 0
        )
    }
}
