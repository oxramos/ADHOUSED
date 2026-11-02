import Foundation
import SwiftUI
import SwiftData
import ADHOUSEDCore
#if canImport(WidgetKit)
import WidgetKit
#endif

public struct UndoToastBannerState: Equatable, Identifiable {
    public let id: UUID
    public let taskID: UUID
    public let taskTitle: String
    public let completionID: UUID
    public let expiresAt: Date
}

public struct ActiveSprintSession: Equatable {
    public let taskID: UUID
    public let taskTitle: String
    public let iconSymbol: String
    public let room: RoomCategory
    public let startedAt: Date
    public let targetEndDate: Date
    public let durationSeconds: Int
}

@MainActor
@Observable
public final class AppSessionViewModel {
    /// Quick & Easy (<= 5 min) filter
    public var lowSpoonsFilterEnabled: Bool = false
    /// Room filter at top of dashboard (`nil` = All Rooms)
    public var selectedRoom: RoomCategory? = nil
    /// Whether to expand the visual Room Health grid at top of dashboard
    public var showRoomHealthGrid: Bool = false
    /// When household has multiple members, filter to my actionable chores vs everyone's
    public var showEveryoneChores: Bool = false
    public var showAllDueTasksInSpotlight: Bool = false

    // Active Focus Timer
    public var activeSprint: ActiveSprintSession? = nil
    public var presentingSprintSheetForTask: ChoreTask? = nil

    // Sheets
    public var presentingNewTaskSheet: Bool = false
    public var editingTask: ChoreTask? = nil
    public var deferringTask: ChoreTask? = nil
    public var presentingVacationBreakSheet: Bool = false
    public var presentingSettingsSheet: Bool = false
    public var presentingStarterCatalogSheet: Bool = false
    public var presentingPartnerSharingSheet: Bool = false
    public var customizingThemePreset: ThemePreset? = nil

    // Undo Toast
    public var undoToast: UndoToastBannerState? = nil
    private var undoDismissTask: Task<Void, Never>?

    public init() {}

    public func triggerCompletionWithToast(
        task: ChoreTask,
        sprintSeconds: Int? = nil,
        in context: ModelContext
    ) {
        HapticsEngine.shared.playCompletionCelebration()
        let actorID = ADHOUSEDPreferences.shared.activeMemberID
        guard let record = try? TaskActionService.completeTask(
            taskID: task.id,
            byMemberID: actorID,
            enableWidgetUndoWindow: false,
            sprintSecondsElapsed: sprintSeconds,
            in: context
        ) else { return }

        if activeSprint?.taskID == task.id {
            activeSprint = nil
            Task {
                await ReminderCoordinator.shared.endAllSprintLiveActivities()
            }
        }

        let toast = UndoToastBannerState(
            id: UUID(),
            taskID: task.id,
            taskTitle: task.title,
            completionID: record.id,
            expiresAt: Date().addingTimeInterval(6.0)
        )
        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
            undoToast = toast
        }

