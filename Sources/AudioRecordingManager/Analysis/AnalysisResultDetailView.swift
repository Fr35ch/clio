// AnalysisResultDetailView.swift
// AudioRecordingManager
//
// Redesigned for Clio Analysis (see clio/project/Clio Analysis.html).
// Three-zone layout: header strip / scrollable content / right source rail.
// Maps the flat AnalysisResult string arrays into the sectioned card
// layout from the design: numbered pain rows, 2-column needs grid,
// workaround pattern cards, and a collapsible quote rail.

import SwiftUI
import AppKit

// MARK: - Private tone constants

private let painTone    = Color(red: 0.82, green: 0.30, blue: 0.08)
private let patternTone = Color(red: 0.18, green: 0.60, blue: 0.48)

// MARK: - Tab model

private enum AnalysisResultTab: Hashable {
    case all, themes, needs, patterns
}

// MARK: - Main view

struct AnalysisResultDetailView: View {
    let analysis: Analysis
    /// Called when the user taps "Ny iterasjon" — wired by the parent
    /// to navigate back to the composer.
    var onNewIteration: (() -> Void)? = nil

    @State private var staleSourceIds: Set<UUID> = []
    @State private var activeTab: AnalysisResultTab = .all

    private var result: AnalysisResult? {
        AnalysisStore.shared.loadResult(id: analysis.id)
    }

    private var template: PromptTemplate? {
        guard let id = analysis.promptTemplateId else { return nil }
        return PromptTemplateLibrary.shared.template(id: id)
    }

    // Template-aware section titles
    private var themesTitle:   String { sectionTitle(for: .keyThemes) }
    private var needsTitle:    String { sectionTitle(for: .identifiedNeeds) }
    private var patternsTitle: String { sectionTitle(for: .opportunities) }

