import SwiftUI
import SwiftData
import ADHOUSEDCore
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(UIKit)
import UIKit
#endif

struct HouseholdAndThemeSettingsView: View {
    @Environment(\.adhousedTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var households: [Household]
    @Query(sort: \HouseholdMember.sortOrder) private var members: [HouseholdMember]
    @Query private var tasks: [ChoreTask]

    @Bindable var session: AppSessionViewModel
    @Bindable var prefs: ADHOUSEDPreferences

    @State private var customizingPreset: ThemePreset? = nil
    @State private var showingPartnerSharing: Bool = false
    @State private var statusBannerMessage: String? = nil
    @State private var currentAlternateIconName: String? = nil

    private let appIconChoices: [(iconName: String?, label: String, previewBg: String, previewAccent: String)] = [
        (nil, "Default", "#232530", "#65D496"),
        ("AppIconOmarchyTokyo", "Tokyo Night", "#1A1B26", "#7AA2F7"),
        ("AppIconOmarchyCatppuccin", "Catppuccin", "#1E1E2E", "#CBA6F7"),
        ("AppIconOmarchyMatte", "Matte Black", "#0E0E10", "#55D197"),
        ("AppIconQuietLinen", "Quiet Linen", "#F6F4EF", "#5E8C71")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                theme.canvasBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if let msg = statusBannerMessage {
                            Text(msg)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.primaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .adhousedCard(highlightTint: theme.accentPrimary, compact: true)
                        }

                        partnerAndCloudSummaryCard
                        quietAndLayoutSection
                        themeStudioGallerySection
                        iconFlavorAndAppIconSection
                        vacationAndBreakSection
                        daytimeReminderWindowSection
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Themes, Icons & Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.heavy)
                }
            }
            .sheet(item: $customizingPreset) { preset in
                ThemeColorCustomizerSheet(preset: preset, prefs: prefs)
                    .preferredColorScheme(theme.isDark ? .dark : .light)
            }
            .sheet(isPresented: $showingPartnerSharing) {
                PartnerSharingSheet(session: session, prefs: prefs)
                    .fontDesign(theme.fontDesign)
                    .environment(\.adhousedTheme, theme)
                    .preferredColorScheme(theme.isDark ? .dark : .light)
            }
            .onAppear {
                #if canImport(UIKit)
                currentAlternateIconName = UIApplication.shared.alternateIconName
                #endif
                HouseholdCloudSyncService.shared.refreshAvailability()
            }
        }
    }

    // MARK: - 1. Partner & iCloud Sharing Quick Card

    private var partnerAndCloudSummaryCard: some View {
        let householdName = households.first?.name ?? "Our Home"

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ChoreIconBadgeView(
                    iconSymbol: "icloud.and.arrow.up.fill",
                    tint: theme.accentPrimary,
                    size: 40
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(householdName)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(members.count) \(members.count == 1 ? "person" : "people") · Share via iCloud with your partner")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            if !members.isEmpty {
                FlowChipLayout(horizontalSpacing: 7, verticalSpacing: 7) {
                    ForEach(members) { member in
                        let isCurrent = prefs.activeMemberID == member.id
                        Button {
                            HapticsEngine.shared.playMechanicalTap()
                            prefs.activeMemberID = member.id
                            session.refreshWidgetsAndReminders(in: modelContext)
                        } label: {
                            HStack(spacing: 5) {
                                Text(member.emoji)
                                Text(member.displayName)
                                if isCurrent {
                                    Text("· You")
                                        .opacity(0.85)
                                }
                            }
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(isCurrent ? theme.accentPrimary : theme.canvasSecondary)
                            )
                            .foregroundStyle(isCurrent ? theme.onAccentPrimary : theme.primaryInk)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                HapticsEngine.shared.playMechanicalTap()
                showingPartnerSharing = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.badge.gearshape.fill")
                    Text("Partner iCloud Sharing, Names & Home Setup…")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.subheadline.weight(.heavy))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(TactileActionButtonStyle(fill: theme.accentPrimary, foreground: theme.onAccentPrimary))
        }
        .padding(15)
        .adhousedCard(highlightTint: theme.accentPrimary)
    }

    // MARK: - 2. Quiet / Minimal Mode & Screen Layout

    private var quietAndLayoutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("QUIET / MINIMAL VIEW & LAYOUT")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            Toggle(isOn: $prefs.quietModeEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quiet / Minimal Screen Mode")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                    Text("Hides extra meters, filters, and stats into a calm checklist. Also toggleable anytime via the **Quiet** button in the top-right header.")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(theme.accentPrimary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Header Display Lettering")
                    .themeFont(.captionStrong, in: theme)
                    .foregroundStyle(theme.primaryInk)

                Picker("Header Lettering", selection: $prefs.displayLetteringStyle) {
                    ForEach(DisplayLetteringStyle.allCases) { styleOpt in
                        Text(styleOpt.title).tag(styleOpt)
                    }
                }
                .pickerStyle(.segmented)

                Text(prefs.displayLetteringStyle.subtitle)
                    .themeFont(.caption, in: theme)
                    .foregroundStyle(theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Standard Dashboard Layout")
                    .themeFont(.captionStrong, in: theme)
                    .foregroundStyle(theme.primaryInk)

                Picker("Layout", selection: $prefs.layoutMode) {
                    ForEach(LayoutUsabilityMode.allCases) { mode in
                        Text(mode.shortLabel).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Toggle(isOn: $prefs.bionicReadingEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bold Word Starts (Faster Scanning)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                    SalientText(
                        "Highlights the beginning of words to guide your eyes smoothly",
                        bionicEnabled: prefs.bionicReadingEnabled,
                        font: .caption2,
                        color: theme.secondaryInk
                    )
                }
            }
            .tint(theme.accentPrimary)

            Toggle(isOn: $prefs.hapticsEnabled) {
                Text("Tactile Haptic Feedback")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.primaryInk)
            }
            .tint(theme.accentPrimary)
        }
        .padding(15)
        .adhousedCard()
    }

    // MARK: - 3. Expanded 21-Theme Gallery + Per-Theme Color Customizer

    private var themeStudioGallerySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("COLOR THEMES & CUSTOMIZATION")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(theme.secondaryInk)
                Spacer()
                Text("\(ThemePreset.allCases.count) Themes")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(theme.accentPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Picker("Appearance", selection: $prefs.colorSchemePreference) {
                    ForEach(ColorSchemePreference.allCases) { opt in
                        Text(opt.title).tag(opt)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: prefs.colorSchemePreference) { _, _ in
                    #if canImport(WidgetKit)
                    WidgetCenter.shared.reloadAllTimelines()
                    #endif
                }

                Text("Tap any theme to apply it, or tap **Customize** on any row to tweak its background, card, text, and accent colors.")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Quick shortcut to customize the currently active theme
            Button {
                HapticsEngine.shared.playMechanicalTap()
                customizingPreset = prefs.themePreset
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paintpalette.fill")
                    Text("Customize Colors for \(prefs.themePreset.title)…")
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .font(.caption.weight(.heavy))
                .padding(.horizontal, 13)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 8 : 12, style: .continuous)
                        .fill(theme.accentPrimary.opacity(0.15))
                )
                .foregroundStyle(theme.accentPrimary)
            }
            .buttonStyle(.plain)

            ForEach(ThemeFamily.allCases) { family in
                VStack(alignment: .leading, spacing: 8) {
                    Text(family.sectionHeader)
                        .font(.system(size: 10.5, weight: .heavy, design: theme.fontDesign))
                        .tracking(0.8)
                        .foregroundStyle(theme.accentPrimary)
                        .padding(.top, 6)

                    ForEach(family.presets) { preset in
                        themeGalleryRow(preset)
                    }
                }
            }
        }
        .padding(15)
        .adhousedCard()
    }

    private func themeGalleryRow(_ preset: ThemePreset) -> some View {
        let selected = prefs.themePreset == preset
        let hasCustomColors = prefs.colorOverrides(for: preset).hasAnyCustomization
        let itemRadius: CGFloat = theme.isTerminalHUD ? 8 : 14

        return HStack(spacing: 10) {
            Button {
                HapticsEngine.shared.playMechanicalTap()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    prefs.selectThemePreset(preset)
                }
                #if canImport(WidgetKit)
                WidgetCenter.shared.reloadAllTimelines()
                #endif
            } label: {
                HStack(spacing: 11) {
                    themeMiniSwatch(for: preset)

                    VStack(alignment: .leading, spacing: 3) {
                        FlowChipLayout(horizontalSpacing: 5, verticalSpacing: 4) {
                            Text(preset.title)
                                .font(.subheadline.weight(.heavy))
                                .fontDesign(preset.isOmarchyQuattroStyle ? .monospaced : .default)
                                .foregroundStyle(theme.primaryInk)

                            if preset.isOmarchyQuattroStyle {
                                OmarchyWordmarkBadge(
                                    text: "OMARCHY",
                                    fontSize: 7.5,
                                    gradientColors: [theme.accentPrimary, theme.accentSecondary],
                                    isDark: theme.isDark
                                )
                                .padding(.horizontal, 5.5)
                                .padding(.vertical, 2.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.accentPrimary.opacity(0.14))
                                )
                            }

                            if hasCustomColors {
                                Text("CUSTOMIZED")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(theme.onAccentSecondary)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(theme.accentSecondary))
                            }
                        }

                        Text(preset.subtitle)
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryInk)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 2)
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 6) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.headline)
                    .foregroundStyle(selected ? theme.accentPrimary : theme.secondaryInk)
                    .onTapGesture {
                        HapticsEngine.shared.playMechanicalTap()
                        prefs.selectThemePreset(preset)
                    }

                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    customizingPreset = preset
                } label: {
                    Image(systemName: "paintpalette")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                        .frame(width: 30, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(theme.cardSurface)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .strokeBorder(theme.borderInk, lineWidth: 0.9)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Customize \(preset.title)")
            }
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: itemRadius, style: .continuous)
                .fill(selected ? theme.accentPrimary.opacity(0.12) : theme.canvasSecondary)
        )
        .overlay {
            if selected {
                RoundedRectangle(cornerRadius: itemRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: theme.focusGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        }
    }

    private func themeMiniSwatch(for preset: ThemePreset) -> some View {
        let previewScheme: ColorScheme = (preset.signatureIsDark ?? false) ? .dark : .light
        let sample = ADHOUSEDThemeTokens.resolve(preset: preset, colorScheme: previewScheme)

        return ZStack {
            if preset.isOmarchyQuattroStyle {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(sample.canvasBackground)
                    .frame(width: 48, height: 48)
                    .overlay(
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 3) {
                                Circle().fill(sample.dueNowColor).frame(width: 4.5, height: 4.5)
                                Circle().fill(sample.warmingColor).frame(width: 4.5, height: 4.5)
                                Circle().fill(sample.freshColor).frame(width: 4.5, height: 4.5)
                                Spacer()
                            }
                            OmarchyPrismEmblemView(
                                primary: sample.accentPrimary,
                                secondary: sample.accentSecondary,
                                height: 11.5
                            )
                            HStack(spacing: 3) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(sample.accentPrimary)
                                    .frame(width: 17, height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(sample.accentSecondary)
                                    .frame(width: 11, height: 4)
                            }
                        }
                        .padding(6.5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: sample.focusGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(sample.canvasBackground)
                    .frame(width: 48, height: 48)
                    .overlay(
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(sample.cardSurface)
                                .frame(width: 34, height: 18)
                                .overlay(
                                    HStack(spacing: 3) {
                                        Circle().fill(sample.accentPrimary).frame(width: 7, height: 7)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(sample.primaryInk.opacity(0.65))
                                            .frame(width: 15, height: 4)
                                    }
                                )
                            HStack(spacing: 4) {
                                Circle().fill(sample.freshColor).frame(width: 7, height: 7)
                                Circle().fill(sample.accentPrimary).frame(width: 7, height: 7)
                                Circle().fill(sample.dueNowColor).frame(width: 7, height: 7)
                            }
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(sample.borderInk, lineWidth: preset == .chunkyNeoBrutalistPop ? 2.0 : 1.0)
                    )
            }
        }
    }

    // MARK: - 4. Icon Pack Style & Home Screen App Icon

    private var iconFlavorAndAppIconSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ICON PACKS & APP ICON")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            Text("Choose how chore icons render across your rooms. **Match Theme** automatically uses sleek Omarchy geometric vector glyphs on Omarchy themes, fine architectural lines on Quiet themes, and duotone glass medallions elsewhere.")
                .themeFont(.caption, in: theme)
                .foregroundStyle(theme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                ForEach(IconStylePreference.allCases) { stylePref in
                    let active = prefs.iconStylePreference == stylePref
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        prefs.iconStylePreference = stylePref
                    } label: {
                        HStack(spacing: 12) {
                            ChoreIconBadgeView(
                                iconSymbol: "dishwasher.fill",
                                tint: theme.accentPrimary,
                                size: 36,
                                styleOverride: stylePref == .autoTheme ? nil : stylePref
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(stylePref.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(theme.primaryInk)
                                Text(stylePref.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(theme.secondaryInk)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Image(systemName: active ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(active ? theme.accentPrimary : theme.secondaryInk)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(active ? theme.accentPrimary.opacity(0.14) : theme.canvasSecondary)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            #if canImport(UIKit)
            if UIApplication.shared.supportsAlternateIcons {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Home Screen App Icon")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.primaryInk)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(appIconChoices, id: \.label) { option in
                                let isChosen = currentAlternateIconName == option.iconName
                                Button {
                                    HapticsEngine.shared.playMechanicalTap()
                                    UIApplication.shared.setAlternateIconName(option.iconName) { error in
                                        if error == nil {
                                            Task { @MainActor in
                                                currentAlternateIconName = option.iconName
                                            }
                                        }
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(hex: option.previewBg))
                                            .frame(width: 52, height: 52)
                                            .overlay {
                                                StylizedVectorGlyphView(
                                                    glyphKey: option.iconName == nil ? "spark" : (option.iconName == "AppIconQuietLinen" ? "plant" : "prism"),
                                                    primaryColor: Color(hex: option.previewAccent),
                                                    glyphSize: 28
                                                )
                                            }
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(
                                                        isChosen ? theme.accentPrimary : theme.borderInk,
                                                        lineWidth: isChosen ? 2.4 : 1.0
                                                    )
                                            }

                                        Text(option.label)
                                            .font(.caption2.weight(isChosen ? .heavy : .semibold))
                                            .foregroundStyle(isChosen ? theme.accentPrimary : theme.secondaryInk)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            #endif
        }
        .padding(15)
        .adhousedCard()
    }

    // MARK: - 5. Vacation & Break Mode

    private var vacationAndBreakSection: some View {
        let activeBreak = prefs.activeVacationBreak()
        let upcomingBreak = prefs.nextUpcomingVacationBreak()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("VACATION & BREAK MODE")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(theme.warmingColor)
                Spacer()
                if activeBreak != nil {
                    Text("ACTIVE")
                        .font(.system(size: 9, weight: .black, design: theme.fontDesign))
                        .foregroundStyle(Color(hex: "#111216"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(theme.warmingColor))
                }
            }

            if let brk = activeBreak {
                Text("**\(brk.title)** is active (\(brk.formattedRangeSummary())). All chores and reminders are paused.")
                    .font(.caption)
                    .foregroundStyle(theme.primaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let upcoming = upcomingBreak {
                Text("Scheduled **\(upcoming.title)**: \(upcoming.formattedRangeSummary())")
                    .font(.caption)
                    .foregroundStyle(theme.primaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Going away for the weekend or on vacation? Set a start & end date and time to pause all chores and notifications.")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        session.presentingVacationBreakSheet = true
                    }
                } label: {
                    Label(
                        activeBreak != nil ? "Edit Break Dates" : "Set Vacation / Break Dates…",
                        systemImage: "calendar.badge.clock"
                    )
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                }
                .buttonStyle(
                    TactileActionButtonStyle(
                        fill: theme.warmingColor,
                        foreground: Color(hex: "#111216")
                    )
                )

                if activeBreak != nil {
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        try? TaskActionService.clearAwayPause(in: modelContext)
                    } label: {
                        Text("I'm Back")
                            .font(.subheadline.weight(.heavy))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(TactileActionButtonStyle(fill: theme.freshColor, foreground: .white))
                }
            }
        }
        .padding(15)
        .adhousedCard(highlightTint: activeBreak != nil ? theme.warmingColor : nil)
    }

    // MARK: - 6. Daytime Reminder Hours & Test Alert

    private var daytimeReminderWindowSection: some View {
        let household = households.first
        let startHourBinding = Binding<Int>(
            get: { (household?.awakeStartMinutes ?? 510) / 60 },
            set: { newHour in
                household?.awakeStartMinutes = newHour * 60
                try? modelContext.save()
                session.refreshWidgetsAndReminders(in: modelContext)
            }
        )
        let endHourBinding = Binding<Int>(
            get: { (household?.awakeEndMinutes ?? 1290) / 60 },
            set: { newHour in
                household?.awakeEndMinutes = newHour * 60
                try? modelContext.save()
                session.refreshWidgetsAndReminders(in: modelContext)
            }
        )

        return VStack(alignment: .leading, spacing: 12) {
            Text("DAYTIME REMINDER HOURS")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            Text("Reminders only alert you during your daytime hours — never overnight.")
                .font(.caption2)
                .foregroundStyle(theme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)

            Stepper("Start Reminders At: **\(startHourBinding.wrappedValue):00**", value: startHourBinding, in: 5...12)
                .font(.subheadline)
            Stepper("Quiet Overnight After: **\(endHourBinding.wrappedValue):00**", value: endHourBinding, in: 18...23)
                .font(.subheadline)

            HStack(spacing: 8) {
                Label("\(NagBudgetScheduler.shared.scheduledSlotCount) reminders scheduled", systemImage: "bell.fill")
                Spacer()
                Label("\(ReminderCoordinator.shared.activeLiveActivityCount) pinned on Lock Screen", systemImage: "platter.filled.top.iphone")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(theme.accentPrimary)

            Button {
                Task {
                    _ = await NagBudgetScheduler.shared.requestNotificationAuthorization()
                    if let sample = tasks.first(where: { !$0.isArchived }) {
                        await NagBudgetScheduler.shared.scheduleTestPing(for: sample)
                        statusBannerMessage = "Test notification scheduled — lock your screen for 3 seconds to try 1-tap Mark Done!"
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "bell.badge.fill")
                    Text("Send 3-Second Test Notification")
                }
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
            }
            .buttonStyle(TactileActionButtonStyle(fill: theme.dueNowColor, foreground: .white))
        }
        .padding(15)
        .adhousedCard()
    }
}
