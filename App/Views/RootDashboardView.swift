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

    private var actionableDueTodayCount: Int {
        FreshnessCalculator.sortedByUrgency(
            tasks: activeUnarchivedTasks,
            forMemberID: activeMember?.id
        )
        .filter { pair in
            guard pair.snapshot.isActionableToday else { return false }
            if session.showEveryoneChores || members.count <= 1 {
                return true
            }
            return pair.task.isActionable(forMemberID: activeMember?.id)
        }
        .count
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Subtle atmospheric canvas depth so background never feels lifeless
            ZStack {
                theme.canvasBackground
                RadialGradient(
                    colors: [
                        theme.accentPrimary.opacity(theme.isDark ? 0.08 : 0.045),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 20,
                    endRadius: 340
                )
            }
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

    // MARK: - 1. Two-Tier Architectural Header (Zero Smooshing + Authentic Omarchy Lettering)

    private var topHeaderBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Row 1: Compact Household Kicker on Left + Fixed-Size Action Controls on Right
            HStack(alignment: .center, spacing: 6) {
                HStack(spacing: 5.5) {
                    if theme.isTerminalHUD || theme.usesOmarchyBlockLettering {
                        OmarchyPrismEmblemView(
                            primary: theme.accentPrimary,
                            secondary: theme.accentSecondary,
                            height: 11
                        )
                        .fixedSize()
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.accentPrimary, theme.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 7, height: 7)
                    }

                    Text((household?.name.isEmpty == false ? household!.name : "Our Home").uppercased())
                        .themeFont(.microTag, in: theme)
                        .foregroundStyle(theme.secondaryInk)
                        .lineLimit(2)
                        .minimumScaleFactor(0.76)
                        .allowsTightening(true)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 8.5)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 6 : 16, style: .continuous)
                        .fill(theme.canvasSecondary.opacity(theme.isDark ? 0.72 : 0.65))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 6 : 16, style: .continuous)
                        .strokeBorder(theme.borderInk.opacity(0.65), lineWidth: 0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right Control Cluster — Fixed-size so Quiet & Toolbar Icons NEVER Smoosh
                HStack(spacing: 5) {
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                            prefs.quietModeEnabled.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: prefs.quietModeEnabled ? "leaf.fill" : "leaf")
                                .font(.system(size: 11, weight: .bold))
                            Text("Quiet")
                                .themeFont(.pillLabel, in: theme)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundStyle(prefs.quietModeEnabled ? theme.onAccentPrimary : theme.primaryInk)
                        .padding(.horizontal, 10)
                        .frame(height: 33)
                        .background(
                            RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 7 : 99, style: .continuous)
                                .fill(prefs.quietModeEnabled ? theme.accentPrimary : theme.cardSurface)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 7 : 99, style: .continuous)
                                .strokeBorder(
                                    prefs.quietModeEnabled ? theme.accentPrimary : theme.borderInk,
                                    lineWidth: 1.0
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityLabel(prefs.quietModeEnabled ? "Exit Quiet Mode" : "Switch to Quiet Minimal Mode")

                    // Household Member & iCloud Partner Sharing Menu
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
                        HStack(spacing: 2.5) {
                            Text(activeMember?.emoji ?? "🏠")
                                .font(.system(size: 13.5))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundStyle(theme.secondaryInk)
                        }
                        .frame(height: 33)
                        .padding(.horizontal, 7.5)
                        .adhousedCard(compact: true)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityLabel("Switch member or invite partner via iCloud")

                    // Vacation / Break Mode Button
                    let hasActivePause = prefs.activeVacationBreak() != nil || household?.isCurrentlyPausedAway() == true
                    let hasUpcomingBreak = prefs.nextUpcomingVacationBreak() != nil
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        session.presentingVacationBreakSheet = true
                    } label: {
                        Image(systemName: hasActivePause ? "pause.circle.fill" : (hasUpcomingBreak ? "calendar.badge.clock" : "suitcase.rolling.fill"))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(hasActivePause ? theme.warmingColor : (hasUpcomingBreak ? theme.accentPrimary : theme.primaryInk))
                            .frame(width: 33, height: 33)
                            .adhousedCard(highlightTint: hasActivePause ? theme.warmingColor : nil, compact: true)
                    }
                    .fixedSize()
                    .accessibilityLabel("Vacation and Break Mode")

                    // Themes & Settings Button
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        session.presentingSettingsSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(theme.primaryInk)
                            .frame(width: 33, height: 33)
                            .adhousedCard(compact: true)
                    }
                    .fixedSize()
                    .accessibilityLabel("Settings and Themes")
                }
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(2)
            }

            // Row 2: Full-Width Hero Title with Authentic Omarchy Lettering & Dimensional Depth
            DimensionalHeroTitleView(
                title: greetingTitle,
                subtitle: heroSubtitleText,
                lineLimit: 2
            )
            .padding(.top, 2)
        }
    }

    private var greetingTitle: String {
        if let name = activeMember?.displayName, !name.isEmpty {
            return "\(name)'s Chores"
        }
        return "Home Chores"
    }

    private var heroSubtitleText: String {
        if prefs.quietModeEnabled {
            return actionableDueTodayCount == 0
                ? "Quiet view · all caught up today"
                : "Quiet view · \(actionableDueTodayCount) due today"
        }
        let duePart = actionableDueTodayCount == 0
            ? "All caught up today"
            : "\(actionableDueTodayCount) due today"
        return "\(duePart) · \(prefs.themePreset.shortLabel)"
    }

    // MARK: - 2. Browse / Filter by Room RIGHT AT THE TOP

    private var topRoomFilterSection: some View {
        let populatedRooms = RoomCategory.allCases.filter { room in
            activeUnarchivedTasks.contains(where: { $0.room == room })
        }

        return VStack(alignment: .leading, spacing: 10) {
            if !populatedRooms.isEmpty {
                HStack(alignment: .center, spacing: 8) {
                    Text(theme.isTerminalHUD ? "[ FILTER BY ROOM ]" : "Filter by Room")
                        .themeFont(.microTag, in: theme)
                        .foregroundStyle(theme.isTerminalHUD ? theme.accentPrimary : theme.secondaryInk)

                    Spacer()

                    if session.selectedRoom != nil {
                        Button("Clear Filter") {
                            HapticsEngine.shared.playMechanicalTap()
                            withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                                session.selectedRoom = nil
                            }
                        }
                        .themeFont(.captionStrong, in: theme)
                        .foregroundStyle(theme.accentPrimary)
                        .fixedSize(horizontal: true, vertical: false)
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
                                    .font(.system(size: 10, weight: .bold))
                                Text(session.showRoomHealthGrid ? "Compact" : "Overview")
                                    .themeFont(.microTag, in: theme)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(theme.secondaryInk)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 5 : 99, style: .continuous)
                                    .fill(theme.canvasSecondary)
                            )
                        }
                        .buttonStyle(.plain)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }

                // Instant 1-Tap Room Filter Pills (Width-Normalized Across All Fonts)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            HapticsEngine.shared.playMechanicalTap()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                                session.selectedRoom = nil
                            }
                        } label: {
                            Text("All Rooms")
                                .themeFont(.pillLabel, in: theme)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 13)
                                .frame(height: 34)
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
                                        StylizedVectorGlyphView(
                                            glyphKey: String(room.omarchyIconKey.dropFirst("omarchy:".count)),
                                            primaryColor: isSelected ? .white : roomTint,
                                            secondaryColor: isSelected ? .white.opacity(0.85) : theme.accentSecondary,
                                            glyphSize: 15
                                        )
                                    } else {
                                        Image(systemName: room.symbolName)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(isSelected ? .white : roomTint)
                                    }

                                    Text(room.shortTitle)
                                        .themeFont(.pillLabel, in: theme)
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)

                                    if health.dueCount > 0 {
                                        Text("\(health.dueCount)")
                                            .themeFont(.microTag, in: theme)
                                            .foregroundStyle(isSelected ? roomTint : .white)
                                            .padding(.horizontal, 5.5)
                                            .padding(.vertical, 1.5)
                                            .background(
                                                Capsule().fill(isSelected ? .white : theme.dueNowColor)
                                            )
                                            .fixedSize()
                                    }
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 34)
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
                    ChoreIconBadgeView(iconSymbol: room.symbolName, tint: roomColor, size: 34)
                    Spacer()
                    if health.dueCount > 0 {
                        Text("\(health.dueCount) due")
                            .themeFont(.microTag, in: theme)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(theme.dueNowColor))
                            .fixedSize()
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.freshColor)
                            .font(.system(size: 15, weight: .bold))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(room.title)
                        .themeFont(.subheadlineStrong, in: theme)
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(health.totalCount) \(health.totalCount == 1 ? "chore" : "chores")")
                        .themeFont(.caption, in: theme)
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

    // MARK: - 3. Clean Sub-Filter & View Row (Width-Stable Across All Themes)

    private var filterAndViewControlRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                        session.lowSpoonsFilterEnabled.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10.5, weight: .bold))
                        Text("Quick & Easy (≤5m)")
                            .themeFont(.pillLabel, in: theme)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 33)
                }
                .buttonStyle(
                    TactileActionButtonStyle(
                        fill: session.lowSpoonsFilterEnabled ? theme.freshColor : theme.cardSurface,
                        foreground: session.lowSpoonsFilterEnabled ? .white : theme.primaryInk
                    )
                )

                if members.count > 1 {
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                            session.showEveryoneChores.toggle()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: session.showEveryoneChores ? "person.2.fill" : "person.fill")
                                .font(.system(size: 10.5, weight: .bold))
                            Text(session.showEveryoneChores ? "Showing Everyone" : "My Turn Only")
                                .themeFont(.pillLabel, in: theme)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 33)
                    }
                    .buttonStyle(
                        TactileActionButtonStyle(
                            fill: session.showEveryoneChores ? theme.accentSecondary : theme.cardSurface,
                            foreground: session.showEveryoneChores ? theme.onAccentSecondary : theme.primaryInk
                        )
                    )
                }

                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                        prefs.layoutMode = (prefs.layoutMode == .spotlightAndRooms) ? .freshnessBatteryStream : .spotlightAndRooms
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: prefs.layoutMode.symbolName)
                            .font(.system(size: 10.5, weight: .bold))
                        Text(prefs.layoutMode.shortLabel)
                            .themeFont(.pillLabel, in: theme)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 33)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.cardSurface, foreground: theme.primaryInk))

                Menu {
                    Button {
                        session.customizingThemePreset = prefs.themePreset
                    } label: {
                        Label("Customize \(prefs.themePreset.shortLabel) Colors & Type…", systemImage: "eyedropper.halffull")
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
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(theme.accentPrimary)
                        Text(prefs.themePreset.shortLabel)
                            .themeFont(.pillLabel, in: theme)
                            .foregroundStyle(theme.primaryInk)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(theme.secondaryInk)
                    }
                    .padding(.horizontal, 11)
                    .frame(height: 33)
                    .adhousedCard(compact: true)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - 4. Vacation / Break Mode Status Banner

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
                            .themeFont(.subheadlineStrong, in: theme)
                            .foregroundStyle(theme.primaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(activeBreak.formattedRangeSummary())
                            .themeFont(.captionStrong, in: theme)
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
                            .themeFont(.pillLabel, in: theme)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(TactileActionButtonStyle(fill: theme.cardElevatedSurface, foreground: theme.primaryInk))

                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        try? TaskActionService.clearAwayPause(in: modelContext)
                    } label: {
                        Text("I'm Back")
                            .themeFont(.pillLabel, in: theme)
                            .fixedSize(horizontal: true, vertical: false)
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
                        .themeFont(.subheadlineStrong, in: theme)
                        .foregroundStyle(theme.primaryInk)
                    Text("Resumes at \(pauseUntil.formatted(date: .abbreviated, time: .shortened))")
                        .themeFont(.caption, in: theme)
                        .foregroundStyle(theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    try? TaskActionService.clearAwayPause(in: modelContext)
                } label: {
                    Text("Resume")
                        .themeFont(.pillLabel, in: theme)
                        .fixedSize(horizontal: true, vertical: false)
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
                        .themeFont(.subheadlineStrong, in: theme)
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(upcoming.formattedRangeSummary())
                        .themeFont(.caption, in: theme)
                        .foregroundStyle(theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    session.presentingVacationBreakSheet = true
                } label: {
                    Text("Edit")
                        .themeFont(.pillLabel, in: theme)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.cardElevatedSurface, foreground: theme.primaryInk))
            }
            .padding(13)
            .adhousedCard(highlightTint: theme.accentPrimary, compact: true)
        }
    }

    // MARK: - 5. Subtle Weekly Progress Card

    private var momentumPulseStrip: some View {
        let stats = FreshnessCalculator.momentumStats(completions: completions)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.isTerminalHUD ? "[ THIS WEEK ]" : "THIS WEEK")
                    .themeFont(.microTag, in: theme)
                    .foregroundStyle(theme.accentPrimary)
                SalientText(
                    stats.headline,
                    style: .captionStrong,
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

    // MARK: - 6. Bottom Floating Dock

    private var bottomFloatingDock: some View {
        VStack(spacing: 10) {
            if let toast = session.undoToast {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(theme.freshColor)
                        .font(.title3)
                    Text("Completed **\(toast.taskTitle)**")
                        .themeFont(.body, in: theme)
                        .foregroundStyle(theme.primaryInk)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 6)
                    Button("Undo") {
                        session.performUndoToast(in: modelContext)
                    }
                    .themeFont(.subheadlineStrong, in: theme)
                    .foregroundStyle(theme.accentSecondary)
                    .fixedSize(horizontal: true, vertical: false)
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
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(theme.warmingColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Focus Timer: \(sprint.taskTitle)")
                                .themeFont(.captionStrong, in: theme)
                                .foregroundStyle(theme.primaryInk)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(remaining > 0 ? String(format: "%d:%02d left", mins, secs) : "Timer finished — tap Done!")
                                .themeFont(.caption, in: theme)
                                .foregroundStyle(theme.secondaryInk)
                        }
                        Spacer(minLength: 6)
                        Button {
                            if let match = tasks.first(where: { $0.id == sprint.taskID }) {
                                session.presentingSprintSheetForTask = match
                            }
                        } label: {
                            Text("Open")
                                .themeFont(.pillLabel, in: theme)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 11)
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
                            .font(.system(size: 13.5, weight: .bold))
                        Text("Catalog")
                            .themeFont(.subheadlineStrong, in: theme)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.cardSurface, foreground: theme.primaryInk))

                Spacer()

                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    session.presentingNewTaskSheet = true
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("Add Chore")
                            .themeFont(.subheadlineStrong, in: theme)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 44)
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
