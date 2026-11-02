import WidgetKit
import SwiftUI
import SwiftData
import AppIntents
import ADHOUSEDCore

struct WidgetChoreRowItem: Identifiable, Sendable {
    let id: String
    let title: String
    let iconSymbol: String
    let room: RoomCategory
    let estimatedMinutes: Int
    let batteryFill: Double
    let stage: FreshnessStage
    let cadenceSummary: String
    let turnBadge: String?
    let isInUndoGraceState: Bool
}

struct ADHOUSEDFocusTimelineEntry: TimelineEntry {
    let date: Date
    let headerLabel: String
    let items: [WidgetChoreRowItem]
    let totalDueCount: Int
    let themePreset: ThemePreset
    let colorSchemePreference: ColorSchemePreference
    let bionicReadingEnabled: Bool
}

struct ADHOUSEDFocusProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ADHOUSEDFocusTimelineEntry {
        sampleEntry(at: .now)
    }

    func snapshot(for configuration: ADHOUSEDWidgetConfigIntent, in context: Context) async -> ADHOUSEDFocusTimelineEntry {
        await buildEntry(for: configuration, at: .now)
    }

    func timeline(for configuration: ADHOUSEDWidgetConfigIntent, in context: Context) async -> Timeline<ADHOUSEDFocusTimelineEntry> {
        let now = Date()
        let (currentEntry, earliestUndoExpiry) = await buildEntryWithExpiry(for: configuration, at: now)

        var entries: [ADHOUSEDFocusTimelineEntry] = [currentEntry]
        if let expiry = earliestUndoExpiry, expiry > now {
            // Schedule automatic post-Undo-grace rotation entry so the 8s Undo pill transitions to the next chore!
            let postGraceDate = expiry.addingTimeInterval(0.4)
            let (rotatedEntry, _) = await buildEntryWithExpiry(for: configuration, at: postGraceDate)
            entries.append(rotatedEntry)
        }

        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 20, to: now) ?? now.addingTimeInterval(1200)
        return Timeline(entries: entries, policy: .after(nextRefresh))
    }

    @MainActor
    private func buildEntry(
        for configuration: ADHOUSEDWidgetConfigIntent,
        at referenceDate: Date
    ) async -> ADHOUSEDFocusTimelineEntry {
        await buildEntryWithExpiry(for: configuration, at: referenceDate).0
    }

    @MainActor
    private func buildEntryWithExpiry(
        for configuration: ADHOUSEDWidgetConfigIntent,
        at referenceDate: Date
    ) async -> (ADHOUSEDFocusTimelineEntry, Date?) {
        let prefs = ADHOUSEDPreferences.shared
        prefs.reloadFromSharedDefaults()

        guard let container = try? SharedAppGroup.makeModelContainer() else {
            return (sampleEntry(at: referenceDate), nil)
        }
        let context = container.mainContext
        let allTasks = ((try? context.fetch(FetchDescriptor<ChoreTask>())) ?? []).filter { !$0.isArchived }
        let members = (try? context.fetch(FetchDescriptor<HouseholdMember>())) ?? []
        let membersByID = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
        let activeMemberID = configuration.onlyMyActionableTasks ? prefs.activeMemberID : nil

        if allTasks.isEmpty {
            return (
                ADHOUSEDFocusTimelineEntry(
                    date: referenceDate,
                    headerLabel: "ADHOUSED",
                    items: [],
                    totalDueCount: 0,
                    themePreset: prefs.themePreset,
                    colorSchemePreference: prefs.colorSchemePreference,
                    bionicReadingEnabled: prefs.bionicReadingEnabled
                ),
                nil
            )
        }

        let candidateTasks: [ChoreTask]
        let header: String

        switch configuration.displayMode {
        case .topDueQueue:
            header = "FOCUS QUEUE"
            candidateTasks = allTasks.filter {
                !configuration.onlyMyActionableTasks || $0.isActionable(forMemberID: activeMemberID) || $0.hasActiveUndoGraceWindow(at: referenceDate)
            }
        case .lowSpoonsQuickWins:
            header = "QUICK WINS (≤5M)"
            candidateTasks = allTasks.filter {
                $0.isQuickLowSpoonWin && (!configuration.onlyMyActionableTasks || $0.isActionable(forMemberID: activeMemberID) || $0.hasActiveUndoGraceWindow(at: referenceDate))
            }
        case .roomFilter:
            let room = configuration.roomFilter.roomCategory
            header = room.title.uppercased()
            candidateTasks = allTasks.filter { $0.room == room }
        case .pinnedChore:
            header = "PINNED CHORE"
            if let pinnedID = configuration.pinnedChore?.id {
                candidateTasks = allTasks.filter { $0.id.uuidString == pinnedID }
            } else {
                candidateTasks = Array(allTasks.prefix(1))
            }
        }

        let sorted = FreshnessCalculator.sortedByUrgency(
            tasks: candidateTasks,
            forMemberID: activeMemberID,
            now: referenceDate
        )

        // Prefer due or active-undo tasks; if none due and mode is pinned/room, show freshest status
        let activeBreak = prefs.activeVacationBreak(at: referenceDate)
        let dueOnly = sorted.filter { $0.snapshot.isActionableToday || $0.task.hasActiveUndoGraceWindow(at: referenceDate) }
        let chosenSource = (dueOnly.isEmpty && (configuration.displayMode == .pinnedChore || configuration.displayMode == .roomFilter))
            ? Array(sorted.prefix(4))
            : Array(dueOnly.prefix(5))

        let nextBreakTransition: Date? = {
            if let activeBreak {
                return activeBreak.endDate
            }
            return prefs.nextUpcomingVacationBreak(at: referenceDate)?.startDate
        }()

        let earliestExpiry = (chosenSource
            .compactMap { $0.task.hasActiveUndoGraceWindow(at: referenceDate) ? $0.task.pendingUndoExpiresAt : nil }
            + [nextBreakTransition].compactMap { $0 })
            .min()

        let effectiveHeader = activeBreak != nil ? "⏸ \(activeBreak!.title.uppercased())" : header

        let items: [WidgetChoreRowItem] = chosenSource.map { pair in
            let task = pair.task
            let snap = pair.snapshot
            let turnText: String? = {
                guard members.count > 1, let ownerID = task.responsibleMemberID, let owner = membersByID[ownerID] else {
                    return nil
                }
                return "\(owner.emoji) \(owner.displayName)"
            }()

            return WidgetChoreRowItem(
                id: task.id.uuidString,
                title: task.title,
                iconSymbol: task.iconSymbol,
                room: task.room,
                estimatedMinutes: task.estimatedMinutes,
                batteryFill: snap.batteryFill,
                stage: snap.stage,
                cadenceSummary: snap.cadenceSummary,
                turnBadge: turnText,
                isInUndoGraceState: task.hasActiveUndoGraceWindow(at: referenceDate)
            )
        }

        return (
            ADHOUSEDFocusTimelineEntry(
                date: referenceDate,
                headerLabel: effectiveHeader,
                items: items,
                totalDueCount: dueOnly.count,
                themePreset: prefs.themePreset,
                colorSchemePreference: prefs.colorSchemePreference,
                bionicReadingEnabled: prefs.bionicReadingEnabled
            ),
            earliestExpiry
        )
    }

    private func sampleEntry(at date: Date) -> ADHOUSEDFocusTimelineEntry {
        ADHOUSEDFocusTimelineEntry(
            date: date,
            headerLabel: "FOCUS QUEUE",
            items: [
                WidgetChoreRowItem(
                    id: UUID().uuidString,
                    title: "Unload dishwasher",
                    iconSymbol: "dishwasher.fill",
                    room: .kitchen,
                    estimatedMinutes: 5,
                    batteryFill: 0.08,
                    stage: .dueToday,
                    cadenceSummary: "Done yesterday · daily",
                    turnBadge: "🦊 Alex",
                    isInUndoGraceState: false
                ),
                WidgetChoreRowItem(
                    id: UUID().uuidString,
                    title: "Scoop litter box",
                    iconSymbol: "pawprint.fill",
                    room: .petsAndPlants,
                    estimatedMinutes: 3,
                    batteryFill: 0.05,
                    stage: .needsAttentionNow,
                    cadenceSummary: "Done 2d ago · daily",
                    turnBadge: nil,
                    isInUndoGraceState: false
                )
            ],
            totalDueCount: 2,
            themePreset: .warmTactileBento,
            colorSchemePreference: .signature,
            bionicReadingEnabled: false
        )
    }
}

