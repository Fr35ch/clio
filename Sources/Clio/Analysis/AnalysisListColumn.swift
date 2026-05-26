// AnalysisListColumn.swift
// Clio
//
// Column 2 of the Analyser tab — the list of past analyses, newest first,
// plus a persistent "Ny analyse" header that deselects the current
// analysis and surfaces the composer in column 3.
//
// Without the header button there's no way back to the composer from a
// completed analysis except switching tabs and back. The button is the
// primary navigation affordance for "I'm done reading this result, I
// want to start another."

import SwiftUI

struct AnalysisListColumn: View {
    @Binding var selectedAnalysisId: UUID?
    @ObservedObject private var store = AnalysisStore.shared
    @State private var analyses: [Analysis] = []
    @State private var pendingDelete: Analysis? = nil

    var body: some View {
        VStack(spacing: 0) {
            newAnalysisHeader

            if analyses.isEmpty {
                ContentUnavailableView(
                    "Ingen analyser ennå",
                    systemImage: "brain.head.profile",
                    description: Text("Bruk komponer-visningen til høyre for å starte en analyse.")
                )
                .frame(maxHeight: .infinity)
            } else {
                List(selection: $selectedAnalysisId) {
                    ForEach(analyses) { analysis in
                        AnalysisListRow(analysis: analysis)
                            .tag(analysis.id)
                            .contextMenu {
                                Button(role: .destructive) {
                                    pendingDelete = analysis
                                } label: {
                                    Label("Slett analyse", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .onAppear { reload() }
        .onChange(of: store.changeToken) { _, _ in reload() }
        .alert(
            "Slett analyse?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            presenting: pendingDelete
        ) { analysis in
            Button("Slett", role: .destructive) {
                performDelete(analysis)
            }
            Button("Avbryt", role: .cancel) {}
        } message: { analysis in
            Text("«\(analysis.title)» blir slettet permanent. Kildetranskripsjonene berøres ikke.")
        }
    }

    private func performDelete(_ analysis: Analysis) {
        do {
            try AnalysisStore.shared.delete(id: analysis.id)
            if selectedAnalysisId == analysis.id {
                selectedAnalysisId = nil
            }
        } catch {
            print("⚠️ Could not delete analyse \(analysis.id.uuidString): \(error)")
        }
    }

    /// Always-visible header at the top of the column. Clicking it nulls
    /// `selectedAnalysisId`, which flips column 3 from the result detail
    /// back to the composer. Highlighted when the composer is the active
    /// surface so the researcher sees "they are here".
    private var newAnalysisHeader: some View {
        let isComposerActive = selectedAnalysisId == nil
        return Button {
            selectedAnalysisId = nil
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.body)
                Text("Ny analyse")
                    .font(.clioSubMedium)
                Spacer()
                if isComposerActive {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + 2)
            .background {
                if isComposerActive {
                    RoundedRectangle(cornerRadius: AppRadius.small)
                        .fill(AppColors.accent.opacity(0.15))
                } else {
                    Color.clear
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isComposerActive ? .primary : AppColors.accent)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xs)
    }

    private func reload() {
        analyses = AnalysisStore.shared.loadAll()
    }
}

/// One row in the analyses list. Compact — title, kind icon, model, source
/// count, relative createdAt.
private struct AnalysisListRow: View {
    let analysis: Analysis

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: analysis.kind == .group ? "person.3.fill" : "person.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(analysis.title)
                    .font(.clioSubMedium)
                    .lineLimit(1)
            }
            HStack(spacing: 6) {
                Text(analysis.model)
                Text("·")
                Text("\(analysis.sources.count) " + (analysis.sources.count == 1 ? "intervju" : "intervjuer"))
                Spacer()
                statusBadge
            }
            .font(.clioLabelSmall)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch analysis.status {
        case .pending, .running:
            Text(analysis.status == .running ? "Kjører" : "Venter")
                .font(.system(size: 10))
                .foregroundStyle(AppColors.warning)
        case .completed:
            EmptyView()
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.caption2)
        }
    }
}
