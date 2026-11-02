import Foundation

public struct TaskFreshnessSnapshot: Sendable, Equatable {
    /// Clamped visual battery fill in `0.0 ... 1.0` (`1.0` = sparkling fresh, `0.0` = depleted / due now)
    public let batteryFill: Double
    /// Unclamped freshness ratio (`< 0.0` indicates overdue beyond target interval, used only for priority sorting — never shame counters)
    public let rawFreshnessRatio: Double
    public let stage: FreshnessStage
    public let dueDate: Date
    public let isActionableToday: Bool
    public let isDeferredPastToday: Bool
    /// Human-friendly ADHD time-blindness caption, e.g. `"Done 6d ago · every 7d"` or `"Every Tue · Due Today"`
    public let cadenceSummary: String
    public let shortElapsedBadge: String

    public init(
        batteryFill: Double,
        rawFreshnessRatio: Double,
        stage: FreshnessStage,
        dueDate: Date,
        isActionableToday: Bool,
        isDeferredPastToday: Bool,
        cadenceSummary: String,
        shortElapsedBadge: String
    ) {
        self.batteryFill = batteryFill
        self.rawFreshnessRatio = rawFreshnessRatio
        self.stage = stage
        self.dueDate = dueDate
        self.isActionableToday = isActionableToday
        self.isDeferredPastToday = isDeferredPastToday
        self.cadenceSummary = cadenceSummary
        self.shortElapsedBadge = shortElapsedBadge
    }
}

public struct HouseholdMomentumStats: Sendable, Equatable {
    public let completionsLast7Days: Int
    public let completionsLast30Days: Int
    /// Last 7 calendar days (oldest to today), true if at least 1 task was kept fresh that day
    public let recent7DayActivityDots: [Bool]
    public let headline: String

    public init(
        completionsLast7Days: Int,
        completionsLast30Days: Int,
        recent7DayActivityDots: [Bool],
        headline: String
    ) {
        self.completionsLast7Days = completionsLast7Days
        self.completionsLast30Days = completionsLast30Days
        self.recent7DayActivityDots = recent7DayActivityDots
        self.headline = headline
    }
}

public enum FreshnessCalculator {

