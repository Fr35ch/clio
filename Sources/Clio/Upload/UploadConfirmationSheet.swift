// UploadConfirmationSheet.swift
// Clio
//
// Shown when the researcher taps "Last opp". Lets the researcher:
//   1. Pick (or confirm) which project to upload to
//   2. See exactly what filename will appear on Teams
//   3. Confirm the anonymization responsibility checkbox
//   4. Read the 8-month Teams retention reminder
//   5. Tap "Bekreft og last opp" to proceed

import SwiftUI

struct UploadConfirmationSheet: View {

    let recording: RecordingMeta
    let projects: [ProjectConfig]
    /// Called with the selected project and remote filename when confirmed.
    let onConfirmed: (ProjectConfig, String) -> Void
    let onCancel: () -> Void

    @State private var selectedProjectId: UUID?
    @State private var anonymizationConfirmed = false

    private var selectedProject: ProjectConfig? {
        projects.first { $0.id == selectedProjectId }
    }

    private var remoteName: String {
        UploadGate.remoteName(displayName: recording.displayName, createdAt: recording.createdAt)
    }

    private var canConfirm: Bool {
        selectedProject != nil && anonymizationConfirmed
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "arrow.up.to.line.circle")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(AppColors.accent)
                Text("Last opp til Teams")
                    .font(AppFont.screenTitle)
            }
            .padding(.top, AppSpacing.xl)
            .padding(.bottom, AppSpacing.lg)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {

                    // Project picker
                    projectPickerSection

                    // File preview
                    filePreviewSection(remoteName: remoteName)

                    // Anonymization confirmation
                    anonymizationSection

                    // Retention warning
                    retentionWarningSection
                }
                .padding(AppSpacing.xl)
            }

            Divider()

            // Actions
            HStack(spacing: AppSpacing.md) {
                Button("Avbryt", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                Button("Bekreft og last opp") {
                    guard let project = selectedProject else { return }
                    onConfirmed(project, remoteName)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canConfirm)
            }
            .padding(AppSpacing.xl)
        }
        .frame(width: 480)
        .onAppear {
            // Pre-select the recording's current project if set and available
            if let projectId = recording.projectId,
               projects.contains(where: { $0.id == projectId }) {
                selectedProjectId = projectId
            } else if projects.count == 1 {
                selectedProjectId = projects[0].id
            }
        }
    }

    // MARK: - Sections

    private var projectPickerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Destinasjon", systemImage: "folder")
                .font(AppFont.pillLabel)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if projects.isEmpty {
                Text("Ingen prosjekter er konfigurert. Gå til innstillinger for å legge til et prosjekt.")
                    .font(AppFont.tableCell)
                    .foregroundStyle(AppColors.warning)
            } else {
                Picker("Velg prosjekt", selection: $selectedProjectId) {
                    Text("Velg prosjekt…").tag(Optional<UUID>.none)
                    ForEach(projects) { project in
                        VStack(alignment: .leading) {
                            Text(project.projectName)
                            if let channel = project.studyChannel {
                                Text(channel.displayName)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(Optional(project.id))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                if let project = selectedProject, let channel = project.studyChannel {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.success)
                            .font(.system(size: 12))
                        Text("Laster opp til: \(channel.displayName)")
                            .font(AppFont.tableCell)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func filePreviewSection(remoteName: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Filnavn på Teams", systemImage: "doc.text")
                .font(AppFont.pillLabel)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(AppColors.accent)
                Text(remoteName)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
            }
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.small)
                    .fill(Color.secondary.opacity(0.08))
            )
        }
    }

    private var anonymizationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Bekreftelse", systemImage: "lock.shield")
                .font(AppFont.pillLabel)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Button {
                anonymizationConfirmed.toggle()
            } label: {
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    Image(systemName: anonymizationConfirmed ? "checkmark.square.fill" : "square")
                        .font(.system(size: 18))
                        .foregroundStyle(anonymizationConfirmed ? AppColors.success : Color.secondary)
                        .animation(.easeInOut(duration: 0.12), value: anonymizationConfirmed)

                    Text("Jeg bekrefter at transkripsjonen er avidentifisert og ikke inneholder personidentifiserbare opplysninger")
                        .font(AppFont.tableCell)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var retentionWarningSection: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 16))
                .foregroundStyle(AppColors.warning)

            VStack(alignment: .leading, spacing: 4) {
                Text("Midlertidig lagring")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.warning)
                Text("Filer på Teams slettes automatisk etter 8 måneder. Teams er midlertidig lagring — ikke et arkiv. Sørg for at materialet er behandlet og arkivert i henhold til prosjektplanen før sletting.")
                    .font(AppFont.tableCell)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.warning.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .stroke(AppColors.warning.opacity(0.25), lineWidth: 1)
                )
        )
    }
}
