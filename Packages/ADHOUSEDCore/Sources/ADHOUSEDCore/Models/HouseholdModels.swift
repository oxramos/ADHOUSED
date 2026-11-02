import Foundation
import SwiftData
import Observation

// MARK: - Core Enumerations

public enum RoomCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case kitchen
    case bathroom
    case bedroom
    case living
    case laundry
    case petsAndPlants
    case entryAndTrash
    case general

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .kitchen: return "Kitchen"
        case .bathroom: return "Bathroom"
        case .bedroom: return "Bedroom"
        case .living: return "Living Space"
        case .laundry: return "Laundry & Linens"
        case .petsAndPlants: return "Pets & Plants"
        case .entryAndTrash: return "Entry & Trash"
        case .general: return "Whole Home"
        }
    }

    public var shortTitle: String {
        switch self {
        case .kitchen: return "Kitchen"
        case .bathroom: return "Bath"
        case .bedroom: return "Bedroom"
        case .living: return "Living"
        case .laundry: return "Laundry"
        case .petsAndPlants: return "Pets/Plants"
        case .entryAndTrash: return "Trash/Entry"
        case .general: return "Home"
        }
    }

    public var symbolName: String {
        switch self {
        case .kitchen: return "fork.knife"
        case .bathroom: return "shower.fill"
        case .bedroom: return "bed.double.fill"
        case .living: return "sofa.fill"
        case .laundry: return "washer.fill"
        case .petsAndPlants: return "pawprint.fill"
        case .entryAndTrash: return "trash.fill"
        case .general: return "house.fill"
        }
    }

    public var categoryColorIndex: Int {
        switch self {
        case .kitchen: return 0
        case .bathroom: return 1
        case .bedroom: return 2
        case .living: return 3
        case .laundry: return 4
        case .petsAndPlants: return 5
        case .entryAndTrash: return 6
        case .general: return 7
        }
    }
}

public enum IntervalUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case days
    case weeks
    case months

    public var id: String { rawValue }

    public var singularLabel: String {
        switch self {
        case .days: return "day"
        case .weeks: return "week"
        case .months: return "month"
        }
    }

    public var pluralLabel: String {
        switch self {
        case .days: return "days"
        case .weeks: return "weeks"
        case .months: return "months"
        }
    }

    public func approximateDays(count: Int) -> Double {
        let safeCount = max(1, count)
        switch self {
        case .days: return Double(safeCount)
        case .weeks: return Double(safeCount * 7)
        case .months: return Double(safeCount * 30)
        }
    }
}

public enum ScheduleMode: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Default ADHD-friendly mode: next due date is measured relative to when you actually last completed it.
    case rollingFromLastDone
    /// Date-locked mode: tied to specific weekdays (1=Sun...7=Sat) or a day of the month (1...28).
    case fixedCalendar

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .rollingFromLastDone: return "Rolling Since Last Done"
        case .fixedCalendar: return "Fixed Calendar Days"
        }
    }

    public var subtitle: String {
        switch self {
        case .rollingFromLastDone: return "Resets cleanly whenever done — zero overdue pileup"
        case .fixedCalendar: return "For date-locked chores like Trash Night or Rent"
        }
    }
}

public enum FixedCalendarRuleKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case weeklyDays
    case monthlyDay

    public var id: String { rawValue }
}

public enum EnergyLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case lowSpoons
    case steady
    case deepClean

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .lowSpoons: return "Low Effort"
        case .steady: return "Steady"
        case .deepClean: return "Deep Clean"
        }
    }

    public var badgeText: String {
        switch self {
        case .lowSpoons: return "Low Spoons"
        case .steady: return "Medium"
        case .deepClean: return "High Focus"
        }
    }

    public var symbolName: String {
        switch self {
        case .lowSpoons: return "battery.100.bolt"
        case .steady: return "bolt.fill"
        case .deepClean: return "sparkles"
        }
    }
}

public enum ReminderIntensityTier: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Tier 1: Repeating Time-Sensitive notification cascade within Awake Hours.
    case gentlePings
    /// Tier 2: Time-Sensitive cascade + Pinned Lock Screen & Dynamic Island Live Activity.
    case stickyLiveActivity
    /// Tier 3: Tier 2 + Native AlarmKit full-screen system alarm at designated cutoff time.
    case cutoffSystemAlarm

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .gentlePings: return "Persistent Pings"
        case .stickyLiveActivity: return "Sticky Lock Screen"
        case .cutoffSystemAlarm: return "Un-ignorable Alarm"
        }
    }

    public var shortBadge: String {
        switch self {
        case .gentlePings: return "Nag Loop"
        case .stickyLiveActivity: return "Lock Pinned"
        case .cutoffSystemAlarm: return "Cutoff Alarm"
        }
    }

    public var explanation: String {
        switch self {
        case .gentlePings:
            return "Re-alerts at your chosen interval during awake hours. Swiping one away won't silence the rest."
        case .stickyLiveActivity:
            return "Repeating Time-Sensitive pings + a persistent Live Activity banner pinned to your Lock Screen."
        case .cutoffSystemAlarm:
            return "Pins to Lock Screen all day and escalates to a ringing system AlarmKit alert if undone by cutoff time."
        }
    }

    public var symbolName: String {
        switch self {
        case .gentlePings: return "bell.badge.fill"
        case .stickyLiveActivity: return "platter.filled.top.iphone"
        case .cutoffSystemAlarm: return "alarm.waves.left.and.right.fill"
        }
    }
}