    public static func snapshot(
        for task: ChoreTask,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> TaskFreshnessSnapshot {
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now

        let deferredPastToday: Bool
        if let deferredUntil = task.deferredUntilDate, deferredUntil >= endOfToday {
            deferredPastToday = true
        } else {
            deferredPastToday = false
        }

        switch task.scheduleMode {
        case .rollingFromLastDone:
            return rollingSnapshot(
                for: task,
                now: now,
                endOfToday: endOfToday,
                deferredPastToday: deferredPastToday,
                calendar: calendar
            )
        case .fixedCalendar:
            return fixedCalendarSnapshot(
                for: task,
                now: now,
                startOfToday: startOfToday,
                endOfToday: endOfToday,
                deferredPastToday: deferredPastToday,
                calendar: calendar
            )
        }
    }

    private static func rollingSnapshot(
        for task: ChoreTask,
        now: Date,
        endOfToday: Date,
        deferredPastToday: Bool,
        calendar: Calendar
    ) -> TaskFreshnessSnapshot {
        let targetDays = max(1.0, task.intervalUnit.approximateDays(count: task.intervalCount))
        let targetSeconds = targetDays * 86_400.0
        let anchorDate = task.lastCompletedAt ?? task.createdAt
        let elapsedSeconds = max(0, now.timeIntervalSince(anchorDate))

        // If task has never been completed and was explicitly created with nil lastCompletedAt, treat as due today
        let effectiveRatio: Double
        let computedDueDate: Date
        if task.lastCompletedAt == nil {
            effectiveRatio = 0.0
            computedDueDate = now
        } else {
            effectiveRatio = 1.0 - (elapsedSeconds / targetSeconds)
            computedDueDate = anchorDate.addingTimeInterval(targetSeconds)
        }

        let effectiveDueDate: Date
        if deferredPastToday, let deferred = task.deferredUntilDate {
            effectiveDueDate = max(computedDueDate, deferred)
        } else {
            effectiveDueDate = computedDueDate
        }

        let fill = deferredPastToday ? max(0.28, min(1.0, effectiveRatio)) : max(0.0, min(1.0, effectiveRatio))

        let stage: FreshnessStage
        let actionable: Bool

        if deferredPastToday {
            stage = .warming
            actionable = false
        } else if effectiveRatio <= -0.15 {
            stage = .needsAttentionNow
            actionable = true
        } else if effectiveRatio <= 0.05 || effectiveDueDate < endOfToday {
            // If 1-day task was completed today already, keep it fresh until tomorrow!
            if let lastDone = task.lastCompletedAt, calendar.isDate(lastDone, inSameDayAs: now) {
                stage = .fresh
                actionable = false
            } else {
                stage = effectiveRatio < -0.05 ? .needsAttentionNow : .dueToday
                actionable = true
            }
        } else if effectiveRatio <= 0.32 {
            stage = .warming
            actionable = false
        } else {
            stage = .fresh
            actionable = false
        }

        let intervalText = formatIntervalPhrase(unit: task.intervalUnit, count: task.intervalCount)
        let elapsedPhrase = formatElapsedPhrase(lastDone: task.lastCompletedAt, now: now, calendar: calendar)
        let summary = deferredPastToday
            ? "Paused till tomorrow · \(intervalText)"
            : "\(elapsedPhrase) · \(intervalText)"

        return TaskFreshnessSnapshot(
            batteryFill: stage == .fresh && effectiveRatio < 0.8 ? 0.92 : fill,
            rawFreshnessRatio: effectiveRatio,
            stage: stage,
            dueDate: effectiveDueDate,
            isActionableToday: actionable,
            isDeferredPastToday: deferredPastToday,
            cadenceSummary: summary,
            shortElapsedBadge: shortElapsedText(lastDone: task.lastCompletedAt, now: now, calendar: calendar)
        )
    }

    private static func fixedCalendarSnapshot(
        for task: ChoreTask,
        now: Date,
        startOfToday: Date,
        endOfToday: Date,
        deferredPastToday: Bool,
        calendar: Calendar
    ) -> TaskFreshnessSnapshot {
        let completedToday: Bool = {
            guard let lastDone = task.lastCompletedAt else { return false }
            return calendar.isDate(lastDone, inSameDayAs: now)
        }()

        // Find most recent scheduled date <= today and next scheduled date > today
        let mostRecentScheduled = mostRecentFixedOccurrence(for: task, onOrBefore: startOfToday, calendar: calendar)
        let nextScheduled = nextFixedOccurrence(for: task, after: startOfToday, calendar: calendar)

        // Was the most recent scheduled occurrence already satisfied?
        let missedOrDueOccurrenceUnsatisfied: Bool = {
            guard let recent = mostRecentScheduled else { return false }
            guard let lastDone = task.lastCompletedAt else { return true }
            return lastDone < recent
        }()

        let isScheduledToday: Bool = {
            guard let recent = mostRecentScheduled else { return false }
            return calendar.isDate(recent, inSameDayAs: startOfToday)
        }()

        let cycleSpan = max(86_400.0, nextScheduled.timeIntervalSince(mostRecentScheduled ?? startOfToday.addingTimeInterval(-7 * 86_400)))
        let scheduleLabel = formatFixedSchedulePhrase(for: task, calendar: calendar)

        if deferredPastToday {
            return TaskFreshnessSnapshot(
                batteryFill: 0.30,
                rawFreshnessRatio: 0.30,
                stage: .warming,
                dueDate: task.deferredUntilDate ?? endOfToday,
                isActionableToday: false,
                isDeferredPastToday: true,
                cadenceSummary: "Moved to tomorrow · \(scheduleLabel)",
                shortElapsedBadge: "Tomorrow"
            )
        }

        if !completedToday && missedOrDueOccurrenceUnsatisfied {
            let overdueFlag = !isScheduledToday
            return TaskFreshnessSnapshot(
                batteryFill: overdueFlag ? 0.04 : 0.12,
                rawFreshnessRatio: overdueFlag ? -0.25 : 0.0,
                stage: overdueFlag ? .needsAttentionNow : .dueToday,
                dueDate: mostRecentScheduled ?? startOfToday,
                isActionableToday: true,
                isDeferredPastToday: false,
                cadenceSummary: isScheduledToday ? "\(scheduleLabel) · Due Today" : "\(scheduleLabel) · Ready Now",
                shortElapsedBadge: isScheduledToday ? "Today" : "Ready"
            )
        }

        let remainingSeconds = max(0, nextScheduled.timeIntervalSince(now))
        let ratio = min(1.0, max(0.15, remainingSeconds / cycleSpan))
        let daysUntil = max(1, calendar.dateComponents([.day], from: startOfToday, to: nextScheduled).day ?? 1)
        let stage: FreshnessStage = daysUntil <= 1 ? .warming : .fresh

        return TaskFreshnessSnapshot(
            batteryFill: completedToday ? 1.0 : ratio,
            rawFreshnessRatio: completedToday ? 1.0 : ratio,
            stage: stage,
            dueDate: nextScheduled,
            isActionableToday: false,
            isDeferredPastToday: false,
            cadenceSummary: completedToday ? "Done today · \(scheduleLabel)" : "\(scheduleLabel) · in \(daysUntil)d",
            shortElapsedBadge: completedToday ? "Done" : "in \(daysUntil)d"
        )
    }

    // MARK: - Priority Sorting & Spotlight Selection

    /// Sorts tasks from highest urgency / lowest freshness to freshest.
    public static func sortedByUrgency(
        tasks: [ChoreTask],
        forMemberID memberID: UUID?,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [(task: ChoreTask, snapshot: TaskFreshnessSnapshot)] {
        let active = tasks.filter { !$0.isArchived }
        let paired = active.map { ($0, snapshot(for: $0, now: now, calendar: calendar)) }

        return paired.sorted { lhs, rhs in
            // Keep active undo-grace items pinned right where the user tapped so inline Undo stays visible!
            let lhsUndo = lhs.0.hasActiveUndoGraceWindow(at: now)
            let rhsUndo = rhs.0.hasActiveUndoGraceWindow(at: now)
            if lhsUndo != rhsUndo { return lhsUndo }

            // Actionable for current member beats someone else's chore
            let lhsMine = lhs.0.isActionable(forMemberID: memberID)
            let rhsMine = rhs.0.isActionable(forMemberID: memberID)
            if lhs.1.isActionableToday != rhs.1.isActionableToday {
                return lhs.1.isActionableToday
            }
            if lhs.1.isActionableToday && lhsMine != rhsMine {
                return lhsMine
            }
            if lhs.1.stage != rhs.1.stage {
                return lhs.1.stage < rhs.1.stage
            }
            if abs(lhs.1.rawFreshnessRatio - rhs.1.rawFreshnessRatio) > 0.001 {
                return lhs.1.rawFreshnessRatio < rhs.1.rawFreshnessRatio
            }
            return lhs.0.estimatedMinutes < rhs.0.estimatedMinutes
        }
    }

    /// Computes room-level average freshness (`0.0 ... 1.0`) and count of due tasks.
    public static func roomHealth(
        room: RoomCategory,
        tasks: [ChoreTask],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> (averageFill: Double, dueCount: Int, totalCount: Int) {
        let roomTasks = tasks.filter { !$0.isArchived && $0.room == room }
        guard !roomTasks.isEmpty else { return (1.0, 0, 0) }
        let snaps = roomTasks.map { snapshot(for: $0, now: now, calendar: calendar) }
        let avg = snaps.map(\.batteryFill).reduce(0, +) / Double(snaps.count)
        let due = snaps.filter(\.isActionableToday).count
        return (avg, due, roomTasks.count)
    }

    /// Shame-free momentum calculation (celebrates cumulative wins, never resets to zero on a missed day).
    public static func momentumStats(
        completions: [CompletionRecord],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> HouseholdMomentumStats {
        let startOfToday = calendar.startOfDay(for: now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? now
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: startOfToday) ?? now

        let count7 = completions.filter { $0.completedAt >= sevenDaysAgo }.count
        let count30 = completions.filter { $0.completedAt >= thirtyDaysAgo }.count

        let dots: [Bool] = (-6...0).map { offset in
            guard let dayStart = calendar.date(byAdding: .day, value: offset, to: startOfToday),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                return false
            }
            return completions.contains { $0.completedAt >= dayStart && $0.completedAt < dayEnd }
        }

        let headline: String
        if count7 == 0 {
            headline = "Ready for an easy win today — zero pressure, start small"
        } else if count7 == 1 {
            headline = "1 chore kept fresh this week · \(count30) in the last 30d"
        } else {
            headline = "\(count7) chores kept fresh this week · \(count30) in 30d"
        }

        return HouseholdMomentumStats(
            completionsLast7Days: count7,
            completionsLast30Days: count30,
            recent7DayActivityDots: dots,
            headline: headline
        )
    }

    // MARK: - Helpers

    private static func mostRecentFixedOccurrence(
        for task: ChoreTask,
        onOrBefore dayStart: Date,
        calendar: Calendar
    ) -> Date? {
        switch task.fixedRuleKind {
        case .weeklyDays:
            let targets = Set(task.fixedWeekdays.isEmpty ? [3] : task.fixedWeekdays)
            for offset in 0...7 {
                guard let candidate = calendar.date(byAdding: .day, value: -offset, to: dayStart) else { continue }
                let weekday = calendar.component(.weekday, from: candidate)
                if targets.contains(weekday) {
                    return candidate
                }
            }
            return dayStart
        case .monthlyDay:
            let targetDay = min(28, max(1, task.fixedDayOfMonth))
            var comps = calendar.dateComponents([.year, .month], from: dayStart)
            comps.day = targetDay
            if let thisMonthDate = calendar.date(from: comps), thisMonthDate <= dayStart {
                return thisMonthDate
            }
            if let prevMonth = calendar.date(byAdding: .month, value: -1, to: dayStart) {
                var prevComps = calendar.dateComponents([.year, .month], from: prevMonth)
                prevComps.day = targetDay
                return calendar.date(from: prevComps)
            }
            return dayStart
        }
    }

    private static func nextFixedOccurrence(
        for task: ChoreTask,
        after dayStart: Date,
        calendar: Calendar
    ) -> Date {
        switch task.fixedRuleKind {
        case .weeklyDays:
            let targets = Set(task.fixedWeekdays.isEmpty ? [3] : task.fixedWeekdays)
            for offset in 1...8 {
                guard let candidate = calendar.date(byAdding: .day, value: offset, to: dayStart) else { continue }
                let weekday = calendar.component(.weekday, from: candidate)
                if targets.contains(weekday) {
                    return candidate
                }
            }
            return calendar.date(byAdding: .day, value: 7, to: dayStart) ?? dayStart
        case .monthlyDay:
            let targetDay = min(28, max(1, task.fixedDayOfMonth))
            var comps = calendar.dateComponents([.year, .month], from: dayStart)
            comps.day = targetDay
            if let thisMonthDate = calendar.date(from: comps), thisMonthDate > dayStart {
                return thisMonthDate
            }
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: dayStart) {
                var nextComps = calendar.dateComponents([.year, .month], from: nextMonth)
                nextComps.day = targetDay
                if let resolved = calendar.date(from: nextComps) {
                    return resolved
                }
            }
            return calendar.date(byAdding: .day, value: 30, to: dayStart) ?? dayStart
        }
    }

    private static func formatIntervalPhrase(unit: IntervalUnit, count: Int) -> String {
        if unit == .days && count == 1 { return "daily" }
        if unit == .weeks && count == 1 { return "every 7d" }
        let shortUnit: String
        switch unit {
        case .days: shortUnit = "d"
        case .weeks: shortUnit = "w"
        case .months: shortUnit = "mo"
        }
        return "every \(count)\(shortUnit)"
    }

    private static func formatElapsedPhrase(lastDone: Date?, now: Date, calendar: Calendar) -> String {
        guard let lastDone else { return "Ready for first checkoff" }
        if calendar.isDate(lastDone, inSameDayAs: now) {
            return "Done today"
        }
        if calendar.isDateInYesterday(lastDone) {
            return "Done yesterday"
        }
        let startLast = calendar.startOfDay(for: lastDone)
        let startNow = calendar.startOfDay(for: now)
        let days = max(1, calendar.dateComponents([.day], from: startLast, to: startNow).day ?? 1)
        return "Done \(days)d ago"
    }

    private static func shortElapsedText(lastDone: Date?, now: Date, calendar: Calendar) -> String {
        guard let lastDone else { return "Due" }
        if calendar.isDate(lastDone, inSameDayAs: now) { return "Fresh" }
        let startLast = calendar.startOfDay(for: lastDone)
        let startNow = calendar.startOfDay(for: now)
        let days = max(1, calendar.dateComponents([.day], from: startLast, to: startNow).day ?? 1)
        return "\(days)d ago"
    }

    private static func formatFixedSchedulePhrase(for task: ChoreTask, calendar: Calendar) -> String {
        switch task.fixedRuleKind {
        case .weeklyDays:
            let symbols = calendar.shortWeekdaySymbols
            let names = task.fixedWeekdays.compactMap { day -> String? in
                guard (1...7).contains(day) else { return nil }
                return symbols[day - 1]
            }
            return "Every " + (names.isEmpty ? "Tue" : names.joined(separator: "/"))
        case .monthlyDay:
            return "Day \(task.fixedDayOfMonth) monthly"
        }
    }
}