    var body: some View {
        VStack(spacing: 0) {
            headerStrip
            Divider()
            HStack(spacing: 0) {
                mainScroll
                Divider()
                AnalysisSourceRail(analysis: analysis, staleSourceIds: staleSourceIds)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.windowBackground)
        .onAppear { refreshStaleness() }
        .onChange(of: analysis.id) { _, _ in refreshStaleness() }
    }

    // MARK: - Header strip

    private var headerStrip: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Row 1: title + status badge + action buttons
            HStack(alignment: .center, spacing: AppSpacing.sm) {
                Text(analysis.title)
                    .font(.clioH1)
                    .lineLimit(1)
                    .textSelection(.enabled)
                AnalysisStatusBadge(status: analysis.status)
                Spacer()
                HStack(spacing: AppSpacing.xs) {
                    Button { copyToClipboard() } label: {
                        Label("Kopier", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)

                    Button { exportResult() } label: {
                        Label("Eksporter", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)

                    Button { onNewIteration?() } label: {
                        Label("Ny iterasjon", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.accent)
                    .controlSize(.small)
                }
                .font(.clioSubMedium)
            }

            // Row 2: meta chips + timestamp
            HStack(spacing: AppSpacing.xs) {
                AnalysisMetaChip(icon: "cpu", text: analysis.model)
                AnalysisMetaChip(
                    icon: analysis.kind == .group ? "person.3.fill" : "person.fill",
                    text: analysis.kind == .group ? "Gruppeanalyse" : "Enkeltanalyse"
                )
                AnalysisMetaChip(
                    icon: "doc.text",
                    text: "\(analysis.sources.count) \(analysis.sources.count == 1 ? "intervju" : "intervjuer")"
                )
                if let t = template {
                    AnalysisMetaChip(icon: "doc.badge.gearshape", text: t.displayName)
                } else if let tid = analysis.promptTemplateId {
                    AnalysisMetaChip(icon: "doc.badge.gearshape", text: tid)
                }
                Spacer()
                if let date = analysis.completedAt ?? analysis.startedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "clock").font(.system(size: 10))
                        Text("Generert \(formattedTimestamp(date))")
                    }
                    .font(.clioCaption)
                    .foregroundStyle(AppColors.textSecondary)
                }
            }

            // Row 3: stale banner (only when sources have drifted)
            if !staleSourceIds.isEmpty {
                staleBanner
            }
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.lg)
        .padding(.bottom, AppSpacing.md)
    }

    private var staleBanner: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(AppColors.warning)
            Text("En eller flere transkripsjoner er endret etter denne analysen ble kjørt. Kjør på nytt for oppdatert resultat.")
                .font(.clioCaption)
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.warning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .stroke(AppColors.warning.opacity(0.4), lineWidth: 1)
                )
        )
    }

    // MARK: - Main scroll

    private var mainScroll: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if let result = result {
                    kpiStrip(for: result)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.top, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.md)
                    tabBar(for: result)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.lg)
                    resultSections(for: result)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.xxl)
                } else if analysis.status == .running || analysis.status == .pending {
                    runningPlaceholder
                        .padding(AppSpacing.xl)
                } else if analysis.status == .failed {
                    failedPlaceholder
                        .padding(AppSpacing.xl)
                } else {
                    runningPlaceholder
                        .padding(AppSpacing.xl)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - KPI strip

    private func kpiStrip(for result: AnalysisResult) -> some View {
        HStack(spacing: AppSpacing.sm) {
            AnalysisKPICard(label: themesTitle,   count: result.keyThemes.count,       tone: painTone)
            AnalysisKPICard(label: needsTitle,    count: result.identifiedNeeds.count, tone: AppColors.accent)
            AnalysisKPICard(label: patternsTitle, count: result.opportunities.count,   tone: patternTone)
            AnalysisKPICard(label: "Sitater",     count: result.keyQuotes.count,       tone: AppColors.textSecondary)
        }
    }

    // MARK: - Tab bar

    private func tabBar(for result: AnalysisResult) -> some View {
        HStack(spacing: 2) {
            AnalysisTabButton(label: "Alt",         count: nil,                          active: activeTab == .all)      { activeTab = .all }
            AnalysisTabButton(label: themesTitle,   count: result.keyThemes.count,       active: activeTab == .themes)   { activeTab = .themes }
            AnalysisTabButton(label: needsTitle,    count: result.identifiedNeeds.count, active: activeTab == .needs)    { activeTab = .needs }
            AnalysisTabButton(label: patternsTitle, count: result.opportunities.count,   active: activeTab == .patterns) { activeTab = .patterns }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.neutralSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .stroke(AppColors.neutralBorder, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Result sections

    @ViewBuilder
    private func resultSections(for result: AnalysisResult) -> some View {
        let showThemes   = activeTab == .all || activeTab == .themes
        let showNeeds    = activeTab == .all || activeTab == .needs
        let showPatterns = activeTab == .all || activeTab == .patterns

        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            if showThemes, !result.keyThemes.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    AnalysisSectionTitle(
                        icon: "flag.fill", tone: painTone,
                        title: themesTitle, count: result.keyThemes.count,
                        subtitle: "Konkrete frustrasjoner og blokkere brukerne opplever"
                    )
                    Divider().padding(.bottom, 2)
                    ForEach(result.keyThemes.indices, id: \.self) { i in
                        AnalysisPainRow(
                            index: i + 1,
                            text: result.keyThemes[i],
                            relatedQuote: i < result.keyQuotes.count ? result.keyQuotes[i] : nil
                        )
                        if i < result.keyThemes.count - 1 {
                            Divider().opacity(0.45)
                        }
                    }
                }
            }

            if showNeeds, !result.identifiedNeeds.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    AnalysisSectionTitle(
                        icon: "lightbulb.fill", tone: AppColors.accent,
                        title: needsTitle, count: result.identifiedNeeds.count,
                        subtitle: "Det brukerne egentlig prøver å oppnå"
                    )
                    AnalysisNeedsGrid(needs: result.identifiedNeeds)
                }
            }

            if showPatterns, !result.opportunities.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    AnalysisSectionTitle(
                        icon: "bolt.fill", tone: patternTone,
                        title: patternsTitle, count: result.opportunities.count,
                        subtitle: "Hva brukerne gjør i dag for å komme rundt smertene"
                    )
                    AnalysisPatternsList(patterns: result.opportunities)
                }
            }

            // Remaining quotes when "Alt" tab and not already shown inline
            if activeTab == .all, !result.keyQuotes.isEmpty {
                let remaining = result.keyQuotes.dropFirst(result.keyThemes.count)
                if !remaining.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        AnalysisSectionTitle(
                            icon: "quote.bubble.fill", tone: AppColors.textSecondary,
                            title: "Nøkkelsitater", count: remaining.count,
                            subtitle: "Direkte sitater fra intervjumaterialet"
                        )
                        ForEach(remaining.indices, id: \.self) { i in
                            AnalysisQuoteRow(text: remaining[i])
                        }
                    }
                }
            }

            if result.keyThemes.isEmpty && result.identifiedNeeds.isEmpty
                && result.opportunities.isEmpty {
                rawFallback(result.rawMarkdown)
            }
        }
    }

    // MARK: - Raw fallback

    private func rawFallback(_ markdown: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Rå modellrespons", systemImage: "doc.plaintext")
                .font(.clioH2)
            Text(markdown)
                .clioAnalysisBody()
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(Color.gray.opacity(0.04))
        )
    }

    // MARK: - Placeholders

    private var runningPlaceholder: some View {
        HStack(spacing: AppSpacing.sm) {
            ProgressView().controlSize(.small)
            Text(analysis.status == .running ? "Analysen kjører…" : "Resultat venter — analysen er ikke ferdig.")
                .font(.clioCaption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
    }

    private var failedPlaceholder: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColors.destructive)
            VStack(alignment: .leading, spacing: 4) {
                Text("Analysen feilet").font(.clioSubMedium)
                if let msg = analysis.errorMessage {
                    Text(msg).font(.clioCaption).foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.destructive.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .stroke(AppColors.destructive.opacity(0.3), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Section title helper

    private func sectionTitle(for tag: SectionTagLocal) -> String {
        switch (analysis.promptTemplateId, tag) {
        case ("group-cross-cutting-patterns-v1", .keyThemes):       return "Felles mønstre"
        case ("group-cross-cutting-patterns-v1", .opportunities):   return "Avvik og divergenser"
        case ("group-cross-cutting-patterns-v1", .identifiedNeeds): return "Felles behov"
        case ("pain-points-and-frustrations-v1", .keyThemes):       return "Smertepunkter"
        case ("pain-points-and-frustrations-v1", .identifiedNeeds): return "Bakenforliggende behov"
        case ("pain-points-and-frustrations-v1", .opportunities):   return "Mønstre i workarounds"
        case ("opportunity-map-v1", .keyThemes):                    return "Datadrevne muligheter"
        case ("opportunity-map-v1", .keyQuotes):                    return "Sitater som forankrer mulighetene"
        case ("opportunity-map-v1", .identifiedNeeds):              return "Brukerbehov som muligheter dekker"
        case ("opportunity-map-v1", .opportunities):                return "Spekulative muligheter"
        default:
            switch tag {
            case .keyThemes:       return "Hovedtemaer"
            case .keyQuotes:       return "Nøkkelsitater"
            case .identifiedNeeds: return "Identifiserte behov"
            case .opportunities:   return "Muligheter"
            }
        }
    }

    private enum SectionTagLocal { case keyThemes, keyQuotes, identifiedNeeds, opportunities }

    // MARK: - Staleness detection

    private func refreshStaleness() {
        var stale: Set<UUID> = []
        for src in analysis.sources {
            let txtURL = StorageLayout.transcriptURL(id: src.recordingId)
            guard let currentHash = TranscriptHash.hash(of: txtURL) else { continue }
            if currentHash != src.transcriptHash {
                stale.insert(src.recordingId)
            }
        }
        staleSourceIds = stale
    }

    // MARK: - Actions

    private func copyToClipboard() {
        let text = AnalysisStore.shared.loadResult(id: analysis.id)?.rawMarkdown ?? analysis.title
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func exportResult() {
        guard let result = AnalysisStore.shared.loadResult(id: analysis.id) else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = analysis.title + ".md"
        panel.allowedContentTypes = [.plainText]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? result.rawMarkdown.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func formattedTimestamp(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: date)
    }
}

// MARK: - AnalysisStatusBadge

private struct AnalysisStatusBadge: View {
    let status: AnalysisStatus

    var body: some View {
        Group {
            switch status {
            case .completed:
                badge(
                    label: "Fullført",
                    dot: .init(red: 0.20, green: 0.72, blue: 0.45),
                    fg:  .init(red: 0.12, green: 0.48, blue: 0.30),
                    bg:  .init(red: 0.88, green: 0.97, blue: 0.91),
                    bd:  .init(red: 0.65, green: 0.88, blue: 0.74)
                )
            case .running:
                HStack(spacing: 5) {
                    ProgressView().controlSize(.mini)
                    Text("Kjører")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.warning)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(AppColors.warning.opacity(0.10))
                        .overlay(Capsule().stroke(AppColors.warning.opacity(0.30), lineWidth: 0.5))
                )
            case .pending:
                badge(
                    label: "Venter",
                    dot: AppColors.textSecondary,
                    fg:  AppColors.textSecondary,
                    bg:  AppColors.neutralSurface,
                    bd:  AppColors.neutralBorder
                )
            case .failed:
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.circle.fill").font(.system(size: 9))
                    Text("Feilet")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.destructive)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(AppColors.destructive.opacity(0.10))
                        .overlay(Capsule().stroke(AppColors.destructive.opacity(0.30), lineWidth: 0.5))
                )
            }
        }
    }

    private func badge(label: String, dot: Color, fg: Color, bg: Color, bd: Color) -> some View {
        HStack(spacing: 5) {
            Circle().fill(dot).frame(width: 6, height: 6)
            Text(label)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(fg)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(
            Capsule()
                .fill(bg)
                .overlay(Capsule().stroke(bd, lineWidth: 0.5))
        )
    }
}

// MARK: - AnalysisMetaChip

private struct AnalysisMetaChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10))
            Text(text).font(.system(size: 11.5))
        }
        .foregroundStyle(AppColors.textSecondary)
        .padding(.horizontal, AppSpacing.sm).padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(AppColors.neutralSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.small)
                        .stroke(AppColors.neutralBorder, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - AnalysisKPICard

private struct AnalysisKPICard: View {
    let label: String
    let count: Int
    let tone: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(AppColors.textSecondary)
            Text("\(count)")
                .font(.system(size: 22, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(tone)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.surfaceAdaptive)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .stroke(AppColors.neutralBorder, lineWidth: 0.5)
                )
        )
    }
}

