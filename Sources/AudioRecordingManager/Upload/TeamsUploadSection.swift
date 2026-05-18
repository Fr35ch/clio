// TeamsUploadSection.swift
// AudioRecordingManager
//
// Upload widget shown in RecordingDetailView's right panel after transcription.
// Renders all precondition-blocked states, the "Last opp" action, uploading
// progress, success, and failure states.
//
// Always visible; shows an informative blocked state when no transcript exists.

import SwiftUI

struct TeamsUploadSection: View {

    let recording: RecordingMeta
    let projects: [ProjectConfig]
    /// Called when the researcher assigns a project or saves a neutral code.
    let onMetaChanged: (RecordingMeta) -> Void
    /// Called when the compliance checklist is confirmed for a project.
    let onProjectUpdated: (ProjectConfig) -> Void

    @StateObject private var uploadService = TeamsUploadService.shared
    @State private var showComingSoonAlert = false
    @State private var showSignOffAlert = false
    @State private var signOffConfirmed = false
    @State private var showConfirmationSheet = false
    @State private var showComplianceSheet = false
    @State private var pendingProject: ProjectConfig?
    @State private var neutralCodeInput: String = ""

    private var readiness: UploadReadiness {
        UploadGate.evaluate(recording: recording, projects: projects)
    }

    var body: some View {
        sectionBody
            .alert("Funksjonen kommer snart", isPresented: $showComingSoonAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Opplasting til Teams er under utvikling og vil være tilgjengelig i en kommende versjon.")
            }
            .alert("Bekreft avidentifisering", isPresented: $showSignOffAlert) {
                Button("Bekreft", role: .none) { confirmSignOff() }
                Button("Avbryt", role: .cancel) {}
            } message: {
                Text("Jeg bekrefter at transkripsjonen er avidentifisert og ikke inneholder personidentifiserbare opplysninger.")
            }
            .sheet(isPresented: $showConfirmationSheet) {
                confirmationSheet
            }
            .sheet(isPresented: $showComplianceSheet) {
                complianceSheet
            }
    }

    // MARK: - State machine

    @ViewBuilder
    private var sectionBody: some View {
        let r = readiness
        if case .uploading = r {
            uploadingView
        } else if case .alreadyUploaded(let uploadedAt, let remoteName) = r {
            uploadedView(uploadedAt: uploadedAt, remoteName: remoteName)
        } else if case .uploadFailed(let project, let remoteName) = r {
            failedView(project: project, remoteName: remoteName)
        } else if case .ready(let project, let remoteName) = r {
            readyView(project: project, remoteName: remoteName)
        } else if case .blockedNoTranscript = r {
            blockedView(
                icon: "waveform.and.mic",
                iconColor: .secondary,
                title: "Ingen transkripsjon",
                message: "Transkriber opptaket for å aktivere opplasting til Teams.",
                actionLabel: nil,
                action: nil
            )
        } else if case .blockedNotConfirmed(let armToolRan) = r {
            signOffView(armToolRan: armToolRan)
        } else if case .blockedNoNeutralCode = r {
            neutralCodeInputView
        } else if case .blockedNoProjectAssigned(let available) = r {
            projectPickerView(available: available)
        } else if case .blockedProjectNotFound = r {
            blockedView(
                icon: "exclamationmark.triangle",
                iconColor: AppColors.warning,
                title: "Prosjekt ikke funnet",
                message: "Det tilknyttede prosjektet finnes ikke lenger. Tilknytt opptaket til et eksisterende prosjekt.",
                actionLabel: nil,
                action: nil
            )
        } else if case .blockedNoProjectConfig(let project) = r {
            blockedView(
                icon: "gear.badge.questionmark",
                iconColor: AppColors.warning,
                title: "Prosjektet er ikke ferdig konfigurert",
                message: "«\(project.projectName)» mangler Teams-kanal. Gå til innstillinger for å fullføre konfigurasjonen.",
                actionLabel: nil,
                action: nil
            )
        } else if case .blockedComplianceNotConfirmed(let project) = r {
            blockedView(
                icon: "checkmark.shield",
                iconColor: AppColors.accent,
                title: "Krav ikke bekreftet",
                message: "Du må bekrefte at kravene i NAV-rutinen er oppfylt før første opplasting for «\(project.projectName)».",
                actionLabel: "Se krav",
                action: {
                    pendingProject = project
                    showComplianceSheet = true
                }
            )
        }
    }

    // MARK: - State views

