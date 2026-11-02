import Foundation
import SwiftData
import CloudKit
#if canImport(Security)
import Security
#endif

public enum CloudSyncAvailabilityState: Equatable, Sendable {
    case localMultiMemberMode(reason: String)
    case readyForCloudShare
    case activelySharedHousehold
}

public struct HouseholdBackupPayload: Codable, Sendable {
    public struct MemberDTO: Codable, Sendable {
        public let id: UUID
        public let displayName: String
        public let emoji: String
        public let accentHex: String
        public let sortOrder: Int
    }

    public struct TaskDTO: Codable, Sendable {
        public let id: UUID
        public let title: String
        public let iconSymbol: String
        public let roomRaw: String
        public let scheduleModeRaw: String
        public let intervalUnitRaw: String
        public let intervalCount: Int
        public let fixedRuleKindRaw: String
        public let fixedWeekdaysCSV: String
        public let fixedDayOfMonth: Int
        public let lastCompletedAt: Date?
        public let lastCompletedByMemberID: UUID?
        public let energyLevelRaw: String
        public let estimatedMinutes: Int
        public let sprintDurationMinutes: Int
        public let remindersEnabled: Bool
        public let nagIntervalMinutes: Int
        public let intensityTierRaw: String
        public let alarmCutoffMinutes: Int
        public let assignmentModeRaw: String
        public let assignedMemberIDsCSV: String
        public let currentTurnIndex: Int
        public let totalCompletionsCount: Int
        public let deferralCount: Int
    }

    public let exportedAt: Date
    public let householdID: UUID
    public let householdName: String
    public let awakeStartMinutes: Int
    public let awakeEndMinutes: Int
    public let members: [MemberDTO]
    public let tasks: [TaskDTO]
}

@MainActor
@Observable
public final class HouseholdCloudSyncService {
    public static let shared = HouseholdCloudSyncService()
    public static let zoneName = "ADHOUSEDHouseholdZone"

    public private(set) var availabilityState: CloudSyncAvailabilityState = .localMultiMemberMode(
        reason: "Running in Local-First Household Mode (add Apple Developer Team ID in Signing.xcconfig to enable live multi-iPhone iCloud links)"
    )
    public private(set) var lastSyncedAt: Date?

    private init() {
        refreshAvailability()
    }

    /// Safely inspects runtime signature/ubiquity state without invoking `CKContainer(identifier:)` when entitlements are absent.
    public func refreshAvailability(hasExistingShare: Bool = false) {
        guard Self.binaryHasCloudKitContainerEntitlement() else {
            availabilityState = .localMultiMemberMode(
                reason: "Local-First Multi-Member Mode active — zero accounts required. Add your Apple Developer Team in Signing.xcconfig to unlock live iCloud invite links."
            )
            return
        }

        guard FileManager.default.ubiquityIdentityToken != nil else {
            availabilityState = .localMultiMemberMode(
                reason: "Sign in to iCloud in iOS Settings to invite household members via iMessage."
            )
            return
        }

        availabilityState = hasExistingShare ? .activelySharedHousehold : .readyForCloudShare
    }

    private static func binaryHasCloudKitContainerEntitlement() -> Bool {
        // Check embedded Info / environment marker so Simulator & Personal Team builds never trap in CloudKit.
        guard Bundle.main.object(forInfoDictionaryKey: "ADHOUSEDCloudKitContainerEnabled") as? Bool == true else {
            return false
        }
        return FileManager.default.ubiquityIdentityToken != nil
    }

    /// Prepares or retrieves a `CKShare` rooted in `ADHOUSEDHouseholdZone` when CloudKit entitlements are enabled.
    public func prepareHouseholdCloudShare(
        for household: Household,
        tasks: [ChoreTask],
        members: [HouseholdMember]
    ) async throws -> (share: CKShare, container: CKContainer) {
        switch availabilityState {
        case .readyForCloudShare, .activelySharedHousehold:
            break
        case .localMultiMemberMode:
            throw NSError(
                domain: "ADHOUSED.CloudSync",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Live iCloud Sharing requires an Apple Developer Team ID & CloudKit entitlement in Signing.xcconfig. Use the built-in Household Member Switcher or Export Backup in the meantime!"
                ]
            )
        }

