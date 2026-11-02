import Foundation
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

public enum PauseScope: Sendable {
    case singleTask(UUID)
    case entireHousehold
}

@MainActor
public enum TaskActionService {
    /// Duration of the fearless 1-tap inline Undo grace state on Home & Lock Screen widgets.
    public static let widgetUndoGraceSeconds: TimeInterval = 8.0

    @discardableResult
    public static func completeTask(
        taskID: UUID,
        byMemberID memberID: UUID?,
        enableWidgetUndoWindow: Bool,
        sprintSecondsElapsed: Int? = nil,
        in context: ModelContext,
        now: Date = .now
    ) throws -> CompletionRecord? {
        let descriptor = FetchDescriptor<ChoreTask>(predicate: #Predicate { $0.id == taskID })
        guard let task = try context.fetch(descriptor).first else { return nil }

        let effectiveActorID = memberID ?? ADHOUSEDPreferences.shared.activeMemberID ?? task.responsibleMemberID

        let record = CompletionRecord(
            taskID: task.id,
            householdID: task.householdID,
            completedAt: now,
            completedByMemberID: effectiveActorID,
            previousLastCompletedAt: task.lastCompletedAt,
            previousLastCompletedByMemberID: task.lastCompletedByMemberID,
            previousTurnIndex: task.currentTurnIndex,
            previousDeferredUntilDate: task.deferredUntilDate,
            sprintSecondsElapsed: sprintSecondsElapsed
        )
        context.insert(record)

        task.lastCompletedAt = now
        task.lastCompletedByMemberID = effectiveActorID
        task.deferredUntilDate = nil
        task.pausedUntil = nil
        task.totalCompletionsCount += 1
        task.updatedAt = now

        // Rotate alternating household turns automatically!
        if task.assignmentMode == .alternating {
            let memberCount = task.assignedMemberIDs.count
            if memberCount > 1 {
                task.currentTurnIndex = (task.currentTurnIndex + 1) % memberCount
            }
        }

        if enableWidgetUndoWindow {
            task.pendingUndoCompletionID = record.id
            task.pendingUndoExpiresAt = now.addingTimeInterval(widgetUndoGraceSeconds)
        } else {
            task.pendingUndoCompletionID = nil
            task.pendingUndoExpiresAt = nil
        }

        try context.save()
        awaitableReconcileAndReloadWidgets(in: context, now: now)
        return record
    }

    @discardableResult
    public static func undoLastCompletion(
        taskID: UUID,
        explicitCompletionID: UUID? = nil,
        in context: ModelContext,
        now: Date = .now
    ) throws -> Bool {
        let taskDesc = FetchDescriptor<ChoreTask>(predicate: #Predicate { $0.id == taskID })
        guard let task = try context.fetch(taskDesc).first else { return false }

        let targetRecordID = explicitCompletionID ?? task.pendingUndoCompletionID
        let record: CompletionRecord?
        if let targetRecordID {
            let recDesc = FetchDescriptor<CompletionRecord>(predicate: #Predicate { $0.id == targetRecordID })
            record = try context.fetch(recDesc).first
        } else {
            var recentDesc = FetchDescriptor<CompletionRecord>(
                predicate: #Predicate { $0.taskID == taskID },
                sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
            )
            recentDesc.fetchLimit = 1
            record = try context.fetch(recentDesc).first
        }

        guard let record else { return false }

        task.lastCompletedAt = record.previousLastCompletedAt
        task.lastCompletedByMemberID = record.previousLastCompletedByMemberID
        task.currentTurnIndex = record.previousTurnIndex
        task.deferredUntilDate = record.previousDeferredUntilDate
        task.totalCompletionsCount = max(0, task.totalCompletionsCount - 1)
        task.pendingUndoCompletionID = nil
        task.pendingUndoExpiresAt = nil
        task.updatedAt = now

        context.delete(record)
        try context.save()
        awaitableReconcileAndReloadWidgets(in: context, now: now)
        return true
    }

    public static func pauseReminders(
        scope: PauseScope,
        durationMinutes: Int,
        in context: ModelContext,
        now: Date = .now
    ) throws {
        let resumeAt = now.addingTimeInterval(Double(max(5, durationMinutes)) * 60.0)
        switch scope {
        case .singleTask(let taskID):
            let desc = FetchDescriptor<ChoreTask>(predicate: #Predicate { $0.id == taskID })
            if let task = try context.fetch(desc).first {
                task.pausedUntil = resumeAt
                task.updatedAt = now
            }
        case .entireHousehold:
            let households = try context.fetch(FetchDescriptor<Household>())
            for household in households {
                household.awayPauseUntil = resumeAt
                household.updatedAt = now
            }
        }
        try context.save()
        awaitableReconcileAndReloadWidgets(in: context, now: now)
    }

    public static func clearAwayPause(in context: ModelContext, now: Date = .now) throws {
        let households = try context.fetch(FetchDescriptor<Household>())
        for household in households {
            household.awayPauseUntil = nil
            household.updatedAt = now
        }
        try context.save()
        awaitableReconcileAndReloadWidgets(in: context, now: now)
    }

    /// Guardrailed app-only deferral to tomorrow's Awake Start — tracks deferralCount so chronic avoidance stays gently visible.
    public static func deferTaskToTomorrow(
        taskID: UUID,
        reasonTag: String,
        byMemberID memberID: UUID?,
        in context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current
    ) throws {
        let desc = FetchDescriptor<ChoreTask>(predicate: #Predicate { $0.id == taskID })
        guard let task = try context.fetch(desc).first else { return }

        let household = try context.fetch(FetchDescriptor<Household>()).first
        let awakeStartMins = household?.awakeStartMinutes ?? (8 * 60 + 30)

        let startOfToday = calendar.startOfDay(for: now)
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now.addingTimeInterval(86_400)
        let tomorrowAwake = tomorrowStart.addingTimeInterval(Double(awakeStartMins * 60))

        task.deferredUntilDate = tomorrowAwake
        task.deferralCount += 1
        task.pausedUntil = tomorrowAwake
        task.updatedAt = now

        let event = DeferralEvent(
            taskID: task.id,
            householdID: task.householdID,
            deferredAt: now,
            deferredByMemberID: memberID ?? ADHOUSEDPreferences.shared.activeMemberID,
            reasonTag: reasonTag
        )
        context.insert(event)
        try context.save()
        awaitableReconcileAndReloadWidgets(in: context, now: now)
    }

    /// Bootstraps a new household, members, and staggered starter chores from Onboarding.
    @discardableResult
    public static func bootstrapHousehold(
        householdName: String,
        memberSpecs: [(name: String, emoji: String, hex: String)],
        selectedTemplates: [(template: StarterChoreTemplate, seed: InitialFreshnessSeed, assignment: AssignmentMode)],
        in context: ModelContext,
        now: Date = .now
    ) throws -> Household {
        let existingHouseholds = try context.fetch(FetchDescriptor<Household>())
        let household: Household
        if let first = existingHouseholds.first {
            first.name = householdName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Our Home" : householdName
            first.updatedAt = now
            household = first
        } else {
            household = Household(
                name: householdName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Our Home" : householdName,
                createdAt: now,
                updatedAt: now
            )
            context.insert(household)
        }

        let existingMembers = try context.fetch(FetchDescriptor<HouseholdMember>())
        var createdMembers: [HouseholdMember] = existingMembers
        if existingMembers.isEmpty {
            let safeSpecs = memberSpecs.isEmpty
                ? [("Me", "🦊", "#4E9F6E")]
                : memberSpecs
            createdMembers = safeSpecs.enumerated().map { idx, spec in
                let member = HouseholdMember(
                    householdID: household.id,
                    displayName: spec.name,
                    emoji: spec.emoji,
                    accentHex: spec.hex,
                    sortOrder: idx,
                    createdAt: now
                )
                context.insert(member)
                return member
            }
        }

        if ADHOUSEDPreferences.shared.activeMemberID == nil {
            ADHOUSEDPreferences.shared.activeMemberID = createdMembers.first?.id
        }

        let memberIDs = createdMembers.map(\.id)
        let total = selectedTemplates.count

        for (idx, item) in selectedTemplates.enumerated() {
            let seededLastDone = StarterCatalogSeeder.initialLastCompletedDate(
                for: item.template,
                seed: item.seed,
                indexInBatch: idx,
                totalBatchCount: total,
                now: now
            )

            let effectiveMode: AssignmentMode = memberIDs.count > 1 ? item.assignment : .anyone
            let assignedIDs: [UUID]
            switch effectiveMode {
            case .anyone:
                assignedIDs = []
            case .assigned:
                assignedIDs = [memberIDs[idx % memberIDs.count]]
            case .alternating:
                assignedIDs = memberIDs
            }

            let chore = ChoreTask(
                householdID: household.id,
                title: item.template.title,
                iconSymbol: item.template.iconSymbol,
                room: item.template.room,
                scheduleMode: item.template.scheduleMode,
                intervalUnit: item.template.intervalUnit,
                intervalCount: item.template.intervalCount,
                fixedRuleKind: .weeklyDays,
                fixedWeekdays: item.template.fixedWeekdays,
                lastCompletedAt: seededLastDone,
                lastCompletedByMemberID: seededLastDone != nil && !memberIDs.isEmpty ? memberIDs[(idx + 1) % memberIDs.count] : nil,
                energyLevel: item.template.energyLevel,
                estimatedMinutes: item.template.estimatedMinutes,
                remindersEnabled: true,
                nagIntervalMinutes: item.template.suggestedNagMinutes,
                intensityTier: item.template.suggestedTier,
                assignmentMode: effectiveMode,
                assignedMemberIDs: assignedIDs,
                currentTurnIndex: idx % max(1, memberIDs.count),
                createdAt: now
            )
            context.insert(chore)
        }

        ADHOUSEDPreferences.shared.hasCompletedOnboarding = true
        try context.save()
        awaitableReconcileAndReloadWidgets(in: context, now: now)
        return household
    }

    public static func awaitableReconcileAndReloadWidgets(in context: ModelContext, now: Date = .now) {
        let bundlePath = Bundle.main.bundlePath
        let isBundledAppOrExtension = bundlePath.hasSuffix(".app") || bundlePath.hasSuffix(".appex")
        #if canImport(WidgetKit)
        if isBundledAppOrExtension {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
        guard isBundledAppOrExtension else { return }
        Task { @MainActor in
            await ReminderCoordinator.shared.reconcileAll(in: context, now: now)
        }
    }
}
