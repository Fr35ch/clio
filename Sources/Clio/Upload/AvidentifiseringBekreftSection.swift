// AvidentifiseringBekreftSection.swift
// Clio
//
// Standalone section for researcher sign-off on de-identification.
// Shown in RecordingDetailView whenever a transcript exists.
// Independent of the Teams upload section — sign-off is a compliance
// step that belongs to the researcher workflow, not the upload workflow.

import SwiftUI

struct AvidentifiseringBekreftSection: View {

    let recording: RecordingMeta
    let onMetaChanged: (RecordingMeta) -> Void

    @State private var showSignOffAlert = false

    private var isConfirmed: Bool {
        recording.anonymization.researcherConfirmedAt != nil
    }

    private var armToolRan: Bool {
        recording.anonymization.status == .done
    }

    var body: some View {
        if isConfirmed {
            confirmedView
        } else {
            pendingView
        }
    }

    // MARK: - Confirmed state

    private var confirmedView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppColors.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("Avidentifisering bekreftet")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.success)
                if let confirmedAt = recording.anonymization.researcherConfirmedAt {
                    Text("Bekreftet \(confirmedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Pending state

    private var pendingView: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: AppRadius.large)
                .fill(AppColors.anonymizerBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.large)
                        .strokeBorder(AppColors.accent.opacity(0.25), lineWidth: 1)
                )

            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.accent)
                .frame(width: 3)
                .padding(.vertical, 10)
                .clipped()

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: armToolRan ? "checkmark.seal.fill" : "lock.shield")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.accent)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Bekreft avidentifisering")
                            .font(.system(size: 13, weight: .semibold))
                        Text(armToolRan ? "ARM-verktøyet er brukt" : "Manuell eller ARM")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(armToolRan
                    ? "Gjennomgå transkripsjonen og bekreft at alle personopplysninger er fjernet."
                    : "Avidentifiser transkripsjonen med ARM-verktøyet eller manuelt, og bekreft før opplasting."
                )
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                Button {
                    showSignOffAlert = true
                } label: {
                    Label("Jeg bekrefter", systemImage: "checkmark")
                }
                .buttonStyle(PillButtonStyle(variant: .primary))
            }
            .padding(.leading, 18)
            .padding(.trailing, 12)
            .padding(.vertical, 12)
        }
        .alert("Bekreft avidentifisering", isPresented: $showSignOffAlert) {
            Button("Bekreft", role: .none) { confirmSignOff() }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Jeg bekrefter at transkripsjonen er avidentifisert og ikke inneholder personidentifiserbare opplysninger.")
        }
    }

    // MARK: - Action

    private func confirmSignOff() {
        var updated = recording
        updated.anonymization.researcherConfirmedAt = Date()
        AuditLogger.shared.logAnonymizationConfirmedByResearcher(
            recordingId: recording.id,
            armToolUsed: recording.anonymization.status == .done
        )
        onMetaChanged(updated)
    }
}
