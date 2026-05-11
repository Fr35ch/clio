// AnonymizationSectionView.swift
// AudioRecordingManager
//
// De-identification (avidentifisering) state machine + UI for the
// transcript editor. Runs the upstream `no-anonymizer` BERT NER on the
// saved transcript, post-processes the redaction set against the user's
// global exception list (see `AppState.avidentExceptions`), persists the
// resulting text to disk, and surfaces both the original and the
// de-identified versions side-by-side via a tab switch.
//
// Terminology note: file/class names retain `Anonymization` for back-
// compat with audit logs and existing call sites; all user-visible
// strings use "avidentifisering" because that is what we actually do —
// we remove direct identifiers but keep the audio on disk, so the data
// remains personal data under GDPR. True anonymisation would be
// irreversible.
//
// State machine: idle → running → completed | failed → idle (on re-run)
// Persistence: `transcript_avidentifisert.txt` (legacy filename kept as
// `transcript_anonymized.txt` for back-compat — see `StorageLayout`).
//
// Implements US-T12 (run from editor), US-A3 (compare original vs
// de-identified — was previously unimplemented).

import SwiftUI

private enum AnonymizationState: Equatable {
    case idle
    case running
    case completed(date: Date, stats: [String: Int])
    case failed(String)
}

private enum CompareTab: String, CaseIterable {
    case original
    case avidentifisert
}

struct AnonymizationSectionView: View {
    let recordingId: UUID
    let isDirty: Bool

    @State private var state: AnonymizationState = .idle
    @State private var task: Task<Void, Never>?
    @State private var showConsentModal = false
    @State private var showExceptionsSheet = false
    @State private var compareTab: CompareTab = .avidentifisert

