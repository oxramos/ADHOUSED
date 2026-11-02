import Foundation

// MARK: - Curated Household Starter Catalog & Anti-Avalanche Seeder

public struct StarterChoreTemplate: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let iconSymbol: String
    public let room: RoomCategory
    public let scheduleMode: ScheduleMode
    public let intervalUnit: IntervalUnit
    public let intervalCount: Int
    public let fixedWeekdays: [Int]
    public let energyLevel: EnergyLevel
    public let estimatedMinutes: Int
    public let suggestedNagMinutes: Int
    public let suggestedTier: ReminderIntensityTier
    public let recommendedByDefault: Bool

    public init(
        id: String,
        title: String,
        iconSymbol: String,
        room: RoomCategory,
        scheduleMode: ScheduleMode = .rollingFromLastDone,
        intervalUnit: IntervalUnit = .days,
        intervalCount: Int = 7,
        fixedWeekdays: [Int] = [3],
        energyLevel: EnergyLevel = .lowSpoons,
        estimatedMinutes: Int = 5,
        suggestedNagMinutes: Int = 60,
        suggestedTier: ReminderIntensityTier = .gentlePings,
        recommendedByDefault: Bool = false
    ) {
        self.id = id
        self.title = title
        self.iconSymbol = iconSymbol
        self.room = room
        self.scheduleMode = scheduleMode
        self.intervalUnit = intervalUnit
        self.intervalCount = intervalCount
        self.fixedWeekdays = fixedWeekdays
        self.energyLevel = energyLevel
        self.estimatedMinutes = estimatedMinutes
        self.suggestedNagMinutes = suggestedNagMinutes
        self.suggestedTier = suggestedTier
        self.recommendedByDefault = recommendedByDefault
    }

    public var cadenceTag: String {
        switch scheduleMode {
        case .rollingFromLastDone:
            if intervalCount == 1 && intervalUnit == .days { return "Daily" }
            if intervalCount == 1 && intervalUnit == .weeks { return "Every 7d" }
            return "Every \(intervalCount) \(intervalCount == 1 ? intervalUnit.singularLabel : intervalUnit.pluralLabel)"
        case .fixedCalendar:
            let formatter = Calendar.current.shortWeekdaySymbols
            let names = fixedWeekdays.compactMap { day -> String? in
                guard (1...7).contains(day) else { return nil }
                return formatter[day - 1]
            }
            return "Every " + names.joined(separator: ", ")
        }
    }
}