        let container = CKContainer(identifier: SharedAppGroup.iCloudContainerID)
        let privateDB = container.privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: Self.zoneName, ownerName: CKCurrentUserDefaultName)
        let zone = CKRecordZone(zoneID: zoneID)
        _ = try await privateDB.modifyRecordZones(saving: [zone], deleting: [])

        let rootRecordID = CKRecord.ID(recordName: "Household-\(household.id.uuidString)", zoneID: zoneID)
        let rootRecord = CKRecord(recordType: "Household", recordID: rootRecordID)
        rootRecord["name"] = household.name as CKRecordValue
        rootRecord["awakeStartMinutes"] = household.awakeStartMinutes as CKRecordValue
        rootRecord["awakeEndMinutes"] = household.awakeEndMinutes as CKRecordValue

        let share = CKShare(rootRecord: rootRecord)
        share[CKShare.SystemFieldKey.title] = "\(household.name) — ADHOUSED Chores" as CKRecordValue
        share.publicPermission = .none

        var recordsToSave: [CKRecord] = [rootRecord, share]

        for member in members {
            let recID = CKRecord.ID(recordName: "Member-\(member.id.uuidString)", zoneID: zoneID)
            let rec = CKRecord(recordType: "HouseholdMember", recordID: recID)
            rec.parent = CKRecord.Reference(recordID: rootRecordID, action: .none)
            rec["displayName"] = member.displayName as CKRecordValue
            rec["emoji"] = member.emoji as CKRecordValue
            rec["accentHex"] = member.accentHex as CKRecordValue
            recordsToSave.append(rec)
        }

        for task in tasks where !task.isArchived {
            let recID = CKRecord.ID(recordName: "ChoreTask-\(task.id.uuidString)", zoneID: zoneID)
            let rec = CKRecord(recordType: "ChoreTask", recordID: recID)
            rec.parent = CKRecord.Reference(recordID: rootRecordID, action: .none)
            rec["title"] = task.title as CKRecordValue
            rec["iconSymbol"] = task.iconSymbol as CKRecordValue
            rec["roomRaw"] = task.roomRaw as CKRecordValue
            rec["scheduleModeRaw"] = task.scheduleModeRaw as CKRecordValue
            rec["intervalUnitRaw"] = task.intervalUnitRaw as CKRecordValue
            rec["intervalCount"] = task.intervalCount as CKRecordValue
            rec["assignmentModeRaw"] = task.assignmentModeRaw as CKRecordValue
            rec["assignedMemberIDsCSV"] = task.assignedMemberIDsCSV as CKRecordValue
            rec["currentTurnIndex"] = task.currentTurnIndex as CKRecordValue
            if let lastDone = task.lastCompletedAt {
                rec["lastCompletedAt"] = lastDone as CKRecordValue
            }
            recordsToSave.append(rec)
        }

        _ = try await privateDB.modifyRecords(saving: recordsToSave, deleting: [], savePolicy: .allKeys)
        lastSyncedAt = .now
        availabilityState = .activelySharedHousehold
        return (share, container)
    }

    // MARK: - Portable Household Snapshot Export & Import (Works 100% Offline & Across Devices)

    public func exportHouseholdJSON(in context: ModelContext) throws -> Data {
        let household = try context.fetch(FetchDescriptor<Household>()).first ?? Household()
        let members = try context.fetch(FetchDescriptor<HouseholdMember>(sortBy: [SortDescriptor(\.sortOrder)]))
        let tasks = try context.fetch(FetchDescriptor<ChoreTask>()).filter { !$0.isArchived }

        let payload = HouseholdBackupPayload(
            exportedAt: .now,
            householdID: household.id,
            householdName: household.name,
            awakeStartMinutes: household.awakeStartMinutes,
            awakeEndMinutes: household.awakeEndMinutes,
            members: members.map {
                .init(
                    id: $0.id,
                    displayName: $0.displayName,
                    emoji: $0.emoji,
                    accentHex: $0.accentHex,
                    sortOrder: $0.sortOrder
                )
            },
            tasks: tasks.map {
                .init(
                    id: $0.id,
                    title: $0.title,
                    iconSymbol: $0.iconSymbol,
                    roomRaw: $0.roomRaw,
                    scheduleModeRaw: $0.scheduleModeRaw,
                    intervalUnitRaw: $0.intervalUnitRaw,
                    intervalCount: $0.intervalCount,
                    fixedRuleKindRaw: $0.fixedRuleKindRaw,
                    fixedWeekdaysCSV: $0.fixedWeekdaysCSV,
                    fixedDayOfMonth: $0.fixedDayOfMonth,
                    lastCompletedAt: $0.lastCompletedAt,
                    lastCompletedByMemberID: $0.lastCompletedByMemberID,
                    energyLevelRaw: $0.energyLevelRaw,
                    estimatedMinutes: $0.estimatedMinutes,
                    sprintDurationMinutes: $0.sprintDurationMinutes,
                    remindersEnabled: $0.remindersEnabled,
                    nagIntervalMinutes: $0.nagIntervalMinutes,
                    intensityTierRaw: $0.intensityTierRaw,
                    alarmCutoffMinutes: $0.alarmCutoffMinutes,
                    assignmentModeRaw: $0.assignmentModeRaw,
                    assignedMemberIDsCSV: $0.assignedMemberIDsCSV,
                    currentTurnIndex: $0.currentTurnIndex,
                    totalCompletionsCount: $0.totalCompletionsCount,
                    deferralCount: $0.deferralCount
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    public func importHouseholdJSON(_ data: Data, in context: ModelContext) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(HouseholdBackupPayload.self, from: data)

        let existingHouseholds = try context.fetch(FetchDescriptor<Household>())
        let household: Household
        if let first = existingHouseholds.first {
            first.name = payload.householdName
            first.awakeStartMinutes = payload.awakeStartMinutes
            first.awakeEndMinutes = payload.awakeEndMinutes
            first.updatedAt = .now
            household = first
        } else {
            let newH = Household(
                id: payload.householdID,
                name: payload.householdName,
                awakeStartMinutes: payload.awakeStartMinutes,
                awakeEndMinutes: payload.awakeEndMinutes
            )
            context.insert(newH)
            household = newH
        }

        let existingMemberIDs = Set(try context.fetch(FetchDescriptor<HouseholdMember>()).map(\.id))
        for m in payload.members where !existingMemberIDs.contains(m.id) {
            context.insert(HouseholdMember(
                id: m.id,
                householdID: household.id,
                displayName: m.displayName,
                emoji: m.emoji,
                accentHex: m.accentHex,
                sortOrder: m.sortOrder
            ))
        }

        let existingTasksByID = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<ChoreTask>()).map { ($0.id, $0) }
        )
        for dto in payload.tasks {
            if let existing = existingTasksByID[dto.id] {
                existing.title = dto.title
                existing.iconSymbol = dto.iconSymbol
                existing.roomRaw = dto.roomRaw
                existing.lastCompletedAt = dto.lastCompletedAt
                existing.lastCompletedByMemberID = dto.lastCompletedByMemberID
                existing.currentTurnIndex = dto.currentTurnIndex
                existing.updatedAt = .now
            } else {
                let t = ChoreTask(
                    id: dto.id,
                    householdID: household.id,
                    title: dto.title,
                    iconSymbol: dto.iconSymbol,
                    room: RoomCategory(rawValue: dto.roomRaw) ?? .general,
                    scheduleMode: ScheduleMode(rawValue: dto.scheduleModeRaw) ?? .rollingFromLastDone,
                    intervalUnit: IntervalUnit(rawValue: dto.intervalUnitRaw) ?? .days,
                    intervalCount: dto.intervalCount,
                    fixedRuleKind: FixedCalendarRuleKind(rawValue: dto.fixedRuleKindRaw) ?? .weeklyDays,
                    lastCompletedAt: dto.lastCompletedAt,
                    lastCompletedByMemberID: dto.lastCompletedByMemberID,
                    energyLevel: EnergyLevel(rawValue: dto.energyLevelRaw) ?? .lowSpoons,
                    estimatedMinutes: dto.estimatedMinutes,
                    sprintDurationMinutes: dto.sprintDurationMinutes,
                    remindersEnabled: dto.remindersEnabled,
                    nagIntervalMinutes: dto.nagIntervalMinutes,
                    intensityTier: ReminderIntensityTier(rawValue: dto.intensityTierRaw) ?? .gentlePings,
                    alarmCutoffMinutes: dto.alarmCutoffMinutes,
                    assignmentMode: AssignmentMode(rawValue: dto.assignmentModeRaw) ?? .anyone,
                    currentTurnIndex: dto.currentTurnIndex
                )
                t.fixedWeekdaysCSV = dto.fixedWeekdaysCSV
                t.fixedDayOfMonth = dto.fixedDayOfMonth
                t.assignedMemberIDsCSV = dto.assignedMemberIDsCSV
                t.totalCompletionsCount = dto.totalCompletionsCount
                t.deferralCount = dto.deferralCount
                context.insert(t)
            }
        }

        try context.save()
        lastSyncedAt = .now
    }
}
