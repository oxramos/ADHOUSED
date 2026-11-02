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
                size: 40
            )

            VStack(alignment: .leading, spacing: 3) {
                SalientText(
                    task.title,
                    style: .cardTitle,
                    color: theme.primaryInk,
                    lineLimit: nil
                )

                Text(quietSubtitleLine)
                    .themeFont(.caption, in: theme)
                    .foregroundStyle(theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            Menu {
                choreContextMenuItems
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.secondaryInk.opacity(0.8))
                    .frame(width: 28, height: 34)
                    .contentShape(Rectangle())
            }
            .fixedSize()

            Button {
                session.triggerCompletionWithToast(task: task, in: modelContext)
            } label: {
                Image(systemName: snapshot.isActionableToday ? "checkmark" : "arrow.clockwise")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(snapshot.isActionableToday ? theme.onAccentPrimary : theme.primaryInk)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(snapshot.isActionableToday ? theme.accentPrimary : theme.canvasSecondary)
                    )
                    .overlay {
                        Circle()
                            .strokeBorder(
                                snapshot.isActionableToday ? Color.white.opacity(0.24) : theme.borderInk,
                                lineWidth: 0.9
                            )
                    }
            }
            .buttonStyle(.plain)
            .fixedSize()
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

    // MARK: - 2. Standard Focus & Battery Card (Dimensional Depth + Width-Normalized Type)

    private var standardCardBody: some View {
        let stageColor = theme.color(for: snapshot.stage)
        let roomColor = theme.roomAccent(for: task.room)

        return VStack(alignment: .leading, spacing: 12) {
            // Top Row: Stylized Vector/Duotone Icon + Dimensional Kicker + Wrapping Title + 1-Tap Done
            HStack(alignment: .top, spacing: 12) {
                ChoreIconBadgeView(
                    iconSymbol: task.iconSymbol,
                    tint: roomColor,
                    size: 46
                )

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Text(task.room.shortTitle.uppercased())
                            .themeFont(.microTag, in: theme)
                            .foregroundStyle(roomColor)
                            .padding(.horizontal, 6.5)
                            .padding(.vertical, 2.5)
                            .background(
                                RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 4 : 6, style: .continuous)
                                    .fill(roomColor.opacity(theme.isDark ? 0.16 : 0.11))
                            )
                            .fixedSize(horizontal: true, vertical: false)

                        if snapshot.isActionableToday {
                            Text(snapshot.stage.label.uppercased())
                                .themeFont(.microTag, in: theme)
                                .foregroundStyle(stageColor)
                                .padding(.horizontal, 6.5)
                                .padding(.vertical, 2.5)
                                .background(
                                    RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 4 : 6, style: .continuous)
                                        .fill(stageColor.opacity(theme.isDark ? 0.16 : 0.11))
                                )
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }

                    SalientText(
                        task.title,
                        style: .cardTitle,
                        color: theme.primaryInk,
                        lineLimit: nil
                    )

                    Text(attributionAndCadenceLine)
                        .themeFont(.caption, in: theme)
                        .foregroundStyle(theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)

                Spacer(minLength: 4)

                // Tactile 1-Tap Complete Button (Fixed 50×50 so never squeezed)
                Button {
                    session.triggerCompletionWithToast(task: task, in: modelContext)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: snapshot.isActionableToday ? "checkmark" : "arrow.clockwise")
                            .font(.system(size: 15, weight: .black))
                        Text(snapshot.isActionableToday ? "Done" : "Log")
                            .themeFont(.microTag, in: theme)
                            .lineLimit(1)
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
                .fixedSize()
                .accessibilityLabel("Mark \(task.title) done")
            }

            // Middle Row: Luminous Progress / Freshness Bar
            switch displayStyle {
            case .spotlightCard, .quietMinimalRow:
                CompactFreshnessBar(snapshot: snapshot, height: 8)
            case .batteryStreamRow:
                HStack(spacing: 12) {
                    LargeBatteryCellGauge(snapshot: snapshot)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(round(snapshot.batteryFill * 100)))% Charged")
                            .themeFont(.captionStrong, in: theme)
                            .foregroundStyle(stageColor)
                        Text(snapshot.cadenceSummary)
                            .themeFont(.caption, in: theme)
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
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(theme.warmingColor)
                    Text("Skipped \(task.deferralCount) times — try just 2 minutes?")
                        .themeFont(.captionStrong, in: theme)
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    Button {
                        session.startBeatTheClockSprint(for: task, minutes: 2)
                        session.presentingSprintSheetForTask = task
                    } label: {
                        Text("2m Timer")
                            .themeFont(.microTag, in: theme)
                            .fixedSize(horizontal: true, vertical: false)
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
                                .font(.system(size: 10.5, weight: .bold))
                            Text("\(task.sprintDurationMinutes)m")
                                .themeFont(.microTag, in: theme)
                        }
                        .foregroundStyle(theme.primaryInk)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 6 : 99, style: .continuous)
                                .fill(theme.canvasSecondary)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 6 : 99, style: .continuous)
                                .strokeBorder(theme.borderInk.opacity(0.7), lineWidth: 0.8)
                        }
                    }
                    .buttonStyle(.plain)
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityLabel("Start \(task.sprintDurationMinutes) minute focus timer")

                    Menu {
                        choreContextMenuItems
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(theme.secondaryInk)
                    }
                    .fixedSize()
                }
                .fixedSize(horizontal: true, vertical: false)
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
                .themeFont(.captionStrong, in: theme)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8.5)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
                .fill(tint.opacity(theme.isDark ? 0.17 : 0.11))
        )
        .overlay {
            RoundedRectangle(cornerRadius: chipRadius, style: .continuous)
                .strokeBorder(tint.opacity(theme.isTerminalHUD ? 0.30 : 0.18), lineWidth: 0.85)
        }
    }
}