public enum StarterCatalog {
    public static let allTemplates: [StarterChoreTemplate] = [
        // Kitchen
        StarterChoreTemplate(
            id: "kitchen_dishes",
            title: "Load or unload dishwasher",
            iconSymbol: "dishwasher.fill",
            room: .kitchen,
            intervalUnit: .days,
            intervalCount: 1,
            energyLevel: .lowSpoons,
            estimatedMinutes: 5,
            suggestedNagMinutes: 45,
            suggestedTier: .stickyLiveActivity,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "kitchen_counters",
            title: "Wipe kitchen counters & stovetop",
            iconSymbol: "sparkles",
            room: .kitchen,
            intervalUnit: .days,
            intervalCount: 2,
            energyLevel: .lowSpoons,
            estimatedMinutes: 4,
            suggestedNagMinutes: 60,
            suggestedTier: .gentlePings,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "kitchen_sink_scrub",
            title: "Scrub kitchen sink & swap sponge",
            iconSymbol: "sink.fill",
            room: .kitchen,
            intervalUnit: .days,
            intervalCount: 7,
            energyLevel: .lowSpoons,
            estimatedMinutes: 4
        ),
        StarterChoreTemplate(
            id: "kitchen_fridge_toss",
            title: "Toss expired fridge leftovers",
            iconSymbol: "refrigerator.fill",
            room: .kitchen,
            intervalUnit: .days,
            intervalCount: 7,
            energyLevel: .lowSpoons,
            estimatedMinutes: 5,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "kitchen_coffee_descale",
            title: "Descale coffee maker / kettle",
            iconSymbol: "cup.and.saucer.fill",
            room: .kitchen,
            intervalUnit: .days,
            intervalCount: 30,
            energyLevel: .steady,
            estimatedMinutes: 10
        ),

        // Bathroom
        StarterChoreTemplate(
            id: "bath_mirror_sink",
            title: "Wipe bathroom sink & mirror",
            iconSymbol: "sparkles.rectangle.stack.fill",
            room: .bathroom,
            intervalUnit: .days,
            intervalCount: 5,
            energyLevel: .lowSpoons,
            estimatedMinutes: 3,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "bath_toilet",
            title: "Quick swish & wipe toilet",
            iconSymbol: "toilet.fill",
            room: .bathroom,
            intervalUnit: .days,
            intervalCount: 7,
            energyLevel: .lowSpoons,
            estimatedMinutes: 4,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "bath_towels",
            title: "Swap out bath & hand towels",
            iconSymbol: "Hands.and.sparkles.fill".lowercased() == "hands.and.sparkles.fill" ? "tshirt.fill" : "tshirt.fill",
            room: .bathroom,
            intervalUnit: .days,
            intervalCount: 5,
            energyLevel: .lowSpoons,
            estimatedMinutes: 2
        ),
        StarterChoreTemplate(
            id: "bath_shower_scrub",
            title: "Scrub shower / tub surfaces",
            iconSymbol: "shower.fill",
            room: .bathroom,
            intervalUnit: .days,
            intervalCount: 14,
            energyLevel: .deepClean,
            estimatedMinutes: 15
        ),

        // Bedroom
        StarterChoreTemplate(
            id: "bed_sheets",
            title: "Wash & change bedsheets",
            iconSymbol: "bed.double.fill",
            room: .bedroom,
            intervalUnit: .days,
            intervalCount: 14,
            energyLevel: .steady,
            estimatedMinutes: 15,
            suggestedNagMinutes: 60,
            suggestedTier: .stickyLiveActivity,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "bed_nightstand",
            title: "Clear cups & clutter off nightstand",
            iconSymbol: "mug.fill",
            room: .bedroom,
            intervalUnit: .days,
            intervalCount: 3,
            energyLevel: .lowSpoons,
            estimatedMinutes: 2,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "bed_floordrobe",
            title: "Reset chair / floor clothes pile",
            iconSymbol: "hanger",
            room: .bedroom,
            intervalUnit: .days,
            intervalCount: 4,
            energyLevel: .lowSpoons,
            estimatedMinutes: 5
        ),

        // Living Space
        StarterChoreTemplate(
            id: "living_surfaces",
            title: "5-minute coffee table & couch reset",
            iconSymbol: "sofa.fill",
            room: .living,
            intervalUnit: .days,
            intervalCount: 2,
            energyLevel: .lowSpoons,
            estimatedMinutes: 5,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "living_vacuum",
            title: "Vacuum main floors & rugs",
            iconSymbol: "fanblades.fill",
            room: .living,
            intervalUnit: .days,
            intervalCount: 7,
            energyLevel: .steady,
            estimatedMinutes: 15,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "living_mop",
            title: "Mop hard floors",
            iconSymbol: "drop.triangle.fill",
            room: .living,
            intervalUnit: .days,
            intervalCount: 14,
            energyLevel: .deepClean,
            estimatedMinutes: 20
        ),
        StarterChoreTemplate(
            id: "living_dust",
            title: "Dust shelves, TV stand & sills",
            iconSymbol: "wind",
            room: .living,
            intervalUnit: .days,
            intervalCount: 21,
            energyLevel: .steady,
            estimatedMinutes: 10
        ),

        // Laundry & Linens
        StarterChoreTemplate(
            id: "laundry_wash",
            title: "Run & dry a load of laundry",
            iconSymbol: "washer.fill",
            room: .laundry,
            intervalUnit: .days,
            intervalCount: 5,
            energyLevel: .steady,
            estimatedMinutes: 10,
            suggestedNagMinutes: 45,
            suggestedTier: .stickyLiveActivity,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "laundry_put_away",
            title: "Put away clean laundry basket",
            iconSymbol: "cabinet.fill",
            room: .laundry,
            intervalUnit: .days,
            intervalCount: 5,
            energyLevel: .steady,
            estimatedMinutes: 10
        ),

        // Pets & Plants
        StarterChoreTemplate(
            id: "plants_water",
            title: "Check & water houseplants",
            iconSymbol: "leaf.fill",
            room: .petsAndPlants,
            intervalUnit: .days,
            intervalCount: 6,
            energyLevel: .lowSpoons,
            estimatedMinutes: 5,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "pets_water_bowls",
            title: "Wash & refill pet water fountain/bowls",
            iconSymbol: "pawprint.fill",
            room: .petsAndPlants,
            intervalUnit: .days,
            intervalCount: 2,
            energyLevel: .lowSpoons,
            estimatedMinutes: 3
        ),
        StarterChoreTemplate(
            id: "pets_litter",
            title: "Scoop litter box",
            iconSymbol: "tray.full.fill",
            room: .petsAndPlants,
            intervalUnit: .days,
            intervalCount: 1,
            energyLevel: .lowSpoons,
            estimatedMinutes: 3,
            suggestedNagMinutes: 30,
            suggestedTier: .stickyLiveActivity
        ),

        // Entry & Trash
        StarterChoreTemplate(
            id: "trash_kitchen_out",
            title: "Take out kitchen trash & recycling",
            iconSymbol: "trash.fill",
            room: .entryAndTrash,
            intervalUnit: .days,
            intervalCount: 3,
            energyLevel: .lowSpoons,
            estimatedMinutes: 4,
            suggestedNagMinutes: 45,
            suggestedTier: .stickyLiveActivity,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "trash_curb_night",
            title: "Roll bins to curb for pickup",
            iconSymbol: "arrow.up.bin.fill",
            room: .entryAndTrash,
            scheduleMode: .fixedCalendar,
            fixedWeekdays: [3], // Tuesday night default
            energyLevel: .lowSpoons,
            estimatedMinutes: 4,
            suggestedNagMinutes: 30,
            suggestedTier: .cutoffSystemAlarm,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "entry_mail_sort",
            title: "Toss junk mail & clear entry drop-zone",
            iconSymbol: "envelope.open.fill",
            room: .entryAndTrash,
            intervalUnit: .days,
            intervalCount: 4,
            energyLevel: .lowSpoons,
            estimatedMinutes: 3
        )
    ]

