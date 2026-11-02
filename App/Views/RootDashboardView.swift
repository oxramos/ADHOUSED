import SwiftUI
import SwiftData
import ADHOUSEDCore
#if canImport(WidgetKit)
import WidgetKit
#endif

struct RootDashboardView: View {
    @Environment(\.adhousedTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    @Query private var households: [Household]
    @Query(sort: \HouseholdMember.sortOrder) private var members: [HouseholdMember]
    @Query private var tasks: [ChoreTask]
    @Query(sort: \CompletionRecord.completedAt, order: .reverse) private var completions: [CompletionRecord]

    @Bindable var session: AppSessionViewModel
    @Bindable var prefs: ADHOUSEDPreferences

    private var household: Household? { households.first }

    private var activeMember: HouseholdMember? {
        if let activeID = prefs.activeMemberID,
           let matched = members.first(where: { $0.id == activeID }) {
            return matched
        }
        return members.first
    }

    private var activeUnarchivedTasks: [ChoreTask] {
        tasks.filter { !$0.isArchived }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            theme.canvasBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: prefs.quietModeEnabled ? 16 : 18) {
                    topHeaderBar
                    awayPauseStatusBanner
                    topRoomFilterSection

                    if !prefs.quietModeEnabled {
                        filterAndViewControlRow
                    }

                    if prefs.quietModeEnabled {
                        SpotlightAndRoomsView(
                            session: session,
                            tasks: tasks,
                            members: members,
                            activeMember: activeMember,
                            isQuietMode: true
                        )
                    } else {
                        switch prefs.layoutMode {
                        case .spotlightAndRooms:
                            SpotlightAndRoomsView(
                                session: session,
                                tasks: tasks,
                                members: members,
                                activeMember: activeMember,
                                isQuietMode: false
                            )
                        case .freshnessBatteryStream:
                            FreshnessBatteryStreamView(
                                session: session,
                                tasks: tasks,
                                members: members,
                                activeMember: activeMember
                            )
                        }

                        momentumPulseStrip
                    }

                    Spacer(minLength: 108)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
            }

            bottomFloatingDock
        }
        .sheet(isPresented: $session.presentingNewTaskSheet) {
            TaskEditorSheet(existingTask: nil, members: members, householdID: household?.id ?? UUID())
                .fontDesign(theme.fontDesign)
                .environment(\.adhousedTheme, theme)
                .preferredColorScheme(theme.isDark ? .dark : .light)
        }
        .sheet(item: $session.editingTask) { task in
            TaskEditorSheet(existingTask: task, members: members, householdID: task.householdID)
                .fontDesign(theme.fontDesign)
                .environment(\.adhousedTheme, theme)
                .preferredColorScheme(theme.isDark ? .dark : .light)
        }
        .sheet(item: $session.deferringTask) { task in
            DeferTaskSheet(
                task: task,
                onStartTwoMinuteSprintInstead: {
                    session.deferringTask = nil
                    session.startBeatTheClockSprint(for: task, minutes: 2)
                    session.presentingSprintSheetForTask = task
                },
                onOpenVacationBreakMode: {
                    session.deferringTask = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        session.presentingVacationBreakSheet = true
                    }
                }
            )
            .fontDesign(theme.fontDesign)
            .environment(\.adhousedTheme, theme)
            .preferredColorScheme(theme.isDark ? .dark : .light)
        }
        .sheet(isPresented: $session.presentingVacationBreakSheet) {
            VacationBreakSheet(session: session, prefs: prefs)
                .fontDesign(theme.fontDesign)
                .environment(\.adhousedTheme, theme)
                .preferredColorScheme(theme.isDark ? .dark : .light)
        }
        .sheet(item: $session.presentingSprintSheetForTask) { task in
            SprintTimerOverlayView(session: session, task: task)
                .fontDesign(theme.fontDesign)
                .environment(\.adhousedTheme, theme)
                .preferredColorScheme(theme.isDark ? .dark : .light)
        }
        .sheet(isPresented: $session.presentingSettingsSheet) {
            HouseholdAndThemeSettingsView(session: session, prefs: prefs)
                .fontDesign(theme.fontDesign)
                .environment(\.adhousedTheme, theme)
                .preferredColorScheme(theme.isDark ? .dark : .light)
        }
        .sheet(isPresented: $session.presentingStarterCatalogSheet) {
            ChoreCatalogSheet(session: session, prefs: prefs, members: members, householdID: household?.id ?? UUID())
                .fontDesign(theme.fontDesign)
                .environment(\.adhousedTheme, theme)
                .preferredColorScheme(theme.isDark ? .dark : .light)
        }
        .sheet(isPresented: $session.presentingPartnerSharingSheet) {
            PartnerSharingSheet(session: session, prefs: prefs)
                .fontDesign(theme.fontDesign)
                .environment(\.adhousedTheme, theme)
                .preferredColorScheme(theme.isDark ? .dark : .light)
        }
        .sheet(item: $session.customizingThemePreset) { preset in
            ThemeColorCustomizerSheet(preset: preset, prefs: prefs)
                .fontDesign(theme.fontDesign)
                .environment(\.adhousedTheme, theme)
                .preferredColorScheme(theme.isDark ? .dark : .light)
        }
        .onAppear {
            if prefs.activeMemberID == nil, let first = members.first {
                prefs.activeMemberID = first.id
            }
        }
    }

    // MARK: - 1. Top Header Bar (Zero Truncation + Lowkey Quiet Button + Partner Menu)

    private var topHeaderBar: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                if let householdName = household?.name, !householdName.isEmpty {
                    Text(householdName.uppercased())
                        .font(.system(size: 10.5, weight: .bold, design: theme.fontDesign))
                        .tracking(0.9)
                        .foregroundStyle(theme.secondaryInk)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SalientText(
                    greetingTitle,
                    font: .title2.weight(.heavy),
                    color: theme.primaryInk,
                    lineLimit: 2
                )
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            HStack(spacing: 7) {
                // Lowkey, Always-Accessible Quiet / Minimal Mode Toggle
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        prefs.quietModeEnabled.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: prefs.quietModeEnabled ? "leaf.fill" : "leaf")
                            .font(.caption.weight(.bold))
                        Text("Quiet")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(prefs.quietModeEnabled ? theme.onAccentPrimary : theme.secondaryInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 7 : 99, style: .continuous)
                            .fill(prefs.quietModeEnabled ? theme.accentPrimary : theme.cardSurface)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 7 : 99, style: .continuous)
                            .strokeBorder(prefs.quietModeEnabled ? theme.accentPrimary : theme.borderInk, lineWidth: 1.0)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(prefs.quietModeEnabled ? "Exit Quiet Mode" : "Switch to Quiet Minimal Mode")

                // Household Member & iCloud Partner Sharing Menu (Compact Avatar so Header Never Truncates!)
                Menu {
                    if !members.isEmpty {
                        Section("Who is using this iPhone?") {
                            ForEach(members) { member in
                                Button {
                                    HapticsEngine.shared.playMechanicalTap()
                                    prefs.activeMemberID = member.id
                                    session.refreshWidgetsAndReminders(in: modelContext)
                                } label: {
                                    Label(
                                        "\(member.emoji) \(member.displayName)",
                                        systemImage: activeMember?.id == member.id ? "checkmark.circle.fill" : "circle"
                                    )
                                }
                            }
                        }
                    }
                    Divider()
                    Button {
                        session.presentingPartnerSharingSheet = true
                    } label: {
                        Label("Invite Partner / iCloud Sharing…", systemImage: "icloud.and.arrow.up.fill")
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(activeMember?.emoji ?? "🏠")
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(theme.secondaryInk)
                    }
                    .frame(height: 36)
                    .padding(.horizontal, 9)
                    .adhousedCard(compact: true)
                }
                .accessibilityLabel("Switch member or invite partner via iCloud")

                // Vacation / Break Mode Button
                let hasActivePause = prefs.activeVacationBreak() != nil || household?.isCurrentlyPausedAway() == true
                let hasUpcomingBreak = prefs.nextUpcomingVacationBreak() != nil
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    session.presentingVacationBreakSheet = true
                } label: {
                    Image(systemName: hasActivePause ? "pause.circle.fill" : (hasUpcomingBreak ? "calendar.badge.clock" : "suitcase.rolling.fill"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(hasActivePause ? theme.warmingColor : (hasUpcomingBreak ? theme.accentPrimary : theme.primaryInk))
                        .frame(width: 36, height: 36)
                        .adhousedCard(highlightTint: hasActivePause ? theme.warmingColor : nil, compact: true)
                }
                .accessibilityLabel("Vacation and Break Mode")

                // Themes & Settings Button
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    session.presentingSettingsSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                        .frame(width: 36, height: 36)
                        .adhousedCard(compact: true)
                }
                .accessibilityLabel("Settings and Themes")
            }
        }
    }

    private var greetingTitle: String {
        if let name = activeMember?.displayName, !name.isEmpty {
            return "\(name)'s Chores"
        }
        return "Home Chores"
    }

    // MARK: - 2. Browse / Filter by Room RIGHT AT THE TOP

    private var topRoomFilterSection: some View {
        let populatedRooms = RoomCategory.allCases.filter { room in
            activeUnarchivedTasks.contains(where: { $0.room == room })
        }

        return VStack(alignment: .leading, spacing: 10) {
            if !populatedRooms.isEmpty {
                HStack(alignment: .center) {
                    Text("Filter by Room")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.secondaryInk)

                    Spacer()

                    if session.selectedRoom != nil {
                        Button("Clear Filter") {
                            HapticsEngine.shared.playMechanicalTap()
                            withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                                session.selectedRoom = nil
                            }
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.accentPrimary)
                    }

                    if !prefs.quietModeEnabled {
                        Button {
                            HapticsEngine.shared.playMechanicalTap()
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                session.showRoomHealthGrid.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: session.showRoomHealthGrid ? "chevron.up" : "square.grid.2x2")
                                    .font(.caption2.weight(.bold))
                                Text(session.showRoomHealthGrid ? "Compact" : "Overview")
                                    .font(.caption2.weight(.bold))
                            }
                            .foregroundStyle(theme.secondaryInk)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(theme.canvasSecondary))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Instant 1-Tap Room Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            HapticsEngine.shared.playMechanicalTap()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                                session.selectedRoom = nil
                            }
                        } label: {
                            Text("All Rooms")
                                .font(.caption.weight(.heavy))
                                .padding(.horizontal, 13)
                                .padding(.vertical, 9)
                        }
                        .buttonStyle(
                            TactileActionButtonStyle(
                                fill: session.selectedRoom == nil ? theme.accentPrimary : theme.cardSurface,
                                foreground: session.selectedRoom == nil ? theme.onAccentPrimary : theme.primaryInk
                            )
                        )

                        ForEach(populatedRooms) { room in
                            let isSelected = session.selectedRoom == room
                            let health = FreshnessCalculator.roomHealth(room: room, tasks: activeUnarchivedTasks)
                            let roomTint = theme.roomAccent(for: room)

                            Button {
                                HapticsEngine.shared.playMechanicalTap()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                                    session.selectedRoom = isSelected ? nil : room
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    if theme.isTerminalHUD || prefs.iconStylePreference == .omarchyPixelHUD {
                                        OmarchyPixelGlyphView(
                                            glyphKey: String(room.omarchyIconKey.dropFirst("omarchy:".count)),
                                            color: isSelected ? .white : roomTint,
                                            pixelSize: 1.35
                                        )
                                    } else {
                                        Image(systemName: room.symbolName)
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(isSelected ? .white : roomTint)
                                    }

                                    Text(room.shortTitle)
                                        .font(.caption.weight(.bold))

                                    if health.dueCount > 0 {
                                        Text("\(health.dueCount)")
                                            .font(.system(size: 10, weight: .black, design: theme.fontDesign))
                                            .foregroundStyle(isSelected ? roomTint : .white)
                                            .padding(.horizontal, 5.5)
                                            .padding(.vertical, 1.5)
                                            .background(
                                                Capsule().fill(isSelected ? .white : theme.dueNowColor)
                                            )
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(
                                TactileActionButtonStyle(
                                    fill: isSelected ? roomTint : theme.cardSurface,
                                    foreground: isSelected ? .white : theme.primaryInk
                                )
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }

                // Optional Expandable Room Health Grid right at top
                if session.showRoomHealthGrid && !prefs.quietModeEnabled {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(populatedRooms) { room in
                            roomOverviewCard(for: room)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private func roomOverviewCard(for room: RoomCategory) -> some View {
        let health = FreshnessCalculator.roomHealth(room: room, tasks: activeUnarchivedTasks)
        let isSelected = session.selectedRoom == room
        let roomColor = theme.roomAccent(for: room)

        return Button {
            HapticsEngine.shared.playMechanicalTap()
            withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                session.selectedRoom = isSelected ? nil : room
            }
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    ChoreIconBadgeView(iconSymbol: room.symbolName, tint: roomColor, size: 32)
                    Spacer()
                    if health.dueCount > 0 {
                        Text("\(health.dueCount) due")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(theme.dueNowColor))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.freshColor)
                            .font(.subheadline)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(room.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(health.totalCount) \(health.totalCount == 1 ? "chore" : "chores")")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryInk)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(theme.canvasSecondary)
                        Capsule()
                            .fill(health.dueCount > 0 ? theme.dueNowColor : roomColor)
                            .frame(width: max(8, geo.size.width * health.averageFill))
                    }
                }
                .frame(height: 5)
            }
            .padding(12)
            .adhousedCard(highlightTint: isSelected ? roomColor : nil, compact: true)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3. Clean Sub-Filter & View Row (Plain English, Zero Clutter)

    private var filterAndViewControlRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Quick & Easy (<= 5 min) Filter — replaces cryptic "Low Spoons"!
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                        session.lowSpoonsFilterEnabled.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "leaf.fill")
                            .font(.caption2.weight(.bold))
                        Text("Quick & Easy (≤5m)")
                            .font(.caption.weight(.bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(
                    TactileActionButtonStyle(
                        fill: session.lowSpoonsFilterEnabled ? theme.freshColor : theme.cardSurface,
                        foreground: session.lowSpoonsFilterEnabled ? .white : theme.primaryInk
                    )
                )

                // My Turn vs Everyone toggle when sharing with partner
                if members.count > 1 {
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                            session.showEveryoneChores.toggle()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: session.showEveryoneChores ? "person.2.fill" : "person.fill")
                                .font(.caption2.weight(.bold))
                            Text(session.showEveryoneChores ? "Showing Everyone" : "My Turn Only")
                                .font(.caption.weight(.bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(
                        TactileActionButtonStyle(
                            fill: session.showEveryoneChores ? theme.accentSecondary : theme.cardSurface,
                            foreground: session.showEveryoneChores ? theme.onAccentSecondary : theme.primaryInk
                        )
                    )
                }

                // Focus List vs Battery View toggle
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                        prefs.layoutMode = (prefs.layoutMode == .spotlightAndRooms) ? .freshnessBatteryStream : .spotlightAndRooms
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: prefs.layoutMode.symbolName)
                            .font(.caption2.weight(.bold))
                        Text(prefs.layoutMode.shortLabel)
                            .font(.caption.weight(.bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.cardSurface, foreground: theme.primaryInk))

                // Quick Theme & Color Customizer Menu
                Menu {
                    Button {
                        session.customizingThemePreset = prefs.themePreset
                    } label: {
                        Label("Customize \(prefs.themePreset.shortLabel) Colors…", systemImage: "eyedropper.halffull")
                    }
                    Divider()
                    ForEach(ThemeFamily.allCases) { family in
                        Section(family.sectionHeader) {
                            ForEach(family.presets) { preset in
                                Button {
                                    HapticsEngine.shared.playMechanicalTap()
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                        prefs.selectThemePreset(preset)
                                    }
                                    #if canImport(WidgetKit)
                                    WidgetCenter.shared.reloadAllTimelines()
                                    #endif
                                } label: {
                                    Label(
                                        preset.title,
                                        systemImage: prefs.themePreset == preset
                                            ? "checkmark.circle.fill"
                                            : (preset.isOmarchyQuattroStyle ? "terminal.fill" : "paintpalette")
                                    )
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: theme.isTerminalHUD ? "terminal.fill" : "paintpalette.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(theme.accentPrimary)
                        Text(prefs.themePreset.shortLabel)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.primaryInk)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(theme.secondaryInk)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .adhousedCard(compact: true)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - 4. Vacation / Break Mode Status Banner (Wrapping, Zero Truncation)

    @ViewBuilder
    private var awayPauseStatusBanner: some View {
        if let activeBreak = prefs.activeVacationBreak() {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: activeBreak.iconSymbol)
                        .font(.title3)
                        .foregroundStyle(theme.warmingColor)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(activeBreak.title) — Chores & Alerts Paused")
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(theme.primaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(activeBreak.formattedRangeSummary())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 8) {
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        session.presentingVacationBreakSheet = true
                    } label: {
                        Text("Edit Dates")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(TactileActionButtonStyle(fill: theme.cardElevatedSurface, foreground: theme.primaryInk))

                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        try? TaskActionService.clearAwayPause(in: modelContext)
                    } label: {
                        Text("I'm Back")
                            .font(.caption.weight(.heavy))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(TactileActionButtonStyle(fill: theme.warmingColor, foreground: Color(hex: "#111216")))
                }
            }
            .padding(13)
            .adhousedCard(highlightTint: theme.warmingColor, compact: true)
        } else if let household, let pauseUntil = household.awayPauseUntil, pauseUntil > .now {
            HStack(spacing: 12) {
                Image(systemName: "pause.circle.fill")
                    .font(.title3)
                    .foregroundStyle(theme.warmingColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reminders Paused")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                    Text("Resumes at \(pauseUntil.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    try? TaskActionService.clearAwayPause(in: modelContext)
                } label: {
                    Text("Resume")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.warmingColor, foreground: Color(hex: "#111216")))
            }
            .padding(13)
            .adhousedCard(highlightTint: theme.warmingColor, compact: true)
        } else if let upcoming = prefs.nextUpcomingVacationBreak() {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(theme.accentPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upcoming Break: \(upcoming.title)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(upcoming.formattedRangeSummary())
                        .font(.caption)
                        .foregroundStyle(theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    session.presentingVacationBreakSheet = true
                } label: {
                    Text("Edit")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.cardElevatedSurface, foreground: theme.primaryInk))
            }
            .padding(13)
            .adhousedCard(highlightTint: theme.accentPrimary, compact: true)
        }
    }

    // MARK: - 5. Subtle Weekly Progress Card (Placed Calmly Below Chores)

    private var momentumPulseStrip: some View {
        let stats = FreshnessCalculator.momentumStats(completions: completions)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("THIS WEEK")
                    .font(.system(size: 10, weight: .heavy, design: theme.fontDesign))
                    .tracking(0.8)
                    .foregroundStyle(theme.accentPrimary)
                SalientText(
                    stats.headline,
                    font: .footnote.weight(.semibold),
                    color: theme.primaryInk,
                    lineLimit: nil
                )
            }
            Spacer(minLength: 8)
            HStack(spacing: 5) {
                ForEach(Array(stats.recent7DayActivityDots.enumerated()), id: \.offset) { _, active in
                    Circle()
                        .fill(active ? theme.accentPrimary : theme.canvasSecondary)
                        .frame(width: 8.5, height: 8.5)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .adhousedCard(compact: true)
    }

    // MARK: - 6. Bottom Floating Dock (Undo Toast + Active Timer + Catalog & New Chore)

    private var bottomFloatingDock: some View {
        VStack(spacing: 10) {
            if let toast = session.undoToast {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(theme.freshColor)
                        .font(.title3)
                    Text("Completed **\(toast.taskTitle)**")
                        .font(.subheadline)
                        .foregroundStyle(theme.primaryInk)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 6)
                    Button("Undo") {
                        session.performUndoToast(in: modelContext)
                    }
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(theme.accentSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .adhousedCard(highlightTint: theme.freshColor, compact: true)
                .padding(.horizontal, 18)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let sprint = session.activeSprint {
                TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
                    let remaining = max(0, Int(sprint.targetEndDate.timeIntervalSince(timeline.date)))
                    let mins = remaining / 60
                    let secs = remaining % 60
                    HStack(spacing: 12) {
                        Image(systemName: "timer")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(theme.warmingColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Focus Timer: \(sprint.taskTitle)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.primaryInk)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(remaining > 0 ? String(format: "%d:%02d left", mins, secs) : "Timer finished — tap Done!")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.secondaryInk)
                        }
                        Spacer(minLength: 6)
                        Button {
                            if let match = tasks.first(where: { $0.id == sprint.taskID }) {
                                session.presentingSprintSheetForTask = match
                            }
                        } label: {
                            Text("Open")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(TactileActionButtonStyle(fill: theme.warmingColor, foreground: Color(hex: "#111216")))
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 11)
                    .adhousedCard(highlightTint: theme.warmingColor, compact: true)
                    .padding(.horizontal, 18)
                }
            }

            HStack(spacing: 10) {
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    session.presentingStarterCatalogSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "books.vertical.fill")
                        Text("Catalog")
                    }
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 15)
                    .padding(.vertical, 13)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.cardSurface, foreground: theme.primaryInk))

                Spacer()

                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    session.presentingNewTaskSheet = true
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                        Text("Add Chore")
                            .font(.subheadline.weight(.heavy))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 13)
                }
                .buttonStyle(
                    TactileActionButtonStyle(
                        fill: theme.accentPrimary,
                        foreground: theme.onAccentPrimary
                    )
                )
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
        }
    }
}