public enum AssignmentMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case anyone
    case assigned
    case alternating

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .anyone: return "Up for Grabs"
        case .assigned: return "Assigned Owner"
        case .alternating: return "Alternating Turns"
        }
    }

    public var subtitle: String {
        switch self {
        case .anyone: return "Anyone can grab it; completing stops alerts for everyone"
        case .assigned: return "Dedicated owner; only reminds that household member"
        case .alternating: return "Ping-pongs automatically to the next person each time it's done"
        }
    }

    public var symbolName: String {
        switch self {
        case .anyone: return "hands.sparkles.fill"
        case .assigned: return "person.crop.circle.badge.checkmark"
        case .alternating: return "arrow.triangle.2.circlepath"
        }
    }
}

public enum FreshnessStage: String, Codable, CaseIterable, Sendable, Comparable {
    case needsAttentionNow
    case dueToday
    case warming
    case fresh

    private var sortRank: Int {
        switch self {
        case .needsAttentionNow: return 0
        case .dueToday: return 1
        case .warming: return 2
        case .fresh: return 3
        }
    }

    public static func < (lhs: FreshnessStage, rhs: FreshnessStage) -> Bool {
        lhs.sortRank < rhs.sortRank
    }

    public var label: String {
        switch self {
        case .needsAttentionNow: return "Needs Love"
        case .dueToday: return "Due Today"
        case .warming: return "Due Soon"
        case .fresh: return "Fresh"
        }
    }
}

public enum LayoutUsabilityMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case spotlightAndRooms
    case freshnessBatteryStream

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .spotlightAndRooms: return "Today Spotlight + Rooms"
        case .freshnessBatteryStream: return "Freshness Battery Stream"
        }
    }

    public var shortLabel: String {
        switch self {
        case .spotlightAndRooms: return "Spotlight"
        case .freshnessBatteryStream: return "Battery Stream"
        }
    }

    public var symbolName: String {
        switch self {
        case .spotlightAndRooms: return "rectangle.grid.2x2.fill"
        case .freshnessBatteryStream: return "battery.75percent"
        }
    }
}

public enum ThemeFamily: String, CaseIterable, Identifiable, Sendable {
    case adhousedOriginals
    case omarchyCore
    case omarchySpectrum

    public var id: String { rawValue }

    public var sectionHeader: String {
        switch self {
        case .adhousedOriginals: return "ADHOUSED ORIGINALS"
        case .omarchyCore: return "OMARCHY QUATTRO OS · CORE & CHROMATIC"
        case .omarchySpectrum: return "OMARCHY QUATTRO OS · MINIMAL & WARM SPECTRUM"
        }
    }

    public var presets: [ThemePreset] {
        ThemePreset.allCases.filter { $0.family == self }
    }
}

public enum ThemePreset: String, Codable, CaseIterable, Identifiable, Sendable {
    case warmTactileBento
    case chunkyNeoBrutalistPop
    case omarchyQuattro
    case omarchyEverforest
    case omarchyCyberpunk
    case quattroMinimal
    case quattroAsh
    case omarchyAmber
    case omarchySolarFlare

    public var id: String { rawValue }

    public var family: ThemeFamily {
        switch self {
        case .warmTactileBento, .chunkyNeoBrutalistPop:
            return .adhousedOriginals
        case .omarchyQuattro, .omarchyEverforest, .omarchyCyberpunk:
            return .omarchyCore
        case .quattroMinimal, .quattroAsh, .omarchyAmber, .omarchySolarFlare:
            return .omarchySpectrum
        }
    }

    public var title: String {
        switch self {
        case .warmTactileBento: return "Warm Tactile Bento"
        case .chunkyNeoBrutalistPop: return "Chunky Neo-Brutalist Pop"
        case .omarchyQuattro: return "Omarchy Quattro"
        case .omarchyEverforest: return "Omarchy Everforest"
        case .omarchyCyberpunk: return "Omarchy Cyberpunk"
        case .quattroMinimal: return "Quattro Minimal & Mist"
        case .quattroAsh: return "Quattro Ash & Desert Sun"
        case .omarchyAmber: return "Amber Wave & Sunflower"
        case .omarchySolarFlare: return "Solar Flare"
        }
    }

