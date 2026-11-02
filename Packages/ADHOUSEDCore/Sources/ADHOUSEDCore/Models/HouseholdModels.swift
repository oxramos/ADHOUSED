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
        case .living: return "Living Room"
        case .laundry: return "Laundry & Linens"
        case .petsAndPlants: return "Pets & Plants"
        case .entryAndTrash: return "Entry & Trash"
        case .general: return "Home & Life"
        }
    }

    public var shortTitle: String {
        switch self {
        case .kitchen: return "Kitchen"
        case .bathroom: return "Bath"
        case .bedroom: return "Bedroom"
        case .living: return "Living"
        case .laundry: return "Laundry"
        case .petsAndPlants: return "Pets & Plants"
        case .entryAndTrash: return "Trash & Entry"
        case .general: return "Home & Life"
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

    public var omarchyIconKey: String {
        switch self {
        case .kitchen: return "omarchy:dishes"
        case .bathroom: return "omarchy:droplet"
        case .bedroom: return "omarchy:bed"
        case .living: return "omarchy:sofa"
        case .laundry: return "omarchy:washer"
        case .petsAndPlants: return "omarchy:plant"
        case .entryAndTrash: return "omarchy:trash"
        case .general: return "omarchy:terminal_home"
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
    /// Default mode: next due date is measured relative to when you actually last completed it.
    case rollingFromLastDone
    /// Date-locked mode: tied to specific weekdays (1=Sun...7=Sat) or a day of the month (1...28).
    case fixedCalendar

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .rollingFromLastDone: return "After Last Done"
        case .fixedCalendar: return "Specific Days"
        }
    }

    public var subtitle: String {
        switch self {
        case .rollingFromLastDone: return "Counts forward from whenever you finish it — never piles up"
        case .fixedCalendar: return "Best for fixed days like Trash Pickup or Rent"
        }
    }
}

public enum FixedCalendarRuleKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case weeklyDays
    case monthlyDay

    public var id: String { rawValue }
}

/// Stored raw values preserved for seamless compatibility; all user-facing text uses plain, everyday English.
public enum EnergyLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case lowSpoons
    case steady
    case deepClean

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .lowSpoons: return "Quick & Easy"
        case .steady: return "Medium"
        case .deepClean: return "Big Task"
        }
    }

    public var badgeText: String {
        switch self {
        case .lowSpoons: return "Easy"
        case .steady: return "Medium"
        case .deepClean: return "Big Task"
        }
    }

    public var symbolName: String {
        switch self {
        case .lowSpoons: return "leaf.fill"
        case .steady: return "bolt.fill"
        case .deepClean: return "sparkles"
        }
    }
}

public enum ReminderIntensityTier: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Tier 1: Repeating notification cascade within Daytime Hours.
    case gentlePings
    /// Tier 2: Repeating notifications + Pinned Lock Screen & Dynamic Island Live Activity.
    case stickyLiveActivity
    /// Tier 3: Tier 2 + Native AlarmKit full-screen system alarm at designated evening cutoff time.
    case cutoffSystemAlarm

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .gentlePings: return "Repeating Reminders"
        case .stickyLiveActivity: return "Pin to Lock Screen + Repeat"
        case .cutoffSystemAlarm: return "Evening Must-Do Alarm"
        }
    }

    public var shortBadge: String {
        switch self {
        case .gentlePings: return "Repeats"
        case .stickyLiveActivity: return "Pinned"
        case .cutoffSystemAlarm: return "Evening Alarm"
        }
    }

    public var explanation: String {
        switch self {
        case .gentlePings:
            return "Sends a reminder at your chosen interval during daytime hours until marked done."
        case .stickyLiveActivity:
            return "Keeps a live banner on your Lock Screen plus repeating notifications until finished."
        case .cutoffSystemAlarm:
            return "Rings a full-screen alarm at your evening cutoff hour if still unfinished (great for trash night or pets)."
        }
    }

    public var symbolName: String {
        switch self {
        case .gentlePings: return "bell.fill"
        case .stickyLiveActivity: return "platter.filled.top.iphone"
        case .cutoffSystemAlarm: return "alarm.fill"
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
        case .anyone: return "Anyone"
        case .assigned: return "One Person"
        case .alternating: return "Take Turns"
        }
    }

    public var subtitle: String {
        switch self {
        case .anyone: return "Either partner can do it; checking it off clears it for both"
        case .assigned: return "Assigned to one specific person's list"
        case .alternating: return "Automatically switches to the other person next time"
        }
    }

    public var symbolName: String {
        switch self {
        case .anyone: return "person.2.fill"
        case .assigned: return "person.crop.circle.badge.checkmark"
        case .alternating: return "arrow.left.arrow.right"
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
        case .needsAttentionNow: return "Overdue"
        case .dueToday: return "Due Today"
        case .warming: return "Due Soon"
        case .fresh: return "Done"
        }
    }
}