    private let whatIsRemoved = [
        "Navn på personer",
        "Telefonnumre og e-postadresser",
        "Fødselsnumre og d-numre",
        "Steds- og organisasjonsnavn (via NER)",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            headerRow

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                switch state {
                case .idle:
                    idleView
                case .running:
                    runningView
                case .completed(let date, let stats):
                    completedView(date: date, stats: stats)
                case .failed(let error):
                    failedView(error: error)
                }
            }
            .padding(AppSpacing.lg)
            .background(Color.gray.opacity(0.04))
            .cornerRadius(AppRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.large)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showConsentModal) {
            AnonymizationModal(isPresented: $showConsentModal, onConfirm: runAnonymization)
        }
        .sheet(isPresented: $showExceptionsSheet) {
            AvidentExceptionsView(isPresented: $showExceptionsSheet)
        }
        .onAppear { loadExistingState() }
    }

    // MARK: - Header row (section label + manage-exceptions affordance)

    private var headerRow: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            Text("Avidentifisering")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
            Button {
                showExceptionsSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Administrer unntak")
                }
                .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Rediger globale unntak som ikke skal fjernes ved avidentifisering")
        }
    }

    // MARK: - States

    private var idleView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Button { showConsentModal = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled")
                    Text("Avidentifiser transkripsjon")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.destructive)
            .disabled(isDirty)
            .help(isDirty ? "Lagre endringer før avidentifisering" : "")

            VStack(alignment: .leading, spacing: 6) {
                Text("Hva som fjernes:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                ForEach(whatIsRemoved, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.warning)
                            .padding(.top, 1)
                        Text(item)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text("Avidentifisering fjerner direkte identifikatorer. Dataene forblir personopplysninger så lenge lydopptaket er bevart — dette er ikke fullstendig anonymisering.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var runningView: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("Avidentifiserer …")
                    .font(.system(size: 14, weight: .medium))
            }
            .frame(maxWidth: .infinity)

            Text("NLP-modellen lastes ved første kjøring – dette kan ta noen sekunder.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Button {
                task?.cancel()
                task = nil
                state = .idle
            } label: {
                Text("Avbryt")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
        }
    }

    private func completedView(date: Date, stats: [String: Int]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(AppColors.success)
                Text("Avidentifisert \(date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.success)
                Spacer()
            }

            if !stats.isEmpty {
                Text(statsSummary(stats))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            compareTabBar
            compareTabContent

            Button { showConsentModal = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Kjør på nytt")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .disabled(isDirty)
            .help(isDirty ? "Lagre endringer før ny avidentifisering" : "")
        }
    }

    private func failedView(error: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppColors.destructive)
                Text("Feil ved avidentifisering")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.destructive)
            }

            Text(error)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button { showConsentModal = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Prøv igjen")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Compare view (US-A3)

    private var compareTabBar: some View {
        HStack(spacing: 0) {
            tabButton(.original, label: "Original")
            tabButton(.avidentifisert, label: "Avidentifisert")
            Spacer()
        }
    }

    private func tabButton(_ tab: CompareTab, label: String) -> some View {
        Button {
            compareTab = tab
        } label: {
            Text(label)
                .font(.system(size: 12, weight: compareTab == tab ? .semibold : .regular))
                .foregroundStyle(compareTab == tab ? .primary : .secondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm - 2)
                .background(
                    compareTab == tab
                        ? AppColors.accent.opacity(0.10)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: AppRadius.small)
                )
        }
        .buttonStyle(.plain)
    }

    private func currentTabPayload() -> (text: String, emptyHint: String) {
        switch compareTab {
        case .original:
            return (loadOriginalText() ?? "", "Fant ingen original transkripsjon.")
        case .avidentifisert:
            return (loadAnonymizedText() ?? "", "Fant ingen avidentifisert versjon på disk.")
        }
    }

    @ViewBuilder
    private var compareTabContent: some View {
        let payload = currentTabPayload()
        if payload.text.isEmpty {
            Text(payload.emptyHint)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.vertical, AppSpacing.sm)
        } else {
            ScrollView {
                Text(payload.text)
                    .font(.system(size: 12))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(AppSpacing.sm)
            }
            .frame(minHeight: 200, maxHeight: 380)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
            .cornerRadius(AppRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.small)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
    }

    // MARK: - Logic

    private func loadExistingState() {
        do {
            if let meta = try RecordingStore.shared.load(id: recordingId),
               meta.anonymization.status == .done,
               let date = meta.anonymization.completedAt {
                state = .completed(date: date, stats: meta.anonymization.stats ?? [:])
            }
        } catch {}
    }

    private func loadOriginalText() -> String? {
        try? String(contentsOf: StorageLayout.transcriptURL(id: recordingId), encoding: .utf8)
    }

    private func loadAnonymizedText() -> String? {
        try? String(contentsOf: StorageLayout.anonymizedTranscriptURL(id: recordingId), encoding: .utf8)
    }

    private func runAnonymization() {
        let txtURL = StorageLayout.transcriptURL(id: recordingId)
        guard let text = try? String(contentsOf: txtURL, encoding: .utf8),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state = .failed("Ingen transkripsjon funnet å avidentifisere")
            return
        }

        // Load global exceptions at run-time so freshly-edited list
        // applies without needing to recreate this view.
        let exceptions = AppStateStore.load().avidentExceptions

        state = .running
        task = Task { @MainActor in
            do {
                let raw = try await AnonymizationService.shared.anonymize(transcript: text)
                guard !Task.isCancelled else { return }

                // Apply user's global exception list (post-processing —
                // upstream no-anonymizer doesn't take exceptions natively).
                let result = raw.applying(exceptions: exceptions, to: text)

                // 1. Write de-identified text
                let anonURL = StorageLayout.anonymizedTranscriptURL(id: recordingId)
                try result.anonymizedText.write(to: anonURL, atomically: true, encoding: .utf8)

                // 2. Update sidecar
                _ = try RecordingStore.shared.updateMeta(id: recordingId) { meta in
                    meta.anonymization.status = .done
                    meta.anonymization.completedAt = Date()
                    meta.anonymization.filename = "transcript_anonymized.txt"
                    meta.anonymization.stats = result.stats
                }

                // 3. Audit (keep legacy event name for log back-compat)
                AuditLogger.shared.log(.transcriptAnonymized, payload: [
                    "recordingId": .string(recordingId.uuidString),
                    "stats": .string(statsSummary(result.stats)),
                    "exceptionCount": .int(exceptions.count),
                ])

                state = .completed(date: Date(), stats: result.stats)
                compareTab = .avidentifisert
            } catch let error as AnonymizationError {
                guard !Task.isCancelled else { return }
                state = .failed(error.errorDescription ?? "Ukjent feil")
            } catch {
                guard !Task.isCancelled else { return }
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func statsSummary(_ stats: [String: Int]) -> String {
        let parts = stats.compactMap { (key, count) -> String? in
            guard count > 0 else { return nil }
            switch key {
            case "NAVN": return "\(count) navn"
            case "TELEFON": return "\(count) telefonnummer"
            case "FØDSELSNUMMER": return "\(count) fødselsnummer"
            case "D-NUMMER": return "\(count) d-nummer"
            case "EPOST": return "\(count) e-postadresse"
            case "ORG": return "\(count) organisasjon"
            case "STED": return "\(count) stedsnavn"
            default: return "\(count) \(key.lowercased())"
            }
        }
        if parts.isEmpty { return "Ingen identifiserende informasjon funnet" }
        return parts.joined(separator: ", ") + " fjernet"
    }
}
