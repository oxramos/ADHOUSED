import Foundation
import UserNotifications

public struct PlannedNagSlot: Sendable, Equatable, Identifiable {
    public var id: String { "\(taskID.uuidString)-\(Int(fireDate.timeIntervalSince1970))" }
    public let taskID: UUID
    public let taskTitle: String
    public let roomTitle: String
    public let fireDate: Date
    public let sequenceIndex: Int
    public let nagIntervalMinutes: Int
    public let estimatedMinutes: Int
    public let intensityTier: ReminderIntensityTier

    public init(
        taskID: UUID,
        taskTitle: String,
        roomTitle: String,
        fireDate: Date,
        sequenceIndex: Int,
        nagIntervalMinutes: Int,
        estimatedMinutes: Int,
        intensityTier: ReminderIntensityTier
    ) {
        self.taskID = taskID
        self.taskTitle = taskTitle
        self.roomTitle = roomTitle
        self.fireDate = fireDate
        self.sequenceIndex = sequenceIndex
        self.nagIntervalMinutes = nagIntervalMinutes
        self.estimatedMinutes = estimatedMinutes
        self.intensityTier = intensityTier
    }
}

public enum NagNotificationConstants {
    public static let categoryIdentifier = "ADHOUSED_CHORE_NAG"
    public static let actionComplete = "ADHOUSED_ACTION_COMPLETE"
    public static let actionPause1Hour = "ADHOUSED_ACTION_PAUSE_1H"
    public static let actionAway3Hours = "ADHOUSED_ACTION_AWAY_3H"
    public static let requestPrefix = "adhoused.nag."
    /// Keep safely below iOS's 64 pending local notification limit per app.
    public static let maxBudgetSlots = 56
}

public enum NagSlotPlanner {
    /// Deterministically computes the rolling notification cascade across all actionable tasks
    /// for the active household member, respecting Awake Hours and Timed "Away / Busy" pauses.
    public static func computeSlots(
        tasks: [ChoreTask],
        household: Household?,
        activeMemberID: UUID?,
        maxSlots: Int = NagNotificationConstants.maxBudgetSlots,
        horizonHours: Int = 36,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [PlannedNagSlot] {
        let awakeStart = household?.awakeStartMinutes ?? (8 * 60 + 30)
        let awakeEnd = max(awakeStart + 60, household?.awakeEndMinutes ?? (21 * 60 + 30))
        let globalPauseUntil = household?.awayPauseUntil

        let horizonEnd = now.addingTimeInterval(Double(horizonHours) * 3600.0)
        var candidates: [PlannedNagSlot] = []

        for task in tasks where !task.isArchived && task.remindersEnabled {
            guard task.isActionable(forMemberID: activeMemberID) else { continue }
            let snap = FreshnessCalculator.snapshot(for: task, now: now, calendar: calendar)

            // Only schedule nag cascades for tasks actionable today (or whose due date falls inside horizon)
            guard snap.isActionableToday || snap.dueDate <= horizonEnd else { continue }

            let intervalSec = Double(max(15, task.nagIntervalMinutes)) * 60.0
            var earliestStart = max(now.addingTimeInterval(60), snap.isActionableToday ? now.addingTimeInterval(intervalSec) : snap.dueDate)

            if let taskPause = task.pausedUntil, taskPause > earliestStart {
                earliestStart = taskPause
            }
            if let globalPause = globalPauseUntil, globalPause > earliestStart {
                earliestStart = globalPause
            }
            if let deferred = task.deferredUntilDate, deferred > earliestStart {
                earliestStart = deferred
            }

            var cursor = clampToAwakeWindow(
                date: earliestStart,
                awakeStartMinutes: awakeStart,
                awakeEndMinutes: awakeEnd,
                calendar: calendar
            )

            var seq = 1
            while cursor <= horizonEnd && seq <= 24 {
                candidates.append(
                    PlannedNagSlot(
                        taskID: task.id,
                        taskTitle: task.title,
                        roomTitle: task.room.title,
                        fireDate: cursor,
                        sequenceIndex: seq,
                        nagIntervalMinutes: task.nagIntervalMinutes,
                        estimatedMinutes: task.estimatedMinutes,
                        intensityTier: task.intensityTier
                    )
                )
                seq += 1
                let nextRaw = cursor.addingTimeInterval(intervalSec)
                cursor = clampToAwakeWindow(
                    date: nextRaw,
                    awakeStartMinutes: awakeStart,
                    awakeEndMinutes: awakeEnd,
                    calendar: calendar
                )
            }
        }

        // Chronological sort so soonest alerts across ALL due tasks always get guaranteed slots in iOS's 64-slot queue
        candidates.sort { lhs, rhs in
            if abs(lhs.fireDate.timeIntervalSince(rhs.fireDate)) > 1 {
                return lhs.fireDate < rhs.fireDate
            }
            return lhs.intensityTier.rawValue > rhs.intensityTier.rawValue
        }

        return Array(candidates.prefix(maxSlots))
    }

    public static func clampToAwakeWindow(
        date: Date,
        awakeStartMinutes: Int,
        awakeEndMinutes: Int,
        calendar: Calendar
    ) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        let minsFromMidnight = Int(date.timeIntervalSince(dayStart) / 60.0)

        if minsFromMidnight < awakeStartMinutes {
            return dayStart.addingTimeInterval(Double(awakeStartMinutes * 60))
        }
        if minsFromMidnight > awakeEndMinutes {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86_400)
            return nextDay.addingTimeInterval(Double(awakeStartMinutes * 60))
        }
        return date
    }

    public static func notificationCopy(for slot: PlannedNagSlot) -> (title: String, body: String) {
        let title: String
        if slot.sequenceIndex == 1 {
            title = "Ready Now: \(slot.taskTitle)"
        } else if slot.sequenceIndex <= 3 {
            title = "Still Waiting (\(slot.estimatedMinutes)m): \(slot.taskTitle)"
        } else {
            title = "Persistent Ping #\(slot.sequenceIndex): \(slot.taskTitle)"
        }

        let body = "\(slot.roomTitle) · ~\(slot.estimatedMinutes) min. Re-alerts every \(slot.nagIntervalMinutes)m until marked Done (swiping away won't cancel)."
        return (title, body)
    }
}

