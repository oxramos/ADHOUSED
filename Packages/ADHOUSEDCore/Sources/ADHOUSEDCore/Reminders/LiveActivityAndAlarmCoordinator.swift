import Foundation
import SwiftData
import SwiftUI
#if os(iOS)
import ActivityKit
#endif
#if canImport(AlarmKit) && os(iOS)
import AlarmKit
#endif

@MainActor
@Observable
public final class ReminderCoordinator {
    public static let shared = ReminderCoordinator()

    public private(set) var activeLiveActivityCount: Int = 0
    public private(set) var activeCutoffAlarmCount: Int = 0

    private init() {}

    /// Full reconciliation across all 3 reminder persistence tiers:
    /// 1. Rolling Time-Sensitive Notification Cascade (`NagBudgetScheduler`)
    /// 2. Pinned Lock Screen Live Activities (`ActivityKit`) for Tier 2 & Tier 3 due tasks
    /// 3. Cutoff System Alarms (`AlarmKit`) for Tier 3 due tasks
    public func reconcileAll(in context: ModelContext, now: Date = .now) async {
        let household = (try? context.fetch(FetchDescriptor<Household>()))?.first
        let members = (try? context.fetch(FetchDescriptor<HouseholdMember>())) ?? []
        let tasks = (try? context.fetch(FetchDescriptor<ChoreTask>())) ?? []
        let activeMemberID = ADHOUSEDPreferences.shared.activeMemberID

        // Tier 1: Recompute & schedule 56-slot rolling Time-Sensitive notification cascade
        let slots = NagSlotPlanner.computeSlots(
            tasks: tasks,
            household: household,
            activeMemberID: activeMemberID,
            now: now
        )
        await NagBudgetScheduler.shared.applySchedule(slots: slots, now: now)

        // Tier 2: Reconcile pinned Lock Screen Live Activities
        #if os(iOS)
        await reconcileChoreNagLiveActivities(
            tasks: tasks,
            household: household,
            members: members,
            activeMemberID: activeMemberID,
            now: now
        )
        #endif

        // Tier 3: Reconcile AlarmKit Cutoff System Alarms
        #if canImport(AlarmKit) && os(iOS)
        if #available(iOS 26.1, *) {
            await reconcileCutoffAlarms(
                tasks: tasks,
                household: household,
                activeMemberID: activeMemberID,
                now: now
            )
        }
        #endif
    }

    #if os(iOS)
    private func reconcileChoreNagLiveActivities(
        tasks: [ChoreTask],
        household: Household?,
        members: [HouseholdMember],
        activeMemberID: UUID?,
        now: Date
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            activeLiveActivityCount = 0
            return
        }

        let membersByID = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
        let globalPaused = household?.isCurrentlyPausedAway(at: now) ?? false
        let globalPauseDate = household?.awayPauseUntil
        let themeRaw = ADHOUSEDPreferences.shared.themePreset.rawValue

        // Top up to 2 Sticky Live Activity tasks actionable today for current member
        let stickyEligible = FreshnessCalculator.sortedByUrgency(
            tasks: tasks.filter {
                !$0.isArchived &&
                $0.remindersEnabled &&
                ($0.intensityTier == .stickyLiveActivity || $0.intensityTier == .cutoffSystemAlarm) &&
                $0.isActionable(forMemberID: activeMemberID)
            },
            forMemberID: activeMemberID,
            now: now
        )
        .filter { $0.snapshot.isActionableToday && !$0.task.hasActiveUndoGraceWindow(at: now) }
        .prefix(2)

        let wantedByID = Dictionary(uniqueKeysWithValues: stickyEligible.map { ($0.task.id.uuidString, $0) })
        let existingActivities = Activity<ChoreNagActivityAttributes>.activities

        // End activities for chores no longer due / just completed!
        for activity in existingActivities {
            if wantedByID[activity.attributes.taskIDString] == nil {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }

        let remainingByID = Dictionary(
            uniqueKeysWithValues: Activity<ChoreNagActivityAttributes>.activities.map { ($0.attributes.taskIDString, $0) }
        )

        for (taskIDStr, entry) in wantedByID {
            let task = entry.task
            let snap = entry.snapshot
            let owner = task.responsibleMemberID.flatMap { membersByID[$0] }
            let pausedDate = [task.pausedUntil, globalPauseDate].compactMap { $0 }.max()
            let isPaused = globalPaused || task.isTaskPaused(at: now)

            let state = ChoreNagActivityAttributes.ContentState(
                stageLabel: snap.stage.label,
                batteryFill: snap.batteryFill,
                nagIntervalMinutes: task.nagIntervalMinutes,
                responsibleMemberName: owner?.displayName,
                responsibleMemberEmoji: owner?.emoji,
                isPaused: isPaused,
                pausedUntil: isPaused ? pausedDate : nil,
                themePresetRaw: themeRaw
            )

            if let existing = remainingByID[taskIDStr] {
                await existing.update(ActivityContent(state: state, staleDate: nil))
            } else {
                let attrs = ChoreNagActivityAttributes(
                    taskIDString: taskIDStr,
                    taskTitle: task.title,
                    iconSymbol: task.iconSymbol,
                    roomTitle: task.room.title,
                    estimatedMinutes: task.estimatedMinutes
                )
                _ = try? Activity.request(
                    attributes: attrs,
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
            }
        }

        activeLiveActivityCount = Activity<ChoreNagActivityAttributes>.activities.count
    }

    // MARK: - Beat-the-Clock Sprint Live Activity

    public func startSprintLiveActivity(for task: ChoreTask, durationMinutes: Int, now: Date = .now) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        await endAllSprintLiveActivities()

        let endDate = now.addingTimeInterval(Double(durationMinutes * 60))
        let attrs = SprintTimerActivityAttributes(
            taskIDString: task.id.uuidString,
            taskTitle: task.title,
            iconSymbol: task.iconSymbol,
            roomTitle: task.room.title
        )
        let state = SprintTimerActivityAttributes.ContentState(
            startDate: now,
            targetEndDate: endDate,
            durationMinutes: durationMinutes,
            themePresetRaw: ADHOUSEDPreferences.shared.themePreset.rawValue
        )
        _ = try? Activity.request(
            attributes: attrs,
            content: ActivityContent(state: state, staleDate: endDate.addingTimeInterval(60)),
            pushType: nil
        )
    }

    public func endAllSprintLiveActivities() async {
        for activity in Activity<SprintTimerActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
    #endif

    // MARK: - Tier 3 AlarmKit Cutoff System Alarms

    #if canImport(AlarmKit) && os(iOS)
    @available(iOS 26.1, *)
    public func requestAlarmKitPermission() async -> Bool {
        do {
            let state = try await AlarmManager.shared.requestAuthorization()
            return state == .authorized
        } catch {
            return false
        }
    }

    @available(iOS 26.1, *)
    private func reconcileCutoffAlarms(
        tasks: [ChoreTask],
        household: Household?,
        activeMemberID: UUID?,
        now: Date,
        calendar: Calendar = .current
    ) async {
        guard AlarmManager.shared.authorizationState == .authorized else {
            activeCutoffAlarmCount = 0
            return
        }

        let startOfToday = calendar.startOfDay(for: now)
        let eligibleTasks = tasks.filter { task in
            guard !task.isArchived,
                  task.remindersEnabled,
                  task.intensityTier == .cutoffSystemAlarm,
                  task.isActionable(forMemberID: activeMemberID) else {
                return false
            }
            let snap = FreshnessCalculator.snapshot(for: task, now: now, calendar: calendar)
            return snap.isActionableToday
        }

        let eligibleIDs = Set(eligibleTasks.map(\.id))

        // Cancel alarms for tasks already completed or no longer due
        if let existing = try? AlarmManager.shared.alarms {
            for alarm in existing where !eligibleIDs.contains(alarm.id) {
                try? AlarmManager.shared.cancel(id: alarm.id)
            }
        }

        var armedCount = 0
        for task in eligibleTasks {
            var cutoffDate = startOfToday.addingTimeInterval(Double(task.alarmCutoffMinutes * 60))
            if let pauseUntil = household?.awayPauseUntil, pauseUntil > cutoffDate {
                cutoffDate = pauseUntil
            }
            if let taskPause = task.pausedUntil, taskPause > cutoffDate {
                cutoffDate = taskPause
            }
            // If cutoff time already passed today, schedule for tomorrow's cutoff if still undone
            if cutoffDate <= now.addingTimeInterval(30) {
                cutoffDate = cutoffDate.addingTimeInterval(86_400)
            }

            let secondaryBtn = AlarmButton(
                text: "Pause 30m",
                textColor: .orange,
                systemImageName: "pause.circle.fill"
            )
            let alertPresentation = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: task.title),
                secondaryButton: secondaryBtn,
                secondaryButtonBehavior: .custom
            )
            let presentation = AlarmPresentation(alert: alertPresentation)
            let metadata = ChoreAlarmMetadata(
                taskIDString: task.id.uuidString,
                taskTitle: task.title,
                roomTitle: task.room.title
            )
            let attrs = AlarmAttributes<ChoreAlarmMetadata>(
                presentation: presentation,
                metadata: metadata,
                tintColor: .orange
            )
            let config = AlarmManager.AlarmConfiguration<ChoreAlarmMetadata>.alarm(
                schedule: .fixed(cutoffDate),
                attributes: attrs,
                stopIntent: CompleteTaskIntent(taskIDString: task.id.uuidString, fromWidgetUndoable: false),
                secondaryIntent: PauseTaskRemindersIntent(taskIDString: task.id.uuidString, pauseMinutes: 30)
            )
            if (try? await AlarmManager.shared.schedule(id: task.id, configuration: config)) != nil {
                armedCount += 1
            }
        }
        activeCutoffAlarmCount = armedCount
    }
    #endif
}
