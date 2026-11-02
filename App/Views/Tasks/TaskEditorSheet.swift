import SwiftUI
import SwiftData
import ADHOUSEDCore

struct TaskEditorSheet: View {
    @Environment(\.adhousedTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let existingTask: ChoreTask?
    let members: [HouseholdMember]
    let householdID: UUID

    @State private var title: String = ""
    @State private var iconSymbol: String = "sparkles"
    @State private var room: RoomCategory = .kitchen
    @State private var scheduleMode: ScheduleMode = .rollingFromLastDone
    @State private var intervalCount: Int = 7
    @State private var intervalUnit: IntervalUnit = .days
    @State private var fixedWeekdays: Set<Int> = [3]

    @State private var energyLevel: EnergyLevel = .lowSpoons
    @State private var estimatedMinutes: Int = 5

    @State private var remindersEnabled: Bool = true
    @State private var nagIntervalMinutes: Int = 45
    @State private var intensityTier: ReminderIntensityTier = .stickyLiveActivity
    @State private var alarmCutoffHour: Int = 20

    @State private var assignmentMode: AssignmentMode = .anyone
    @State private var selectedOwnerID: UUID? = nil

    private let quickIcons = [
        "sparkles", "dishwasher.fill", "washer.fill", "bed.double.fill",
        "trash.fill", "shower.fill", "pawprint.fill", "leaf.fill",
        "refrigerator.fill", "fanblades.fill", "sofa.fill", "mug.fill"
    ]
    private let nagOptions = [15, 30, 45, 60, 120, 180]
    private let minuteOptions = [2, 5, 10, 15, 30]

    var body: some View {
        NavigationStack {
            ZStack {
                theme.canvasBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        titleAndIconCard
                        recurrenceCard
                        adhdEffortAndTimeCard
                        persistentReminderCard
                        if members.count > 1 {
                            householdAssignmentCard
                        }
                        if let existingTask {
                            archiveDeleteCard(existingTask)
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle(existingTask == nil ? "New Household Chore" : "Edit Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTask() }
                        .fontWeight(.heavy)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: populateIfEditing)
        }
    }

    private var titleAndIconCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHORE & ROOM")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            TextField("e.g., Wash bedsheets, Scoop litter…", text: $title)
                .font(.headline.weight(.bold))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(theme.canvasSecondary))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RoomCategory.allCases) { category in
                        let selected = room == category
                        Button {
                            room = category
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: category.symbolName)
                                Text(category.shortTitle)
                            }
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(selected ? theme.roomAccent(for: category) : theme.canvasSecondary)
                            )
                            .foregroundStyle(selected ? .white : theme.primaryInk)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickIcons, id: \.self) { sym in
                        Button {
                            iconSymbol = sym
                        } label: {
                            Image(systemName: sym)
                                .font(.headline)
                                .frame(width: 38, height: 38)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(iconSymbol == sym ? theme.accentPrimary : theme.canvasSecondary)
                                )
                                .foregroundStyle(iconSymbol == sym ? theme.onAccentPrimary : theme.primaryInk)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(15)
        .adhousedCard()
    }

    private var recurrenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HOW OFTEN IT NEEDS DOING")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            Picker("Schedule Mode", selection: $scheduleMode) {
                Text("Rolling Interval").tag(ScheduleMode.rollingFromLastDone)
                Text("Fixed Weekdays").tag(ScheduleMode.fixedCalendar)
            }
            .pickerStyle(.segmented)

            Text(scheduleMode.subtitle)
                .font(.caption)
                .foregroundStyle(theme.secondaryInk)

            if scheduleMode == .rollingFromLastDone {
                HStack(spacing: 10) {
                    Stepper("Every **\(intervalCount)**", value: $intervalCount, in: 1...90)
                        .font(.subheadline)
                    Picker("Unit", selection: $intervalUnit) {
                        ForEach(IntervalUnit.allCases) { u in
                            Text(intervalCount == 1 ? u.singularLabel : u.pluralLabel).tag(u)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // 1-Tap Quick Cadence Presets
                HStack(spacing: 6) {
                    ForEach([(1, "Daily"), (3, "3d"), (7, "Weekly"), (14, "2w"), (30, "Monthly")], id: \.1) { days, label in
                        Button(label) {
                            intervalUnit = .days
                            intervalCount = days
                        }
                        .font(.caption2.weight(.heavy))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(
                                (intervalUnit == .days && intervalCount == days)
                                    ? theme.accentPrimary
                                    : theme.canvasSecondary
                            )
                        )
                        .foregroundStyle((intervalUnit == .days && intervalCount == days) ? theme.onAccentPrimary : theme.primaryInk)
                        .buttonStyle(.plain)
                    }
                }
            } else {
                let symbols = Calendar.current.shortWeekdaySymbols
                HStack(spacing: 6) {
                    ForEach(1...7, id: \.self) { day in
                        let active = fixedWeekdays.contains(day)
                        Button {
                            if active && fixedWeekdays.count > 1 {
                                fixedWeekdays.remove(day)
                            } else {
                                fixedWeekdays.insert(day)
                            }
                        } label: {
                            Text(String(symbols[day - 1].prefix(2)))
                                .font(.caption.weight(.heavy))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(active ? theme.accentPrimary : theme.canvasSecondary)
                                )
                                .foregroundStyle(active ? theme.onAccentPrimary : theme.primaryInk)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(15)
        .adhousedCard()
    }

    private var adhdEffortAndTimeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SPOONS & TIME ESTIMATE")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            HStack(spacing: 8) {
                ForEach(EnergyLevel.allCases) { level in
                    let active = energyLevel == level
                    Button {
                        energyLevel = level
                    } label: {
                        Text(level.label)
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(active ? theme.accentPrimary : theme.canvasSecondary)
                            )
                            .foregroundStyle(active ? .white : theme.primaryInk)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                Text("Approx time:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.secondaryInk)
                ForEach(minuteOptions, id: \.self) { mins in
                    Button("\(mins)m") {
                        estimatedMinutes = mins
                    }
                    .font(.caption.weight(.heavy))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(estimatedMinutes == mins ? theme.warmingColor : theme.canvasSecondary)
                    )
                    .foregroundStyle(estimatedMinutes == mins ? .black : theme.primaryInk)
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(15)
        .adhousedCard()
    }

    private var persistentReminderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $remindersEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PERSISTENT REMINDER LOOP")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(theme.secondaryInk)
                    Text("Keeps raising due task until marked Done")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryInk)
                }
            }
            .tint(theme.accentPrimary)

            if remindersEnabled {
                Text("Re-alert frequency on due day:")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.primaryInk)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(nagOptions, id: \.self) { mins in
                            let label = mins < 60 ? "Every \(mins)m" : "Every \(mins / 60)h"
                            Button(label) {
                                nagIntervalMinutes = mins
                            }
                            .font(.caption.weight(.heavy))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(nagIntervalMinutes == mins ? theme.dueNowColor : theme.canvasSecondary)
                            )
                            .foregroundStyle(nagIntervalMinutes == mins ? .white : theme.primaryInk)
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(spacing: 8) {
                    ForEach(ReminderIntensityTier.allCases) { tier in
                        let active = intensityTier == tier
                        Button {
                            intensityTier = tier
                            if tier == .cutoffSystemAlarm {
                                Task {
                                    #if canImport(AlarmKit)
                                    if #available(iOS 26.1, *) {
                                        _ = await ReminderCoordinator.shared.requestAlarmKitPermission()
                                    }
                                    #endif
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: tier.symbolName)
                                    .foregroundStyle(active ? theme.dueNowColor : theme.secondaryInk)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tier.title)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(theme.primaryInk)
                                    Text(tier.explanation)
                                        .font(.caption2)
                                        .foregroundStyle(theme.secondaryInk)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: active ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(active ? theme.dueNowColor : theme.secondaryInk)
                            }
                            .padding(11)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(active ? theme.dueNowColor.opacity(0.12) : theme.canvasSecondary)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if intensityTier == .cutoffSystemAlarm {
                    Stepper("Cutoff System Alarm at **\(alarmCutoffHour):00**", value: $alarmCutoffHour, in: 12...23)
                        .font(.caption.weight(.bold))
                }
            }
        }
        .padding(15)
        .adhousedCard()
    }

    private var householdAssignmentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SHARED HOUSEHOLD TURN MODE")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            Picker("Assignment", selection: $assignmentMode) {
                ForEach(AssignmentMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(assignmentMode.subtitle)
                .font(.caption2)
                .foregroundStyle(theme.secondaryInk)

            if assignmentMode == .assigned {
                HStack(spacing: 8) {
                    ForEach(members) { m in
                        let active = (selectedOwnerID ?? members.first?.id) == m.id
                        Button {
                            selectedOwnerID = m.id
                        } label: {
                            Text("\(m.emoji) \(m.displayName)")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(active ? theme.accentSecondary : theme.canvasSecondary))
                                .foregroundStyle(active ? theme.onAccentSecondary : theme.primaryInk)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(15)
        .adhousedCard()
    }

    private func archiveDeleteCard(_ task: ChoreTask) -> some View {
        Button(role: .destructive) {
            task.isArchived = true
            try? modelContext.save()
            TaskActionService.awaitableReconcileAndReloadWidgets(in: modelContext)
            dismiss()
        } label: {
            HStack {
                Spacer()
                Label("Archive Chore", systemImage: "archivebox")
                    .font(.subheadline.weight(.bold))
                Spacer()
            }
            .padding(13)
        }
        .adhousedCard(compact: true)
    }

    private func populateIfEditing() {
        guard let t = existingTask else {
            selectedOwnerID = members.first?.id
            return
        }
        title = t.title
        iconSymbol = t.iconSymbol
        room = t.room
        scheduleMode = t.scheduleMode
        intervalCount = t.intervalCount
        intervalUnit = t.intervalUnit
        fixedWeekdays = Set(t.fixedWeekdays)
        energyLevel = t.energyLevel
        estimatedMinutes = t.estimatedMinutes
        remindersEnabled = t.remindersEnabled
        nagIntervalMinutes = t.nagIntervalMinutes
        intensityTier = t.intensityTier
        alarmCutoffHour = max(12, min(23, t.alarmCutoffMinutes / 60))
        assignmentMode = t.assignmentMode
        selectedOwnerID = t.assignedMemberIDs.first ?? members.first?.id
    }

    private func saveTask() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let assignedIDs: [UUID]
        switch assignmentMode {
        case .anyone:
            assignedIDs = []
        case .assigned:
            if let owner = selectedOwnerID ?? members.first?.id {
                assignedIDs = [owner]
            } else {
                assignedIDs = []
            }
        case .alternating:
            assignedIDs = members.map(\.id)
        }

        if let task = existingTask {
            task.title = trimmed
            task.iconSymbol = iconSymbol
            task.room = room
            task.scheduleMode = scheduleMode
            task.intervalCount = intervalCount
            task.intervalUnit = intervalUnit
            task.fixedWeekdays = Array(fixedWeekdays)
            task.energyLevel = energyLevel
            task.estimatedMinutes = estimatedMinutes
            task.sprintDurationMinutes = min(15, max(2, estimatedMinutes))
            task.remindersEnabled = remindersEnabled
            task.nagIntervalMinutes = nagIntervalMinutes
            task.intensityTier = intensityTier
            task.alarmCutoffMinutes = alarmCutoffHour * 60
            task.assignmentMode = assignmentMode
            task.assignedMemberIDs = assignedIDs
            task.updatedAt = .now
        } else {
            let newTask = ChoreTask(
                householdID: householdID,
                title: trimmed,
                iconSymbol: iconSymbol,
                room: room,
                scheduleMode: scheduleMode,
                intervalUnit: intervalUnit,
                intervalCount: intervalCount,
                fixedRuleKind: .weeklyDays,
                fixedWeekdays: Array(fixedWeekdays),
                lastCompletedAt: nil,
                energyLevel: energyLevel,
                estimatedMinutes: estimatedMinutes,
                remindersEnabled: remindersEnabled,
                nagIntervalMinutes: nagIntervalMinutes,
                intensityTier: intensityTier,
                alarmCutoffMinutes: alarmCutoffHour * 60,
                assignmentMode: assignmentMode,
                assignedMemberIDs: assignedIDs
            )
            modelContext.insert(newTask)
        }

        try? modelContext.save()
        TaskActionService.awaitableReconcileAndReloadWidgets(in: modelContext)
        HapticsEngine.shared.playMechanicalTap()
        dismiss()
    }
}
