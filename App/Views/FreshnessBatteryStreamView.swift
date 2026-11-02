import SwiftUI
import ADHOUSEDCore

struct FreshnessBatteryStreamView: View {
    @Environment(\.adhousedTheme) private var theme
    @Bindable var session: AppSessionViewModel

    let tasks: [ChoreTask]
    let members: [HouseholdMember]
    let activeMember: HouseholdMember?

    @State private var showStillFreshDrawer: Bool = false

    private var prioritizedStream: [(task: ChoreTask, snapshot: TaskFreshnessSnapshot)] {
        let visible = tasks.filter { task in
            guard !task.isArchived else { return false }
            if let room = session.selectedRoom, task.room != room {
                return false
            }
            if session.lowSpoonsFilterEnabled && !task.isQuickLowSpoonWin {
                return false
            }
            if !session.showEveryoneChores && members.count > 1 && !task.isActionable(forMemberID: activeMember?.id) {
                return false
            }
            return true
        }
        return FreshnessCalculator.sortedByUrgency(tasks: visible, forMemberID: activeMember?.id)
    }

    var body: some View {
        let activeDepleting = prioritizedStream.filter { $0.snapshot.isActionableToday || $0.snapshot.batteryFill <= 0.55 }
        let stillFresh = prioritizedStream.filter { !$0.snapshot.isActionableToday && $0.snapshot.batteryFill > 0.55 }

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 7) {
                    Image(systemName: "battery.50percent")
                        .foregroundStyle(theme.warmingColor)
                    Text(session.selectedRoom != nil ? "\(session.selectedRoom!.title) — Battery View" : "Chore Battery Levels")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                Text("Lowest first")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryInk)
            }

            if activeDepleting.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "battery.100percent.bolt")
                        .font(.title2)
                        .foregroundStyle(theme.freshColor)
                    Text("Every chore in this view is well-charged right now!")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(16)
                .adhousedCard(highlightTint: theme.freshColor)
            } else {
                ForEach(activeDepleting, id: \.task.id) { pair in
                    ChoreTaskCardView(
                        session: session,
                        task: pair.task,
                        snapshot: pair.snapshot,
                        members: members,
                        activeMember: activeMember,
                        displayStyle: .batteryStreamRow
                    )
                }
            }

            if !stillFresh.isEmpty {
                VStack(alignment: .leading, spacing: 11) {
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            showStillFreshDrawer.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.freshColor)
                            Text("Not Due Yet · Well Charged (\(stillFresh.count))")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(theme.secondaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            Image(systemName: showStillFreshDrawer ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.secondaryInk)
                        }
                        .padding(14)
                        .adhousedCard(compact: true)
                    }
                    .buttonStyle(.plain)

                    if showStillFreshDrawer {
                        ForEach(stillFresh, id: \.task.id) { pair in
                            ChoreTaskCardView(
                                session: session,
                                task: pair.task,
                                snapshot: pair.snapshot,
                                members: members,
                                activeMember: activeMember,
                                displayStyle: .batteryStreamRow
                            )
                            .opacity(0.82)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}
