import SwiftUI
import SwiftData
import ADHOUSEDCore
#if canImport(WidgetKit)
import WidgetKit
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

    @State private var newMemberName: String = ""
    @State private var newMemberEmoji: String = "🐝"
    @State private var statusBannerMessage: String? = nil
    @State private var exportedJSONURL: URL? = nil

    private let emojis = ["🦊", "🦦", "🐝", "🐻", "🐙", "🦉", "🐢", "🦄"]

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
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .adhousedCard(highlightTint: theme.accentPrimary, compact: true)
                        }

                        dualThemeSelectorSection
                        adhdVisualErgonomicsSection
                        vacationAndBreakSection
                        awakeWindowAndTestPingSection
                        sharedHouseholdMembersSection
                        cloudShareAndBackupSection
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Themes, Brain & Household")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.heavy)
                }
            }
        }
    }

    // MARK: - Multi-Family Theme Studio (Originals + Omarchy Quattro OS 4.x)

    private var dualThemeSelectorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(theme.hudTag("VISUAL THEME ENGINE"))
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(theme.secondaryInk)
                    .lineLimit(1)
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

                Text("Signature uses each style sheet's showcase palette; Light & Dark unlock pairing modes (Quattro Light, Mist, Desert Sun, Sunflower).")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryInk)
            }

            ForEach(ThemeFamily.allCases) { family in
                VStack(alignment: .leading, spacing: 8) {
                    Text(family.sectionHeader)
                        .font(.system(size: 10, weight: .heavy, design: theme.fontDesign))
                        .tracking(0.8)
                        .foregroundStyle(theme.accentPrimary)
                        .padding(.top, 4)

                    ForEach(family.presets) { preset in
                        let selected = prefs.themePreset == preset
                        let itemRadius: CGFloat = theme.isTerminalHUD ? 8 : 14
                        Button {
                            HapticsEngine.shared.playMechanicalTap()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                prefs.selectThemePreset(preset)
                            }
                            #if canImport(WidgetKit)
                            WidgetCenter.shared.reloadAllTimelines()
                            #endif
                        } label: {
                            HStack(spacing: 12) {
                                themeMiniSwatch(for: preset)
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(preset.title)
                                            .font(.subheadline.weight(.heavy))
                                            .fontDesign(preset.isOmarchyQuattroStyle ? .monospaced : .default)
                                            .foregroundStyle(theme.primaryInk)
                                        if preset.isOmarchyQuattroStyle {
                                            Text("MONO")
                                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                                .foregroundStyle(theme.accentPrimary)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(theme.accentPrimary.opacity(0.15))
                                                )
                                        }
                                    }
                                    Text(preset.subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(theme.secondaryInk)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 4)
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selected ? theme.accentPrimary : theme.secondaryInk)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: itemRadius, style: .continuous)
                                    .fill(selected ? theme.accentPrimary.opacity(0.12) : theme.canvasSecondary)
                            )
                            .overlay {
                                if selected && theme.isTerminalHUD {
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
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(15)
        .adhousedCard()
    }

    private func themeMiniSwatch(for preset: ThemePreset) -> some View {
        let previewScheme: ColorScheme = (preset.signatureIsDark ?? false) ? .dark : .light
        let sample = ADHOUSEDThemeTokens.resolve(preset: preset, colorScheme: previewScheme)

        return ZStack {
            switch preset {
            case .warmTactileBento:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "#F7F2EA"))
                    .frame(width: 48, height: 48)
                    .overlay(
                        HStack(spacing: 3) {
                            Circle().fill(Color(hex: "#3E9B6C")).frame(width: 10, height: 10)
                            Circle().fill(Color(hex: "#E0942C")).frame(width: 10, height: 10)
                            Circle().fill(Color(hex: "#DC5B3E")).frame(width: 10, height: 10)
                        }
                    )
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#D5C8B8"), lineWidth: 1))

            case .chunkyNeoBrutalistPop:
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color(hex: "#FFF8D6"))
                    .frame(width: 45, height: 45)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(Color(hex: "#111216"))
                            .offset(x: 3, y: 3)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Color(hex: "#111216"), lineWidth: 2))
                    .overlay(
                        HStack(spacing: 3) {
                            Rectangle().fill(Color(hex: "#00C97E")).frame(width: 9, height: 9)
                            Rectangle().fill(Color(hex: "#FF4D5E")).frame(width: 9, height: 9)
                        }
                    )

            default:
                // Omarchy Quattro OS 4.x Miniature Window Swatch (8pt geometry + 45° focus ring + mono prompt)
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(sample.canvasBackground)
                    .frame(width: 48, height: 48)
                    .overlay(
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 3) {
                                Circle().fill(sample.urgentColor).frame(width: 4.5, height: 4.5)
                                Circle().fill(sample.warmingColor).frame(width: 4.5, height: 4.5)
                                Circle().fill(sample.freshColor).frame(width: 4.5, height: 4.5)
                                Spacer()
                            }
                            Text(">_")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(sample.accentPrimary)
                            HStack(spacing: 3) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(sample.accentPrimary)
                                    .frame(width: 16, height: 5)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(sample.accentSecondary)
                                    .frame(width: 12, height: 5)
                            }
                        }
                        .padding(6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: sample.focusGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.6
                            )
                    )
            }
        }
    }

    // MARK: - ADHD Visual Ergonomics & Usability Mode

    private var adhdVisualErgonomicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ADHD VISUAL PROCESSING & LAYOUT")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            Picker("Default Home Layout", selection: $prefs.layoutMode) {
                ForEach(LayoutUsabilityMode.allCases) { mode in
                    Text(mode.shortLabel).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Toggle(isOn: $prefs.bionicReadingEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("High-Salience / Bionic Typography")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                    SalientText(
                        "Anchors eye fixation on word starts for faster scanning",
                        bionicEnabled: prefs.bionicReadingEnabled,
                        font: .caption,
                        color: theme.secondaryInk
                    )
                }
            }
            .tint(theme.accentPrimary)

            Toggle(isOn: $prefs.hapticsEnabled) {
                Text("Rich CoreHaptics Tactile Feedback")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.primaryInk)
            }
            .tint(theme.accentPrimary)
        }
        .padding(15)
        .adhousedCard()
    }

    // MARK: - Vacation & Break Mode Section

    private var vacationAndBreakSection: some View {
        let activeBreak = prefs.activeVacationBreak()
        let upcomingBreak = prefs.nextUpcomingVacationBreak()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(theme.hudTag("VACATION & BREAK MODE"))
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
                Text("**\(brk.title)** is active (\(brk.formattedRangeSummary())). All chores and persistent reminders are paused.")
                    .font(.caption)
                    .foregroundStyle(theme.primaryInk)
            } else if let upcoming = upcomingBreak {
                Text("Scheduled **\(upcoming.title)**: \(upcoming.formattedRangeSummary())")
                    .font(.caption)
                    .foregroundStyle(theme.primaryInk)
            } else {
                Text("Heading out of town or to the countryside for the weekend? Designate a From Date & Time → Until Date & Time break to pause chores and notifications.")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryInk)
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
                        activeBreak != nil ? "Edit Break Dates" : "Configure Vacation / Break…",
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

    // MARK: - Awake Hours & Live Persistent Reminder Test

    private var awakeWindowAndTestPingSection: some View {
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
            Text("PERSISTENT REMINDER ENGINE")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            Stepper("Awake Window Starts: **\(startHourBinding.wrappedValue):00**", value: startHourBinding, in: 5...12)
                .font(.subheadline)
            Stepper("Awake Window Ends: **\(endHourBinding.wrappedValue):00**", value: endHourBinding, in: 18...23)
                .font(.subheadline)

            HStack(spacing: 8) {
                Label("\(NagBudgetScheduler.shared.scheduledSlotCount) pings queued", systemImage: "bell.badge.fill")
                Spacer()
                Label("\(ReminderCoordinator.shared.activeLiveActivityCount) Lock Live", systemImage: "platter.filled.top.iphone")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(theme.accentPrimary)

            Button {
                Task {
                    _ = await NagBudgetScheduler.shared.requestNotificationAuthorization()
                    if let sample = tasks.first(where: { !$0.isArchived }) {
                        await NagBudgetScheduler.shared.scheduleTestPing(for: sample)
                        statusBannerMessage = "Test Time-Sensitive ping scheduled! Lock screen (Cmd+L) in 3 seconds to try 1-tap actions."
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "bell.and.waves.left.and.right.fill")
                    Text("Fire 3-Second Test Persistent Ping")
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

    // MARK: - Shared Household Members & Simulator Member Switcher

    private var sharedHouseholdMembersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SHARED HOUSEHOLD MEMBERS")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            Text("Tap a member below to set whose phone this is (routes their Alternating Turns, Spotlight Deck & Widgets).")
                .font(.caption2)
                .foregroundStyle(theme.secondaryInk)

            ForEach(members) { member in
                let isCurrent = prefs.activeMemberID == member.id
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    prefs.activeMemberID = member.id
                    session.refreshWidgetsAndReminders(in: modelContext)
                } label: {
                    HStack {
                        Text(member.emoji)
                            .font(.title3)
                        Text(member.displayName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(theme.primaryInk)
                        Spacer()
                        if isCurrent {
                            Text("THIS PHONE")
                                .font(.system(size: 10, weight: .black, design: theme.fontDesign))
                                .foregroundStyle(theme.onAccentPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(theme.accentPrimary))
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 11)
                            .fill(isCurrent ? theme.accentPrimary.opacity(0.14) : theme.canvasSecondary)
                    )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Menu {
                    ForEach(emojis, id: \.self) { em in
                        Button(em) { newMemberEmoji = em }
                    }
                } label: {
                    Text(newMemberEmoji)
                        .font(.title3)
                        .frame(width: 40, height: 40)
                        .background(RoundedRectangle(cornerRadius: 10).fill(theme.canvasSecondary))
                }

                TextField("Add household member…", text: $newMemberName)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 10).fill(theme.canvasSecondary))

                Button {
                    let trimmed = newMemberName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty, let hid = households.first?.id else { return }
                    let member = HouseholdMember(
                        householdID: hid,
                        displayName: trimmed,
                        emoji: newMemberEmoji,
                        accentHex: "#3B66FF",
                        sortOrder: members.count
                    )
                    modelContext.insert(member)
                    try? modelContext.save()
                    newMemberName = ""
                } label: {
                    Text("Add")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.accentPrimary, foreground: theme.onAccentPrimary))
            }
        }
        .padding(15)
        .adhousedCard()
    }

    // MARK: - iCloud Household Sharing & Portable Backup

    private var cloudShareAndBackupSection: some View {
        let syncService = HouseholdCloudSyncService.shared

        return VStack(alignment: .leading, spacing: 12) {
            Text("ICLOUD SHARING & PORTABLE BACKUP")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            switch syncService.availabilityState {
            case .localMultiMemberMode(let reason):
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(theme.secondaryInk)
            case .readyForCloudShare, .activelySharedHousehold:
                Text("iCloud Household Zone ready — invite partners/roommates via iMessage.")
                    .font(.caption)
                    .foregroundStyle(theme.freshColor)
            }

            HStack(spacing: 10) {
                Button {
                    Task {
                        guard let household = households.first else { return }
                        do {
                            _ = try await syncService.prepareHouseholdCloudShare(
                                for: household,
                                tasks: tasks,
                                members: members
                            )
                            statusBannerMessage = "iCloud Household Share Zone prepared!"
                        } catch {
                            statusBannerMessage = error.localizedDescription
                        }
                    }
                } label: {
                    Label("Invite via iCloud", systemImage: "icloud.and.arrow.up.fill")
                        .font(.caption.weight(.heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.accentSecondary, foreground: theme.onAccentSecondary))

                Button {
                    if let data = try? syncService.exportHouseholdJSON(in: modelContext) {
                        let tempURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent("ADHOUSED-Backup.json")
                        try? data.write(to: tempURL)
                        exportedJSONURL = tempURL
                        statusBannerMessage = "Household backup prepared! Tap Share Backup below."
                    }
                } label: {
                    Label("Prepare JSON Backup", systemImage: "square.and.arrow.up")
                        .font(.caption.weight(.heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.cardElevatedSurface, foreground: theme.primaryInk))
            }

            if let url = exportedJSONURL {
                ShareLink(item: url) {
                    Label("Share ADHOUSED-Backup.json", systemImage: "paperplane.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.accentPrimary)
                }
            }
        }
        .padding(15)
        .adhousedCard()
    }
}
