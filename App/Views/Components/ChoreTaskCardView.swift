import SwiftUI
import SwiftData
import ADHOUSEDCore

enum ChoreCardDisplayStyle {
    case spotlightCard
    case batteryStreamRow
}

struct ChoreTaskCardView: View {
    @Environment(\.adhousedTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    @Bindable var session: AppSessionViewModel
    let task: ChoreTask
    let snapshot: TaskFreshnessSnapshot
    let members: [HouseholdMember]
    let activeMember: HouseholdMember?
    let displayStyle: ChoreCardDisplayStyle

    private var membersByID: [UUID: HouseholdMember] {
        Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
    }

    private var responsibleMember: HouseholdMember? {
        task.responsibleMemberID.flatMap { membersByID[$0] }
    }

    private var lastCompletedMember: HouseholdMember? {
        task.lastCompletedByMemberID.flatMap { membersByID[$0] }
    }

    var body: some View {
        let stageColor = theme.color(for: snapshot.stage)
        let roomColor = theme.roomAccent(for: task.room)
        let iconRadius: CGFloat = theme.isTerminalHUD ? 8 : 14

        VStack(alignment: .leading, spacing: 12) {
            // Top Row: Room Icon + Title + Cadence + Giant 1-Tap Check Button
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: iconRadius, style: .continuous)
                        .fill(roomColor.opacity(theme.isDark ? 0.20 : 0.14))
                        .frame(width: 46, height: 46)
                        .overlay {
                            if theme.isTerminalHUD {
                                RoundedRectangle(cornerRadius: iconRadius, style: .continuous)
                                    .strokeBorder(roomColor.opacity(0.45), lineWidth: 1.0)
                            }
                        }
                    Image(systemName: task.iconSymbol)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(roomColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(theme.hudTag(task.room.shortTitle.uppercased()))
                            .font(.system(size: 10, weight: .heavy, design: theme.fontDesign))
                            .tracking(0.8)
                            .foregroundStyle(roomColor)

                        if snapshot.isActionableToday {
                            Text("· \(snapshot.stage.label.uppercased())")
                                .font(.system(size: 10, weight: .heavy, design: theme.fontDesign))
                                .tracking(0.6)
                                .foregroundStyle(stageColor)
                        }
                    }

                    SalientText(
                        task.title,
                        font: .headline.weight(.bold),
                        color: theme.primaryInk,
                        lineLimit: 2
                    )

                    Text(attributionAndCadenceLine)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(theme.secondaryInk)
                }

                Spacer(minLength: 4)

                // Giant Tactile 1-Tap Complete Button
                Button {
                    session.triggerCompletionWithToast(task: task, in: modelContext)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: snapshot.isActionableToday ? "checkmark" : "arrow.clockwise")
                            .font(.headline.weight(.black))
                        Text(snapshot.isActionableToday ? "Done" : "Log")
                            .font(.system(size: 10, weight: .heavy, design: theme.fontDesign))
                    }
                    .frame(width: 52, height: 52)
                }
                .buttonStyle(
                    TactileActionButtonStyle(
                        fill: snapshot.isActionableToday ? theme.accentPrimary : theme.cardElevatedSurface,
                        foreground: snapshot.isActionableToday ? theme.onAccentPrimary : theme.primaryInk,
                        cornerRadius: theme.isTerminalHUD ? 8 : 15
                    )
                )
                .accessibilityLabel("Mark \(task.title) done")
            }

            // Middle Row: Visual Time-Blindness Gauge (Compact Fluid Bar vs Physical Battery Cell)
            switch displayStyle {
            case .spotlightCard:
                CompactFreshnessBar(snapshot: snapshot, height: 9)
            case .batteryStreamRow:
                HStack(spacing: 12) {
                    LargeBatteryCellGauge(snapshot: snapshot)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(round(snapshot.batteryFill * 100)))% Freshness Charge")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(stageColor)
                        Text(snapshot.cadenceSummary)
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryInk)
                    }
                    Spacer()
                }
            }

            // Chronic Avoidance Gentle Transparency Nudge (when postponed >= 2 times)
            if task.deferralCount >= 2 && snapshot.isActionableToday {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.warmingColor)
                    Text("Deferred \(task.deferralCount)× — break inertia with a 2m micro-sprint?")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                    Spacer()
                    Button {
                        session.startBeatTheClockSprint(for: task, minutes: 2)
                        session.presentingSprintSheetForTask = task
                    } label: {
                        Text("Race 2m")
                            .font(.caption2.weight(.heavy))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(TactileActionButtonStyle(fill: theme.warmingColor, foreground: .black, cornerRadius: 8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(theme.warmingColor.opacity(0.14))
                )
            }

            // Bottom Row: ADHD Effort/Time Chips + Turn Badge + Sprint / Actions Menu
            HStack(spacing: theme.isTerminalHUD ? 5 : 7) {
                metaBadge(
                    icon: "bolt.fill",
                    text: "\(task.estimatedMinutes)m·\(shortEnergyTag)",
                    tint: task.isQuickLowSpoonWin ? theme.freshColor : theme.secondaryInk
                )

                if let turnLabel = turnBadgeText {
                    metaBadge(
                        icon: task.assignmentMode.symbolName,
                        text: turnLabel,
                        tint: theme.accentSecondary
                    )
                }

                if task.remindersEnabled && snapshot.isActionableToday {
                    metaBadge(
                        icon: task.intensityTier.symbolName,
                        text: task.isTaskPaused() ? "Paused" : "q\(task.nagIntervalMinutes)m",
                        tint: stageColor
                    )
                }

                Spacer(minLength: 2)

                // 1-Tap "Beat the Clock" Sprint Trigger
                Button {
                    let mins = task.sprintDurationMinutes
                    session.startBeatTheClockSprint(for: task, minutes: mins)
                    session.presentingSprintSheetForTask = task
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                        Text("\(task.sprintDurationMinutes)m")
                    }
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(theme.primaryInk)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 5 : 99, style: .continuous)
                            .fill(theme.canvasSecondary)
                    )
                    .overlay {
                        if theme.isTerminalHUD {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .strokeBorder(theme.borderInk, lineWidth: 1.0)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Contextual More Menu (Pause 1h, Defer to Tomorrow with Guardrails, Edit)
                Menu {
                    if snapshot.isActionableToday {
                        Button {
                            HapticsEngine.shared.playMechanicalTap()
                            try? TaskActionService.pauseReminders(scope: .singleTask(task.id), durationMinutes: 60, in: modelContext)
                        } label: {
                            Label("Pause Alerts for 1 Hour", systemImage: "pause.circle")
                        }

                        Button {
                            session.deferringTask = task
                        } label: {
                            Label("Push to Tomorrow…", systemImage: "sunrise")
                        }
                        Divider()
                    }

                    Button {
                        session.editingTask = task
                    } label: {
                        Label("Edit Frequency & Alerts…", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .foregroundStyle(theme.secondaryInk)
                }
            }
        }
        .padding(15)
        .adhousedCard(highlightTint: snapshot.isActionableToday ? stageColor : nil)
    }

    private var attributionAndCadenceLine: String {
        if let who = lastCompletedMember, let lastDone = task.lastCompletedAt {
            let days = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastDone), to: Calendar.current.startOfDay(for: .now)).day ?? 0)
            let when = days == 0 ? "today" : (days == 1 ? "yesterday" : "\(days)d ago")
            let modePhrase = task.scheduleMode == .rollingFromLastDone
                ? "every \(task.intervalCount)\(task.intervalUnit == .days ? "d" : (task.intervalUnit == .weeks ? "w" : "mo"))"
                : "fixed schedule"
            return "\(who.emoji) \(who.displayName) did \(when) · \(modePhrase)"
        }
        return snapshot.cadenceSummary
    }

    private var shortEnergyTag: String {
        switch task.energyLevel {
        case .lowSpoons: return theme.isTerminalHUD ? "Low" : "Low Spoons"
        case .steady: return theme.isTerminalHUD ? "Med" : "Medium"
        case .deepClean: return theme.isTerminalHUD ? "Deep" : "High Focus"
        }
    }

    private var turnBadgeText: String? {
        guard members.count > 1 else { return nil }
        switch task.assignmentMode {
        case .anyone:
            return "Anyone"
        case .assigned:
            guard let owner = responsibleMember else { return nil }
            return "\(owner.emoji) \(owner.displayName)"
        case .alternating:
            guard let owner = responsibleMember else { return "Turns" }
            if owner.id == activeMember?.id {
                return theme.isTerminalHUD ? "\(owner.emoji) Yours" : "\(owner.emoji) Your turn"
            }
            return theme.isTerminalHUD ? "\(owner.emoji) \(owner.displayName)" : "\(owner.emoji) \(owner.displayName)'s turn"
        }
    }

    private func metaBadge(icon: String, text: String, tint: Color) -> some View {
        let chipRadius: CGFloat = theme.isTerminalHUD ? 5 : 99
        return HStack(spacing: 3.5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: theme.isTerminalHUD ? 10 : 11, weight: .bold, design: theme.fontDesign))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, theme.isTerminalHUD ? 6.5 : 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
                .fill(tint.opacity(theme.isDark ? 0.18 : 0.12))
        )
        .overlay {
            if theme.isTerminalHUD {
                RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
                    .strokeBorder(tint.opacity(0.32), lineWidth: 0.9)
            }
        }
    }
}
