import Foundation

// MARK: - Curated Household & Life Activity Catalog + User Custom Templates

public struct StarterChoreTemplate: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var iconSymbol: String
    public var room: RoomCategory
    public var scheduleMode: ScheduleMode
    public var intervalUnit: IntervalUnit
    public var intervalCount: Int
    public var fixedWeekdays: [Int]
    public var energyLevel: EnergyLevel
    public var estimatedMinutes: Int
    public var suggestedNagMinutes: Int
    public var suggestedTier: ReminderIntensityTier
    public var recommendedByDefault: Bool
    public var isCustom: Bool

    public init(
        id: String = "custom_\(UUID().uuidString)",
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
        recommendedByDefault: Bool = false,
        isCustom: Bool = false
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
        self.isCustom = isCustom
    }

    public var cadenceTag: String {
        switch scheduleMode {
        case .rollingFromLastDone:
            if intervalCount == 1 && intervalUnit == .days { return "Daily" }
            if intervalCount == 1 && intervalUnit == .weeks { return "Weekly" }
            if intervalCount == 7 && intervalUnit == .days { return "Weekly" }
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
    /// Combined catalog of user-created custom templates (shown first) plus built-in household & life templates.
    public static var combinedTemplates: [StarterChoreTemplate] {
        ADHOUSEDPreferences.shared.customCatalogTemplates + allTemplates
    }

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
            suggestedNagMinutes: 60,
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
            title: "Clear old leftovers from fridge",
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
            title: "Clean coffee machine / kettle",
            iconSymbol: "cup.and.saucer.fill",
            room: .kitchen,
            intervalUnit: .days,
            intervalCount: 30,
            energyLevel: .steady,
            estimatedMinutes: 10
        ),
        StarterChoreTemplate(
            id: "kitchen_water_bottles",
            title: "Wash reusable water bottles",
            iconSymbol: "waterbottle.fill",
            room: .kitchen,
            intervalUnit: .days,
            intervalCount: 3,
            energyLevel: .lowSpoons,
            estimatedMinutes: 3
        ),
        StarterChoreTemplate(
            id: "kitchen_groceries",
            title: "Check pantry & plan groceries",
            iconSymbol: "cart.fill",
            room: .kitchen,
            intervalUnit: .days,
            intervalCount: 7,
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
            title: "Quick brush & wipe toilet",
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
            title: "Swap bath & hand towels",
            iconSymbol: "tshirt.fill",
            room: .bathroom,
            intervalUnit: .days,
            intervalCount: 5,
            energyLevel: .lowSpoons,
            estimatedMinutes: 2
        ),
        StarterChoreTemplate(
            id: "bath_shower_scrub",
            title: "Clean shower / tub surfaces",
            iconSymbol: "shower.fill",
            room: .bathroom,
            intervalUnit: .days,
            intervalCount: 14,
            energyLevel: .deepClean,
            estimatedMinutes: 15
        ),
        StarterChoreTemplate(
            id: "bath_mat_wash",
            title: "Wash bath mat",
            iconSymbol: "washer.fill",
            room: .bathroom,
            intervalUnit: .days,
            intervalCount: 14,
            energyLevel: .lowSpoons,
            estimatedMinutes: 3
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
            title: "Put away chair / floor clothes pile",
            iconSymbol: "hanger",
            room: .bedroom,
            intervalUnit: .days,
            intervalCount: 4,
            energyLevel: .lowSpoons,
            estimatedMinutes: 5
        ),
        StarterChoreTemplate(
            id: "bed_air_room",
            title: "Open windows & air out bedroom",
            iconSymbol: "wind",
            room: .bedroom,
            intervalUnit: .days,
            intervalCount: 2,
            energyLevel: .lowSpoons,
            estimatedMinutes: 2
        ),

        // Living Space
        StarterChoreTemplate(
            id: "living_surfaces",
            title: "5-minute coffee table & couch tidy",
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
            iconSymbol: "sparkles",
            room: .living,
            intervalUnit: .days,
            intervalCount: 21,
            energyLevel: .steady,
            estimatedMinutes: 10
        ),
        StarterChoreTemplate(
            id: "living_desk_reset",
            title: "Clear desk & wipe keyboard/screen",
            iconSymbol: "desktopcomputer",
            room: .living,
            intervalUnit: .days,
            intervalCount: 7,
            energyLevel: .lowSpoons,
            estimatedMinutes: 5
        ),

        // Laundry & Linens
        StarterChoreTemplate(
            id: "laundry_wash",
            title: "Wash & dry a load of laundry",
            iconSymbol: "washer.fill",
            room: .laundry,
            intervalUnit: .days,
            intervalCount: 5,
            energyLevel: .steady,
            estimatedMinutes: 10,
            suggestedNagMinutes: 60,
            suggestedTier: .stickyLiveActivity,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "laundry_put_away",
            title: "Fold & put away clean laundry",
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
            title: "Wash & refill pet water bowls",
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
            suggestedNagMinutes: 45,
            suggestedTier: .stickyLiveActivity
        ),
        StarterChoreTemplate(
            id: "pets_brush",
            title: "Brush pet coat / trim nails",
            iconSymbol: "comb.fill",
            room: .petsAndPlants,
            intervalUnit: .days,
            intervalCount: 10,
            energyLevel: .steady,
            estimatedMinutes: 10
        ),

        // Entry & Trash
        StarterChoreTemplate(
            id: "trash_kitchen_out",
            title: "Take out trash & recycling",
            iconSymbol: "trash.fill",
            room: .entryAndTrash,
            intervalUnit: .days,
            intervalCount: 3,
            energyLevel: .lowSpoons,
            estimatedMinutes: 4,
            suggestedNagMinutes: 60,
            suggestedTier: .stickyLiveActivity,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "trash_curb_night",
            title: "Roll bins out for pickup",
            iconSymbol: "arrow.up.bin.fill",
            room: .entryAndTrash,
            scheduleMode: .fixedCalendar,
            fixedWeekdays: [3],
            energyLevel: .lowSpoons,
            estimatedMinutes: 4,
            suggestedNagMinutes: 30,
            suggestedTier: .cutoffSystemAlarm,
            recommendedByDefault: true
        ),
        StarterChoreTemplate(
            id: "entry_mail_sort",
            title: "Sort mail & tidy entryway shoes",
            iconSymbol: "envelope.open.fill",
            room: .entryAndTrash,
            intervalUnit: .days,
            intervalCount: 4,
            energyLevel: .lowSpoons,
            estimatedMinutes: 3
        ),

        // Whole Home & Life Activities
        StarterChoreTemplate(
            id: "home_meds_refill",
            title: "Refill weekly pill / vitamin organizer",
            iconSymbol: "pills.fill",
            room: .general,
            intervalUnit: .days,
            intervalCount: 7,
            energyLevel: .lowSpoons,
            estimatedMinutes: 4
        ),
        StarterChoreTemplate(
            id: "home_bills_admin",
            title: "Quick check on bills & deliveries",
            iconSymbol: "creditcard.fill",
            room: .general,
            intervalUnit: .days,
            intervalCount: 14,
            energyLevel: .steady,
            estimatedMinutes: 10
        ),
        StarterChoreTemplate(
            id: "home_backpack_car",
            title: "Clear out bag / car trash",
            iconSymbol: "backpack.fill",
            room: .general,
            intervalUnit: .days,
            intervalCount: 7,
            energyLevel: .lowSpoons,
            estimatedMinutes: 5
        ),
        StarterChoreTemplate(
            id: "home_air_filter",
            title: "Clean purifier / AC filter",
            iconSymbol: "aqi.medium",
            room: .general,
            intervalUnit: .days,
            intervalCount: 30,
            energyLevel: .lowSpoons,
            estimatedMinutes: 5
        )
    ]

    public static func templates(for room: RoomCategory) -> [StarterChoreTemplate] {
        combinedTemplates.filter { $0.room == room }
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
            return now.addingTimeInterval(-intervalSeconds)
        case .dueSoon:
            return now.addingTimeInterval(-intervalSeconds * 0.78)
        case .fresh:
            return now.addingTimeInterval(-intervalSeconds * 0.10)
        case .autoStagger:
            if indexInBatch < 2 {
                return now.addingTimeInterval(-intervalSeconds)
            }
            let remainingCount = max(1, totalBatchCount - 2)
            let slotIndex = indexInBatch - 2
            let fraction = 0.15 + (0.67 * Double(slotIndex) / Double(remainingCount))
            if intervalDays <= 1.0 {
                return calendar.startOfDay(for: now).addingTimeInterval(3600)
            }
            return now.addingTimeInterval(-intervalSeconds * min(0.85, fraction))
        }
    }
}