// MARK: - AnalysisTabButton

private struct AnalysisTabButton: View {
    let label: String
    let count: Int?
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(active ? AppColors.textPrimary : AppColors.textSecondary)
                if let count {
                    Text("\(count)")
                        .font(.system(size: 10.5, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, 5).padding(.vertical, 0.5)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(active ? AppColors.neutralSurface : AppColors.surfaceAdaptive)
                        )
                }
            }
            .padding(.horizontal, AppSpacing.sm + 3).padding(.vertical, 5)
            .background(
                Group {
                    if active {
                        RoundedRectangle(cornerRadius: AppRadius.small)
                            .fill(AppColors.surfaceAdaptive)
                            .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AnalysisSectionTitle

private struct AnalysisSectionTitle: View {
    let icon: String
    let tone: Color
    let title: String
    let count: Int
    let subtitle: String?

    init(icon: String, tone: Color, title: String, count: Int, subtitle: String? = nil) {
        self.icon = icon; self.tone = tone; self.title = title
        self.count = count; self.subtitle = subtitle
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(tone.opacity(0.14))
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(tone)
            }
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .lastTextBaseline, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(.clioH3)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("\(count)")
                        .font(.clioCaption)
                        .monospacedDigit()
                        .foregroundStyle(AppColors.textSecondary)
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            Spacer()
        }
    }
}

// MARK: - AnalysisPainRow

private struct AnalysisPainRow: View {
    let index: Int
    let text: String
    let relatedQuote: String?

    @State private var quoteExpanded = false

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Text(String(format: "%02d", index))
                .font(.system(size: 11, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(AppColors.textSecondary)
                .padding(.top, 1)
                .frame(width: 20, alignment: .trailing)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(text)
                    .font(.clioSub)
                    .foregroundStyle(AppColors.textPrimary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                if let quote = relatedQuote {
                    if quoteExpanded {
                        quoteBlock(quote)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { quoteExpanded.toggle() }
                    } label: {
                        Text(quoteExpanded ? "− Skjul sitat" : "+ Vis sitat")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, AppSpacing.sm + 2)
    }

    private func quoteBlock(_ quote: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "quote.opening")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.accent)
                .padding(.top, 2)
            Text(quote)
                .font(.clioCaption)
                .italic()
                .foregroundStyle(AppColors.textPrimary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppSpacing.sm + 2)
        .padding(.vertical, AppSpacing.xs + 2)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppRadius.small)
                    .fill(AppColors.neutralSurface)
                RoundedRectangle(cornerRadius: AppRadius.small)
                    .stroke(AppColors.neutralBorder, lineWidth: 0.5)
                Rectangle()
                    .fill(AppColors.accent)
                    .frame(width: 2)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: AppRadius.small,
                            bottomLeadingRadius: AppRadius.small
                        )
                    )
            }
        )
    }
}