    public var shortLabel: String {
        switch self {
        case .warmTactileBento: return "Bento"
        case .chunkyNeoBrutalistPop: return "Pop"
        case .omarchyQuattro: return "Quattro"
        case .omarchyEverforest: return "Everforest"
        case .omarchyCyberpunk: return "Cyberpunk"
        case .quattroMinimal: return "Minimal"
        case .quattroAsh: return "Ash"
        case .omarchyAmber: return "Amber"
        case .omarchySolarFlare: return "Solar"
        }
    }

    public var subtitle: String {
        switch self {
        case .warmTactileBento:
            return "Calm rounded tactile cards, organic sage-to-coral freshness gradients & soft depth"
        case .chunkyNeoBrutalistPop:
            return "High-contrast crisp borders, physical switch shadows & dopamine color blocks"
        case .omarchyQuattro:
            return "Tokyo-Night #1A1B26 HUD, SF Mono type, 8pt geometry & 45° blue-purple focus rings (Quattro Light in Day)"
        case .omarchyEverforest:
            return "Woodland moss & calming botanical sage mist with monospaced HUD framing"
        case .omarchyCyberpunk:
            return "Synthwave #13141C cyber-void with electric cyan & neon magenta 45° focus borders"
        case .quattroMinimal:
            return "Zero-saturation Slate monochrome & pale Mist with high-contrast text & solid focus rings"
        case .quattroAsh:
            return "Low-saturation warm mineral stone in Dark & sunlit Desert Sun sand in Light"
        case .omarchyAmber:
            return "Burnished Amber Wave gold on #13141C obsidian & Sunflower yellow tonal focus borders"
        case .omarchySolarFlare:
            return "Radiant tangerine & burnt-umber Solar Flare spectrum for high-energy activation"
        }
    }

    public var isOmarchyQuattroStyle: Bool {
        family != .adhousedOriginals
    }

    /// Signature showcase appearance from the reference style sheets (`nil` = follows system Light/Dark).
    public var signatureIsDark: Bool? {
        switch self {
        case .warmTactileBento, .chunkyNeoBrutalistPop:
            return nil
        case .omarchyQuattro, .omarchyEverforest, .omarchyCyberpunk, .quattroMinimal, .quattroAsh, .omarchyAmber:
            return true
        case .omarchySolarFlare:
            return false
        }
    }
}

public enum ColorSchemePreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case signature
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .signature: return "Signature"
        case .system: return "Auto"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

public enum InitialFreshnessSeed: String, Codable, CaseIterable, Identifiable, Sendable {
    case autoStagger
    case fresh
    case dueSoon
    case dueNow

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .autoStagger: return "Auto-Stagger"
        case .fresh: return "Fresh"
        case .dueSoon: return "Soon"
        case .dueNow: return "Due Now"
        }
    }
}

// MARK: - SwiftData Models

@Model
public final class Household {
    @Attribute(.unique) public var id: UUID
    public var name: String
    /// Awake start in minutes from midnight (default 8:30 AM = 510)
    public var awakeStartMinutes: Int
    /// Awake end in minutes from midnight (default 9:30 PM = 1290)
    public var awakeEndMinutes: Int
    /// Global "Out of the House / Busy" timed pause expiration
    public var awayPauseUntil: Date?
    public var cloudShareRecordData: Data?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String = "Our Home",
        awakeStartMinutes: Int = 8 * 60 + 30,
        awakeEndMinutes: Int = 21 * 60 + 30,
        awayPauseUntil: Date? = nil,
        cloudShareRecordData: Data? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.awakeStartMinutes = awakeStartMinutes
        self.awakeEndMinutes = awakeEndMinutes
        self.awayPauseUntil = awayPauseUntil
        self.cloudShareRecordData = cloudShareRecordData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public func isCurrentlyPausedAway(at now: Date = .now) -> Bool {
        if let activeBreak = ADHOUSEDPreferences.shared.activeVacationBreak(at: now) {
            return activeBreak.endDate > now
        }
        guard let awayPauseUntil else { return false }
        return awayPauseUntil > now
    }

    public func effectivePauseEnd(at now: Date = .now) -> Date? {
        let breakEnd = ADHOUSEDPreferences.shared.activeVacationBreak(at: now)?.endDate
        let legacyEnd = (awayPauseUntil != nil && awayPauseUntil! > now) ? awayPauseUntil : nil
        return [breakEnd, legacyEnd].compactMap { $0 }.max()
    }
}

