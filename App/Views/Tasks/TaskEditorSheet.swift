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
    @State private var nagIntervalMinutes: Int = 60
    @State private var intensityTier: ReminderIntensityTier = .stickyLiveActivity
    @State private var alarmCutoffHour: Int = 20

    @State private var assignmentMode: AssignmentMode = .anyone
    @State private var selectedOwnerID: UUID? = nil

    @State private var alsoSaveToCatalog: Bool = false

    @State private var isChorePausedUntilDate: Bool = false
    @State private var chorePausedUntil: Date = Date.now.addingTimeInterval(2 * 86_400)

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
                        effortAndTimeCard
                        persistentReminderCard
                        if members.count > 1 {
                            householdAssignmentCard
                        }
                        if existingTask == nil {
                            saveToCatalogOptionCard
                        }
                        if let existingTask {
                            singleChorePauseCard
                            archiveDeleteCard(existingTask)
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle(existingTask == nil ? "New Chore or Activity" : "Edit Chore")
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
        VStack(alignment: .leading, spacing: 14) {
            Text("NAME, ROOM & ICON")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            TextField("e.g., Wash bedsheets, Water plants, Clean desk…", text: $title)
                .font(.headline.weight(.bold))
                .foregroundStyle(theme.primaryInk)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 8 : 12, style: .continuous)
                        .fill(theme.canvasSecondary)
                )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(RoomCategory.allCases) { category in
                        let selected = room == category
                        Button {
                            HapticsEngine.shared.playMechanicalTap()
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

            ChoreIconPickerView(
                selectedIcon: $iconSymbol,
                accentTint: theme.roomAccent(for: room)
            )
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
                Text("After Last Done").tag(ScheduleMode.rollingFromLastDone)
                Text("Specific Days").tag(ScheduleMode.fixedCalendar)
            }
            .pickerStyle(.segmented)

            Text(scheduleMode.subtitle)
                .font(.caption)
                .foregroundStyle(theme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)

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

                FlowChipLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                    ForEach([(1, "Daily"), (2, "Every 2d"), (3, "Every 3d"), (7, "Weekly"), (14, "Every 2w"), (30, "Monthly")], id: \.1) { days, label in
                        let selected = intervalUnit == .days && intervalCount == days
                        Button(label) {
                            intervalUnit = .days
                            intervalCount = days
                        }
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(selected ? theme.accentPrimary : theme.canvasSecondary)
                        )
                        .foregroundStyle(selected ? theme.onAccentPrimary : theme.primaryInk)
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
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
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

    private var effortAndTimeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EFFORT & TIME ESTIMATE")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            HStack(spacing: 8) {
                ForEach(EnergyLevel.allCases) { level in
                    let active = energyLevel == level
                    Button {
                        energyLevel = level
                    } label: {
                        Text(level.badgeText)
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(active ? theme.accentPrimary : theme.canvasSecondary)
                            )
                            .foregroundStyle(active ? theme.onAccentPrimary : theme.primaryInk)
                    }
                    .buttonStyle(.plain)
                }
            }

            FlowChipLayout(horizontalSpacing: 7, verticalSpacing: 7) {
                Text("Approx time:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.secondaryInk)
                    .padding(.vertical, 5)

                ForEach(minuteOptions, id: \.self) { mins in
                    Button("\(mins) min") {
                        estimatedMinutes = mins
                    }
                    .font(.caption.weight(.heavy))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(estimatedMinutes == mins ? theme.warmingColor : theme.canvasSecondary)
                    )
                    .foregroundStyle(estimatedMinutes == mins ? Color(hex: "#121317") : theme.primaryInk)
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
                    Text("REPEATING DUE-DAY REMINDERS")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(theme.secondaryInk)
                    Text("Keeps gently reminding you on the due day until marked Done")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(theme.accentPrimary)

            if remindersEnabled {
                Text("How often to remind you when due:")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.primaryInk)

                FlowChipLayout(horizontalSpacing: 7, verticalSpacing: 7) {
                    ForEach(nagOptions, id: \.self) { mins in
                        let label = ChoreTask.humanIntervalText(forMinutes: mins)
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
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(tier.explanation)
                                        .font(.caption2)
                                        .foregroundStyle(theme.secondaryInk)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                                Image(systemName: active ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(active ? theme.dueNowColor : theme.secondaryInk)
                            }
                            .padding(11)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(active ? theme.dueNowColor.opacity(0.12) : theme.canvasSecondary)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if intensityTier == .cutoffSystemAlarm {
                    Stepper("Evening Alarm at **\(alarmCutoffHour):00**", value: $alarmCutoffHour, in: 12...23)
                        .font(.caption.weight(.bold))
                }
            }
        }
        .padding(15)
        .adhousedCard()
    }

    private var householdAssignmentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHO DOES THIS CHORE?")
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
                .fixedSize(horizontal: false, vertical: true)

            if assignmentMode == .assigned {
                FlowChipLayout(horizontalSpacing: 8, verticalSpacing: 8) {
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

    private var saveToCatalogOptionCard: some View {
        Toggle(isOn: $alsoSaveToCatalog) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Also save to my Chore & Activity Catalog")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.primaryInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Keeps this custom item in your Catalog for future re-use or sharing")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(theme.accentPrimary)
        .padding(15)
        .adhousedCard()
    }

    private var singleChorePauseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PAUSE THIS CHORE")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.warmingColor)

            Toggle(isOn: $isChorePausedUntilDate) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pause Chore & Reminders Until Date & Time")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Silences notifications for this chore without deleting it")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(theme.warmingColor)

            if isChorePausedUntilDate {
                DatePicker(
                    "Resume At",
                    selection: $chorePausedUntil,
                    in: Date.now.addingTimeInterval(600)...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .font(.subheadline.weight(.bold))
            }
        }
        .padding(15)
        .adhousedCard(highlightTint: isChorePausedUntilDate ? theme.warmingColor : nil)
    }

    private func archiveDeleteCard(_ task: ChoreTask) -> some View {
        Button(role: .destructive) {
            task.isArchived = true
            task.updatedAt = .now
            try? modelContext.save()
            TaskActionService.awaitableReconcileAndReloadWidgets(in: modelContext)
            dismiss()
        } label: {
            HStack {
                Spacer()
                Label("Remove / Archive Chore", systemImage: "trash")
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
            if theme.preset.isOmarchyQuattroStyle || ADHOUSEDPreferences.shared.iconStylePreference == .omarchyPixelHUD {
                iconSymbol = "omarchy:spark"
            }
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
        if let paused = t.pausedUntil, paused > .now {
            isChorePausedUntilDate = true
            chorePausedUntil = paused
        } else {
            isChorePausedUntilDate = false
            chorePausedUntil = Date.now.addingTimeInterval(2 * 86_400)
        }
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
            task.pausedUntil = isChorePausedUntilDate ? chorePausedUntil : nil
            task.deferredUntilDate = isChorePausedUntilDate ? chorePausedUntil : nil
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

            if alsoSaveToCatalog {
                let tpl = StarterChoreTemplate(
                    title: trimmed,
                    iconSymbol: iconSymbol,
                    room: room,
                    scheduleMode: scheduleMode,
                    intervalUnit: intervalUnit,
                    intervalCount: intervalCount,
                    fixedWeekdays: Array(fixedWeekdays),
                    energyLevel: energyLevel,
                    estimatedMinutes: estimatedMinutes,
                    suggestedNagMinutes: nagIntervalMinutes,
                    suggestedTier: intensityTier,
                    recommendedByDefault: false,
                    isCustom: true
                )
                ADHOUSEDPreferences.shared.addOrUpdateCustomCatalogTemplate(tpl)
            }
        }

        try? modelContext.save()
        TaskActionService.awaitableReconcileAndReloadWidgets(in: modelContext)
        HapticsEngine.shared.playMechanicalTap()
        dismiss()
    }
}