public enum LayoutUsabilityMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case spotlightAndRooms
    case freshnessBatteryStream

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .spotlightAndRooms: return "Focus List"
        case .freshnessBatteryStream: return "Battery Bars"
        }
    }

    public var shortLabel: String {
        switch self {
        case .spotlightAndRooms: return "Focus List"
        case .freshnessBatteryStream: return "Battery View"
        }
    }

    public var symbolName: String {
        switch self {
        case .spotlightAndRooms: return "checklist"
        case .freshnessBatteryStream: return "battery.75percent"
        }
    }
}

// MARK: - Icon Style Packs & Per-Theme Color Customization

public enum IconStylePreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case autoTheme
    case omarchyPixelHUD
    case minimalOutline
    case softMedallion
    case boldBadge

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .autoTheme: return "Match Theme"
        case .omarchyPixelHUD: return "Omarchy Pixel"
        case .minimalOutline: return "Minimal Line"
        case .softMedallion: return "Soft Tinted"
        case .boldBadge: return "Solid Badge"
        }
    }

    public var subtitle: String {
        switch self {
        case .autoTheme:
            return "Automatically uses Omarchy pixel glyphs on Omarchy themes, minimal strokes on Quiet themes, and soft badges elsewhere."
        case .omarchyPixelHUD:
            return "Crisp custom pixel-matrix & Waybar bracket glyphs across all chores and rooms."
        case .minimalOutline:
            return "Clean, low-noise architectural outlines with subtle borders."
        case .softMedallion:
            return "Cozy rounded pastel-tinted medallions."
        case .boldBadge:
            return "High-contrast filled color tiles for quick visual scanning."
        }
    }
}

public enum ThemeCornerOverride: String, Codable, CaseIterable, Identifiable, Sendable {
    case themeDefault
    case sharpTerminal
    case crispModern
    case softRounded

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .themeDefault: return "Default"
        case .sharpTerminal: return "Sharp (6pt)"
        case .crispModern: return "Crisp (14pt)"
        case .softRounded: return "Plush (24pt)"
        }
    }
}

public enum ThemeFontOverride: String, Codable, CaseIterable, Identifiable, Sendable {
    case themeDefault
    case cleanSans
    case softRounded
    case monospaced

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .themeDefault: return "Default"
        case .cleanSans: return "Clean Sans"
        case .softRounded: return "Rounded"
        case .monospaced: return "Mono"
        }
    }
}

public struct ThemeColorOverrides: Codable, Equatable, Sendable {
    public var canvasBackgroundHex: String?
    public var cardSurfaceHex: String?
    public var primaryInkHex: String?
    public var accentPrimaryHex: String?
    public var accentSecondaryHex: String?
    public var freshColorHex: String?
    public var dueNowColorHex: String?
    public var cornerStyle: ThemeCornerOverride
    public var fontStyle: ThemeFontOverride

