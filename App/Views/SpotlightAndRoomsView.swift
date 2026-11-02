import SwiftUI
import ADHOUSEDCore

struct SpotlightAndRoomsView: View {
    @Environment(\.adhousedTheme) private var theme
    @Bindable var session: AppSessionViewModel

    let tasks: [ChoreTask]
    let members: [HouseholdMember]
    let activeMember: HouseholdMember?
    var isQuietMode: Bool = false

    @State private var showPartnerSection: Bool = false
    @State private var showUpcomingDrawer: Bool = false

    private var filteredTasks: [ChoreTask] {
        tasks.filter { task in
            guard !task.isArchived else { return false }
            if let room = session.selectedRoom, task.room != room {
                return false
            }
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

    /// Tasks due today for me (or everyone if `showEveryoneChores` is enabled or a specific room is selected).
    private var dueTodayPrimary: [(task: ChoreTask, snapshot: TaskFreshnessSnapshot)] {
        prioritizedAll.filter { pair in
            guard pair.snapshot.isActionableToday else { return false }
            if session.showEveryoneChores || members.count <= 1 {
                return true
            }
            return pair.task.isActionable(forMemberID: activeMember?.id)
        }
    }

    /// Partner's due tasks (when >1 member and viewing "My Turn Only" mode).
    private var dueForPartnerToday: [(task: ChoreTask, snapshot: TaskFreshnessSnapshot)] {
        guard members.count > 1 && !session.showEveryoneChores else { return [] }
        return prioritizedAll.filter { pair in
            pair.snapshot.isActionableToday && !pair.task.isActionable(forMemberID: activeMember?.id)
        }
    }

    /// Chores that are already clean / not due yet!
    private var notDueYetItems: [(task: ChoreTask, snapshot: TaskFreshnessSnapshot)] {
        prioritizedAll.filter { !$0.snapshot.isActionableToday }
    }

    private var cardStyle: ChoreCardDisplayStyle {
        isQuietMode ? .quietMinimalRow : .spotlightCard
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isQuietMode ? 14 : 20) {
            dueTodaySection

            if !dueForPartnerToday.isEmpty {
                partnerDueSection
            }

            if !notDueYetItems.isEmpty {
                notDueYetSection
            }
        }
    }

    // MARK: - 1. Due Today Section

    private var dueTodaySection: some View {
        let cap = session.selectedRoom != nil ? 12 : (isQuietMode ? 5 : 4)
        let visibleDeck = session.showAllDueTasksInSpotlight
            ? dueTodayPrimary
            : Array(dueTodayPrimary.prefix(cap))
        let hiddenCount = max(0, dueTodayPrimary.count - cap)

        let sectionTitle: String = {
            if let room = session.selectedRoom {
                return "\(room.title) — Due Today"
            }
            return isQuietMode ? "Focus Today" : "Due Today"
        }()

        return VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                Text(sectionTitle)
                    .font(isQuietMode ? .headline.weight(.bold) : .title3.weight(.heavy))
                    .foregroundStyle(theme.primaryInk)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Text(dueTodayPrimary.isEmpty ? "All done" : "\(dueTodayPrimary.count) due")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(dueTodayPrimary.isEmpty ? theme.freshColor : theme.dueNowColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((dueTodayPrimary.isEmpty ? theme.freshColor : theme.dueNowColor).opacity(0.14))
                    )
            }

            if visibleDeck.isEmpty {
                calmCaughtUpCard
            } else {
                VStack(spacing: isQuietMode ? 9 : 12) {
                    ForEach(visibleDeck, id: \.task.id) { pair in
                        ChoreTaskCardView(
                            session: session,
                            task: pair.task,
                            snapshot: pair.snapshot,
                            members: members,
                            activeMember: activeMember,
                            displayStyle: cardStyle
                        )
                    }
                }

                if hiddenCount > 0 {
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            session.showAllDueTasksInSpotlight.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: session.showAllDueTasksInSpotlight ? "chevron.up.circle.fill" : "plus.circle.fill")
                            Text(
                                session.showAllDueTasksInSpotlight
                                    ? "Show top \(cap) only"
                                    : "Show \(hiddenCount) more due today"
                            )
                            Spacer()
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.secondaryInk)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .adhousedCard(compact: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var calmCaughtUpCard: some View {
        let activeBreak = ADHOUSEDPreferences.shared.activeVacationBreak()

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((activeBreak != nil ? theme.warmingColor : theme.freshColor).opacity(0.16))
                    .frame(width: 44, height: 44)
                Image(systemName: activeBreak?.iconSymbol ?? "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(activeBreak != nil ? theme.warmingColor : theme.freshColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                SalientText(
                    activeBreak != nil
                        ? "Paused for \(activeBreak!.title)"
                        : (session.selectedRoom != nil
                            ? "Nothing due in \(session.selectedRoom!.title) right now!"
                            : (session.lowSpoonsFilterEnabled
                                ? "No quick 5-minute chores due right now!"
                                : "You're all caught up for today!")),
                    font: .subheadline.weight(.bold),
                    color: theme.primaryInk
                )
                Text(
                    activeBreak != nil
                        ? "Chores and alerts resume \(activeBreak!.endDate.formatted(date: .abbreviated, time: .shortened))."
                        : "Everything on your list is taken care of."
                )
                .font(.caption)
                .foregroundStyle(theme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(15)
        .adhousedCard(highlightTint: activeBreak != nil ? theme.warmingColor : theme.freshColor)
    }

    // MARK: - 2. Partner's Turn Section (Crystal Clear Replacement for "Partner Turns")

    private var partnerDueSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                HapticsEngine.shared.playMechanicalTap()
                withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                    showPartnerSection.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.accentSecondary)
                    Text("Assigned to Partner (\(dueForPartnerToday.count) due)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                    Spacer()
                    Image(systemName: showPartnerSection ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.secondaryInk)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .adhousedCard(compact: true)
            }
            .buttonStyle(.plain)

            if showPartnerSection {
                VStack(spacing: isQuietMode ? 9 : 11) {
                    ForEach(dueForPartnerToday, id: \.task.id) { pair in
                        ChoreTaskCardView(
                            session: session,
                            task: pair.task,
                            snapshot: pair.snapshot,
                            members: members,
                            activeMember: activeMember,
                            displayStyle: cardStyle
                        )
                    }
                }
            }
        }
    }

    // MARK: - 3. Not Due Yet Section (Crystal Clear Replacement for "Warming Up")

    private var notDueYetSection: some View {
        let autoExpand = session.selectedRoom != nil
        let isExpanded = autoExpand || showUpcomingDrawer

        return VStack(alignment: .leading, spacing: 10) {
            if autoExpand {
                Text("Not Due Yet in \(session.selectedRoom!.title)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.secondaryInk)
                    .padding(.top, 2)
            } else {
                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                        showUpcomingDrawer.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.freshColor)
                        Text("Not Due Yet · Coming Up Later (\(notDueYetItems.count))")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(theme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Image(systemName: showUpcomingDrawer ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.secondaryInk)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .adhousedCard(compact: true)
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                VStack(spacing: isQuietMode ? 9 : 11) {
                    ForEach(notDueYetItems, id: \.task.id) { pair in
                        ChoreTaskCardView(
                            session: session,
                            task: pair.task,
                            snapshot: pair.snapshot,
                            members: members,
                            activeMember: activeMember,
                            displayStyle: cardStyle
                        )
                    }
                }
            }
        }
    }
}
