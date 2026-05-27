// TeamsUploadSection.swift
// Clio
//
// Upload widget shown in RecordingDetailView's right panel after transcription.
// Gate: transcript must exist AND researcher must have confirmed de-identification.
// Actual Azure AD / Graph API integration is a separate upcoming phase.

import SwiftUI

struct TeamsUploadSection: View {

    let recording: RecordingMeta

    @StateObject private var uploadService = TeamsUploadService.shared
    @State private var showComingSoonAlert = false

    private var readiness: UploadReadiness {
        UploadGate.evaluate(recording: recording)
    }

    var body: some View {
        sectionBody
            .alert("Funksjonen kommer snart", isPresented: $showComingSoonAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Opplasting til Teams er under utvikling og vil være tilgjengelig i en kommende versjon.")
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
        } else if case .uploadFailed(let remoteName) = r {
            failedView(remoteName: remoteName)
        } else if case .ready(let remoteName) = r {
            readyView(remoteName: remoteName)
        } else if case .blockedNoTranscript = r {
            blockedView(
                icon: "waveform.and.mic",
                iconColor: .secondary,
                title: "Ingen transkripsjon",
                message: "Transkriber opptaket for å aktivere opplasting til Teams."
            )
        } else if case .blockedNotConfirmed = r {
            blockedView(
                icon: "lock.shield",
                iconColor: AppColors.accent,
                title: "Avidentifisering ikke bekreftet",
                message: "Bekreft avidentifisering i seksjonen over for å aktivere opplasting."
            )
        }
    }

    // MARK: - State views

    private func blockedView(
        icon: String,
        iconColor: Color,
        title: String,
        message: String
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
            }
        }
    }

    private func readyView(remoteName: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.success)
                    .font(.system(size: 14))
                Text("Klar for opplasting")
                    .font(.system(size: 13, weight: .medium))
            }
            Text(remoteName)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Button("Last opp til Teams") {
                showComingSoonAlert = true
            }
            .buttonStyle(PillButtonStyle(variant: .primary))
            .frame(maxWidth: .infinity)
        }
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

    private func failedView(remoteName: String) -> some View {
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
                showComingSoonAlert = true
            }
            .buttonStyle(PillButtonStyle(variant: .primary))
        }
    }
}