@Model
public final class HouseholdMember {
    @Attribute(.unique) public var id: UUID
    public var householdID: UUID
    public var displayName: String
    public var emoji: String
    public var accentHex: String
    public var sortOrder: Int
    public var cloudParticipantID: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        householdID: UUID,
        displayName: String,
        emoji: String = "🦊",
        accentHex: String = "#4E9F6E",
        sortOrder: Int = 0,
        cloudParticipantID: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.householdID = householdID
        self.displayName = displayName
        self.emoji = emoji
        self.accentHex = accentHex
        self.sortOrder = sortOrder
        self.cloudParticipantID = cloudParticipantID
        self.createdAt = createdAt
    }
}

@Model
public final class ChoreTask {
    @Attribute(.unique) public var id: UUID
    public var householdID: UUID
    public var title: String
    public var iconSymbol: String
    public var roomRaw: String
    public var isArchived: Bool

    // Recurrence storage
    public var scheduleModeRaw: String
    public var intervalUnitRaw: String
    public var intervalCount: Int
    public var fixedRuleKindRaw: String
    /// Weekdays 1 (Sun) ... 7 (Sat), encoded as comma-separated ints for rock-solid SwiftData compatibility
    public var fixedWeekdaysCSV: String
    public var fixedDayOfMonth: Int

    // Completion & freshness state
    public var createdAt: Date
    public var updatedAt: Date
    public var lastCompletedAt: Date?
    public var lastCompletedByMemberID: UUID?
    /// Used when user explicitly defers a due task to tomorrow morning
    public var deferredUntilDate: Date?
    public var deferralCount: Int
    public var totalCompletionsCount: Int

    // ADHD Scaffolds
    public var energyLevelRaw: String
    public var estimatedMinutes: Int
    public var sprintDurationMinutes: Int

    // Persistent Reminder Config
    public var remindersEnabled: Bool
    public var nagIntervalMinutes: Int
    public var intensityTierRaw: String
    /// Cutoff alarm time in minutes from midnight (default 20:00 = 1200)
    public var alarmCutoffMinutes: Int
    public var pausedUntil: Date?

    // Shared Household Assignment
    public var assignmentModeRaw: String
    /// Ordered UUID strings participating in assignment or alternating turn rotation
    public var assignedMemberIDsCSV: String
    public var currentTurnIndex: Int

    // 1-Tap Widget Undo Grace Window
    public var pendingUndoCompletionID: UUID?
    public var pendingUndoExpiresAt: Date?

    // CloudKit sync metadata
    public var ckSystemFields: Data?

    public init(
        id: UUID = UUID(),
        householdID: UUID,
        title: String,
        iconSymbol: String = "sparkles",
        room: RoomCategory = .general,
        scheduleMode: ScheduleMode = .rollingFromLastDone,
        intervalUnit: IntervalUnit = .days,
        intervalCount: Int = 7,
        fixedRuleKind: FixedCalendarRuleKind = .weeklyDays,
        fixedWeekdays: [Int] = [3],
        fixedDayOfMonth: Int = 1,
        lastCompletedAt: Date? = nil,
        lastCompletedByMemberID: UUID? = nil,
        energyLevel: EnergyLevel = .lowSpoons,
        estimatedMinutes: Int = 5,
        sprintDurationMinutes: Int? = nil,
        remindersEnabled: Bool = true,
        nagIntervalMinutes: Int = 60,
        intensityTier: ReminderIntensityTier = .gentlePings,
        alarmCutoffMinutes: Int = 20 * 60,
        assignmentMode: AssignmentMode = .anyone,
        assignedMemberIDs: [UUID] = [],
        currentTurnIndex: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.householdID = householdID
        self.title = title
        self.iconSymbol = iconSymbol
        self.roomRaw = room.rawValue
        self.isArchived = false
        self.scheduleModeRaw = scheduleMode.rawValue
        self.intervalUnitRaw = intervalUnit.rawValue
        self.intervalCount = max(1, intervalCount)
        self.fixedRuleKindRaw = fixedRuleKind.rawValue
        self.fixedWeekdaysCSV = fixedWeekdays.map(String.init).joined(separator: ",")
        self.fixedDayOfMonth = min(28, max(1, fixedDayOfMonth))
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.lastCompletedAt = lastCompletedAt
        self.lastCompletedByMemberID = lastCompletedByMemberID
        self.deferredUntilDate = nil
        self.deferralCount = 0
        self.totalCompletionsCount = 0
        self.energyLevelRaw = energyLevel.rawValue
        self.estimatedMinutes = max(1, estimatedMinutes)
        self.sprintDurationMinutes = sprintDurationMinutes ?? min(15, max(2, estimatedMinutes))
        self.remindersEnabled = remindersEnabled
        self.nagIntervalMinutes = max(10, nagIntervalMinutes)
        self.intensityTierRaw = intensityTier.rawValue
        self.alarmCutoffMinutes = alarmCutoffMinutes
        self.pausedUntil = nil
        self.assignmentModeRaw = assignmentMode.rawValue
        self.assignedMemberIDsCSV = assignedMemberIDs.map(\.uuidString).joined(separator: ",")
        self.currentTurnIndex = max(0, currentTurnIndex)
        self.pendingUndoCompletionID = nil
        self.pendingUndoExpiresAt = nil
        self.ckSystemFields = nil
    }

