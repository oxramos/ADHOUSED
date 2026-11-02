import Foundation
import AppIntents
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

// MARK: - Interactive 1-Tap Intents (Home Screen Widgets, Lock Screen Widgets, Live Activities & AlarmKit)

#if os(iOS)
public typealias ChoreActionIntentProtocol = LiveActivityIntent
#else
public typealias ChoreActionIntentProtocol = AppIntent
#endif

public struct CompleteTaskIntent: ChoreActionIntentProtocol {
    public static let title: LocalizedStringResource = "Complete Household Chore"
    public static let description = IntentDescription("Marks a due household chore done right from your Home Screen or Lock Screen.")
    public static let openAppWhenRun: Bool = false

    @Parameter(title: "Task ID")
    public var taskIDString: String

    @Parameter(title: "Enable 8s Inline Undo", default: true)
    public var fromWidgetUndoable: Bool

    public init() {
        self.taskIDString = ""
        self.fromWidgetUndoable = true
    }

    public init(taskIDString: String, fromWidgetUndoable: Bool = true) {
        self.taskIDString = taskIDString
        self.fromWidgetUndoable = fromWidgetUndoable
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: taskIDString) else {
            return .result()
        }
        let container = try SharedAppGroup.makeModelContainer()
        let context = container.mainContext
        ADHOUSEDPreferences.shared.reloadFromSharedDefaults()

        _ = try TaskActionService.completeTask(
            taskID: uuid,
            byMemberID: ADHOUSEDPreferences.shared.activeMemberID,
            enableWidgetUndoWindow: fromWidgetUndoable,
            in: context
        )
        #if os(iOS)
        await ReminderCoordinator.shared.endAllSprintLiveActivities()
        #endif
        await ReminderCoordinator.shared.reconcileAll(in: context)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        return .result()
    }
}

public struct UndoCompleteTaskIntent: ChoreActionIntentProtocol {
    public static let title: LocalizedStringResource = "Undo Chore Completion"
    public static let description = IntentDescription("Reverts an accidental 1-tap chore checkoff right on the widget.")
    public static let openAppWhenRun: Bool = false

    @Parameter(title: "Task ID")
    public var taskIDString: String

    public init() {
        self.taskIDString = ""
    }

    public init(taskIDString: String) {
        self.taskIDString = taskIDString
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: taskIDString) else {
            return .result()
        }
        let container = try SharedAppGroup.makeModelContainer()
        let context = container.mainContext
        ADHOUSEDPreferences.shared.reloadFromSharedDefaults()

        _ = try TaskActionService.undoLastCompletion(taskID: uuid, in: context)
        await ReminderCoordinator.shared.reconcileAll(in: context)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        return .result()
    }
}

public struct PauseTaskRemindersIntent: ChoreActionIntentProtocol {
    public static let title: LocalizedStringResource = "Pause Chore Reminders"
    public static let description = IntentDescription("Pauses persistent reminders temporarily (e.g., 1h or Away from Home 3h) and auto-resumes afterward.")
    public static let openAppWhenRun: Bool = false

    @Parameter(title: "Task ID (empty for whole household)")
    public var taskIDString: String

    @Parameter(title: "Pause Minutes", default: 60)
    public var pauseMinutes: Int

    public init() {
        self.taskIDString = ""
        self.pauseMinutes = 60
    }

    public init(taskIDString: String, pauseMinutes: Int = 60) {
        self.taskIDString = taskIDString
        self.pauseMinutes = pauseMinutes
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        let container = try SharedAppGroup.makeModelContainer()
        let context = container.mainContext
        let scope: PauseScope
        if let uuid = UUID(uuidString: taskIDString) {
            scope = .singleTask(uuid)
        } else {
            scope = .entireHousehold
        }
        try TaskActionService.pauseReminders(scope: scope, durationMinutes: pauseMinutes, in: context)
        await ReminderCoordinator.shared.reconcileAll(in: context)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        return .result()
    }
}

// MARK: - Widget Configuration Entities & Intents