struct ADHOUSEDFocusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: ADHOUSEDFocusTimelineEntry

    private var theme: ADHOUSEDThemeTokens {
        let effective = ADHOUSEDThemeTokens.effectiveColorScheme(
            preset: entry.themePreset,
            preference: entry.colorSchemePreference,
            systemColorScheme: colorScheme
        )
        return ADHOUSEDThemeTokens.resolve(preset: entry.themePreset, colorScheme: effective)
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallHomeWidget
            case .systemMedium:
                listHomeWidget(maxRows: 2)
            case .systemLarge:
                listHomeWidget(maxRows: 4)
            case .accessoryRectangular:
                lockScreenRectangularWidget
            case .accessoryCircular:
                lockScreenCircularWidget
            default:
                listHomeWidget(maxRows: 2)
            }
        }
        .fontDesign(theme.fontDesign)
        .environment(\.adhousedTheme, theme)
        .containerBackground(for: .widget) {
            theme.canvasBackground
        }
    }

    // MARK: - Home Screen Small (1-Tap Single Hero Chore + Inline Undo)

    private var smallHomeWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(theme.hudTag(entry.headerLabel))
                    .font(.system(size: 9, weight: .black, design: theme.fontDesign))
                    .tracking(0.7)
                    .foregroundStyle(theme.secondaryInk)
                Spacer()
                if entry.totalDueCount > 0 {
                    Text("\(entry.totalDueCount)")
                        .font(.system(size: 10, weight: .black, design: theme.fontDesign))
                        .foregroundStyle(theme.isDark && theme.isTerminalHUD ? Color(hex: "#13141C") : .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 4 : 99, style: .continuous)
                                .fill(theme.dueNowColor)
                        )
                }
            }

            if let top = entry.items.first {
                if top.isInUndoGraceState {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Marked Fresh!", systemImage: "checkmark.seal.fill")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(theme.freshColor)
                        Text(top.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.secondaryInk)
                            .lineLimit(2)
                        Spacer(minLength: 2)
                        Button(intent: UndoCompleteTaskIntent(taskIDString: top.id)) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Undo Tap")
                            }
                            .font(.caption.weight(.heavy))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 10).fill(theme.warmingColor))
                            .foregroundStyle(.black)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 5) {
                            Image(systemName: top.iconSymbol)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.roomAccent(for: top.room))
                            Text("⚡ \(top.estimatedMinutes)m")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(theme.secondaryInk)
                        }

                        SalientText(
                            top.title,
                            bionicEnabled: entry.bionicReadingEnabled,
                            font: .subheadline.weight(.heavy),
                            color: theme.primaryInk,
                            lineLimit: 2
                        )

                        Spacer(minLength: 2)

                        Button(intent: CompleteTaskIntent(taskIDString: top.id, fromWidgetUndoable: true)) {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Tap Done")
                            }
                            .font(.caption.weight(.heavy))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: theme.pillCornerRadius, style: .continuous)
                                    .fill(theme.accentPrimary)
                            )
                            .foregroundStyle(theme.onAccentPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(theme.freshColor)
                Text("All Fresh!")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(theme.primaryInk)
                Text("Zero chores due right now")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryInk)
                Spacer()
            }
        }
    }

    // MARK: - Home Screen Medium & Large (Multi-Row 1-Tap Queue + Inline Undo)

    private func listHomeWidget(maxRows: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: theme.isTerminalHUD ? "terminal.fill" : "sparkles")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(theme.accentPrimary)
                    Text(theme.hudTag(entry.headerLabel))
                        .font(.system(size: 10, weight: .black, design: theme.fontDesign))
                        .tracking(0.8)
                        .foregroundStyle(theme.secondaryInk)
                }
                Spacer()
                Text(entry.totalDueCount == 0 ? "All Caught Up" : "\(entry.totalDueCount) Ready")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(entry.totalDueCount == 0 ? theme.freshColor : theme.dueNowColor)
            }

            if entry.items.isEmpty {
                Spacer()
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title)
                        .foregroundStyle(theme.freshColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Focus Deck is Clear!")
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(theme.primaryInk)
                        Text("Every task for your turn is still fresh.")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryInk)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                VStack(spacing: 7) {
                    ForEach(entry.items.prefix(maxRows)) { item in
                        widgetInteractiveRow(item)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func widgetInteractiveRow(_ item: WidgetChoreRowItem) -> some View {
        HStack(spacing: 10) {
            if item.isInUndoGraceState {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(theme.freshColor)
                    .font(.headline)
                Text("Done: \(item.title)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.secondaryInk)
                    .lineLimit(1)
                Spacer()
                Button(intent: UndoCompleteTaskIntent(taskIDString: item.id)) {
                    Text("Undo")
                        .font(.caption2.weight(.black))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(theme.warmingColor))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: item.iconSymbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.roomAccent(for: item.room))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    SalientText(
                        item.title,
                        bionicEnabled: entry.bionicReadingEnabled,
                        font: .caption.weight(.heavy),
                        color: theme.primaryInk,
                        lineLimit: 1
                    )
                    HStack(spacing: 5) {
                        Text("\(item.room.shortTitle) · ⚡ \(item.estimatedMinutes)m")
                        if let turn = item.turnBadge {
                            Text("· \(turn)")
                        }
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.secondaryInk)
                    .lineLimit(1)
                }

                Spacer(minLength: 4)

                Button(intent: CompleteTaskIntent(taskIDString: item.id, fromWidgetUndoable: true)) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                        Text("Done")
                            .font(.system(size: 11, weight: .heavy))
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: theme.pillCornerRadius, style: .continuous)
                            .fill(theme.accentPrimary)
                    )
                    .foregroundStyle(theme.onAccentPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 8 : 12, style: .continuous)
                .fill(theme.cardSurface)
        )
        .overlay {
            if theme.isTerminalHUD {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: theme.focusGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.25
                    )
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(theme.borderInk, lineWidth: theme.usesHardOffsetShadow ? 1.8 : 0.8)
            }
        }
    }

    // MARK: - Lock Screen Accessory Rectangular & Circular (1-Tap Right Under Clock!)

    private var lockScreenRectangularWidget: some View {
        Group {
            if let top = entry.items.first {
                if top.isInUndoGraceState {
                    Button(intent: UndoCompleteTaskIntent(taskIDString: top.id)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Label("Marked Fresh!", systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.heavy))
                            Text("Tap here within 8s to Undo")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(intent: CompleteTaskIntent(taskIDString: top.id, fromWidgetUndoable: true)) {
                        HStack(spacing: 8) {
                            Image(systemName: "circle.inset.filled")
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(top.title)
                                    .font(.caption.weight(.heavy))
                                    .lineLimit(1)
                                Text("Tap to complete · \(top.estimatedMinutes)m · \(entry.totalDueCount) due")
                                    .font(.caption2)
                                    .opacity(0.85)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                    VStack(alignment: .leading, spacing: 1) {
                        Text("ADHOUSED Clear")
                            .font(.caption.weight(.bold))
                        Text("Zero chores due")
                            .font(.caption2)
                    }
                }
            }
        }
    }

    private var lockScreenCircularWidget: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let top = entry.items.first {
                Button(intent: CompleteTaskIntent(taskIDString: top.id, fromWidgetUndoable: true)) {
                    VStack(spacing: 1) {
                        Image(systemName: top.isInUndoGraceState ? "arrow.uturn.backward" : top.iconSymbol)
                            .font(.caption.weight(.bold))
                        Text("\(entry.totalDueCount)")
                            .font(.caption2.weight(.black))
                    }
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "checkmark")
                    .font(.headline.weight(.bold))
            }
        }
    }
}

struct ADHOUSEDFocusWidget: Widget {
    let kind: String = "ADHOUSEDFocusWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ADHOUSEDWidgetConfigIntent.self,
            provider: ADHOUSEDFocusProvider()
        ) { entry in
            ADHOUSEDFocusWidgetView(entry: entry)
        }
        .configurationDisplayName("ADHOUSED 1-Tap Chores")
        .description("Check off due household tasks in 1 tap (with an 8-second Undo safety window) right from your Home Screen or Lock Screen.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryCircular
        ])
    }
}