    // MARK: Typed Accessors

    public var room: RoomCategory {
        get { RoomCategory(rawValue: roomRaw) ?? .general }
        set { roomRaw = newValue.rawValue }
    }

    public var scheduleMode: ScheduleMode {
        get { ScheduleMode(rawValue: scheduleModeRaw) ?? .rollingFromLastDone }
        set { scheduleModeRaw = newValue.rawValue }
    }

    public var intervalUnit: IntervalUnit {
        get { IntervalUnit(rawValue: intervalUnitRaw) ?? .days }
        set { intervalUnitRaw = newValue.rawValue }
    }

    public var fixedRuleKind: FixedCalendarRuleKind {
        get { FixedCalendarRuleKind(rawValue: fixedRuleKindRaw) ?? .weeklyDays }
        set { fixedRuleKindRaw = newValue.rawValue }
    }

    public var fixedWeekdays: [Int] {
        get {
            fixedWeekdaysCSV
                .split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                .filter { (1...7).contains($0) }
                .sorted()
        }
        set {
            let valid = Array(Set(newValue.filter { (1...7).contains($0) })).sorted()
            fixedWeekdaysCSV = valid.map(String.init).joined(separator: ",")
        }
    }

    public var energyLevel: EnergyLevel {
        get { EnergyLevel(rawValue: energyLevelRaw) ?? .lowSpoons }
        set { energyLevelRaw = newValue.rawValue }
    }

    public var intensityTier: ReminderIntensityTier {
        get { ReminderIntensityTier(rawValue: intensityTierRaw) ?? .gentlePings }
        set { intensityTierRaw = newValue.rawValue }
    }

    public var assignmentMode: AssignmentMode {
        get { AssignmentMode(rawValue: assignmentModeRaw) ?? .anyone }
        set { assignmentModeRaw = newValue.rawValue }
    }

    public var assignedMemberIDs: [UUID] {
        get {
            assignedMemberIDsCSV
                .split(separator: ",")
                .compactMap { UUID(uuidString: String($0).trimmingCharacters(in: .whitespaces)) }
        }
        set {
            assignedMemberIDsCSV = newValue.map(\.uuidString).joined(separator: ",")
        }
    }

    /// Returns the household member currently responsible (nil if `.anyone` or unconfigured).
    public var responsibleMemberID: UUID? {
        let ids = assignedMemberIDs
        switch assignmentMode {
        case .anyone:
            return nil
        case .assigned:
            return ids.first
        case .alternating:
            guard !ids.isEmpty else { return nil }
            let idx = ((currentTurnIndex % ids.count) + ids.count) % ids.count
            return ids[idx]
        }
    }

    public func isActionable(forMemberID memberID: UUID?) -> Bool {
        guard let memberID else { return true }
        switch assignmentMode {
        case .anyone:
            return true
        case .assigned, .alternating:
            guard let responsible = responsibleMemberID else { return true }
            return responsible == memberID
        }
    }

    public func hasActiveUndoGraceWindow(at now: Date = .now) -> Bool {
        guard let expires = pendingUndoExpiresAt, pendingUndoCompletionID != nil else {
            return false
        }
        return expires > now
    }

    public func isTaskPaused(at now: Date = .now) -> Bool {
        guard let pausedUntil else { return false }
        return pausedUntil > now
    }

    public var isQuickLowSpoonWin: Bool {
        energyLevel == .lowSpoons || estimatedMinutes <= 5
    }
}

@Model
public final class CompletionRecord {
    @Attribute(.unique) public var id: UUID
    public var taskID: UUID
    public var householdID: UUID
    public var completedAt: Date
    public var completedByMemberID: UUID?
    /// Snapshot fields to support lossless 1-tap Undo rollback
    public var previousLastCompletedAt: Date?
    public var previousLastCompletedByMemberID: UUID?
    public var previousTurnIndex: Int
    public var previousDeferredUntilDate: Date?
    public var sprintSecondsElapsed: Int?

