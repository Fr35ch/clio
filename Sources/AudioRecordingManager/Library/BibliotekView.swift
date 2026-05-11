// BibliotekView.swift
// AudioRecordingManager
//
// "Bibliotek" — the canonical library view of every recording in the
// app. Replaces the card-row RecordingsListColumn in the recordings
// tab's column 2. Implements US-R13–R18:
//
//   - Title + summary stats (N opptak · M transkribert · K analysert)
//   - Search by displayName
//   - Sort menu (newest / oldest / name / expiry soonest)
//   - Filter chip row with counts independent of search
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
    @Binding var selectedRecording: RecordingItem?
    /// `true` when column 3 is visible (a recording is selected); the
    /// table compresses to play + name + date + a single urgency chip.
    /// `false` when column 3 is hidden; the full status pipeline shows.
    let isCompact: Bool

    @State private var searchText: String = ""
    @State private var activeFilter: BibliotekFilter = .alle
    @State private var sort: BibliotekSort = .newestFirst
    @State private var bundles: [RecordingStatusBundle] = []
    @State private var projectConfigured: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
            filterChipsRow
            expiryBanner
            Divider()
            tableArea
                .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { reload() }
        .onChange(of: recordingsManager.recordings) { _, _ in reload() }
        .onChange(of: analysisStore.changeToken) { _, _ in reload() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bibliotek")
                    .font(.system(size: 28, weight: .semibold))
                Text(summaryLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            Spacer()
            searchField
            sortMenu
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

    private var searchField: some View {
        HStack(spacing: 4) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Søk i alle opptak …", text: $searchText)
                .textFieldStyle(.plain)
                .frame(width: 220)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
    }

    private var sortMenu: some View {
        Menu {
            ForEach(BibliotekSort.allCases) { option in
                Button {
                    sort = option
                } label: {
                    HStack {
                        Text(option.label)
                        if sort == option {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("Sorter")
                Image(systemName: "arrow.down")
            }
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
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
        let count = filter.matches(bundles.first ?? .placeholder) ? 0 : 0  // recomputed below
        _ = count  // silence warning; real value via helper
        let n = bundles.filter { filter.matches($0) }.count
        let tone = isActive ? filter.tone : ChipTone.neutral

        return Button {
            activeFilter = filter
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(chipForegroundColor(tone))
                    .frame(width: 6, height: 6)
                Text("\(filter.label) (\(n))")
                    .font(.system(size: 12, weight: isActive ? .medium : .regular))
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(chipBackgroundColor(tone, active: isActive))
            )
            .overlay(
                Capsule()
                    .stroke(chipForegroundColor(tone).opacity(isActive ? 0 : 0.3), lineWidth: 1)
            )
            .foregroundStyle(isActive ? chipForegroundColor(tone) : .primary)
        }
        .buttonStyle(.plain)
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
                    .font(.system(size: 12))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button {
                    activeFilter = .utløperSnart
                } label: {
                    HStack(spacing: 4) {
                        Text("Vis dem")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
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

    private var tableArea: some View {
        Group {
            if filteredBundles.isEmpty {
                emptyState
            } else {
                tableHeader
                Divider()
                tableRows
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("").frame(width: 32, alignment: .leading)
            columnHeader("NAVN", width: nil, alignment: .leading)
            if !isCompact {
                columnHeader("VARIGH.", width: 70, alignment: .leading)
            }
            columnHeader("DATO", width: 130, alignment: .leading)
            if !isCompact {
                columnHeader("TRANSKR.", width: 120, alignment: .leading)
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
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                    .frame(width: width, alignment: alignment)
            } else {
                Text(text)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                    .frame(maxWidth: .infinity, alignment: alignment)
            }
        }
    }

    private var tableRows: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredBundles) { bundle in
                    rowView(bundle)
                    Divider().padding(.leading, AppSpacing.lg)
                }
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
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help("Spill av")

            Text(bundle.displayName)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !isCompact {
                Text(formatDuration(bundle.durationSeconds))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: 70, alignment: .leading)
            }

            Text(formatDate(bundle.createdAt))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 130, alignment: .leading)

            if !isCompact {
                chipView(bundle.transcript).frame(width: 120, alignment: .leading)
                chipView(bundle.avident).frame(width: 110, alignment: .leading)
                chipView(bundle.analyse).frame(width: 100, alignment: .leading)
                chipView(bundle.teams).frame(width: 70, alignment: .leading)
            }
            chipView(bundle.slettes).frame(width: 70, alignment: .leading)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, 6)
        .background(
            isSelected
                ? AppColors.accent.opacity(0.12)
                : Color.clear
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedRecording = recordingsManager.recordings.first { $0.id == bundle.id }
        }
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

    // MARK: - Chip rendering

    private func chipView(_ chip: StatusChip) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(chipForegroundColor(chip.tone))
                .frame(width: 6, height: 6)
            Text(chip.label)
                .font(.system(size: 11))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(chipBackgroundColor(chip.tone, active: false))
        )
        .overlay(
            Capsule()
                .stroke(chipForegroundColor(chip.tone).opacity(0.4), lineWidth: 1)
        )
        .foregroundStyle(chipForegroundColor(chip.tone))
    }

    private func chipForegroundColor(_ tone: ChipTone) -> Color {
        switch tone {
        case .neutral: return .secondary
        case .info:    return AppColors.accent
        case .success: return AppColors.success
        case .warning: return AppColors.warning
        case .danger:  return AppColors.destructive
        }
    }

    private func chipBackgroundColor(_ tone: ChipTone, active: Bool) -> Color {
        let base = chipForegroundColor(tone)
        return active ? base.opacity(0.15) : base.opacity(0.08)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary.opacity(0.6))
            if !searchText.isEmpty {
                Text("Ingen treff for «\(searchText)»")
                    .font(.system(size: 14, weight: .medium))
                Button("Tøm søk") { searchText = "" }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            } else if activeFilter != .alle {
                Text("Ingen opptak i dette filteret")
                    .font(.system(size: 14, weight: .medium))
                Button("Vis alle") { activeFilter = .alle }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            } else {
                Text("Ingen opptak ennå")
                    .font(.system(size: 14, weight: .medium))
                Text("Bruk «Ta opp lyd» for å starte ditt første opptak.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Derived data

    private var filteredBundles: [RecordingStatusBundle] {
        let filtered = bundles.filter { activeFilter.matches($0) }
        let searched: [RecordingStatusBundle]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searched = filtered
        } else {
            let needle = searchText.lowercased()
            searched = filtered.filter { $0.displayName.lowercased().contains(needle) }
        }
        return sort.apply(to: searched)
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
