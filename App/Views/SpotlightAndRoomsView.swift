import SwiftUI
import ADHOUSEDCore

struct SpotlightAndRoomsView: View {
    @Environment(\.adhousedTheme) private var theme
    @Bindable var session: AppSessionViewModel

    let tasks: [ChoreTask]
    let members: [HouseholdMember]
    let activeMember: HouseholdMember?

    private var filteredTasks: [ChoreTask] {
        tasks.filter { task in
            guard !task.isArchived else { return false }
            if session.lowSpoonsFilterEnabled && !task.isQuickLowSpoonWin {
                return false
            }
            return true
        }
    }

    private var prioritizedAll: [(task: ChoreTask, snapshot: TaskFreshnessSnapshot)] {
        FreshnessCalculator.sortedByUrgency(
            tasks: filteredTasks,
            forMemberID: activeMember?.id
        )
    }

    /// Focus Deck strictly shows tasks actionable today for the active household member (or Up for Grabs).
    private var dueForMeToday: [(task: ChoreTask, snapshot: TaskFreshnessSnapshot)] {
        prioritizedAll.filter { pair in
            pair.snapshot.isActionableToday && pair.task.isActionable(forMemberID: activeMember?.id)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            todaySpotlightSection
            roomsBentoSection
        }
    }

    // MARK: - Today Spotlight (Capped Focus Deck to Prevent Wall-of-Chores Paralysis)

    private var todaySpotlightSection: some View {
        let cap = 3
        let visibleDeck = session.showAllDueTasksInSpotlight
            ? dueForMeToday
            : Array(dueForMeToday.prefix(cap))
        let hiddenCount = max(0, dueForMeToday.count - cap)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 7) {
                    Image(systemName: theme.isTerminalHUD ? "terminal.fill" : "sun.max.fill")
                        .foregroundStyle(theme.dueNowColor)
                    Text(theme.hudTag("Today Spotlight"))
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(theme.primaryInk)
                }
                Spacer()
                Text(dueForMeToday.isEmpty ? "0 due" : "\(dueForMeToday.count) ready")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(dueForMeToday.isEmpty ? theme.freshColor : theme.dueNowColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 5 : 99, style: .continuous)
                            .fill((dueForMeToday.isEmpty ? theme.freshColor : theme.dueNowColor).opacity(0.15))
                    )
            }

            if visibleDeck.isEmpty {
                calmCaughtUpCard
            } else {
                VStack(spacing: 13) {
                    ForEach(visibleDeck, id: \.task.id) { pair in
                        ChoreTaskCardView(
                            session: session,
                            task: pair.task,
                            snapshot: pair.snapshot,
                            members: members,
                            activeMember: activeMember,
                            displayStyle: .spotlightCard
                        )
                    }
                }

                if hiddenCount > 0 {
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            session.showAllDueTasksInSpotlight.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: session.showAllDueTasksInSpotlight ? "chevron.up.circle.fill" : "plus.circle.fill")
                            Text(
                                session.showAllDueTasksInSpotlight
                                    ? "Cap back to Top 3 Focus Deck"
                                    : "Show \(hiddenCount) more ready today (hidden to prevent overwhelm)"
                            )
                            Spacer()
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.secondaryInk)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .adhousedCard(compact: true)
                    }
                }
            }
        }
    }

    private var calmCaughtUpCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(theme.freshColor.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(theme.freshColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                SalientText(
                    session.lowSpoonsFilterEnabled
                        ? "Zero Low-Spoons tasks due right now!"
                        : "Your Focus Deck is sparkling clear!",
                    font: .headline.weight(.bold),
                    color: theme.primaryInk
                )
                Text("Everything assigned to your turn is still fresh. Browse rooms below if you feel like getting ahead.")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryInk)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .adhousedCard(highlightTint: theme.freshColor)
    }

    // MARK: - Room / Zone Bento Switcher

    private var roomsBentoSection: some View {
        let populatedRooms = RoomCategory.allCases.filter { room in
            filteredTasks.contains(where: { $0.room == room })
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(theme.hudTag("Browse by Room"))
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(theme.primaryInk)
                Spacer()
                if session.selectedRoom != nil {
                    Button("Show All Rooms") {
                        HapticsEngine.shared.playMechanicalTap()
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
                            session.selectedRoom = nil
                        }
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accentPrimary)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)], spacing: 11) {
                ForEach(populatedRooms) { room in
                    roomBentoTile(for: room)
                }
            }

            // Room Chores List (either selected room or warming-up chores across rooms)
            let roomPairs: [(task: ChoreTask, snapshot: TaskFreshnessSnapshot)] = {
                if let selectedRoom = session.selectedRoom {
                    return prioritizedAll.filter { $0.task.room == selectedRoom }
                } else {
                    return prioritizedAll.filter { !$0.snapshot.isActionableToday || !$0.task.isActionable(forMemberID: activeMember?.id) }
                }
            }()

            if !roomPairs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(session.selectedRoom != nil ? "\(session.selectedRoom!.title) Chores" : "Warming Up & Partner Turns")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(theme.secondaryInk)
                        .padding(.top, 4)

                    ForEach(roomPairs, id: \.task.id) { pair in
                        ChoreTaskCardView(
                            session: session,
                            task: pair.task,
                            snapshot: pair.snapshot,
                            members: members,
                            activeMember: activeMember,
                            displayStyle: .spotlightCard
                        )
                    }
                }
            }
        }
    }

    private func roomBentoTile(for room: RoomCategory) -> some View {
        let health = FreshnessCalculator.roomHealth(room: room, tasks: filteredTasks)
        let isSelected = session.selectedRoom == room
        let roomColor = theme.roomAccent(for: room)

        return Button {
            HapticsEngine.shared.playMechanicalTap()
            withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
                session.selectedRoom = isSelected ? nil : room
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 6 : 10, style: .continuous)
                            .fill(roomColor.opacity(0.20))
                            .frame(width: 34, height: 34)
                        Image(systemName: room.symbolName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(roomColor)
                    }
                    Spacer()
                    if health.dueCount > 0 {
                        Text("\(health.dueCount) due")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(theme.isDark && theme.isTerminalHUD ? Color(hex: "#13141C") : .white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 5 : 99, style: .continuous)
                                    .fill(theme.dueNowColor)
                            )
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.freshColor)
                            .font(.subheadline)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    SalientText(
                        room.shortTitle,
                        font: .subheadline.weight(.heavy),
                        color: theme.primaryInk,
                        lineLimit: 1
                    )
                    Text("\(Int(round(health.averageFill * 100)))% fresh · \(health.totalCount) \(health.totalCount == 1 ? "task" : "tasks")")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(theme.secondaryInk)
                }

                GeometryReader { geo in
                    let barRadius: CGFloat = theme.isTerminalHUD ? 2.5 : 4.0
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: barRadius, style: .continuous)
                            .fill(theme.canvasSecondary)
                        RoundedRectangle(cornerRadius: barRadius, style: .continuous)
                            .fill(health.dueCount > 0 ? theme.dueNowColor : roomColor)
                            .frame(width: max(8, geo.size.width * health.averageFill))
                    }
                }
                .frame(height: 6)
            }
            .padding(13)
            .adhousedCard(highlightTint: isSelected ? roomColor : nil, compact: true)
        }
        .buttonStyle(.plain)
    }
}