    public init(
        id: UUID = UUID(),
        taskID: UUID,
        householdID: UUID,
        completedAt: Date = .now,
        completedByMemberID: UUID? = nil,
        previousLastCompletedAt: Date? = nil,
        previousLastCompletedByMemberID: UUID? = nil,
        previousTurnIndex: Int = 0,
        previousDeferredUntilDate: Date? = nil,
        sprintSecondsElapsed: Int? = nil
    ) {
        self.id = id
        self.taskID = taskID
        self.householdID = householdID
        self.completedAt = completedAt
        self.completedByMemberID = completedByMemberID
        self.previousLastCompletedAt = previousLastCompletedAt
        self.previousLastCompletedByMemberID = previousLastCompletedByMemberID
        self.previousTurnIndex = previousTurnIndex
        self.previousDeferredUntilDate = previousDeferredUntilDate
        self.sprintSecondsElapsed = sprintSecondsElapsed
    }
}

@Model
public final class DeferralEvent {
    @Attribute(.unique) public var id: UUID
    public var taskID: UUID
    public var householdID: UUID
    public var deferredAt: Date
    public var deferredByMemberID: UUID?
    public var reasonTag: String

    public init(
        id: UUID = UUID(),
        taskID: UUID,
        householdID: UUID,
        deferredAt: Date = .now,
        deferredByMemberID: UUID? = nil,
        reasonTag: String = "Need tomorrow"
    ) {
        self.id = id
        self.taskID = taskID
        self.householdID = householdID
        self.deferredAt = deferredAt
        self.deferredByMemberID = deferredByMemberID
        self.reasonTag = reasonTag
    }
}

// MARK: - Shared App Group Container & Preferences

public enum SharedAppGroup {
    public static var identifier: String {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "ADHOUSEDAppGroupIdentifier") as? String,
           configured.hasPrefix("group.") {
            return configured
        }
        return "group.com.oxramos.adhoused"
    }

    public static let iCloudContainerID = "iCloud.com.oxramos.adhoused"

    public static var sharedUserDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    public static var databaseURL: URL {
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
            let dir = containerURL.appendingPathComponent("ADHOUSEDStore", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir.appendingPathComponent("ADHOUSED.store")
        }
        let fallback = URL.applicationSupportDirectory.appendingPathComponent("ADHOUSEDStore", isDirectory: true)
        try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
        return fallback.appendingPathComponent("ADHOUSED.store")
    }

    public static func makeModelContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            Household.self,
            HouseholdMember.self,
            ChoreTask.self,
            CompletionRecord.self,
            DeferralEvent.self
        ])
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                url: databaseURL,
                allowsSave: true,
                cloudKitDatabase: .none
            )
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

// MARK: - Vacation / Break Mode Models (Date & Time Range)