        undoDismissTask?.cancel()
        undoDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(6))
            if !Task.isCancelled, self.undoToast?.id == toast.id {
                withAnimation(.easeInOut(duration: 0.22)) {
                    self.undoToast = nil
                }
            }
        }
    }

    public func performUndoToast(in context: ModelContext) {
        guard let current = undoToast else { return }
        HapticsEngine.shared.playUndoRewind()
        undoDismissTask?.cancel()
        _ = try? TaskActionService.undoLastCompletion(
            taskID: current.taskID,
            explicitCompletionID: current.completionID,
            in: context
        )
        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            undoToast = nil
        }
    }

    public func startBeatTheClockSprint(for task: ChoreTask, minutes: Int) {
        HapticsEngine.shared.playSprintStart()
        let now = Date()
        let secs = max(60, minutes * 60)
        let sprintSession = ActiveSprintSession(
            taskID: task.id,
            taskTitle: task.title,
            iconSymbol: task.iconSymbol,
            room: task.room,
            startedAt: now,
            targetEndDate: now.addingTimeInterval(Double(secs)),
            durationSeconds: secs
        )
        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
            activeSprint = sprintSession
        }
        Task {
            await ReminderCoordinator.shared.startSprintLiveActivity(for: task, durationMinutes: minutes, now: now)
        }
    }

    public func cancelActiveSprint() {
        withAnimation(.easeInOut(duration: 0.2)) {
            activeSprint = nil
        }
        Task {
            await ReminderCoordinator.shared.endAllSprintLiveActivities()
        }
    }

    public func refreshWidgetsAndReminders(in context: ModelContext) {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        Task {
            await ReminderCoordinator.shared.reconcileAll(in: context)
        }
    }

    /// Supports launch flags so UI states can be previewed deterministically in Simulator.
    public func applyLaunchArgumentsIfPresent(_ args: [String], in context: ModelContext) {
        let prefs = ADHOUSEDPreferences.shared
        if args.contains("--demo-household") {
            let existing = (try? context.fetch(FetchDescriptor<ChoreTask>())) ?? []
            if existing.isEmpty {
                let templates = StarterCatalog.allTemplates.filter(\.recommendedByDefault)
                let specs: [(name: String, emoji: String, hex: String)] = [
                    ("Oscar", "🦊", "#3E9B6C"),
                    ("Partner", "🦦", "#3B66FF")
                ]
                let mapped: [(StarterChoreTemplate, InitialFreshnessSeed, AssignmentMode)] = templates.enumerated().map { idx, tpl in
                    let mode: AssignmentMode = idx % 3 == 0 ? .alternating : (idx % 3 == 1 ? .anyone : .assigned)
                    let seed: InitialFreshnessSeed = idx < 3 ? .dueNow : (idx < 5 ? .dueSoon : .autoStagger)
                    return (tpl, seed, mode)
                }
                if let household = try? TaskActionService.bootstrapHousehold(
                    householdName: "Big Boss's Flat",
                    memberSpecs: specs,
                    selectedTemplates: mapped,
                    in: context
                ) {
                    let members = (try? context.fetch(FetchDescriptor<HouseholdMember>())) ?? []
                    let tasks = (try? context.fetch(FetchDescriptor<ChoreTask>())) ?? []
                    for dayOffset in [0, -1, -2, -4, -5] {
                        if let sampleTask = tasks.first {
                            context.insert(
                                CompletionRecord(
                                    taskID: sampleTask.id,
                                    householdID: household.id,
                                    completedAt: Date().addingTimeInterval(Double(dayOffset) * 86_400),
                                    completedByMemberID: members.first?.id
                                )
                            )
                        }
                    }
                    try? context.save()
                }
            } else {
                prefs.hasCompletedOnboarding = true
            }
        }

        let themeArgMap: [String: ThemePreset] = [
            "--theme-quiet": .quietSanctuary,
            "--theme-japandi": .japandiMoss,
            "--theme-nordic": .nordicDaylight,
            "--theme-matcha": .matchaOat,
            "--theme-lofi": .lofiDusk,
            "--theme-oceanic": .oceanicFocus,
            "--theme-brutalist": .chunkyNeoBrutalistPop,
            "--theme-bento": .warmTactileBento,
            "--theme-quattro": .omarchyQuattro,
            "--theme-catppuccin": .omarchyCatppuccin,
            "--theme-kanagawa": .omarchyKanagawa,
            "--theme-rosepine": .omarchyRosePine,
            "--theme-nord": .omarchyNord,
            "--theme-matteblack": .omarchyMatteBlack,
            "--theme-everforest": .omarchyEverforest,
            "--theme-gruvbox": .omarchyGruvbox,
            "--theme-cyberpunk": .omarchyCyberpunk,
            "--theme-minimal": .quattroMinimal,
            "--theme-ash": .quattroAsh,
            "--theme-amber": .omarchyAmber,
            "--theme-solar": .omarchySolarFlare
        ]
        for (flag, preset) in themeArgMap where args.contains(flag) {
            prefs.selectThemePreset(preset)
        }

        if args.contains("--quiet-on") {
            prefs.quietModeEnabled = true
        } else if args.contains("--quiet-off") {
            prefs.quietModeEnabled = false
        }

        if args.contains("--dark-mode") {
            prefs.colorSchemePreference = .dark
        } else if args.contains("--light-mode") {
            prefs.colorSchemePreference = .light
        } else if args.contains("--signature-mode") {
            prefs.colorSchemePreference = .signature
        }

        if args.contains("--mode-stream") {
            prefs.layoutMode = .freshnessBatteryStream
        } else if args.contains("--mode-spotlight") {
            prefs.layoutMode = .spotlightAndRooms
        }

        if args.contains("--open-settings") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.presentingSettingsSheet = true
            }
        }
        if args.contains("--open-catalog") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.presentingStarterCatalogSheet = true
            }
        }
        if args.contains("--open-sharing") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.presentingPartnerSharingSheet = true
            }
        }
        if args.contains("--open-vacation") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.presentingVacationBreakSheet = true
            }
        }
    }
}