    public init(
        canvasBackgroundHex: String? = nil,
        cardSurfaceHex: String? = nil,
        primaryInkHex: String? = nil,
        accentPrimaryHex: String? = nil,
        accentSecondaryHex: String? = nil,
        freshColorHex: String? = nil,
        dueNowColorHex: String? = nil,
        cornerStyle: ThemeCornerOverride = .themeDefault,
        fontStyle: ThemeFontOverride = .themeDefault
    ) {
        self.canvasBackgroundHex = canvasBackgroundHex
        self.cardSurfaceHex = cardSurfaceHex
        self.primaryInkHex = primaryInkHex
        self.accentPrimaryHex = accentPrimaryHex
        self.accentSecondaryHex = accentSecondaryHex
        self.freshColorHex = freshColorHex
        self.dueNowColorHex = dueNowColorHex
        self.cornerStyle = cornerStyle
        self.fontStyle = fontStyle
    }

    public var hasAnyCustomization: Bool {
        canvasBackgroundHex != nil ||
        cardSurfaceHex != nil ||
        primaryInkHex != nil ||
        accentPrimaryHex != nil ||
        accentSecondaryHex != nil ||
        freshColorHex != nil ||
        dueNowColorHex != nil ||
        cornerStyle != .themeDefault ||
        fontStyle != .themeDefault
    }
}

// MARK: - Expanded Theme Families & Presets

public enum ThemeFamily: String, CaseIterable, Identifiable, Sendable {
    case quietAndCalm
    case modernFocus
    case omarchyDesktops
    case omarchyChromatic

    public var id: String { rawValue }

    public var sectionHeader: String {
        switch self {
        case .quietAndCalm: return "QUIET & MINIMAL · LOW STIMULATION"
        case .modernFocus: return "MODERN ADHD FOCUS · CALM & COZY"
        case .omarchyDesktops: return "OMARCHY · SIGNATURE HYPRLAND THEMES"
        case .omarchyChromatic: return "OMARCHY · RETRO, CYBER & TONAL"
        }
    }

    public var presets: [ThemePreset] {
        ThemePreset.allCases.filter { $0.family == self }
    }
}

public enum ThemePreset: String, Codable, CaseIterable, Identifiable, Sendable {
    // 1. Quiet & Minimal (Low-Stimulation Sanctuary)
    case quietSanctuary
    case japandiMoss
    case nordicDaylight

    // 2. Modern ADHD Focus (Biophilic & Cozy Dopamine)
    case matchaOat
    case lofiDusk
    case oceanicFocus
    case warmTactileBento
    case chunkyNeoBrutalistPop

    // 3. Omarchy · Signature Hyprland Desktops
    case omarchyQuattro        // Tokyo Night
    case omarchyCatppuccin     // Catppuccin Mocha / Latte
    case omarchyKanagawa       // Kanagawa Wave / Lotus
    case omarchyRosePine       // Rosé Pine / Dawn
    case omarchyNord           // Nord Polar Frost
    case omarchyMatteBlack     // Ghostty Matte Black OLED
    case omarchyEverforest     // Everforest Woodland

    // 4. Omarchy · Retro, Cyber & Tonal
    case omarchyGruvbox        // Gruvbox Material
    case omarchyCyberpunk      // Synthwave Cyber
    case quattroMinimal        // Monochrome Slate / Mist
    case quattroAsh            // Mineral Stone / Sand
    case omarchyAmber          // Amber Wave
    case omarchySolarFlare     // Solar Tangerine

    public var id: String { rawValue }

    public var family: ThemeFamily {
        switch self {
        case .quietSanctuary, .japandiMoss, .nordicDaylight:
            return .quietAndCalm
        case .matchaOat, .lofiDusk, .oceanicFocus, .warmTactileBento, .chunkyNeoBrutalistPop:
            return .modernFocus
        case .omarchyQuattro, .omarchyCatppuccin, .omarchyKanagawa, .omarchyRosePine, .omarchyNord, .omarchyMatteBlack, .omarchyEverforest:
            return .omarchyDesktops
        case .omarchyGruvbox, .omarchyCyberpunk, .quattroMinimal, .quattroAsh, .omarchyAmber, .omarchySolarFlare:
            return .omarchyChromatic
        }
    }

