// AnalysisListColumn.swift
// AudioRecordingManager
//
// Column 2 of the Analyser tab — the list of past analyses, newest first.
// Selecting a row drives the column-3 detail view via `selectedAnalysisId`.
//
// Phase B1 status: placeholder shell. Reads from `AnalysisStore.shared` so
// the list updates as analyses are created, but lacks the row chrome,
// search, and toolbar affordances that B3 will add.

import SwiftUI

struct AnalysisListColumn: View {
    @Binding var selectedAnalysisId: UUID?
    @ObservedObject private var store = AnalysisStore.shared
    @State private var analyses: [Analysis] = []

    var body: some View {
        Group {
            if analyses.isEmpty {
                ContentUnavailableView(
                    "Ingen analyser ennå",
                    systemImage: "brain.head.profile",
                    description: Text("Velg en eller flere transkripsjoner i komponer-visningen for å starte en analyse.")
                )
            } else {
                List(selection: $selectedAnalysisId) {
                    ForEach(analyses) { analysis in
                        AnalysisListRow(analysis: analysis)
                            .tag(analysis.id)
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .onAppear { reload() }
        .onChange(of: store.changeToken) { _, _ in reload() }
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
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }
            HStack(spacing: 6) {
                Text(analysis.model)
                Text("·")
                Text("\(analysis.sources.count) " + (analysis.sources.count == 1 ? "intervju" : "intervjuer"))
                Spacer()
                statusBadge
            }
            .font(.system(size: 10))
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
                .foregroundStyle(.orange)
        case .completed:
            EmptyView()
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.caption2)
        }
    }
}
