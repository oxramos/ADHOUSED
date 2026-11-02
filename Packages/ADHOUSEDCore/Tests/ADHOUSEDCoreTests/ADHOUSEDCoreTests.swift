import Testing
import Foundation
import SwiftUI
import SwiftData
@testable import ADHOUSEDCore

@Suite("ADHOUSED Core Domain & ADHD Engine Tests")
struct ADHOUSEDCoreTests {

    @Test("Rolling interval calculates freshness decay and resets cleanly without overdue pileup")
    func rollingIntervalFreshnessAndReset() throws {
        let now = Date(timeIntervalSince1970: 1_760_000_000)
        let householdID = UUID()

        let tenDaysAgo = now.addingTimeInterval(-10 * 86_400)
        let task = ChoreTask(
            householdID: householdID,
            title: "Wash bedsheets",
            room: .bedroom,
            scheduleMode: .rollingFromLastDone,
            intervalUnit: .days,
            intervalCount: 7,
            lastCompletedAt: tenDaysAgo,
            createdAt: tenDaysAgo
        )

        let overdueSnap = FreshnessCalculator.snapshot(for: task, now: now)
        #expect(overdueSnap.isActionableToday == true)
        #expect(overdueSnap.stage == .needsAttentionNow)
        #expect(overdueSnap.batteryFill == 0.0)
        #expect(overdueSnap.cadenceSummary.contains("10d ago"))

        task.lastCompletedAt = now
        let freshSnap = FreshnessCalculator.snapshot(for: task, now: now)
        #expect(freshSnap.isActionableToday == false)
        #expect(freshSnap.stage == .fresh)
        #expect(freshSnap.batteryFill == 1.0)
    }

    @Test("Fixed calendar weekday schedule surfaces missed occurrence as single active item")
    func fixedCalendarSingleRollover() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let wednesday = ISO8601DateFormatter().date(from: "2026-10-21T12:00:00Z")!
        let tenDaysPrior = wednesday.addingTimeInterval(-10 * 86_400)

        let trashTask = ChoreTask(
            householdID: UUID(),
            title: "Roll bins to curb",
            room: .entryAndTrash,
            scheduleMode: .fixedCalendar,
            fixedRuleKind: .weeklyDays,
            fixedWeekdays: [3],
            lastCompletedAt: tenDaysPrior,
            createdAt: tenDaysPrior
        )

        let missedSnap = FreshnessCalculator.snapshot(for: trashTask, now: wednesday, calendar: calendar)
        #expect(missedSnap.isActionableToday == true)
        #expect(missedSnap.stage == .needsAttentionNow)

