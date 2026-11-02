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
            if session.lowSpoonsFilterEnabled && !task.isQuickLowSpoonWin {
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
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "battery.50percent")
                        .foregroundStyle(theme.warmingColor)
                    Text(theme.hudTag(theme.isTerminalHUD ? "Battery Stream" : "Freshness Battery Stream"))
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(theme.primaryInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 6)
                Text("Sorted by depletion")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryInk)
            }

            if activeDepleting.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "battery.100percent.bolt")
                        .font(.title2)
                        .foregroundStyle(theme.freshColor)
                    Text("Every household chore battery is above 55% charge!")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                    Spacer()
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

            // Auto-dimmed collapsible drawer for Still-Fresh items (>55% charge)
            if !stillFresh.isEmpty {
                VStack(alignment: .leading, spacing: 11) {
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            showStillFreshDrawer.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(theme.freshColor)
                            Text("Still Charged & Handled (\(stillFresh.count))")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(theme.secondaryInk)
                            Spacer()
                            Image(systemName: showStillFreshDrawer ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.secondaryInk)
                        }
                        .padding(14)
                        .adhousedCard(compact: true)
                    }

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
                            .opacity(0.76)
                        }
                    }
                }
                .padding(.top, 6)
            }
        }
    }
}