public enum VacationBreakPreset: String, CaseIterable, Identifiable, Sendable {
    case countrysideWeekend
    case longWeekend
    case weekVacation
    case restOfToday
    case quickThreeHours
    case custom

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .countrysideWeekend: return "Countryside Weekend"
        case .longWeekend: return "Long Weekend (3d)"
        case .weekVacation: return "1-Week Vacation"
        case .restOfToday: return "Rest of Today"
        case .quickThreeHours: return "Quick Break (3h)"
        case .custom: return "Custom Dates"
        }
    }

    public var shortChipLabel: String {
        switch self {
        case .countrysideWeekend: return "🏡 Weekend Away"
        case .longWeekend: return "⛺ 3-Day Trip"
        case .weekVacation: return "🌴 7-Day Vacation"
        case .restOfToday: return "🌙 Rest of Today"
        case .quickThreeHours: return "☕ 3 Hours"
        case .custom: return "🗓️ Custom Range"
        }
    }

    public var defaultTitle: String {
        switch self {
        case .countrysideWeekend: return "Countryside Weekend"
        case .longWeekend: return "Long Weekend Trip"
        case .weekVacation: return "Vacation Mode"
        case .restOfToday: return "Evening Break"
        case .quickThreeHours: return "Out of the House"
        case .custom: return "Away Break"
        }
    }

    public var iconSymbol: String {
        switch self {
        case .countrysideWeekend: return "tree.fill"
        case .longWeekend: return "tent.fill"
        case .weekVacation: return "suitcase.rolling.fill"
        case .restOfToday: return "moon.stars.fill"
        case .quickThreeHours: return "cup.and.saucer.fill"
        case .custom: return "calendar.badge.clock"
        }
    }

    /// Computes a smart `(startDate, endDate)` range for the preset relative to `now`.
    public func suggestedRange(
        from now: Date = .now,
        awakeStartMinutes: Int = 8 * 60 + 30,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date) {
        let startOfToday = calendar.startOfDay(for: now)
        switch self {
        case .countrysideWeekend:
            // Weekday: 1 = Sun, 2 = Mon, ..., 6 = Fri, 7 = Sat
            let weekday = calendar.component(.weekday, from: now)
            if weekday == 6 {
                // Friday: start at 5:00 PM today (or now if already past 5 PM), end Sunday 8:00 PM
                let fri5PM = startOfToday.addingTimeInterval(17 * 3600)
                let start = now >= fri5PM ? now : fri5PM
                let sunStart = calendar.date(byAdding: .day, value: 2, to: startOfToday) ?? startOfToday.addingTimeInterval(2 * 86_400)
                let end = sunStart.addingTimeInterval(20 * 3600)
                return (start, end)
            } else if weekday == 7 {
                // Saturday: start now, end Sunday 8:00 PM
                let sunStart = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday.addingTimeInterval(86_400)
                let end = sunStart.addingTimeInterval(20 * 3600)
                return (now, end)
            } else if weekday == 1 {
                // Sunday: start now, end Monday 9:00 AM (or tonight 8:00 PM if still before 6 PM)
                let sun8PM = startOfToday.addingTimeInterval(20 * 3600)
                if now < startOfToday.addingTimeInterval(18 * 3600) {
                    return (now, sun8PM)
                } else {
                    let monStart = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday.addingTimeInterval(86_400)
                    return (now, monStart.addingTimeInterval(9 * 3600))
                }
            } else {
                // Mon–Thu: default to upcoming Friday 5:00 PM -> Sunday 8:00 PM
                let daysUntilFri = (6 - weekday + 7) % 7
                let friStart = calendar.date(byAdding: .day, value: daysUntilFri, to: startOfToday) ?? startOfToday
                let start = friStart.addingTimeInterval(17 * 3600)
                let sunStart = calendar.date(byAdding: .day, value: daysUntilFri + 2, to: startOfToday) ?? friStart.addingTimeInterval(2 * 86_400)
                let end = sunStart.addingTimeInterval(20 * 3600)
                return (start, end)
            }

        case .longWeekend:
            let threeDaysOut = calendar.date(byAdding: .day, value: 3, to: startOfToday) ?? now.addingTimeInterval(3 * 86_400)
            return (now, threeDaysOut.addingTimeInterval(20 * 3600))

        case .weekVacation:
            let sevenDaysOut = calendar.date(byAdding: .day, value: 7, to: startOfToday) ?? now.addingTimeInterval(7 * 86_400)
            return (now, sevenDaysOut.addingTimeInterval(Double(awakeStartMinutes * 60)))

        case .restOfToday:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now.addingTimeInterval(86_400)
            return (now, tomorrow.addingTimeInterval(Double(awakeStartMinutes * 60)))

        case .quickThreeHours:
            return (now, now.addingTimeInterval(3 * 3600))

        case .custom:
            let twoDaysOut = calendar.date(byAdding: .day, value: 2, to: startOfToday) ?? now.addingTimeInterval(2 * 86_400)
            return (now, twoDaysOut.addingTimeInterval(20 * 3600))
        }
    }
}

public struct VacationBreakWindow: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var iconSymbol: String
    public var startDate: Date
    public var endDate: Date
    /// When true, chore freshness decay is frozen during `[startDate, endDate]` and rolling intervals shift forward so tasks don't pile up while away.
    public var freezeChoreDecay: Bool
    /// Tracks how many seconds of rolling interval grace shift have already been applied to tasks for this break window.
    public var appliedDecayShiftSeconds: Double
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String = "Countryside Weekend",
        iconSymbol: String = "tree.fill",
        startDate: Date,
        endDate: Date,
        freezeChoreDecay: Bool = true,
        appliedDecayShiftSeconds: Double = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Away Break" : title
        self.iconSymbol = iconSymbol
        self.startDate = startDate
        self.endDate = max(startDate.addingTimeInterval(300), endDate)
        self.freezeChoreDecay = freezeChoreDecay
        self.appliedDecayShiftSeconds = appliedDecayShiftSeconds
        self.createdAt = createdAt
    }

    public func isActive(at date: Date = .now) -> Bool {
        date >= startDate && date < endDate
    }

    public func isUpcoming(at date: Date = .now) -> Bool {
        startDate > date && endDate > startDate
    }

    public func contains(_ date: Date) -> Bool {
        date >= startDate && date < endDate
    }

    public var durationHours: Int {
        max(1, Int(round(endDate.timeIntervalSince(startDate) / 3600.0)))
    }

    public func formattedRangeSummary(now: Date = .now, calendar: Calendar = .current) -> String {
        let sameDay = calendar.isDate(startDate, inSameDayAs: endDate)
        let startStr = startDate.formatted(date: .abbreviated, time: .shortened)
        let endStr = sameDay
            ? endDate.formatted(date: .omitted, time: .shortened)
            : endDate.formatted(date: .abbreviated, time: .shortened)
        return "\(startStr) → \(endStr)"
    }
}

/// Shared preferences synchronized instantaneously between App, Widgets, and Live Activities.
@Observable
public final class ADHOUSEDPreferences: @unchecked Sendable {
    public static let shared = ADHOUSEDPreferences()

