import SwiftUI
import ADHOUSEDCore
#if canImport(WidgetKit)
import WidgetKit
#endif

struct ThemeColorCustomizerSheet: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.dismiss) private var dismiss

    let preset: ThemePreset
    @Bindable var prefs: ADHOUSEDPreferences

    @State private var draft: ThemeColorOverrides = ThemeColorOverrides()
    @State private var didLoad: Bool = false

    private let accentQuickSwatches: [String] = [
        "#7AA2F7", "#CBA6F7", "#9ECE6A", "#88C0D0",
        "#EBBCBA", "#FAB387", "#F7768E", "#5E8C71",
        "#488A73", "#D8A657", "#00F0FF", "#E08D3C"
    ]

    private let backgroundQuickSwatches: [String] = [
        "#0E0E10", "#1A1B26", "#1E1E2E", "#1F1F28",
        "#252C2A", "#2E3440", "#F6F4EF", "#F3F1EC",
        "#F5F7FA", "#EFF1F5", "#FAF4ED", "#1E1D2B"
    ]

    private var effectivePreviewScheme: ColorScheme {
        ADHOUSEDThemeTokens.effectiveColorScheme(
            preset: preset,
            preference: prefs.colorSchemePreference,
            systemColorScheme: systemColorScheme
        )
    }

    private var baseTokens: ADHOUSEDThemeTokens {
        ADHOUSEDThemeTokens.resolve(
            preset: preset,
            colorScheme: effectivePreviewScheme,
            overrides: ThemeColorOverrides()
        )
    }

    private var previewTokens: ADHOUSEDThemeTokens {
        ADHOUSEDThemeTokens.resolve(
            preset: preset,
            colorScheme: effectivePreviewScheme,
            overrides: draft
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                previewTokens.canvasBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        livePreviewSection
                        accentColorsCard
                        surfaceAndTextColorsCard
                        statusColorsCard
                        shapeFontAndIconCard

                        if draft.hasAnyCustomization {
                            Button(role: .destructive) {
                                HapticsEngine.shared.playMechanicalTap()
                                draft = ThemeColorOverrides()
                                persistDraft()
                            } label: {
                                HStack {
                                    Spacer()
                                    Label("Reset \(preset.shortLabel) to Default Colors", systemImage: "arrow.counterclockwise")
                                        .font(.subheadline.weight(.bold))
                                    Spacer()
                                }
                                .padding(.vertical, 13)
                            }
                            .adhousedCard(compact: true)
                        }

                        Spacer(minLength: 28)
                    }
                    .padding(18)
                }
            }
            .environment(\.adhousedTheme, previewTokens)
            .fontDesign(previewTokens.fontDesign)
            .navigationTitle("Customize \(preset.shortLabel)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(prefs.themePreset == preset ? "Done" : "Use Theme") {
                        prefs.selectThemePreset(preset)
                        persistDraft()
                        dismiss()
                    }
                    .fontWeight(.heavy)
                }
            }
            .onAppear {
                guard !didLoad else { return }
                didLoad = true
                draft = prefs.colorOverrides(for: preset)
            }
        }
    }

    // MARK: - 1. Live Interactive Preview Card

    private var livePreviewSection: some View {
        let p = previewTokens
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LIVE PREVIEW · \(preset.title.uppercased())")
                        .font(.system(size: 10.5, weight: .heavy, design: p.fontDesign))
                        .tracking(0.8)
                        .foregroundStyle(p.secondaryInk)
                    Text("Changes save automatically to this theme")
                        .font(.caption2)
                        .foregroundStyle(p.secondaryInk)
                }
                Spacer()
                if prefs.themePreset != preset {
                    Button("Activate Theme") {
                        HapticsEngine.shared.playMechanicalTap()
                        prefs.selectThemePreset(preset)
                        persistDraft()
                    }
                    .font(.caption.weight(.heavy))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(p.accentPrimary))
                    .foregroundStyle(p.onAccentPrimary)
                    .buttonStyle(.plain)
                }
            }

            // Live Hero Lettering + Sample Chore Card Preview
            VStack(alignment: .leading, spacing: 11) {
                DimensionalHeroTitleView(
                    title: preset.shortLabel,
                    subtitle: "Live typography & icon preview",
                    lineLimit: 1
                )

                Divider()

                HStack(spacing: 12) {
                    ChoreIconBadgeView(
                        iconSymbol: preset.isOmarchyQuattroStyle ? "omarchy:dishes" : "dishwasher.fill",
                        tint: p.accentPrimary,
                        size: 42
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Load or unload dishwasher")
                            .themeFont(.cardTitle, in: p)
                            .foregroundStyle(p.primaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Kitchen · ~5 min · Easy · Reminds every 1 hr")
                            .themeFont(.caption, in: p)
                            .foregroundStyle(p.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 4)
                }

                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Done")
                    }
                    .font(.caption.weight(.heavy))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: p.pillCornerRadius, style: .continuous)
                            .fill(p.accentPrimary)
                    )
                    .foregroundStyle(p.onAccentPrimary)

                    HStack(spacing: 4) {
                        Circle().fill(p.freshColor).frame(width: 8, height: 8)
                        Text("Done")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(p.primaryInk)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(p.canvasSecondary))

                    HStack(spacing: 4) {
                        Circle().fill(p.dueNowColor).frame(width: 8, height: 8)
                        Text("Due Today")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(p.primaryInk)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(p.canvasSecondary))
                }
            }
            .padding(14)
            .adhousedCard(highlightTint: p.accentPrimary)
        }
    }

    // MARK: - 2. Accent Colors

    private var accentColorsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ACCENT & BUTTON COLORS")
                .font(.caption.weight(.heavy))
                .foregroundStyle(previewTokens.secondaryInk)

            colorCustomizationRow(
                title: "Primary Accent",
                subtitle: "Main buttons, active pills & highlights",
                currentColor: previewTokens.accentPrimary,
                isCustomized: draft.accentPrimaryHex != nil,
                onPick: { newColor in
                    draft.accentPrimaryHex = newColor.toHexString()
                    persistDraft()
                },
                onReset: {
                    draft.accentPrimaryHex = nil
                    persistDraft()
                }
            )

            // Quick Palette Swatches for Primary Accent
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(accentQuickSwatches, id: \.self) { hex in
                        let selected = draft.accentPrimaryHex?.uppercased() == hex.uppercased()
                        Button {
                            HapticsEngine.shared.playMechanicalTap()
                            draft.accentPrimaryHex = hex
                            persistDraft()
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 28, height: 28)
                                .overlay {
                                    Circle()
                                        .strokeBorder(selected ? previewTokens.primaryInk : .white.opacity(0.25), lineWidth: selected ? 2.5 : 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            Divider()

            colorCustomizationRow(
                title: "Secondary Accent",
                subtitle: "Partner badges, custom tags & gradient pair",
                currentColor: previewTokens.accentSecondary,
                isCustomized: draft.accentSecondaryHex != nil,
                onPick: { newColor in
                    draft.accentSecondaryHex = newColor.toHexString()
                    persistDraft()
                },
                onReset: {
                    draft.accentSecondaryHex = nil
                    persistDraft()
                }
            )
        }
        .padding(15)
        .adhousedCard()
    }

    // MARK: - 3. Background, Card & Text Colors

    private var surfaceAndTextColorsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BACKGROUND, CARDS & TEXT")
                .font(.caption.weight(.heavy))
                .foregroundStyle(previewTokens.secondaryInk)

            colorCustomizationRow(
                title: "Screen Background",
                subtitle: "Main canvas color behind cards",
                currentColor: previewTokens.canvasBackground,
                isCustomized: draft.canvasBackgroundHex != nil,
                onPick: { newColor in
                    draft.canvasBackgroundHex = newColor.toHexString()
                    persistDraft()
                },
                onReset: {
                    draft.canvasBackgroundHex = nil
                    persistDraft()
                }
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(backgroundQuickSwatches, id: \.self) { hex in
                        let selected = draft.canvasBackgroundHex?.uppercased() == hex.uppercased()
                        Button {
                            HapticsEngine.shared.playMechanicalTap()
                            draft.canvasBackgroundHex = hex
                            persistDraft()
                        } label: {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 26)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .strokeBorder(selected ? previewTokens.accentPrimary : previewTokens.borderInk, lineWidth: selected ? 2.2 : 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            Divider()

            colorCustomizationRow(
                title: "Card Surface",
                subtitle: "Chore cards and containers",
                currentColor: previewTokens.cardSurface,
                isCustomized: draft.cardSurfaceHex != nil,
                onPick: { newColor in
                    draft.cardSurfaceHex = newColor.toHexString()
                    persistDraft()
                },
                onReset: {
                    draft.cardSurfaceHex = nil
                    persistDraft()
                }
            )

            Divider()

            colorCustomizationRow(
                title: "Primary Text Color",
                subtitle: "Headings and chore titles",
                currentColor: previewTokens.primaryInk,
                isCustomized: draft.primaryInkHex != nil,
                onPick: { newColor in
                    draft.primaryInkHex = newColor.toHexString()
                    persistDraft()
                },
                onReset: {
                    draft.primaryInkHex = nil
                    persistDraft()
                }
            )
        }
        .padding(15)
        .adhousedCard()
    }

    // MARK: - 4. Status Colors

    private var statusColorsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CHORE STATUS COLORS")
                .font(.caption.weight(.heavy))
                .foregroundStyle(previewTokens.secondaryInk)

            colorCustomizationRow(
                title: "Completed / Good Color",
                subtitle: "Freshly finished chores & checkmarks",
                currentColor: previewTokens.freshColor,
                isCustomized: draft.freshColorHex != nil,
                onPick: { newColor in
                    draft.freshColorHex = newColor.toHexString()
                    persistDraft()
                },
                onReset: {
                    draft.freshColorHex = nil
                    persistDraft()
                }
            )

            Divider()

            colorCustomizationRow(
                title: "Due Today / Attention Color",
                subtitle: "Due indicators and overdue badges",
                currentColor: previewTokens.dueNowColor,
                isCustomized: draft.dueNowColorHex != nil,
                onPick: { newColor in
                    draft.dueNowColorHex = newColor.toHexString()
                    persistDraft()
                },
                onReset: {
                    draft.dueNowColorHex = nil
                    persistDraft()
                }
            )
        }
        .padding(15)
        .adhousedCard()
    }

    // MARK: - 5. Shape, Typography & Icon Pack Style

    private var shapeFontAndIconCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SHAPE, FONT & ICON FLAVOR")
                .font(.caption.weight(.heavy))
                .foregroundStyle(previewTokens.secondaryInk)

            VStack(alignment: .leading, spacing: 6) {
                Text("Card Corner Style")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(previewTokens.primaryInk)

                Picker("Corner Style", selection: $draft.cornerStyle) {
                    ForEach(ThemeCornerOverride.allCases) { opt in
                        Text(opt.title).tag(opt)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: draft.cornerStyle) { _, _ in persistDraft() }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Typography")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(previewTokens.primaryInk)

                Picker("Font Style", selection: $draft.fontStyle) {
                    ForEach(ThemeFontOverride.allCases) { opt in
                        Text(opt.title).tag(opt)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: draft.fontStyle) { _, _ in persistDraft() }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Header Display Lettering")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(previewTokens.primaryInk)

                Picker("Header Lettering", selection: $prefs.displayLetteringStyle) {
                    ForEach(DisplayLetteringStyle.allCases) { opt in
                        Text(opt.title).tag(opt)
                    }
                }
                .pickerStyle(.segmented)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("App-Wide Chore Icon Style")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(previewTokens.primaryInk)

                ForEach(IconStylePreference.allCases) { stylePref in
                    let active = prefs.iconStylePreference == stylePref
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        prefs.iconStylePreference = stylePref
                    } label: {
                        HStack(spacing: 12) {
                            ChoreIconBadgeView(
                                iconSymbol: "dishwasher.fill",
                                tint: previewTokens.accentPrimary,
                                size: 36,
                                styleOverride: stylePref == .autoTheme ? nil : stylePref
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(stylePref.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(previewTokens.primaryInk)
                                Text(stylePref.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(previewTokens.secondaryInk)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Image(systemName: active ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(active ? previewTokens.accentPrimary : previewTokens.secondaryInk)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(active ? previewTokens.accentPrimary.opacity(0.14) : previewTokens.canvasSecondary)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(15)
        .adhousedCard()
    }

    // MARK: - Reusable Color Picker Row

    private func colorCustomizationRow(
        title: String,
        subtitle: String,
        currentColor: Color,
        isCustomized: Bool,
        onPick: @escaping (Color) -> Void,
        onReset: @escaping () -> Void
    ) -> some View {
        let colorBinding = Binding<Color>(
            get: { currentColor },
            set: { newVal in onPick(newVal) }
        )

        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(previewTokens.primaryInk)
                    if isCustomized {
                        Text("CUSTOM")
                            .font(.system(size: 8.5, weight: .black))
                            .foregroundStyle(previewTokens.onAccentPrimary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(previewTokens.accentPrimary))
                    }
                }
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(previewTokens.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            if isCustomized {
                Button("Reset") {
                    HapticsEngine.shared.playMechanicalTap()
                    onReset()
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(previewTokens.secondaryInk)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule().fill(previewTokens.canvasSecondary))
                .buttonStyle(.plain)
            }

            ColorPicker("", selection: colorBinding, supportsOpacity: false)
                .labelsHidden()
        }
    }

    private func persistDraft() {
        prefs.setColorOverrides(draft, for: preset)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