    public static func templates(for room: RoomCategory) -> [StarterChoreTemplate] {
        allTemplates.filter { $0.room == room }
    }
}

public enum StarterCatalogSeeder {
    /// Computes an initial `lastCompletedAt` date so adopting 12–20 chores on Day 1
    /// never triggers an overwhelming wall of simultaneous alerts.
    public static func initialLastCompletedDate(
        for template: StarterChoreTemplate,
        seed: InitialFreshnessSeed,
        indexInBatch: Int,
        totalBatchCount: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Date? {
        let intervalDays = max(1.0, template.intervalUnit.approximateDays(count: template.intervalCount))
        let intervalSeconds = intervalDays * 86_400.0

        switch seed {
        case .dueNow:
            // Elapsed 100% of interval -> actionable right now
            return now.addingTimeInterval(-intervalSeconds)
        case .dueSoon:
            // Elapsed ~78% of interval -> warming up in next day or two
            return now.addingTimeInterval(-intervalSeconds * 0.78)
        case .fresh:
            // Just done recently (~10% elapsed)
            return now.addingTimeInterval(-intervalSeconds * 0.10)
        case .autoStagger:
            // Cap immediate Day-1 due items at most 2 tasks; spread remaining tasks evenly between 15% and 82% elapsed!
            if indexInBatch < 2 {
                return now.addingTimeInterval(-intervalSeconds)
            }
            let remainingCount = max(1, totalBatchCount - 2)
            let slotIndex = indexInBatch - 2
            let fraction = 0.15 + (0.67 * Double(slotIndex) / Double(remainingCount))
            // For 1-day daily tasks that aren't in the first 2 due slots, mark done earlier today so they come due tomorrow
            if intervalDays <= 1.0 {
                return calendar.startOfDay(for: now).addingTimeInterval(3600)
            }
            return now.addingTimeInterval(-intervalSeconds * min(0.85, fraction))
        }
    }
}