@MainActor
public final class NagBudgetScheduler {
    public static let shared = NagBudgetScheduler()
    public private(set) var scheduledSlotCount: Int = 0

    private init() {}

    private var canAccessNotificationCenter: Bool {
        guard Bundle.main.bundleIdentifier != nil else { return false }
        let path = Bundle.main.bundlePath
        return path.hasSuffix(".app") || path.hasSuffix(".appex")
    }

    public func registerInteractiveCategories() {
        guard canAccessNotificationCenter else { return }
        let center = UNUserNotificationCenter.current()
        let doneAction = UNNotificationAction(
            identifier: NagNotificationConstants.actionComplete,
            title: "✓ Mark Done",
            options: [.authenticationRequired]
        )
        let pause1hAction = UNNotificationAction(
            identifier: NagNotificationConstants.actionPause1Hour,
            title: "⏸ Pause 1h",
            options: []
        )
        let away3hAction = UNNotificationAction(
            identifier: NagNotificationConstants.actionAway3Hours,
            title: "🏠 Away — Pause 3h",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: NagNotificationConstants.categoryIdentifier,
            actions: [doneAction, pause1hAction, away3hAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        center.setNotificationCategories([category])
    }

    public func requestNotificationAuthorization() async -> Bool {
        guard canAccessNotificationCenter else { return false }
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            registerInteractiveCategories()
            return granted
        } catch {
            return false
        }
    }

    public func applySchedule(slots: [PlannedNagSlot], now: Date = .now, calendar: Calendar = .current) async {
        guard canAccessNotificationCenter else {
            scheduledSlotCount = slots.count
            return
        }
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let existingNagIDs = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(NagNotificationConstants.requestPrefix) }

        if !existingNagIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: existingNagIDs)
        }

        var scheduled = 0
        for slot in slots where slot.fireDate > now.addingTimeInterval(5) {
            let copy = NagSlotPlanner.notificationCopy(for: slot)
            let content = UNMutableNotificationContent()
            content.title = copy.title
            content.body = copy.body
            content.sound = .default
            content.categoryIdentifier = NagNotificationConstants.categoryIdentifier
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = slot.intensityTier == .cutoffSystemAlarm ? 1.0 : 0.85
            content.userInfo = [
                "taskID": slot.taskID.uuidString,
                "sequenceIndex": slot.sequenceIndex
            ]

            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: slot.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(NagNotificationConstants.requestPrefix)\(slot.id)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
            scheduled += 1
        }
        scheduledSlotCount = scheduled
    }

    /// Fires a live demonstration Time-Sensitive notification in 3 seconds so users can test Lock Screen actions immediately.
    public func scheduleTestPing(for task: ChoreTask) async {
        guard canAccessNotificationCenter else { return }
        registerInteractiveCategories()
        let content = UNMutableNotificationContent()
        content.title = "Persistent Ping Preview: \(task.title)"
        content.body = "Long-press this banner on your Lock Screen to test [✓ Mark Done], [⏸ Pause 1h], or [🏠 Away 3h]!"
        content.sound = .default
        content.categoryIdentifier = NagNotificationConstants.categoryIdentifier
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["taskID": task.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let req = UNNotificationRequest(
            identifier: "adhoused.test.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(req)
    }
}