    public var title: String {
        switch self {
        case .quietSanctuary: return "Quiet Sanctuary"
        case .japandiMoss: return "Japandi Stone & Moss"
        case .nordicDaylight: return "Nordic Daylight"
        case .matchaOat: return "Matcha & Oat"
        case .lofiDusk: return "Cozy Lo-Fi Dusk"
        case .oceanicFocus: return "Oceanic Deep Teal"
        case .warmTactileBento: return "Warm Linen Bento"
        case .chunkyNeoBrutalistPop: return "Tactile Studio Pop"
        case .omarchyQuattro: return "Omarchy Tokyo Night"
        case .omarchyCatppuccin: return "Omarchy Catppuccin"
        case .omarchyKanagawa: return "Omarchy Kanagawa"
        case .omarchyRosePine: return "Omarchy Rosé Pine"
        case .omarchyNord: return "Omarchy Nord Frost"
        case .omarchyMatteBlack: return "Omarchy Matte Black"
        case .omarchyEverforest: return "Omarchy Everforest"
        case .omarchyGruvbox: return "Omarchy Gruvbox"
        case .omarchyCyberpunk: return "Omarchy Cyberpunk"
        case .quattroMinimal: return "Omarchy Mono Slate"
        case .quattroAsh: return "Omarchy Mineral Ash"
        case .omarchyAmber: return "Omarchy Amber Phosphor"
        case .omarchySolarFlare: return "Omarchy Solar Copper"
        }
    }

    public var shortLabel: String {
        switch self {
        case .quietSanctuary: return "Quiet"
        case .japandiMoss: return "Japandi"
        case .nordicDaylight: return "Nordic"
        case .matchaOat: return "Matcha"
        case .lofiDusk: return "Lo-Fi Dusk"
        case .oceanicFocus: return "Oceanic"
        case .warmTactileBento: return "Bento"
        case .chunkyNeoBrutalistPop: return "Pop"
        case .omarchyQuattro: return "Tokyo Night"
        case .omarchyCatppuccin: return "Catppuccin"
        case .omarchyKanagawa: return "Kanagawa"
        case .omarchyRosePine: return "Rosé Pine"
        case .omarchyNord: return "Nord"
        case .omarchyMatteBlack: return "Matte Black"
        case .omarchyEverforest: return "Everforest"
        case .omarchyGruvbox: return "Gruvbox"
        case .omarchyCyberpunk: return "Cyberpunk"
        case .quattroMinimal: return "Mono Slate"
        case .quattroAsh: return "Ash"
        case .omarchyAmber: return "Amber"
        case .omarchySolarFlare: return "Copper"
        }
    }