// MARK: - AnalysisNeedsGrid

private struct AnalysisNeedsGrid: View {
    let needs: [String]

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.sm),
        GridItem(.flexible(), spacing: AppSpacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            ForEach(needs.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(AppColors.accent.opacity(0.12))
                            .frame(width: 24, height: 24)
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SOM BRUKER TRENGER JEG")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.5)
                            .foregroundStyle(AppColors.textSecondary)
                        Text(needs[i])
                            .font(.clioSubMedium)
                            .foregroundStyle(AppColors.textPrimary)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .fill(AppColors.surfaceAdaptive)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.medium)
                                .stroke(AppColors.neutralBorder, lineWidth: 0.5)
                        )
                )
            }
        }
    }
}

// MARK: - AnalysisPatternsList

private struct AnalysisPatternsList: View {
    let patterns: [String]

    var body: some View {
        VStack(spacing: AppSpacing.xs + 2) {
            ForEach(patterns.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(patternTone.opacity(0.12))
                            .frame(width: 24, height: 24)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(patternTone)
                    }
                    Text(patterns[i])
                        .font(.clioSub)
                        .foregroundStyle(AppColors.textPrimary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .fill(AppColors.surfaceAdaptive)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.medium)
                                .stroke(AppColors.neutralBorder, lineWidth: 0.5)
                        )
                )
            }
        }
    }
}