public struct ChoreEntity: AppEntity, Identifiable, Sendable {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Household Chore")
    public static let defaultQuery = ChoreEntityQuery()

    public let id: String
    public let title: String
    public let roomTitle: String
    public let symbolName: String

    public init(id: String, title: String, roomTitle: String, symbolName: String) {
        self.id = id
        self.title = title
        self.roomTitle = roomTitle
        self.symbolName = symbolName
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(roomTitle)",
            image: .init(systemName: symbolName)
        )
    }
}

public struct ChoreEntityQuery: EntityQuery {
    public init() {}

    @MainActor
    public func entities(for identifiers: [ChoreEntity.ID]) async throws -> [ChoreEntity] {
        let container = try SharedAppGroup.makeModelContainer()
        let tasks = try container.mainContext.fetch(FetchDescriptor<ChoreTask>())
        let idSet = Set(identifiers)
        return tasks
            .filter { idSet.contains($0.id.uuidString) && !$0.isArchived }
            .map { ChoreEntity(id: $0.id.uuidString, title: $0.title, roomTitle: $0.room.title, symbolName: ChoreIconCatalog.fallbackSystemSymbol(for: $0.iconSymbol)) }
    }

    @MainActor
    public func suggestedEntities() async throws -> [ChoreEntity] {
        let container = try SharedAppGroup.makeModelContainer()
        let tasks = try container.mainContext.fetch(FetchDescriptor<ChoreTask>())
        return tasks
            .filter { !$0.isArchived }
            .sorted { $0.title < $1.title }
            .map { ChoreEntity(id: $0.id.uuidString, title: $0.title, roomTitle: $0.room.title, symbolName: ChoreIconCatalog.fallbackSystemSymbol(for: $0.iconSymbol)) }
    }
}

public enum WidgetDisplayModeOption: String, AppEnum, Sendable {
    case topDueQueue
    case lowSpoonsQuickWins
    case pinnedChore
    case roomFilter

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Widget Mode")
    public static let caseDisplayRepresentations: [WidgetDisplayModeOption: DisplayRepresentation] = [
        .topDueQueue: "Due Today Queue",
        .lowSpoonsQuickWins: "Quick & Easy (≤5 min)",
        .pinnedChore: "Single Pinned Chore",
        .roomFilter: "Filter by Room"
    ]
}

public enum WidgetRoomOption: String, AppEnum, Sendable {
    case kitchen
    case bathroom
    case bedroom
    case living
    case laundry
    case petsAndPlants
    case entryAndTrash

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Room")
    public static let caseDisplayRepresentations: [WidgetRoomOption: DisplayRepresentation] = [
        .kitchen: "Kitchen",
        .bathroom: "Bathroom",
        .bedroom: "Bedroom",
        .living: "Living Space",
        .laundry: "Laundry & Linens",
        .petsAndPlants: "Pets & Plants",
        .entryAndTrash: "Entry & Trash"
    ]

    public var roomCategory: RoomCategory {
        RoomCategory(rawValue: rawValue) ?? .kitchen
    }
}

public struct ADHOUSEDWidgetConfigIntent: WidgetConfigurationIntent {
    public static let title: LocalizedStringResource = "Configure ADHOUSED Widget"
    public static let description = IntentDescription("Choose whether this widget shows your Top Due Queue, a Pinned Single Chore, a Room, or Low-Energy Quick Wins.")

    @Parameter(title: "Display Mode", default: .topDueQueue)
    public var displayMode: WidgetDisplayModeOption

    @Parameter(title: "Room (when Room mode selected)", default: .kitchen)
    public var roomFilter: WidgetRoomOption

    @Parameter(title: "Pinned Chore (when Pinned mode selected)")
    public var pinnedChore: ChoreEntity?

    @Parameter(title: "Only My Turn & Up for Grabs", default: true)
    public var onlyMyActionableTasks: Bool

    public init() {
        self.displayMode = .topDueQueue
        self.roomFilter = .kitchen
        self.pinnedChore = nil
        self.onlyMyActionableTasks = true
    }
}
