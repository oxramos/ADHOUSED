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

    var body: some View {
        ZStack(alignment: .bottom) {
            theme.canvasBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topHeaderBar
                    awayPauseStatusBanner
                    usabilityAndEnergyControlStrip
                    momentumPulseStrip

                    switch prefs.layoutMode {
                    case .spotlightAndRooms:
                        SpotlightAndRoomsView(
                            session: session,
                            tasks: tasks,
                            members: members,
                            activeMember: activeMember
                        )
                    case .freshnessBatteryStream:
                        FreshnessBatteryStreamView(
                            session: session,
                            tasks: tasks,
                            members: members,
                            activeMember: activeMember
                        )
                    }

                    Spacer(minLength: 110)
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
                }
            )
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
            StarterCatalogOnboardingView(session: session, isInitialOnboarding: false)
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

    // MARK: - Top Header Bar

    private var topHeaderBar: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(household?.name.uppercased() ?? "ADHOUSED")
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(theme.secondaryInk)
                SalientText(
                    greetingTitle,
                    font: .title2.weight(.heavy),
                    color: theme.primaryInk,
                    lineLimit: 1
                )
            }

            Spacer(minLength: 6)

            // Shared Household Member Switcher Pill
            if !members.isEmpty {
                Menu {
                    Section("Viewing & Acting As") {
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
                    Divider()
                    Button {
                        session.presentingSettingsSheet = true
                    } label: {
                        Label("Manage Household & Sharing…", systemImage: "person.2.fill")
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(activeMember?.emoji ?? "🏠")
                            .font(.subheadline)
                        Text(activeMember?.displayName ?? "All")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(theme.primaryInk)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(theme.secondaryInk)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .adhousedCard(compact: true)
                }
            }

            // Away 3h Timed Pause Quick Button
            Button {
                HapticsEngine.shared.playMechanicalTap()
                if household?.isCurrentlyPausedAway() == true {
                    try? TaskActionService.clearAwayPause(in: modelContext)
                } else {
                    try? TaskActionService.pauseReminders(scope: .entireHousehold, durationMinutes: 180, in: modelContext)
                }
            } label: {
                Image(systemName: household?.isCurrentlyPausedAway() == true ? "play.fill" : "door.right.hand.open")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(household?.isCurrentlyPausedAway() == true ? theme.warmingColor : theme.primaryInk)
                    .frame(width: 38, height: 38)
                    .adhousedCard(compact: true)
            }
            .accessibilityLabel("Toggle Out of House 3 hour reminder pause")

            // Theme & Settings Button
            Button {
                HapticsEngine.shared.playMechanicalTap()
                session.presentingSettingsSheet = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.primaryInk)
                    .frame(width: 38, height: 38)
                    .adhousedCard(compact: true)
            }
            .accessibilityLabel("Settings and Theme Switcher")
        }
    }

    private var greetingTitle: String {
        if let name = activeMember?.displayName {
            return "\(name)'s Focus"
        }
        return "Home Focus"
    }

    // MARK: - Timed Away Pause Banner

    @ViewBuilder
    private var awayPauseStatusBanner: some View {
        if let household, let pauseUntil = household.awayPauseUntil, pauseUntil > .now {
            HStack(spacing: 12) {
                Image(systemName: "pause.circle.fill")
                    .font(.title3)
                    .foregroundStyle(theme.warmingColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Out of House — Alerts Paused")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                    Text("Persistent pings auto-resume at \(pauseUntil.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryInk)
                }
                Spacer()
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    try? TaskActionService.clearAwayPause(in: modelContext)
                } label: {
                    Text("I'm Home")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.warmingColor, foreground: .black))
            }
            .padding(13)
            .adhousedCard(highlightTint: theme.warmingColor, compact: true)
        }
    }

    // MARK: - Usability Mode & Low-Spoons Filter Strip

    private var usabilityAndEnergyControlStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Switch between Today Spotlight + Rooms & Freshness Battery Stream
                ForEach(LayoutUsabilityMode.allCases) { mode in
                    let isSelected = prefs.layoutMode == mode
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            prefs.layoutMode = mode
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.symbolName)
                                .font(.caption.weight(.bold))
                            Text(mode.shortLabel)
                                .font(.subheadline.weight(.bold))
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                    }
                    .buttonStyle(
                        TactileActionButtonStyle(
                            fill: isSelected ? theme.accentPrimary : theme.cardSurface,
                            foreground: isSelected ? theme.onAccentPrimary : theme.primaryInk
                        )
                    )
                }

                // Low-Spoons / Quick Wins Filter
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
                        session.lowSpoonsFilterEnabled.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.heart.fill")
                            .font(.caption.weight(.bold))
                        Text("Low Spoons (≤5m)")
                            .font(.subheadline.weight(.bold))
                    }
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                }
                .buttonStyle(
                    TactileActionButtonStyle(
                        fill: session.lowSpoonsFilterEnabled ? theme.warmingColor : theme.cardSurface,
                        foreground: session.lowSpoonsFilterEnabled ? Color(hex: "#111216") : theme.primaryInk
                    )
                )

                // Quick Multi-Theme Switcher Menu (Originals + Omarchy Quattro OS 4.x)
                Menu {
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
                                        systemImage: prefs.themePreset == preset ? "checkmark.circle.fill" : (preset.isOmarchyQuattroStyle ? "terminal.fill" : "paintpalette")
                                    )
                                }
                            }
                        }
                    }
                    Divider()
                    Button {
                        session.presentingSettingsSheet = true
                    } label: {
                        Label("Theme Studio & Light/Dark…", systemImage: "slider.horizontal.3")
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: theme.isTerminalHUD ? "terminal.fill" : "paintpalette.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.accentPrimary)
                        Text(prefs.themePreset.shortLabel)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(theme.primaryInk)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(theme.secondaryInk)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .adhousedCard(compact: true)
                }
            }
            .padding(.vertical, 3)
            .padding(.trailing, 6)
        }
    }

    // MARK: - Shame-Free Momentum Pulse Strip

    private var momentumPulseStrip: some View {
        let stats = FreshnessCalculator.momentumStats(completions: completions)

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.hudTag("HOUSEHOLD MOMENTUM"))
                    .font(.system(size: 10, weight: .heavy, design: theme.fontDesign))
                    .tracking(0.9)
                    .foregroundStyle(theme.accentPrimary)
                SalientText(
                    stats.headline,
                    font: .footnote.weight(.semibold),
                    color: theme.primaryInk,
                    lineLimit: 1
                )
            }
            Spacer(minLength: 8)
            HStack(spacing: 5) {
                ForEach(Array(stats.recent7DayActivityDots.enumerated()), id: \.offset) { _, active in
                    Group {
                        if theme.isTerminalHUD {
                            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                .fill(active ? theme.accentPrimary : theme.canvasSecondary)
                                .frame(width: 9, height: 9)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                        .strokeBorder(theme.borderInk.opacity(0.75), lineWidth: 0.9)
                                }
                        } else {
                            Circle()
                                .fill(active ? theme.accentPrimary : theme.canvasSecondary)
                                .frame(width: 9, height: 9)
                                .overlay {
                                    if theme.usesHardOffsetShadow {
                                        Circle().strokeBorder(theme.borderInk.opacity(0.6), lineWidth: 1)
                                    }
                                }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .adhousedCard(compact: true)
    }

    // MARK: - Bottom Floating Dock (Undo Toast + Active Sprint Bar + Add Chore)

    private var bottomFloatingDock: some View {
        VStack(spacing: 10) {
            if let toast = session.undoToast {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(theme.freshColor)
                        .font(.title3)
                    Text("Marked **\(toast.taskTitle)** fresh!")
                        .font(.subheadline)
                        .foregroundStyle(theme.primaryInk)
                        .lineLimit(1)
                    Spacer()
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
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Beat the Clock: \(sprint.taskTitle)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.primaryInk)
                                .lineLimit(1)
                            Text(remaining > 0 ? String(format: "%d:%02d left — you got this!", mins, secs) : "Time's up — tap Done if finished!")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.secondaryInk)
                        }
                        Spacer()
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
                        .buttonStyle(TactileActionButtonStyle(fill: theme.warmingColor, foreground: .black))
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
                        Image(systemName: "sparkles.rectangle.stack.fill")
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
                        Text("New Chore")
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
