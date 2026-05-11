// AnalysisResultDetailView.swift
// AudioRecordingManager
//
// Column-3 view for a selected analysis. Shows the header (title, kind,
// model, sources, prompt template, createdAt), a stale banner if any
// source transcript has drifted since the run, the structured result
// sections, and actions (re-run / slett / kopier).
//
// `AnalysisResultView.swift` (sheet-style) remains in place but is no
// longer wired into the navigation tree; future cleanup may remove it.

import SwiftUI

struct AnalysisResultDetailView: View {
    let analysis: Analysis
    @Binding var selectedAnalysisId: UUID?

    @State private var staleSourceIds: Set<UUID> = []
    @State private var showDeleteConfirm = false
    @State private var rerunTask: Task<Void, Never>?
    @State private var rerunState: RerunState = .idle

    private enum RerunState: Equatable {
        case idle
        case running
        case failed(String)
    }

    private var result: AnalysisResult? {
        AnalysisStore.shared.loadResult(id: analysis.id)
    }

    private var template: PromptTemplate? {
        guard let id = analysis.promptTemplateId else { return nil }
        return PromptTemplateLibrary.shared.template(id: id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                header
                staleBanner
                statusBanner
                if let result = result {
                    sections(for: result)
                } else if analysis.status == .running {
                    pendingPlaceholder
                } else if analysis.status == .failed {
                    failedPlaceholder
                } else {
                    pendingPlaceholder
                }
                Spacer(minLength: AppSpacing.xxl)
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: 900, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { refreshStaleness() }
        .onChange(of: analysis.id) { _, _ in refreshStaleness() }
        .toolbar { toolbarContent }
        .confirmationDialog(
            "Slett denne analysen?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Slett", role: .destructive) { performDelete() }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Manifest, prompt og resultat blir slettet permanent. Kildetranskripsjonene berøres ikke.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(analysis.title)
                .font(.title2.weight(.semibold))
                .textSelection(.enabled)

            HStack(spacing: AppSpacing.lg) {
                Label(analysis.model, systemImage: "cpu")
                Label(analysis.kind == .group ? "Gruppeanalyse" : "Enkeltanalyse",
                      systemImage: analysis.kind == .group ? "person.3.fill" : "person.fill")
                Label("\(analysis.sources.count) " + (analysis.sources.count == 1 ? "intervju" : "intervjuer"),
                      systemImage: "doc.text")
                if let template = template {
                    Label(template.displayName, systemImage: "doc.badge.gearshape")
                } else if let templateId = analysis.promptTemplateId {
                    Label(templateId, systemImage: "doc.badge.gearshape")
                }
                Spacer()
                if let date = analysis.completedAt ?? analysis.startedAt {
                    Text(formattedTimestamp(date))
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !analysis.sources.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(analysis.sources.enumerated()), id: \.element.recordingId) { (index, src) in
                        HStack(spacing: 6) {
                            Text("Intervju \(index + 1):")
                                .foregroundStyle(.secondary)
                            Text(src.displayName)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            if staleSourceIds.contains(src.recordingId) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.orange)
                                    .help("Transkripsjonen er endret etter denne analysen ble kjørt.")
                            }
                        }
                        .font(.system(size: 11))
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    // MARK: - Banners

    @ViewBuilder
    private var staleBanner: some View {
        if !staleSourceIds.isEmpty {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                Text("En eller flere transkripsjoner er endret etter denne analysen ble kjørt. Kjør på nytt for oppdatert resultat.")
                    .font(.caption)
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .fill(Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(Color.orange.opacity(0.4), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch rerunState {
        case .idle:
            EmptyView()
        case .running:
            HStack(spacing: AppSpacing.sm) {
                ProgressView().controlSize(.small)
                Text("Kjører på nytt …")
                    .font(.caption)
                Spacer()
                Button("Avbryt", role: .destructive) { rerunTask?.cancel() }
                    .buttonStyle(.bordered)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .fill(Color.gray.opacity(0.08))
            )
        case .failed(let msg):
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppColors.destructive)
                Text(msg)
                    .font(.caption)
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .fill(AppColors.destructive.opacity(0.08))
            )
        }
    }

    // MARK: - Sections

    private func sections(for result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            if !result.keyThemes.isEmpty {
                section(title: sectionTitle(for: .keyThemes), icon: "tag.fill", items: result.keyThemes)
            }
            if !result.keyQuotes.isEmpty {
                section(title: sectionTitle(for: .keyQuotes), icon: "quote.bubble.fill", items: result.keyQuotes)
            }
            if !result.identifiedNeeds.isEmpty {
                section(title: sectionTitle(for: .identifiedNeeds), icon: "lightbulb.fill", items: result.identifiedNeeds)
            }
            if !result.opportunities.isEmpty {
                section(title: sectionTitle(for: .opportunities), icon: "arrow.up.right.circle.fill", items: result.opportunities)
            }
            if result.keyThemes.isEmpty && result.keyQuotes.isEmpty
                && result.identifiedNeeds.isEmpty && result.opportunities.isEmpty
            {
                rawFallback(result.rawMarkdown)
            }
        }
    }

    private func section(title: String, icon: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)
            ForEach(items.indices, id: \.self) { idx in
                HStack(alignment: .top, spacing: 8) {
                    Text("•").foregroundStyle(.secondary)
                    Text(items[idx])
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(Color.gray.opacity(0.04))
        )
    }

    private func rawFallback(_ markdown: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Rå modellrespons", systemImage: "doc.plaintext")
                .font(.headline)
            Text(markdown)
                .font(.body)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(Color.gray.opacity(0.04))
        )
    }

    /// Template-aware section titles. Bundled templates carry their own
    /// Norwegian section labels in their bodies, but the parser keys on
    /// the English machine tags — so we map back to Norwegian here based
    /// on which template was used. Falls back to a generic Norwegian
    /// label for custom templates / unknown ids.
    private func sectionTitle(for tag: SectionTag) -> String {
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

    private enum SectionTag { case keyThemes, keyQuotes, identifiedNeeds, opportunities }

    // MARK: - Placeholders

    private var pendingPlaceholder: some View {
        HStack(spacing: AppSpacing.sm) {
            ProgressView().controlSize(.small)
            Text("Resultat venter — analysen er ikke ferdig.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(AppSpacing.md)
    }

    private var failedPlaceholder: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColors.destructive)
            VStack(alignment: .leading, spacing: 4) {
                Text("Analysen feilet").font(.headline)
                if let msg = analysis.errorMessage {
                    Text(msg).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.destructive.opacity(0.08))
        )
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                if analysis.status == .completed {
                    Button { copyMarkdown() } label: { Label("Kopier som markdown", systemImage: "doc.on.doc") }
                    Button { startRerun() } label: { Label("Kjør på nytt", systemImage: "arrow.counterclockwise") }
                    Divider()
                }
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: { Label("Slett analyse", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Actions

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

    private func copyMarkdown() {
        guard let result = result else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result.rawMarkdown, forType: .string)
    }

    private func performDelete() {
        let id = analysis.id
        do {
            try AnalysisStore.shared.delete(id: id)
            selectedAnalysisId = nil
        } catch {
            rerunState = .failed("Sletting feilet: \(error.localizedDescription)")
        }
    }

    /// "Kjør på nytt" clones: same sources + template + model, new
    /// analysis id, new transcript hashes captured now. The previous
    /// analysis stays untouched on disk so the researcher can compare.
    private func startRerun() {
        guard let template = template else {
            rerunState = .failed("Kan ikke kjøre på nytt — malen finnes ikke lenger.")
            return
        }
        rerunState = .running
        rerunTask?.cancel()
        rerunTask = Task {
            do {
                let newId = try await performRerun(template: template)
                await MainActor.run {
                    rerunState = .idle
                    selectedAnalysisId = newId
                }
            } catch is CancellationError {
                await MainActor.run { rerunState = .failed("Avbrutt av bruker.") }
            } catch let err as OllamaAnalysisError {
                await MainActor.run { rerunState = .failed(err.localizedDescription) }
            } catch {
                await MainActor.run { rerunState = .failed(error.localizedDescription) }
            }
        }
    }

    private func performRerun(template: PromptTemplate) async throws -> UUID {
        // Re-read sources with fresh transcript hashes.
        var sources: [AnalysisSource] = []
        var renderedSources: [(displayName: String, text: String)] = []
        for src in analysis.sources {
            let meta = (try? RecordingStore.shared.load(id: src.recordingId)) ?? nil
            let txtURL = StorageLayout.transcriptURL(id: src.recordingId)
            guard let text = try? String(contentsOf: txtURL, encoding: .utf8) else {
                throw NSError(
                    domain: "AnalysisRerun",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Mangler transkripsjon for \(src.displayName)."]
                )
            }
            let displayName = meta?.displayName ?? src.displayName
            let hash = TranscriptHash.hash(text: text)
            sources.append(AnalysisSource(
                recordingId: src.recordingId,
                transcriptHash: hash,
                displayName: displayName
            ))
            renderedSources.append((displayName: displayName, text: text))
        }
        try Task.checkCancellation()

        let context: PromptRenderContext
        switch analysis.kind {
        case .single:
            context = PromptRenderContext(
                researchContext: "",
                kind: .single,
                transcript: renderedSources[0].text,
                concatenatedTranscripts: "",
                interviewCount: 1
            )
        case .group:
            context = PromptRenderContext(
                researchContext: "",
                kind: .group,
                transcript: "",
                concatenatedTranscripts: GroupTranscriptAssembly.concatenate(renderedSources),
                interviewCount: renderedSources.count
            )
        }
        let renderedPrompt = template.render(context: context)

        var clone = Analysis.new(
            kind: analysis.kind,
            sources: sources,
            promptTemplateId: template.id,
            model: analysis.model
        )
        try AnalysisStore.shared.create(clone)
        try AnalysisStore.shared.savePrompt(renderedPrompt, id: clone.id)
        clone.status = .running
        clone.startedAt = Date()
        try AnalysisStore.shared.save(clone)

        try Task.checkCancellation()
        do {
            let result = try await OllamaAnalysisService.shared.analyse(
                prompt: renderedPrompt,
                model: analysis.model
            )
            try AnalysisStore.shared.saveResult(result, id: clone.id)
            clone.status = .completed
            clone.completedAt = Date()
            try AnalysisStore.shared.save(clone)

            AuditLogger.shared.log(.transcriptAnalysed, payload: [
                "analysisId": .string(clone.id.uuidString),
                "kind": .string(clone.kind.rawValue),
                "sourceCount": .int(clone.sources.count),
                "model": .string(clone.model),
                "promptTemplateId": .string(template.id),
                "rerunOf": .string(analysis.id.uuidString),
            ])
            return clone.id
        } catch {
            clone.status = .failed
            clone.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            clone.completedAt = Date()
            try? AnalysisStore.shared.save(clone)
            throw error
        }
    }

    private func formattedTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