        trashTask.lastCompletedAt = wednesday
        let doneSnap = FreshnessCalculator.snapshot(for: trashTask, now: wednesday, calendar: calendar)
        #expect(doneSnap.isActionableToday == false)
        #expect(doneSnap.batteryFill == 1.0)
    }

    @Test("Starter Seeder caps Day-1 due tasks when adopting large catalog")
    func starterStaggering() throws {
        let now = Date(timeIntervalSince1970: 1_760_000_000)
        let chosen = Array(StarterCatalog.allTemplates.prefix(14))
        let hid = UUID()

        let tasks: [ChoreTask] = chosen.enumerated().map { idx, tpl in
            let seededDate = StarterCatalogSeeder.initialLastCompletedDate(
                for: tpl,
                seed: .autoStagger,
                indexInBatch: idx,
                totalBatchCount: chosen.count,
                now: now
            )
            return ChoreTask(
                householdID: hid,
                title: tpl.title,
                room: tpl.room,
                scheduleMode: .rollingFromLastDone,
                intervalUnit: tpl.intervalUnit,
                intervalCount: tpl.intervalCount,
                lastCompletedAt: seededDate,
                createdAt: now
            )
        }

        let dueOnDayOne = tasks.filter { FreshnessCalculator.snapshot(for: $0, now: now).isActionableToday }
        #expect(dueOnDayOne.count == 2)
    }

    @Test("Shared Household alternating turns rotate on completion and revert cleanly on 1-tap Widget Undo")
    @MainActor
    func alternatingTurnsAndWidgetUndoGrace() throws {
        let container = try SharedAppGroup.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let now = Date(timeIntervalSince1970: 1_760_000_000)

        let household = Household(name: "Test Nest", createdAt: now, updatedAt: now)
        context.insert(household)

        let alex = HouseholdMember(householdID: household.id, displayName: "Alex", emoji: "🦊", sortOrder: 0)
        let sam = HouseholdMember(householdID: household.id, displayName: "Sam", emoji: "🦦", sortOrder: 1)
        context.insert(alex)
        context.insert(sam)

        let eightDaysAgo = now.addingTimeInterval(-8 * 86_400)
        let task = ChoreTask(
            householdID: household.id,
            title: "Unload dishwasher",
            room: .kitchen,
            intervalUnit: .days,
            intervalCount: 2,
            lastCompletedAt: eightDaysAgo,
            lastCompletedByMemberID: sam.id,
            assignmentMode: .alternating,
            assignedMemberIDs: [alex.id, sam.id],
            currentTurnIndex: 0,
            createdAt: eightDaysAgo
        )
        context.insert(task)
        try context.save()

        #expect(task.responsibleMemberID == alex.id)
        #expect(task.isActionable(forMemberID: alex.id) == true)
        #expect(task.isActionable(forMemberID: sam.id) == false)

        let record = try TaskActionService.completeTask(
            taskID: task.id,
            byMemberID: alex.id,
            enableWidgetUndoWindow: true,
            in: context,
            now: now
        )
        #expect(record != nil)
        #expect(task.responsibleMemberID == sam.id)
        #expect(task.hasActiveUndoGraceWindow(at: now.addingTimeInterval(4)) == true)
        #expect(task.hasActiveUndoGraceWindow(at: now.addingTimeInterval(10)) == false)

        let undone = try TaskActionService.undoLastCompletion(taskID: task.id, in: context, now: now.addingTimeInterval(3))
        #expect(undone == true)
        #expect(task.responsibleMemberID == alex.id)
        #expect(task.lastCompletedAt == eightDaysAgo)
        #expect(task.hasActiveUndoGraceWindow(at: now.addingTimeInterval(4)) == false)
    }

    @Test("NagSlotPlanner respects Awake Hours, 56-slot budget, and Timed Away Pause")
    func persistentNagSlotAllocationAndAwayPause() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let baseMorning = ISO8601DateFormatter().date(from: "2026-10-25T09:00:00Z")!

        let household = Household(
            name: "Home",
            awakeStartMinutes: 8 * 60 + 30,
            awakeEndMinutes: 21 * 60
        )

        let task = ChoreTask(
            householdID: household.id,
            title: "Scoop litter box",
            room: .petsAndPlants,
            intervalUnit: .days,
            intervalCount: 1,
            lastCompletedAt: baseMorning.addingTimeInterval(-2 * 86_400),
            remindersEnabled: true,
            nagIntervalMinutes: 30,
            intensityTier: .stickyLiveActivity,
            createdAt: baseMorning.addingTimeInterval(-5 * 86_400)
        )

        let slots = NagSlotPlanner.computeSlots(
            tasks: [task],
            household: household,
            activeMemberID: nil,
            now: baseMorning,
            calendar: calendar
        )
        #expect(!slots.isEmpty)
        #expect(slots.count <= NagNotificationConstants.maxBudgetSlots)

        for slot in slots {
            let dayStart = calendar.startOfDay(for: slot.fireDate)
            let mins = Int(slot.fireDate.timeIntervalSince(dayStart) / 60.0)
            #expect(mins >= household.awakeStartMinutes)
            #expect(mins <= household.awakeEndMinutes)
        }

        let threeHoursLater = baseMorning.addingTimeInterval(3 * 3600)
        household.awayPauseUntil = threeHoursLater
        let pausedSlots = NagSlotPlanner.computeSlots(
            tasks: [task],
            household: household,
            activeMemberID: nil,
            now: baseMorning,
            calendar: calendar
        )
        #expect(pausedSlots.first != nil)
        #expect(pausedSlots.first!.fireDate >= threeHoursLater)
    }

    @Test("SalientTextFormatter bolds leading fixation stems cleanly")
    func bionicReadingFormatting() {
        let attr = SalientTextFormatter.format("Wash bedsheets today!", bionicEnabled: true)
        let plain = String(attr.characters)
        #expect(plain == "Wash bedsheets today!")

        let disabled = SalientTextFormatter.format("Wash bedsheets", bionicEnabled: false)
        #expect(String(disabled.characters) == "Wash bedsheets")
    }

    @Test("All 21 ThemePresets resolve Light, Dark, Omarchy HUD, Quiet Minimal, and Per-Theme Color Overrides")
    func multiThemeEngineAndColorCustomization() {
        #expect(ThemePreset.allCases.count == 21)

        for preset in ThemePreset.allCases {
            let lightTokens = ADHOUSEDThemeTokens.resolve(
                preset: preset,
                colorScheme: .light,
                overrides: ThemeColorOverrides()
            )
            let darkTokens = ADHOUSEDThemeTokens.resolve(
                preset: preset,
                colorScheme: .dark,
                overrides: ThemeColorOverrides()
            )

            #expect(lightTokens.isDark == false)
            #expect(darkTokens.isDark == true)
            #expect(lightTokens.focusGradientColors.count >= 2)
            #expect(darkTokens.focusGradientColors.count >= 2)

            if preset.isOmarchyQuattroStyle {
                #expect(lightTokens.isTerminalHUD == true)
                #expect(darkTokens.isTerminalHUD == true)
                #expect(lightTokens.fontDesign == .monospaced)
                #expect(darkTokens.cardCornerRadius >= 8 && darkTokens.cardCornerRadius <= 10)
            } else {
                #expect(lightTokens.isTerminalHUD == false)
            }

            for room in RoomCategory.allCases {
                _ = lightTokens.roomAccent(for: room)
                _ = darkTokens.roomAccent(for: room)
            }
        }

        // Verify per-theme Color & Geometry Overrides
        let customOverrides = ThemeColorOverrides(
            canvasBackgroundHex: "#101820",
            accentPrimaryHex: "#FFAA33",
            cornerStyle: .softRounded,
            fontStyle: .softRounded
        )
        #expect(customOverrides.hasAnyCustomization == true)

        let customizedTokyo = ADHOUSEDThemeTokens.resolve(
            preset: .omarchyQuattro,
            colorScheme: .dark,
            overrides: customOverrides
        )
        #expect(customizedTokyo.cardCornerRadius == 24)
        #expect(customizedTokyo.fontDesign == .rounded)

        // Signature mode maps Omarchy dark-showcase themes to .dark and Quiet Sanctuary to .light
        #expect(
            ADHOUSEDThemeTokens.effectiveColorScheme(
                preset: .omarchyCatppuccin,
                preference: .signature,
                systemColorScheme: .light
            ) == .dark
        )
        #expect(
            ADHOUSEDThemeTokens.effectiveColorScheme(
                preset: .quietSanctuary,
                preference: .signature,
                systemColorScheme: .dark
            ) == .light
        )
    }

    @Test("Plain-English labels replace jargon and Omarchy pixel glyphs map cleanly")
    func plainEnglishLabelsAndOmarchyIcons() {
        let task60 = ChoreTask(householdID: UUID(), title: "Wipe counters", nagIntervalMinutes: 60, intensityTier: .gentlePings)
        #expect(task60.reminderIntervalSummary == "Reminds every 1 hr")
        #expect(task60.reminderBadgeIcon == "bell.fill")

        let task45Alarm = ChoreTask(householdID: UUID(), title: "Roll bins out", nagIntervalMinutes: 45, intensityTier: .cutoffSystemAlarm)
        #expect(task45Alarm.reminderIntervalSummary == "Reminds every 45 min")
        #expect(task45Alarm.reminderBadgeIcon == "alarm.fill")

        #expect(EnergyLevel.lowSpoons.label == "Quick & Easy")
        #expect(EnergyLevel.lowSpoons.badgeText == "Easy")

        #expect(ChoreIconCatalog.mappedOmarchyGlyphKey(for: "dishwasher.fill") == "dishes")
        #expect(ChoreIconCatalog.mappedOmarchyGlyphKey(for: "omarchy:ghost") == "ghost")
        #expect(ChoreIconCatalog.mappedOmarchyGlyphKey(for: "omarchy:prism") == "prism")
        #expect(ChoreIconCatalog.fallbackSystemSymbol(for: "omarchy:cat") == "cat.fill")
        #expect(ChoreIconCatalog.fallbackSystemSymbol(for: "emoji:🪴") == "sparkles")
    }

    @Test("Bundled Omarchy display font and JetBrains Mono register cleanly and sanitize smart punctuation")
    func bundledOmarchyAndJetBrainsFontsRegister() {
        ADHOUSEDFontRegistry.registerFontsIfNeeded()
        #expect(ADHOUSEDFontRegistry.isFontAvailable(ADHOUSEDFontRegistry.omarchyDisplayPostScript) == true)
        #expect(ADHOUSEDFontRegistry.isFontAvailable(ADHOUSEDFontRegistry.jetBrainsRegular) == true)
        #expect(ADHOUSEDFontRegistry.isFontAvailable(ADHOUSEDFontRegistry.jetBrainsBold) == true)
        #expect(ADHOUSEDFontRegistry.isFontAvailable(ADHOUSEDFontRegistry.jetBrainsExtraBold) == true)

        let sanitized = ADHOUSEDFontRegistry.sanitizeForOmarchyDisplay("Big Boss’s Chores — Quiet!")
        #expect(sanitized == "BIG BOSS'S CHORES - QUIET!")

        let suiteName = "adhoused.fonttest.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let prefs = ADHOUSEDPreferences(defaults: defaults)
        #expect(prefs.displayLetteringStyle == .autoTheme)
        prefs.displayLetteringStyle = .omarchyBlock
        #expect(prefs.displayLetteringStyle == .omarchyBlock)
    }

    @Test("Custom Catalog items persist, adopt without overwriting household name, and round-trip in JSON backup")
    @MainActor
    func customCatalogAndPortableSyncRoundTrip() throws {
        let suiteName = "adhoused.test.\(UUID().uuidString)"
        let isolatedDefaults = UserDefaults(suiteName: suiteName)!
        defer { isolatedDefaults.removePersistentDomain(forName: suiteName) }

        let prefs = ADHOUSEDPreferences(defaults: isolatedDefaults)
        let customItem = StarterChoreTemplate(
            title: "Water balcony herbs",
            iconSymbol: "omarchy:plant",
            room: .petsAndPlants,
            intervalUnit: .days,
            intervalCount: 3,
            estimatedMinutes: 4,
            isCustom: true
        )
        prefs.addOrUpdateCustomCatalogTemplate(customItem)
        #expect(prefs.customCatalogTemplates.count == 1)
        #expect(prefs.customCatalogTemplates.first?.title == "Water balcony herbs")

        let container = try SharedAppGroup.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let household = Household(name: "Big Boss's Fortress")
        context.insert(household)
        let member = HouseholdMember(householdID: household.id, displayName: "Big Boss", emoji: "🦊")
        context.insert(member)
        try context.save()

        let adopted = try TaskActionService.adoptCatalogTemplates(
            [(customItem, .dueNow, .anyone)],
            in: context
        )
        #expect(adopted.count == 1)
        #expect(household.name == "Big Boss's Fortress") // Never overwritten to "Our Home"!

        // Round-trip portable JSON export -> import into second container
        let backupData = try HouseholdCloudSyncService.shared.exportHouseholdJSON(in: context)
        let partnerContainer = try SharedAppGroup.makeModelContainer(inMemory: true)
        try HouseholdCloudSyncService.shared.importHouseholdJSON(backupData, in: partnerContainer.mainContext)

        let importedHouseholds = try partnerContainer.mainContext.fetch(FetchDescriptor<Household>())
        let importedTasks = try partnerContainer.mainContext.fetch(FetchDescriptor<ChoreTask>())
        #expect(importedHouseholds.first?.name == "Big Boss's Fortress")
        #expect(importedTasks.contains(where: { $0.title == "Water balcony herbs" }))
    }

    @Test("Vacation & Break Date-Time window pauses chores, silences notifications during range, and shifts rolling decay")
    @MainActor
    func vacationBreakWindowPausesChoresAndNotifications() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let fridayNoon = calendar.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 12, minute: 0))!
        let friday5PM = calendar.date(from: DateComponents(year: 2026, month: 11, day: 6, hour: 17, minute: 0))!
        let saturdayNoon = calendar.date(from: DateComponents(year: 2026, month: 11, day: 7, hour: 12, minute: 0))!
        let sunday8PM = calendar.date(from: DateComponents(year: 2026, month: 11, day: 8, hour: 20, minute: 0))!

        let container = try SharedAppGroup.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let household = Household(name: "Countryside Test", awakeStartMinutes: 9 * 60, awakeEndMinutes: 21 * 60)
        context.insert(household)

        let task = ChoreTask(
            householdID: household.id,
            title: "Vacuum living room",
            room: .living,
            scheduleMode: .rollingFromLastDone,
            intervalUnit: .days,
            intervalCount: 7,
            lastCompletedAt: fridayNoon.addingTimeInterval(-7 * 86_400),
            remindersEnabled: true,
            nagIntervalMinutes: 60
        )
        context.insert(task)
        try context.save()

        let weekendBreak = VacationBreakWindow(
            title: "Countryside Weekend",
            iconSymbol: "tree.fill",
            startDate: friday5PM,
            endDate: sunday8PM,
            freezeChoreDecay: true
        )

        let preBreakSlots = NagSlotPlanner.computeSlots(
            tasks: [task],
            household: household,
            activeMemberID: nil,
            vacationBreaks: [weekendBreak],
            horizonHours: 72,
            now: fridayNoon,
            calendar: calendar
        )
        #expect(!preBreakSlots.isEmpty)
        for slot in preBreakSlots {
            let insideBreak = slot.fireDate >= friday5PM && slot.fireDate < sunday8PM
            #expect(insideBreak == false)
        }

        let midBreakSnap = FreshnessCalculator.snapshot(
            for: task,
            now: saturdayNoon,
            activeVacationBreak: weekendBreak,
            calendar: calendar
        )
        #expect(midBreakSnap.isActionableToday == false)
        #expect(midBreakSnap.shortElapsedBadge == "On Break")

        let midBreakSlots24h = NagSlotPlanner.computeSlots(
            tasks: [task],
            household: household,
            activeMemberID: nil,
            vacationBreaks: [weekendBreak],
            horizonHours: 24,
            now: saturdayNoon,
            calendar: calendar
        )
        #expect(midBreakSlots24h.isEmpty)
    }
}