// MARK: - AnalysisQuoteRow

private struct AnalysisQuoteRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "quote.opening")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.accent)
                .padding(.top, 2)
            Text(text)
                .font(.clioSub)
                .italic()
                .foregroundStyle(AppColors.textPrimary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .fill(AppColors.neutralSurface)
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(AppColors.neutralBorder, lineWidth: 0.5)
                Rectangle()
                    .fill(AppColors.accent)
                    .frame(width: 2)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: AppRadius.medium,
                            bottomLeadingRadius: AppRadius.medium
                        )
                    )
            }
        )
    }
}

// MARK: - AnalysisSourceRail

private struct AnalysisSourceRail: View {
    let analysis: Analysis
    let staleSourceIds: Set<UUID>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                railSection(label: "KILDE") {
                    ForEach(Array(analysis.sources.enumerated()), id: \.element.recordingId) { _, src in
                        AnalysisSourceCard(
                            src: src,
                            stale: staleSourceIds.contains(src.recordingId)
                        )
                    }
                }

                railSection(label: "FORSLAG TIL OPPFØLGING") {
                    ForEach(Array(followUpSuggestions.enumerated()), id: \.offset) { i, suggestion in
                        HStack(alignment: .top, spacing: AppSpacing.xs) {
                            Text("\(i + 1)")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundStyle(AppColors.textSecondary)
                                .frame(width: 14, height: 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppColors.neutralSurface)
                                )
                            Text(suggestion)
                                .font(.system(size: 11.5))
                                .foregroundStyle(AppColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs + 2)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.small)
                                .fill(AppColors.surfaceAdaptive)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppRadius.small)
                                        .stroke(AppColors.neutralBorder, lineWidth: 0.5)
                                )
                        )
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.md)
        }
        .frame(width: 252)
        .background(AppColors.windowBackground)
    }

    @ViewBuilder
    private func railSection<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(.clioLabelSmall)
                .tracking(ClioTracking.cardHeader())
                .foregroundStyle(AppColors.textSecondary)
            content()
        }
    }

    private var followUpSuggestions: [String] {
        switch analysis.promptTemplateId {
        case "pain-points-and-frustrations-v1":
            return [
                "Kjør Mulighetskart over samme materiale",
                "Sammenlign med eventuelle gruppeanalyser",
                "Følg opp høyfrekvente smertepunkter i neste intervju"
            ]
        default:
            return [
                "Kjør en ny analyse med annen mal",
                "Eksporter funnene og del med teamet",
                "Planlegg oppfølgingsintervjuer basert på funnene"
            ]
        }
    }
}

// MARK: - AnalysisSourceCard

private struct AnalysisSourceCard: View {
    let src: AnalysisSource
    let stale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppColors.neutralSurface)
                        .frame(width: 22, height: 22)
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textSecondary)
                }
                Text(src.displayName)
                    .font(.clioSubMedium)
                    .lineLimit(1)
                    .foregroundStyle(AppColors.textPrimary)
                if stale {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(AppColors.warning)
                        .font(.caption)
                        .help("Transkripsjonen er endret etter denne analysen ble kjørt.")
                }
            }

            Button {
                // Future: navigate to transcript view for this recording
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.square").font(.system(size: 11))
                    Text("Åpne transkripsjon").font(.system(size: 11.5))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.vertical, AppSpacing.xs + 2)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.small)
                    .fill(AppColors.neutralSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.small)
                            .stroke(AppColors.neutralBorder, lineWidth: 0.5)
                    )
            )
        }
        .padding(AppSpacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.surfaceAdaptive)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .stroke(AppColors.neutralBorder, lineWidth: 0.5)
                )
        )
    }
}
