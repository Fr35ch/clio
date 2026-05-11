// AnalysisDetailColumn.swift
// AudioRecordingManager
//
// Column 3 of the Analyser tab — switches between the composer (no
// analysis selected) and the result detail (one selected).

import SwiftUI

struct AnalysisDetailColumn: View {
    @Binding var selectedAnalysisId: UUID?
    @ObservedObject private var store = AnalysisStore.shared

    var body: some View {
        Group {
            if let id = selectedAnalysisId,
               let analysis = try? AnalysisStore.shared.load(id: id)
            {
                AnalysisResultDetailView(
                    analysis: analysis,
                    selectedAnalysisId: $selectedAnalysisId
                )
                .id(analysis.id)
            } else {
                AnalysisComposerView(selectedAnalysisId: $selectedAnalysisId)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
