import SwiftUI
import SwiftData
import ADHOUSEDCore

enum ChoreCardDisplayStyle {
    case quietMinimalRow
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
        switch displayStyle {
        case .quietMinimalRow:
            quietMinimalBody
        case .spotlightCard, .batteryStreamRow:
            standardCardBody
        }
    }

    // MARK: - 1. Quiet / Minimal Mode Row (Low-Noise, Breathable, Zero Clutter)

    private var quietMinimalBody: some View {
        let roomColor = theme.roomAccent(for: task.room)

        return HStack(alignment: .center, spacing: 13) {
            ChoreIconBadgeView(
                iconSymbol: task.iconSymbol,
                tint: roomColor,
                size: 38
            )

            VStack(alignment: .leading, spacing: 3) {
                SalientText(
                    task.title,
                    font: .body.weight(.semibold),
                    color: theme.primaryInk,
                    lineLimit: nil
                )

                Text(quietSubtitleLine)
                    .font(.caption)
                    .foregroundStyle(theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            Menu {
                choreContextMenuItems
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.secondaryInk.opacity(0.75))
                    .frame(width: 28, height: 34)
                    .contentShape(Rectangle())
            }

            Button {
                session.triggerCompletionWithToast(task: task, in: modelContext)
            } label: {
                Image(systemName: snapshot.isActionableToday ? "checkmark" : "arrow.clockwise")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(snapshot.isActionableToday ? theme.onAccentPrimary : theme.primaryInk)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(snapshot.isActionableToday ? theme.accentPrimary : theme.canvasSecondary)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Mark \(task.title) done")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .adhousedCard(compact: true)
    }

    private var quietSubtitleLine: String {
        var parts: [String] = [task.room.shortTitle, "~\(task.estimatedMinutes) min"]
        if let turn = turnBadgeText {
            parts.append(turn)
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - 2. Standard Focus & Battery Card (Zero Truncation + Wrapping Chips)

    private var standardCardBody: some View {
        let stageColor = theme.color(for: snapshot.stage)
        let roomColor = theme.roomAccent(for: task.room)

        return VStack(alignment: .leading, spacing: 12) {
            // Top Row: Themed / Omarchy Icon + Full Wrapping Title + 1-Tap Done Button
            HStack(alignment: .top, spacing: 12) {
                ChoreIconBadgeView(
                    iconSymbol: task.iconSymbol,
                    tint: roomColor,
                    size: 46
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(task.room.shortTitle.uppercased())
                            .font(.system(size: 10, weight: .heavy, design: theme.fontDesign))
                            .tracking(0.6)
                            .foregroundStyle(roomColor)

                        if snapshot.isActionableToday {
                            Text("· \(snapshot.stage.label.uppercased())")
                                .font(.system(size: 10, weight: .heavy, design: theme.fontDesign))
                                .tracking(0.5)
                                .foregroundStyle(stageColor)
                        }
                    }

                    SalientText(
                        task.title,
                        font: .headline.weight(.bold),
                        color: theme.primaryInk,
                        lineLimit: nil
                    )

                    Text(attributionAndCadenceLine)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer(minLength: 4)

                // Tactile 1-Tap Complete Button
                Button {
                    session.triggerCompletionWithToast(task: task, in: modelContext)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: snapshot.isActionableToday ? "checkmark" : "arrow.clockwise")
                            .font(.headline.weight(.black))
                        Text(snapshot.isActionableToday ? "Done" : "Log")
                            .font(.system(size: 10, weight: .heavy, design: theme.fontDesign))
                    }
                    .frame(width: 50, height: 50)
                }
                .buttonStyle(
                    TactileActionButtonStyle(
                        fill: snapshot.isActionableToday ? theme.accentPrimary : theme.cardElevatedSurface,
                        foreground: snapshot.isActionableToday ? theme.onAccentPrimary : theme.primaryInk,
                        cornerRadius: theme.isTerminalHUD ? 8 : 14
                    )
                )
                .accessibilityLabel("Mark \(task.title) done")
            }

            // Middle Row: Progress / Freshness Bar
            switch displayStyle {
            case .spotlightCard, .quietMinimalRow:
                CompactFreshnessBar(snapshot: snapshot, height: 8)
            case .batteryStreamRow:
                HStack(spacing: 12) {
                    LargeBatteryCellGauge(snapshot: snapshot)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(round(snapshot.batteryFill * 100)))% Charged")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(stageColor)
                        Text(snapshot.cadenceSummary)
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }

            // Gentle Nudge if Postponed 2+ Times
            if task.deferralCount >= 2 && snapshot.isActionableToday {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.warmingColor)
                    Text("Skipped \(task.deferralCount) times — try just 2 minutes?")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    Button {
                        session.startBeatTheClockSprint(for: task, minutes: 2)
                        session.presentingSprintSheetForTask = task
                    } label: {
                        Text("2m Timer")
                            .font(.caption2.weight(.heavy))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(TactileActionButtonStyle(fill: theme.warmingColor, foreground: Color(hex: "#121317"), cornerRadius: 8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(theme.warmingColor.opacity(0.14))
                )
            }

            // Bottom Row: Wrapping Plain-English Metadata Chips + Quick Timer + Menu
            HStack(alignment: .center, spacing: 8) {
                FlowChipLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                    metaBadge(
                        icon: task.energyLevel.symbolName,
                        text: "~\(task.estimatedMinutes) min · \(task.energyLevel.badgeText)",
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
                            icon: task.reminderBadgeIcon,
                            text: task.reminderIntervalSummary,
                            tint: stageColor
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
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
                            RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 6 : 99, style: .continuous)
                                .fill(theme.canvasSecondary)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Start \(task.sprintDurationMinutes) minute focus timer")

                    Menu {
                        choreContextMenuItems
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title3)
                            .foregroundStyle(theme.secondaryInk)
                    }
                }
            }
        }
        .padding(15)
        .adhousedCard(highlightTint: snapshot.isActionableToday ? stageColor : nil)
    }

    @ViewBuilder
    private var choreContextMenuItems: some View {
        if snapshot.isActionableToday {
            Button {
                HapticsEngine.shared.playMechanicalTap()
                try? TaskActionService.pauseReminders(scope: .singleTask(task.id), durationMinutes: 60, in: modelContext)
            } label: {
                Label("Pause Reminders for 1 Hour", systemImage: "pause.circle")
            }

            Button {
                session.deferringTask = task
            } label: {
                Label("Do Tomorrow or Pause Until Date…", systemImage: "sunrise")
            }
            Divider()
        }

        Button {
            let mins = task.sprintDurationMinutes
            session.startBeatTheClockSprint(for: task, minutes: mins)
            session.presentingSprintSheetForTask = task
        } label: {
            Label("Start \(task.sprintDurationMinutes)-Min Focus Timer", systemImage: "timer")
        }

        Button {
            session.editingTask = task
        } label: {
            Label("Edit Chore, Schedule & Icon…", systemImage: "pencil")
        }
    }

    private var attributionAndCadenceLine: String {
        if let who = lastCompletedMember, let lastDone = task.lastCompletedAt {
            let days = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastDone), to: Calendar.current.startOfDay(for: .now)).day ?? 0)
            let when = days == 0 ? "today" : (days == 1 ? "yesterday" : "\(days) days ago")
            let modePhrase: String = {
                guard task.scheduleMode == .rollingFromLastDone else { return "specific days" }
                if task.intervalCount == 1 && task.intervalUnit == .days { return "daily" }
                if (task.intervalCount == 7 && task.intervalUnit == .days) || (task.intervalCount == 1 && task.intervalUnit == .weeks) {
                    return "weekly"
                }
                let unitWord = task.intervalCount == 1 ? task.intervalUnit.singularLabel : task.intervalUnit.pluralLabel
                return "every \(task.intervalCount) \(unitWord)"
            }()
            return "\(who.emoji) \(who.displayName) did \(when) · \(modePhrase)"
        }
        return snapshot.cadenceSummary
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
            guard let owner = responsibleMember else { return "Take turns" }
            if owner.id == activeMember?.id {
                return "\(owner.emoji) Your turn"
            }
            return "\(owner.emoji) \(owner.displayName)'s turn"
        }
    }

    private func metaBadge(icon: String, text: String, tint: Color) -> some View {
        let chipRadius: CGFloat = theme.isTerminalHUD ? 5 : 99
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9.5, weight: .bold))
            Text(text)
                .font(.system(size: theme.isTerminalHUD ? 10.5 : 11, weight: .semibold, design: theme.fontDesign))
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
                .fill(tint.opacity(theme.isDark ? 0.17 : 0.11))
        )
        .overlay {
            if theme.isTerminalHUD {
                RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
                    .strokeBorder(tint.opacity(0.30), lineWidth: 0.9)
            }
        }
    }
}
