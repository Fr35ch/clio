// DesignShowcaseView.swift
// Clio
//
// ⚠️ DESIGN SURFACE — read `Design/README.md` before editing.
//
// Live "style guide" view — the CSS-equivalent for this app. Renders every
// design token with its actual value so a reader can see what the system
// looks like in light + dark mode without running it through the real UI.
//
// Open with ⌘⇧D from anywhere in the app.

import SwiftUI

struct DesignShowcaseView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    colorsSection
                    Divider()
                    clioSection
                    Divider()
                    typographySection
                    Divider()
                    spacingSection
                    Divider()
                    radiusSection
                    Divider()
                    sizeSection
                    Divider()
                    pillButtonsSection
                    Divider()
                    runningPillSection
                    Divider()
                    statusChipsSection
                    Divider()
                    hoverCursorSection
                }
                .padding(AppSpacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 760, minHeight: 600)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Design System")
                    .font(AppFont.sectionTitle)
                Text("Live preview of every token in Sources/AudioRecordingManager/Design/")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Lukk") { isPresented = false }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Sections

    private var colorsSection: some View {
        section(title: "AppColors", subtitle: "Sources/AudioRecordingManager/Design/DesignTokens.swift") {
            LazyVGrid(columns: gridColumns(min: 180), alignment: .leading, spacing: AppSpacing.md) {
                swatch("accent",                AppColors.accent)
                swatch("accentSubtle",          AppColors.accentSubtle)
                swatch("accentTint",            AppColors.accentTint)
                swatch("accentFill",            AppColors.accentFill)
                swatch("success",               AppColors.success)
                swatch("warning",               AppColors.warning)
                swatch("destructive",           AppColors.destructive)
                swatch("neutralSurface",        AppColors.neutralSurface)
                swatch("neutralSurfaceStrong",  AppColors.neutralSurfaceStrong)
                swatch("neutralBorder",         AppColors.neutralBorder)
                swatch("neutralBorderStrong",   AppColors.neutralBorderStrong)
            }
        }
    }

    private var clioSection: some View {
        section(title: "Clio Design Tokens", subtitle: "Sources/AudioRecordingManager/Design/Color+Clio.swift · Brand Guide v1.0 · Nav Innsikt") {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                clioSwatchGroup("Brand · Primærfarger", [
                    ("clioPurple",   .clioPurple,   "#7C3AED"),
                    ("clioRec",      .clioRec,      "#E91E63"),
                ])
                clioSwatchGroup("Brand · Varmt spekter", [
                    ("clioCoral",    .clioCoral,    "#FF9A8B"),
                    ("clioPeach",    .clioPeach,    "#FFA8A1"),
                    ("clioLavender", .clioLavender, "#F5F3FF"),
                ])
                clioSwatchGroup("Status · Arkivindikatorer (sidebar-dots)", [
                    ("Analysert",    .clioStatusAnalysed,    "#7C3AED"),
                    ("Transkribert", .clioStatusTranscribed, "#28C840"),
                    ("Venter",       .clioStatusPending,     "#FEBC2E"),
                    ("Importert",    .clioStatusImported,    "#3A3A42"),
                ])
                clioSwatchGroup("Tint-overflater", [
                    ("purpleTint",   .clioPurpleTint,   "7C3AED·20%"),
                    ("purpleBorder", .clioPurpleBorder, "7C3AED·35%"),
                    ("recTint",      .clioRecTint,      "E91E63·15%"),
                    ("coralTint",    .clioCoralTint,    "FF9A8B·15%"),
                    ("whiteDim",     .clioWhiteDim,     "FFF·7%"),
                    ("whiteBorder",  .clioWhiteBorder,  "FFF·10%"),
                ])
                clioSwatchGroup("Adaptive tokens (skifter med systemtema)", [
                    ("windowBackground",  .clioWindowBackground,  "adaptiv"),
                    ("surfaceAdaptive",   .clioSurfaceAdaptive,   "adaptiv"),
                    ("contentAdaptive",   .clioContentAdaptive,   "adaptiv"),
                    ("textPrimary",       .clioTextPrimary,       "adaptiv"),
                    ("textSecondary",     .clioTextSecondary,     "adaptiv"),
                    ("border",            .clioBorderColor,       "adaptiv"),
                ])
            }
        }
    }

    private func clioSwatchGroup(_ title: String, _ swatches: [(String, Color, String)]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: gridColumns(min: 130), alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(swatches, id: \.0) { name, color, hex in
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: AppRadius.small)
                            .fill(color)
                            .frame(height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.small)
                                    .strokeBorder(AppColors.neutralBorder, lineWidth: 0.5)
                            )
                        Text(name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(hex)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }


    private var typographySection: some View {
        section(title: "AppFont", subtitle: "Sources/AudioRecordingManager/Design/AppFont.swift") {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                fontRow("screenTitle",        "Bibliotek",                 AppFont.screenTitle)
                fontRow("sectionTitle",       "Design System",             AppFont.sectionTitle)
                fontRow("groupTitle",         "Group title",               AppFont.groupTitle)
                fontRow("body",               "Body copy across the app.", AppFont.body)
                fontRow("bodyMedium",         "Body medium",               AppFont.bodyMedium)
                fontRow("tableCell",          "test_20260509_083233",      AppFont.tableCell)
                fontRow("tableMetaCell",      "May 9, 08:31",              AppFont.tableMetaCell)
                fontRow("tableMonoCell",      "01:23:45",                  AppFont.tableMonoCell)
                fontRow("tableColumnHeader",  "NAVN · DATO · TEAMS",       AppFont.tableColumnHeader)
                fontRow("chipLabel",          "Ikke transkribert (3)",     AppFont.chipLabel)
                fontRow("chipLabelActive",   "Alle (11)",                  AppFont.chipLabelActive)
                fontRow("pillLabel",          "Avbryt · 42 %",             AppFont.pillLabel)
                fontRow("pillPrimary",        "Transkriber",               AppFont.pillPrimary)
                fontRow("caption",            "Helper hint text.",         AppFont.caption)
            }
        }
    }

    private var spacingSection: some View {
        section(title: "AppSpacing", subtitle: "Sources/AudioRecordingManager/Design/DesignTokens.swift") {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                spacingRow("xs",  AppSpacing.xs)
                spacingRow("sm",  AppSpacing.sm)
                spacingRow("md",  AppSpacing.md)
                spacingRow("lg",  AppSpacing.lg)
                spacingRow("xl",  AppSpacing.xl)
                spacingRow("xxl", AppSpacing.xxl)
            }
        }
    }

    private var radiusSection: some View {
        section(title: "AppRadius", subtitle: "Sources/AudioRecordingManager/Design/DesignTokens.swift") {
            HStack(spacing: AppSpacing.lg) {
                radiusBlock("small",  AppRadius.small)
                radiusBlock("medium", AppRadius.medium)
                radiusBlock("large",  AppRadius.large)
                radiusBlock("xlarge", AppRadius.xlarge)
                Spacer()
            }
        }
    }

    private var sizeSection: some View {
        section(title: "AppSize", subtitle: "Sources/AudioRecordingManager/Design/DesignTokens.swift") {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                sizeRow("pill",    width: AppSize.pillWidth,    height: AppSize.pillHeight)
                sizeRow("navItem", width: AppSize.navItemWidth, height: AppSize.navItemHeight)
            }
        }
    }

    private var pillButtonsSection: some View {
        section(title: "PillButtonStyle", subtitle: "Sources/AudioRecordingManager/Design/PillButton.swift") {
            HStack(spacing: AppSpacing.md) {
                Button("Transkriber") {}
                    .buttonStyle(PillButtonStyle(variant: .primary))
                Button("Åpne") {}
                    .buttonStyle(PillButtonStyle(variant: .secondary))
                Spacer()
            }
        }
    }

    private var runningPillSection: some View {
        section(title: "RunningPill", subtitle: "Sources/AudioRecordingManager/Design/PillButton.swift") {
            HStack(spacing: AppSpacing.md) {
                RunningPill(startTime: nil) {}
                RunningPill(startTime: Date().addingTimeInterval(-142), audioDuration: 3600) {}
                Spacer()
            }
        }
    }

    private var statusChipsSection: some View {
        section(title: "StatusChipView", subtitle: "Sources/AudioRecordingManager/Design/StatusChipView.swift") {
            HStack(spacing: AppSpacing.sm) {
                StatusChipView(chip: .init(label: "—",            tone: .neutral))
                StatusChipView(chip: .init(label: "Klar",         tone: .info))
                StatusChipView(chip: .init(label: "Ferdig",       tone: .success))
                StatusChipView(chip: .init(label: "Venter",       tone: .warning))
                StatusChipView(chip: .init(label: "Feilet",       tone: .danger))
                Spacer()
            }
        }
    }

    private var hoverCursorSection: some View {
        section(title: ".hoverCursor()", subtitle: "Sources/AudioRecordingManager/Design/HoverCursor.swift") {
            Text("Hover over the rectangle below — cursor changes to a pointing hand.")
                .font(AppFont.body)
                .foregroundStyle(.secondary)
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.neutralSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .strokeBorder(AppColors.neutralBorder, lineWidth: 1)
                )
                .frame(width: 280, height: 56)
                .overlay(Text("Hover me").font(AppFont.body))
                .hoverCursor()
                .padding(.top, AppSpacing.sm)
        }
    }

    // MARK: - Section helper

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppFont.groupTitle)
                Text(subtitle).font(AppFont.caption).foregroundStyle(.secondary)
            }
            content()
        }
    }

    private func gridColumns(min: CGFloat) -> [GridItem] {
        [GridItem(.adaptive(minimum: min, maximum: .infinity), spacing: AppSpacing.md, alignment: .leading)]
    }

    // MARK: - Item renderers

    private func swatch(_ name: String, _ color: Color) -> some View {
        HStack(spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: AppRadius.small)
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.small)
                        .strokeBorder(AppColors.neutralBorder, lineWidth: 1)
                )
            Text(name)
                .font(AppFont.tableCell)
                .lineLimit(1)
        }
    }

    private func fontRow(_ name: String, _ sample: String, _ font: Font) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.lg) {
            Text(name)
                .font(AppFont.tableMonoCell)
                .foregroundStyle(.secondary)
                .frame(width: 170, alignment: .leading)
            Text(sample).font(font)
            Spacer()
        }
    }

    private func spacingRow(_ name: String, _ value: CGFloat) -> some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            Text(name)
                .font(AppFont.tableMonoCell)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            Text("\(Int(value)) pt")
                .font(AppFont.tableMonoCell)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            Rectangle()
                .fill(AppColors.accent.opacity(0.4))
                .frame(width: value, height: 18)
            Spacer()
        }
    }

    private func radiusBlock(_ name: String, _ value: CGFloat) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: value)
                .fill(AppColors.neutralSurfaceStrong)
                .overlay(
                    RoundedRectangle(cornerRadius: value)
                        .strokeBorder(AppColors.neutralBorder, lineWidth: 1)
                )
                .frame(width: 72, height: 56)
            Text("\(name) (\(Int(value)))")
                .font(AppFont.tableMonoCell)
                .foregroundStyle(.secondary)
        }
    }

    private func sizeRow(_ name: String, width: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: AppSpacing.md) {
            Text(name)
                .font(AppFont.tableMonoCell)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text("\(Int(width)) × \(Int(height)) pt")
                .font(AppFont.tableMonoCell)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            RoundedRectangle(cornerRadius: AppRadius.medium)
                .fill(AppColors.accentTint)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium)
                        .strokeBorder(AppColors.accent.opacity(0.4), lineWidth: 1)
                )
                .frame(width: width, height: height)
            Spacer()
        }
    }
}
