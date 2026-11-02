import SwiftUI
import SwiftData
import ADHOUSEDCore

struct VacationBreakSheet: View {
    @Environment(\.adhousedTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var households: [Household]
    @Bindable var session: AppSessionViewModel
    @Bindable var prefs: ADHOUSEDPreferences

    @State private var editingBreakID: UUID? = nil
    @State private var selectedPreset: VacationBreakPreset = .countrysideWeekend
    @State private var breakTitle: String = "Countryside Weekend"
    @State private var iconSymbol: String = "tree.fill"
    @State private var startDate: Date = .now
    @State private var endDate: Date = Date.now.addingTimeInterval(2 * 86_400)
    @State private var freezeChoreDecay: Bool = true
    @State private var didInitialize: Bool = false

    private let iconChoices: [(symbol: String, label: String)] = [
        ("tree.fill", "Countryside"),
        ("tent.fill", "Cabin / Camp"),
        ("suitcase.rolling.fill", "Vacation"),
        ("car.fill", "Road Trip"),
        ("airplane", "Flight"),
        ("house.lodge.fill", "Getaway"),
        ("heart.text.square.fill", "Rest Break"),
        ("moon.stars.fill", "Evening Off")
    ]

    private var awakeStartMinutes: Int {
        households.first?.awakeStartMinutes ?? (8 * 60 + 30)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.canvasBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if !prefs.activeOrUpcomingVacationBreaks().isEmpty {
                            activeAndScheduledBreaksCard
                        }

                        quickPresetsCard
                        dateTimeRangeCard
                        labelAndFreezeOptionsCard
                        saveActionCard
                    }
                    .padding(18)
                }
            }
            .navigationTitle(editingBreakID == nil ? "Vacation & Break Mode" : "Edit Break Dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingBreakID == nil ? (isStartingImmediately ? "Start Now" : "Schedule") : "Update") {
                        commitBreakWindow()
                    }
                    .fontWeight(.heavy)
                }
            }
            .onAppear {
                guard !didInitialize else { return }
                didInitialize = true
                if let active = prefs.activeVacationBreak() {
                    loadExistingBreak(active)
                } else {
                    applyPreset(.countrysideWeekend)
                }
            }
        }
    }

    private var isStartingImmediately: Bool {
        startDate <= Date.now.addingTimeInterval(300)
    }

    // MARK: - 1. Active & Scheduled Breaks Card

    private var activeAndScheduledBreaksCard: some View {
        let breaks = prefs.activeOrUpcomingVacationBreaks()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(theme.hudTag("ACTIVE & SCHEDULED BREAKS"))
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(theme.warmingColor)
                Spacer()
                if editingBreakID != nil {
                    Button("New Break") {
                        HapticsEngine.shared.playMechanicalTap()
                        editingBreakID = nil
                        applyPreset(.countrysideWeekend)
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accentPrimary)
                }
            }

            ForEach(breaks) { brk in
                let activeNow = brk.isActive()
                let isEditingThis = editingBreakID == brk.id

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 6 : 10, style: .continuous)
                                .fill((activeNow ? theme.warmingColor : theme.accentPrimary).opacity(0.20))
                                .frame(width: 38, height: 38)
                            Image(systemName: brk.iconSymbol)
                                .font(.headline)
                                .foregroundStyle(activeNow ? theme.warmingColor : theme.accentPrimary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(brk.title)
                                    .font(.subheadline.weight(.heavy))
                                    .foregroundStyle(theme.primaryInk)
                                Text(activeNow ? "ACTIVE NOW" : "SCHEDULED")
                                    .font(.system(size: 9, weight: .black, design: theme.fontDesign))
                                    .foregroundStyle(activeNow ? Color(hex: "#111216") : theme.onAccentPrimary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule().fill(activeNow ? theme.warmingColor : theme.accentPrimary)
                                    )
                            }
                            Text(brk.formattedRangeSummary())
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.secondaryInk)
                        }

                        Spacer(minLength: 4)
                    }

                    HStack(spacing: 8) {
                        Label(
                            brk.freezeChoreDecay ? "Chores & alerts frozen" : "Alerts silenced",
                            systemImage: brk.freezeChoreDecay ? "snowflake" : "bell.slash.fill"
                        )
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.secondaryInk)

                        Spacer()

                        if !isEditingThis {
                            Button {
                                HapticsEngine.shared.playMechanicalTap()
                                loadExistingBreak(brk)
                            } label: {
                                Text("Edit Dates")
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(TactileActionButtonStyle(fill: theme.cardElevatedSurface, foreground: theme.primaryInk))
                        }

                        Button {
                            HapticsEngine.shared.playMechanicalTap()
                            try? TaskActionService.removeVacationBreak(id: brk.id, in: modelContext)
                            if editingBreakID == brk.id {
                                editingBreakID = nil
                                applyPreset(.countrysideWeekend)
                            }
                        } label: {
                            Text(activeNow ? "I'm Back (End)" : "Cancel")
                                .font(.caption.weight(.heavy))
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(
                            TactileActionButtonStyle(
                                fill: activeNow ? theme.freshColor : theme.urgentColor,
                                foreground: .white
                            )
                        )
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 8 : 13, style: .continuous)
                        .fill(isEditingThis ? theme.warmingColor.opacity(0.14) : theme.canvasSecondary)
                )
            }
        }
        .padding(15)
        .adhousedCard(highlightTint: theme.warmingColor)
    }

    // MARK: - 2. Quick Presets Strip

    private var quickPresetsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(theme.hudTag("QUICK VACATION & BREAK PRESETS"))
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            Text("Tap a preset to pre-fill dates, or dial in any exact From & Until date and time below.")
                .font(.caption2)
                .foregroundStyle(theme.secondaryInk)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(VacationBreakPreset.allCases) { preset in
                    let isSelected = selectedPreset == preset
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        applyPreset(preset)
                    } label: {
                        HStack(spacing: 6) {
                            Text(preset.shortChipLabel)
                                .font(.caption.weight(.heavy))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 7 : 11, style: .continuous)
                                .fill(isSelected ? theme.accentPrimary : theme.canvasSecondary)
                        )
                        .foregroundStyle(isSelected ? theme.onAccentPrimary : theme.primaryInk)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(15)
        .adhousedCard()
    }

    // MARK: - 3. Date & Time Range Pickers (From -> Until)

    private var dateTimeRangeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(theme.hudTag("DESIGNATE DATE & TIME WINDOW"))
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(theme.secondaryInk)
                Spacer()
                Text(durationSummaryLabel)
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(theme.warmingColor)
            }

            // FROM (Start Date & Time)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("From (Start)", systemImage: "calendar.badge.plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                    Spacer()
                    DatePicker(
                        "Start Date & Time",
                        selection: $startDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .onChange(of: startDate) { _, newStart in
                        if endDate <= newStart.addingTimeInterval(900) {
                            endDate = newStart.addingTimeInterval(3 * 3600)
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        quickTimeChip("Start Right Now") {
                            startDate = .now
                        }
                        quickTimeChip("Today 5:00 PM") {
                            startDate = todayAt(hour: 17, minute: 0)
                        }
                        quickTimeChip("Fri 5:00 PM") {
                            startDate = upcomingWeekdayAt(weekday: 6, hour: 17, minute: 0)
                        }
                        quickTimeChip("Sat 9:00 AM") {
                            startDate = upcomingWeekdayAt(weekday: 7, hour: 9, minute: 0)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 8 : 12, style: .continuous)
                    .fill(theme.canvasSecondary)
            )

            // UNTIL (End Date & Time)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Until (Resume)", systemImage: "calendar.badge.checkmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                    Spacer()
                    DatePicker(
                        "End Date & Time",
                        selection: $endDate,
                        in: startDate.addingTimeInterval(900)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        quickTimeChip("Sun 8:00 PM") {
                            endDate = upcomingEndWeekdayAt(after: startDate, weekday: 1, hour: 20, minute: 0)
                        }
                        quickTimeChip("Mon 9:00 AM") {
                            endDate = upcomingEndWeekdayAt(after: startDate, weekday: 2, hour: 9, minute: 0)
                        }
                        quickTimeChip("+2 Days") {
                            endDate = startDate.addingTimeInterval(2 * 86_400)
                        }
                        quickTimeChip("+3 Days") {
                            endDate = startDate.addingTimeInterval(3 * 86_400)
                        }
                        quickTimeChip("+1 Week") {
                            endDate = startDate.addingTimeInterval(7 * 86_400)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 8 : 12, style: .continuous)
                    .fill(theme.canvasSecondary)
            )
        }
        .padding(15)
        .adhousedCard()
    }

    private func quickTimeChip(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticsEngine.shared.playMechanicalTap()
            selectedPreset = .custom
            action()
            if endDate <= startDate.addingTimeInterval(900) {
                endDate = startDate.addingTimeInterval(24 * 3600)
            }
        } label: {
            Text(title)
                .font(.caption2.weight(.heavy))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(theme.cardSurface))
                .foregroundStyle(theme.accentPrimary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Break Label & Chore Freeze Toggle

    private var labelAndFreezeOptionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(theme.hudTag("BREAK LABEL & CHORE FREEZE"))
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            TextField("e.g., Countryside Weekend, Vacation…", text: $breakTitle)
                .font(.subheadline.weight(.bold))
                .padding(11)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.canvasSecondary))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(iconChoices, id: \.symbol) { item in
                        let selected = iconSymbol == item.symbol
                        Button {
                            HapticsEngine.shared.playMechanicalTap()
                            iconSymbol = item.symbol
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: item.symbol)
                                Text(item.label)
                            }
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(selected ? theme.accentPrimary : theme.canvasSecondary)
                            )
                            .foregroundStyle(selected ? theme.onAccentPrimary : theme.primaryInk)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Toggle(isOn: $freezeChoreDecay) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pause Chore Freshness Decay While Away")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                    Text("Freezes chore batteries during your trip and shifts rolling intervals forward so you don't return to a wall of overdue chores.")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryInk)
                }
            }
            .tint(theme.accentPrimary)
        }
        .padding(15)
        .adhousedCard()
    }

    // MARK: - 5. Primary Action Button

    private var saveActionCard: some View {
        VStack(spacing: 10) {
            Button {
                commitBreakWindow()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isStartingImmediately ? "pause.circle.fill" : "calendar.badge.clock")
                        .font(.headline)
                    Text(
                        editingBreakID != nil
                            ? "Save Updated Break Window"
                            : (isStartingImmediately ? "Activate Break & Silence Alerts Now" : "Schedule Break for Selected Dates")
                    )
                    .font(.subheadline.weight(.heavy))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(
                TactileActionButtonStyle(
                    fill: theme.warmingColor,
                    foreground: Color(hex: "#111216")
                )
            )

            Text("All persistent notifications, Lock Screen Live Activities, and Cutoff Alarms inside your From → Until window are automatically suppressed and resume when you're back.")
                .font(.caption2)
                .foregroundStyle(theme.secondaryInk)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Helpers

    private var durationSummaryLabel: String {
        let totalMinutes = max(15, Int(endDate.timeIntervalSince(startDate) / 60.0))
        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes % (24 * 60)) / 60
        if days > 0 {
            return hours > 0 ? "\(days)d \(hours)h break" : "\(days)d break"
        }
        return "\(max(1, hours))h break"
    }

    private func applyPreset(_ preset: VacationBreakPreset) {
        selectedPreset = preset
        let range = preset.suggestedRange(from: .now, awakeStartMinutes: awakeStartMinutes)
        startDate = range.start
        endDate = range.end
        breakTitle = preset.defaultTitle
        iconSymbol = preset.iconSymbol
    }

    private func loadExistingBreak(_ brk: VacationBreakWindow) {
        editingBreakID = brk.id
        selectedPreset = .custom
        breakTitle = brk.title
        iconSymbol = brk.iconSymbol
        startDate = brk.startDate
        endDate = brk.endDate
        freezeChoreDecay = brk.freezeChoreDecay
    }

    private func commitBreakWindow() {
        HapticsEngine.shared.playMechanicalTap()
        let window = VacationBreakWindow(
            id: editingBreakID ?? UUID(),
            title: breakTitle,
            iconSymbol: iconSymbol,
            startDate: startDate,
            endDate: endDate,
            freezeChoreDecay: freezeChoreDecay
        )
        _ = try? TaskActionService.scheduleVacationBreak(window, in: modelContext)
        dismiss()
    }

    private func todayAt(hour: Int, minute: Int) -> Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        return start.addingTimeInterval(Double(hour * 3600 + minute * 60))
    }

    private func upcomingWeekdayAt(weekday: Int, hour: Int, minute: Int) -> Date {
        let cal = Calendar.current
        let now = Date.now
        let startOfToday = cal.startOfDay(for: now)
        let currentWeekday = cal.component(.weekday, from: now)
        let daysAhead = (weekday - currentWeekday + 7) % 7
        let targetDay = cal.date(byAdding: .day, value: daysAhead, to: startOfToday) ?? startOfToday
        let candidate = targetDay.addingTimeInterval(Double(hour * 3600 + minute * 60))
        if candidate < now.addingTimeInterval(-3600) {
            return candidate.addingTimeInterval(7 * 86_400)
        }
        return candidate
    }

    private func upcomingEndWeekdayAt(after anchor: Date, weekday: Int, hour: Int, minute: Int) -> Date {
        let cal = Calendar.current
        let anchorDayStart = cal.startOfDay(for: anchor)
        let anchorWeekday = cal.component(.weekday, from: anchor)
        var daysAhead = (weekday - anchorWeekday + 7) % 7
        if daysAhead == 0 {
            daysAhead = 7
        }
        let targetDay = cal.date(byAdding: .day, value: daysAhead, to: anchorDayStart) ?? anchorDayStart
        let candidate = targetDay.addingTimeInterval(Double(hour * 3600 + minute * 60))
        if candidate <= anchor {
            return candidate.addingTimeInterval(7 * 86_400)
        }
        return candidate
    }
}