    public var subtitle: String {
        switch self {
        case .quietSanctuary:
            return "Ultra-calm warm linen & velvet slate with muted contrast and whisper-quiet visual rhythm"
        case .japandiMoss:
            return "Architectural limestone, hinoki forest moss & warm walnut tones"
        case .nordicDaylight:
            return "Airy Scandinavian paper & calm fjord slate-blue for effortless clarity"
        case .matchaOat:
            return "Creamy oat milk, ceremonial matcha green & soft peach accents"
        case .lofiDusk:
            return "Soothing twilight plum-indigo, soft lavender & warm apricot — gentle on tired eyes"
        case .oceanicFocus:
            return "Biophilic deep sea teal & seafoam — lowers visual overstimulation"
        case .warmTactileBento:
            return "Soft rounded cards with warm sage-to-terracotta progress indicators"
        case .chunkyNeoBrutalistPop:
            return "Crisp tactile borders and cheerful color blocks for high-energy days"
        case .omarchyQuattro:
            return "Classic Hyprland Tokyo Night #1A1B26 with periwinkle blue, violet & pixel HUD glyphs"
        case .omarchyCatppuccin:
            return "Beloved Catppuccin Mocha velvet (#1E1E2E) with lavender, peach & mint (Latte in Light)"
        case .omarchyKanagawa:
            return "Hokusai sumi-ink #1F1F28 with wave blue, sakura pink & carp gold"
        case .omarchyRosePine:
            return "Soho pine #191724 with iris, seafoam & muted rose (Rosé Pine Dawn in Light)"
        case .omarchyNord:
            return "Arctic polar night #2E3440 with frost cyan, glacier blue & aurora sage"
        case .omarchyMatteBlack:
            return "Pure OLED #0E0E10 Ghostty terminal black with crisp emerald phosphor & zero glare"
        case .omarchyEverforest:
            return "Deep woodland moss & calming botanical sage with crisp monospaced HUD framing"
        case .omarchyGruvbox:
            return "Warm retro Gruvbox Material charcoal, parchment cream, olive & ochre"
        case .omarchyCyberpunk:
            return "Night-city synthwave void with electric cyan & neon magenta focus rings"
        case .quattroMinimal:
            return "Zero-saturation monochrome slate & mist for distraction-free terminal focus"
        case .quattroAsh:
            return "Low-saturation mineral stone in Dark & warm sandstone in Light"
        case .omarchyAmber:
            return "Retro CRT burnished amber phosphor on obsidian"
        case .omarchySolarFlare:
            return "Warm copper & sunlit terracotta terminal palette"
        }
    }

    public var isOmarchyQuattroStyle: Bool {
        family == .omarchyDesktops || family == .omarchyChromatic
    }

    public var isQuietMinimalFamily: Bool {
        family == .quietAndCalm
    }