    private func blockedView(
        icon: String,
        iconColor: Color,
        title: String,
        message: String,
        actionLabel: String?,
        action: (() -> Void)?
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let label = actionLabel, let action {
                    Button(label, action: action)
                        .buttonStyle(PillButtonStyle(variant: .secondary))
                        .padding(.top, 4)
                }
            }
        }
    }

    private var neutralCodeInputView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "number.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.warning)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Deltakerkode mangler")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Sett en nøytral deltakerkode (f.eks. D01) for å generere et Teams-filnavn uten personopplysninger.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                TextField("D01", text: $neutralCodeInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .onAppear { neutralCodeInput = recording.neutralCode ?? "" }

                Button("Lagre") {
                    guard !neutralCodeInput.isEmpty else { return }
                    var updated = recording
                    updated.neutralCode = neutralCodeInput.trimmingCharacters(in: .whitespaces)
                    onMetaChanged(updated)
                }
                .buttonStyle(PillButtonStyle(variant: .primary))
                .disabled(neutralCodeInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func projectPickerView(available: [ProjectConfig]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.warning)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Velg prosjekt")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Knytt dette opptaket til et prosjekt for å velge Teams-destinasjon.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if available.isEmpty {
                Text("Ingen prosjekter er konfigurert. Gå til innstillinger for å legge til et prosjekt.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.warning)
            } else {
                Picker("Prosjekt", selection: Binding(
                    get: { recording.projectId },
                    set: { newId in
                        var updated = recording
                        updated.projectId = newId
                        onMetaChanged(updated)
                    }
                )) {
                    Text("Velg prosjekt…").tag(Optional<UUID>.none)
                    ForEach(available) { project in
                        Text(project.projectName).tag(Optional(project.id))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
    }

    private func readyView(project: ProjectConfig, remoteName: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.success)
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.projectName)
                        .font(.system(size: 13, weight: .medium))
                    if let channel = project.studyChannel {
                        Text(channel.displayName)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button("Last opp") {
                showComingSoonAlert = true
            }
            .buttonStyle(PillButtonStyle(variant: .primary))
            .frame(maxWidth: .infinity)
        }
    }

    private func signOffView(armToolRan: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "signature")
                    .foregroundStyle(AppColors.accent)
                    .font(.system(size: 14))
                Text("Bekreft avidentifisering")
                    .font(.system(size: 13, weight: .semibold))
            }
            if armToolRan {
                Text("ARM-verktøyet er brukt. Bekreft at transkripsjonen er ferdig avidentifisert for å låse opp opplasting.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            } else {
                Text("Transkripsjonen må være avidentifisert — enten med ARM-verktøyet eller manuelt — før opplasting til Teams.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Button("Bekreft avidentifisering…") {
                showSignOffAlert = true
            }
            .buttonStyle(PillButtonStyle(variant: .secondary))
            .frame(maxWidth: .infinity)
        }
    }

    private func confirmSignOff() {
        var updated = recording
        updated.anonymization.researcherConfirmedAt = Date()
        AuditLogger.shared.logAnonymizationConfirmedByResearcher(
            recordingId: recording.id,
            armToolUsed: recording.anonymization.status == .done
        )
        onMetaChanged(updated)
    }

    private var uploadingView: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text("Laster opp…")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func uploadedView(uploadedAt: Date, remoteName: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.success)
                Text("Lastet opp")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.success)
            }
            Text(remoteName)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
            Text("Lastet opp \(uploadedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private func failedView(project: ProjectConfig, remoteName: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.destructive)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Opplasting feilet")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Kontroller nettverkstilkobling og prøv igjen.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Button("Prøv igjen") {
                Task {
                    await uploadService.upload(
                        recording: recording,
                        project: project,
                        remoteName: remoteName
                    )
                }
            }
            .buttonStyle(PillButtonStyle(variant: .primary))
        }
    }

    // MARK: - Sheets

    private var confirmationSheet: some View {
        UploadConfirmationSheet(
            recording: recording,
            projects: projects.filter { $0.isConfigured && $0.isComplianceConfirmed }
        ) { project, remoteName in
            showConfirmationSheet = false
            Task {
                await uploadService.upload(
                    recording: recording,
                    project: project,
                    remoteName: remoteName
                )
            }
        } onCancel: {
            showConfirmationSheet = false
        }
    }

    private var complianceSheet: some View {
        Group {
            if let project = pendingProject {
                ComplianceChecklistSheet(project: project) { updatedProject in
                    showComplianceSheet = false
                    pendingProject = nil
                    onProjectUpdated(updatedProject)
                } onCancel: {
                    showComplianceSheet = false
                    pendingProject = nil
                }
            }
        }
    }
}