    private let defaults: UserDefaults

    private enum Keys {
        static let themePreset = "adhoused.themePreset"
        static let colorScheme = "adhoused.colorScheme"
        static let layoutMode = "adhoused.layoutMode"
        static let bionicReading = "adhoused.bionicReading"
        static let hapticsEnabled = "adhoused.hapticsEnabled"
        static let activeMemberID = "adhoused.activeMemberID"
        static let hasCompletedOnboarding = "adhoused.hasCompletedOnboarding"
        static let vacationBreaksJSON = "adhoused.vacationBreaksJSON"
    }

    public var themePreset: ThemePreset {
        didSet { defaults.set(themePreset.rawValue, forKey: Keys.themePreset) }
    }

    public var colorSchemePreference: ColorSchemePreference {
        didSet { defaults.set(colorSchemePreference.rawValue, forKey: Keys.colorScheme) }
    }

    public var layoutMode: LayoutUsabilityMode {
        didSet { defaults.set(layoutMode.rawValue, forKey: Keys.layoutMode) }
    }

    public var bionicReadingEnabled: Bool {
        didSet { defaults.set(bionicReadingEnabled, forKey: Keys.bionicReading) }
    }

    public var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    public var activeMemberID: UUID? {
        didSet { defaults.set(activeMemberID?.uuidString, forKey: Keys.activeMemberID) }
    }

    public var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    public var vacationBreaks: [VacationBreakWindow] {
        didSet {
            if let encoded = try? JSONEncoder().encode(vacationBreaks) {
                defaults.set(encoded, forKey: Keys.vacationBreaksJSON)
            }
        }
    }

    public init(defaults: UserDefaults = SharedAppGroup.sharedUserDefaults) {
        self.defaults = defaults
        self.themePreset = ThemePreset(rawValue: defaults.string(forKey: Keys.themePreset) ?? "") ?? .warmTactileBento
        self.colorSchemePreference = ColorSchemePreference(rawValue: defaults.string(forKey: Keys.colorScheme) ?? "") ?? .signature
        self.layoutMode = LayoutUsabilityMode(rawValue: defaults.string(forKey: Keys.layoutMode) ?? "") ?? .spotlightAndRooms
        self.bionicReadingEnabled = defaults.object(forKey: Keys.bionicReading) as? Bool ?? false
        self.hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        if let str = defaults.string(forKey: Keys.activeMemberID) {
            self.activeMemberID = UUID(uuidString: str)
        } else {
            self.activeMemberID = nil
        }
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        if let data = defaults.data(forKey: Keys.vacationBreaksJSON),
           let decoded = try? JSONDecoder().decode([VacationBreakWindow].self, from: data) {
            self.vacationBreaks = decoded
        } else {
            self.vacationBreaks = []
        }
    }

    public func activeVacationBreak(at date: Date = .now) -> VacationBreakWindow? {
        vacationBreaks
            .filter { $0.isActive(at: date) }
            .sorted { $0.endDate > $1.endDate }
            .first
    }

    public func nextUpcomingVacationBreak(at date: Date = .now) -> VacationBreakWindow? {
        vacationBreaks
            .filter { $0.isUpcoming(at: date) }
            .sorted { $0.startDate < $1.startDate }
            .first
    }

    public func activeOrUpcomingVacationBreaks(at date: Date = .now) -> [VacationBreakWindow] {
        vacationBreaks
            .filter { $0.endDate > date }
            .sorted { $0.startDate < $1.startDate }
    }

    public func selectThemePreset(_ preset: ThemePreset) {
        themePreset = preset
        if preset.signatureIsDark != nil && colorSchemePreference == .system {
            colorSchemePreference = .signature
        }
    }

    public func reloadFromSharedDefaults() {
        if let preset = ThemePreset(rawValue: defaults.string(forKey: Keys.themePreset) ?? "") {
            themePreset = preset
        }
        if let scheme = ColorSchemePreference(rawValue: defaults.string(forKey: Keys.colorScheme) ?? "") {
            colorSchemePreference = scheme
        }
        if let mode = LayoutUsabilityMode(rawValue: defaults.string(forKey: Keys.layoutMode) ?? "") {
            layoutMode = mode
        }
        bionicReadingEnabled = defaults.object(forKey: Keys.bionicReading) as? Bool ?? false
        hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        if let str = defaults.string(forKey: Keys.activeMemberID) {
            activeMemberID = UUID(uuidString: str)
        }
        hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        if let data = defaults.data(forKey: Keys.vacationBreaksJSON),
           let decoded = try? JSONDecoder().decode([VacationBreakWindow].self, from: data) {
            vacationBreaks = decoded
        }
    }
}