    /// Signature showcase appearance (`nil` = follows system Light/Dark).
    public var signatureIsDark: Bool? {
        switch self {
        case .quietSanctuary, .japandiMoss, .nordicDaylight, .matchaOat, .warmTactileBento, .chunkyNeoBrutalistPop:
            return false
        case .lofiDusk, .oceanicFocus:
            return true
        case .omarchyQuattro, .omarchyCatppuccin, .omarchyKanagawa, .omarchyRosePine, .omarchyNord,
             .omarchyMatteBlack, .omarchyEverforest, .omarchyGruvbox, .omarchyCyberpunk,
             .quattroMinimal, .quattroAsh, .omarchyAmber:
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
        case .signature: return "Theme Default"
        case .system: return "System"
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
        case .autoStagger: return "Spread Out"
        case .fresh: return "Just Done"
        case .dueSoon: return "Due Soon"
        case .dueNow: return "Due Today"
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

    // Effort & Time Scaffolds
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

    /// Plain-English description of how often reminders repeat on a due day (replaces cryptic `"q60m"`).
    public var reminderIntervalSummary: String {
        if isTaskPaused() {
            return "Alerts paused"
        }
        return Self.humanIntervalText(forMinutes: nagIntervalMinutes, prefix: "Reminds every ")
    }

    public var reminderBadgeIcon: String {
        intensityTier == .cutoffSystemAlarm ? "alarm.fill" : "bell.fill"
    }

    public static func humanIntervalText(forMinutes mins: Int, prefix: String = "Every ") -> String {
        if mins == 60 {
            return "\(prefix)1 hr"
        } else if mins > 60 && mins % 60 == 0 {
            return "\(prefix)\(mins / 60) hrs"
        } else if mins > 60 {
            let hrs = mins / 60
            let rem = mins % 60
            return "\(prefix)\(hrs)h \(rem)m"
        } else {
            return "\(prefix)\(mins) min"
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

    public func suggestedRange(
        from now: Date = .now,
        awakeStartMinutes: Int = 8 * 60 + 30,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date) {
        let startOfToday = calendar.startOfDay(for: now)
        switch self {
        case .countrysideWeekend:
            let weekday = calendar.component(.weekday, from: now)
            if weekday == 6 {
                let fri5PM = startOfToday.addingTimeInterval(17 * 3600)
                let start = now >= fri5PM ? now : fri5PM
                let sunStart = calendar.date(byAdding: .day, value: 2, to: startOfToday) ?? startOfToday.addingTimeInterval(2 * 86_400)
                let end = sunStart.addingTimeInterval(20 * 3600)
                return (start, end)
            } else if weekday == 7 {
                let sunStart = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday.addingTimeInterval(86_400)
                let end = sunStart.addingTimeInterval(20 * 3600)
                return (now, end)
            } else if weekday == 1 {
                let sun8PM = startOfToday.addingTimeInterval(20 * 3600)
                if now < startOfToday.addingTimeInterval(18 * 3600) {
                    return (now, sun8PM)
                } else {
                    let monStart = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday.addingTimeInterval(86_400)
                    return (now, monStart.addingTimeInterval(9 * 3600))
                }
            } else {
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
    public var freezeChoreDecay: Bool
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
        static let quietModeEnabled = "adhoused.quietModeEnabled"
        static let iconStylePreference = "adhoused.iconStylePreference"
        static let bionicReading = "adhoused.bionicReading"
        static let hapticsEnabled = "adhoused.hapticsEnabled"
        static let activeMemberID = "adhoused.activeMemberID"
        static let hasCompletedOnboarding = "adhoused.hasCompletedOnboarding"
        static let vacationBreaksJSON = "adhoused.vacationBreaksJSON"
        static let themeColorOverridesJSON = "adhoused.themeColorOverridesJSON"
        static let customCatalogTemplatesJSON = "adhoused.customCatalogTemplatesJSON"
        static let cloudShareZoneOwnerName = "adhoused.cloudShareZoneOwnerName"
        static let isAcceptedCloudShareParticipant = "adhoused.isAcceptedCloudShareParticipant"
        static let cloudShareURLString = "adhoused.cloudShareURLString"
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

    public var quietModeEnabled: Bool {
        didSet { defaults.set(quietModeEnabled, forKey: Keys.quietModeEnabled) }
    }

    public var iconStylePreference: IconStylePreference {
        didSet { defaults.set(iconStylePreference.rawValue, forKey: Keys.iconStylePreference) }
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

    public var themeColorOverrides: [String: ThemeColorOverrides] {
        didSet {
            if let encoded = try? JSONEncoder().encode(themeColorOverrides) {
                defaults.set(encoded, forKey: Keys.themeColorOverridesJSON)
            }
        }
    }

    public var customCatalogTemplates: [StarterChoreTemplate] {
        didSet {
            if let encoded = try? JSONEncoder().encode(customCatalogTemplates) {
                defaults.set(encoded, forKey: Keys.customCatalogTemplatesJSON)
            }
        }
    }

    public var cloudShareZoneOwnerName: String? {
        didSet { defaults.set(cloudShareZoneOwnerName, forKey: Keys.cloudShareZoneOwnerName) }
    }

    public var isAcceptedCloudShareParticipant: Bool {
        didSet { defaults.set(isAcceptedCloudShareParticipant, forKey: Keys.isAcceptedCloudShareParticipant) }
    }

    public var cloudShareURLString: String? {
        didSet { defaults.set(cloudShareURLString, forKey: Keys.cloudShareURLString) }
    }

    public init(defaults: UserDefaults = SharedAppGroup.sharedUserDefaults) {
        self.defaults = defaults
        self.themePreset = ThemePreset(rawValue: defaults.string(forKey: Keys.themePreset) ?? "") ?? .quietSanctuary
        self.colorSchemePreference = ColorSchemePreference(rawValue: defaults.string(forKey: Keys.colorScheme) ?? "") ?? .signature
        self.layoutMode = LayoutUsabilityMode(rawValue: defaults.string(forKey: Keys.layoutMode) ?? "") ?? .spotlightAndRooms
        self.quietModeEnabled = defaults.object(forKey: Keys.quietModeEnabled) as? Bool ?? false
        self.iconStylePreference = IconStylePreference(rawValue: defaults.string(forKey: Keys.iconStylePreference) ?? "") ?? .autoTheme
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

        if let data = defaults.data(forKey: Keys.themeColorOverridesJSON),
           let decoded = try? JSONDecoder().decode([String: ThemeColorOverrides].self, from: data) {
            self.themeColorOverrides = decoded
        } else {
            self.themeColorOverrides = [:]
        }

        if let data = defaults.data(forKey: Keys.customCatalogTemplatesJSON),
           let decoded = try? JSONDecoder().decode([StarterChoreTemplate].self, from: data) {
            self.customCatalogTemplates = decoded
        } else {
            self.customCatalogTemplates = []
        }

        self.cloudShareZoneOwnerName = defaults.string(forKey: Keys.cloudShareZoneOwnerName)
        self.isAcceptedCloudShareParticipant = defaults.bool(forKey: Keys.isAcceptedCloudShareParticipant)
        self.cloudShareURLString = defaults.string(forKey: Keys.cloudShareURLString)
    }

    // MARK: - Theme Overrides Helpers

    public func colorOverrides(for preset: ThemePreset) -> ThemeColorOverrides {
        themeColorOverrides[preset.rawValue] ?? ThemeColorOverrides()
    }

    public func setColorOverrides(_ overrides: ThemeColorOverrides, for preset: ThemePreset) {
        var copy = themeColorOverrides
        if overrides.hasAnyCustomization {
            copy[preset.rawValue] = overrides
        } else {
            copy.removeValue(forKey: preset.rawValue)
        }
        themeColorOverrides = copy
    }

    public func resetColorOverrides(for preset: ThemePreset) {
        var copy = themeColorOverrides
        copy.removeValue(forKey: preset.rawValue)
        themeColorOverrides = copy
    }

    // MARK: - Custom Catalog Helpers

    public func addOrUpdateCustomCatalogTemplate(_ template: StarterChoreTemplate) {
        var copy = customCatalogTemplates
        var mutable = template
        mutable.isCustom = true
        if let existingIdx = copy.firstIndex(where: { $0.id == mutable.id }) {
            copy[existingIdx] = mutable
        } else {
            copy.insert(mutable, at: 0)
        }
        customCatalogTemplates = copy
    }

    public func removeCustomCatalogTemplate(id: String) {
        customCatalogTemplates.removeAll { $0.id == id }
    }

    // MARK: - Vacation Break Helpers

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
        quietModeEnabled = defaults.object(forKey: Keys.quietModeEnabled) as? Bool ?? false
        if let iconPref = IconStylePreference(rawValue: defaults.string(forKey: Keys.iconStylePreference) ?? "") {
            iconStylePreference = iconPref
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
        if let data = defaults.data(forKey: Keys.themeColorOverridesJSON),
           let decoded = try? JSONDecoder().decode([String: ThemeColorOverrides].self, from: data) {
            themeColorOverrides = decoded
        }
        if let data = defaults.data(forKey: Keys.customCatalogTemplatesJSON),
           let decoded = try? JSONDecoder().decode([StarterChoreTemplate].self, from: data) {
            customCatalogTemplates = decoded
        }
        cloudShareZoneOwnerName = defaults.string(forKey: Keys.cloudShareZoneOwnerName)
        isAcceptedCloudShareParticipant = defaults.bool(forKey: Keys.isAcceptedCloudShareParticipant)
        cloudShareURLString = defaults.string(forKey: Keys.cloudShareURLString)
    }
}
