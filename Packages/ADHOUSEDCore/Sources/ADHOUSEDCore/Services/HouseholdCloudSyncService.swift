import Foundation
import SwiftData
import CloudKit

public enum CloudSyncAvailabilityState: Equatable, Sendable {
    case localMultiMemberMode(reason: String)
    case readyForCloudShare
    case activelySharedHousehold(roleSummary: String)
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
        public let isArchived: Bool
        public let scheduleModeRaw: String
        public let intervalUnitRaw: String
        public let intervalCount: Int
        public let fixedRuleKindRaw: String
        public let fixedWeekdaysCSV: String
        public let fixedDayOfMonth: Int
        public let lastCompletedAt: Date?
        public let lastCompletedByMemberID: UUID?
        public let updatedAt: Date?
        public let pausedUntil: Date?
        public let deferredUntilDate: Date?
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
    public let vacationBreaks: [VacationBreakWindow]?
    public let customCatalogTemplates: [StarterChoreTemplate]?
}

@MainActor
@Observable
public final class HouseholdCloudSyncService {
    public static let shared = HouseholdCloudSyncService()
    public static let zoneName = "ADHOUSEDHouseholdZone"

    public private(set) var availabilityState: CloudSyncAvailabilityState = .localMultiMemberMode(
        reason: "Checking iCloud status…"
    )
    public private(set) var isSyncing: Bool = false
    public private(set) var lastSyncedAt: Date?
    public private(set) var lastSyncErrorMessage: String?

    private init() {
        refreshAvailability()
    }

    public func refreshAvailability(hasExistingShare: Bool? = nil) {
        guard Self.binaryHasCloudKitContainerEntitlement() else {
            availabilityState = .localMultiMemberMode(
                reason: "iCloud Sharing is disabled in this Simulator/local build. Use Share File Backup below or build with Team signing on iPhone."
            )
            return
        }

        guard FileManager.default.ubiquityIdentityToken != nil else {
            availabilityState = .localMultiMemberMode(
                reason: "Sign in to iCloud in iOS Settings on this iPhone to invite your partner via iCloud."
            )
            return
        }

        let prefs = ADHOUSEDPreferences.shared
        let sharedActive = hasExistingShare ?? (prefs.isAcceptedCloudShareParticipant || prefs.cloudShareURLString != nil)
        if sharedActive {
            let role = prefs.isAcceptedCloudShareParticipant
                ? "Joined Partner's Shared Home"
                : "Sharing Home via iCloud"
            availabilityState = .activelySharedHousehold(roleSummary: role)
        } else {
            availabilityState = .readyForCloudShare
        }
    }

    private static func binaryHasCloudKitContainerEntitlement() -> Bool {
        guard Bundle.main.object(forInfoDictionaryKey: "ADHOUSEDCloudKitContainerEnabled") as? Bool == true else {
            return false
        }
        return true
    }

    private var activeZoneID: CKRecordZone.ID {
        let prefs = ADHOUSEDPreferences.shared
        if prefs.isAcceptedCloudShareParticipant,
           let owner = prefs.cloudShareZoneOwnerName,
           !owner.isEmpty {
            return CKRecordZone.ID(zoneName: Self.zoneName, ownerName: owner)
        }
        return CKRecordZone.ID(zoneName: Self.zoneName, ownerName: CKCurrentUserDefaultName)
    }

    private func activeDatabase(in container: CKContainer) -> CKDatabase {
        ADHOUSEDPreferences.shared.isAcceptedCloudShareParticipant
            ? container.sharedCloudDatabase
            : container.privateCloudDatabase
    }

    // MARK: - 1. Prepare or Retrieve Live `CKShare` for `UICloudSharingController`

    public func prepareHouseholdCloudShare(
        for household: Household,
        tasks: [ChoreTask],
        members: [HouseholdMember]
    ) async throws -> (share: CKShare, container: CKContainer) {
        refreshAvailability()
        switch availabilityState {
        case .readyForCloudShare, .activelySharedHousehold:
            break
        case .localMultiMemberMode(let reason):
            throw NSError(
                domain: "ADHOUSED.CloudSync",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: reason]
            )
        }

        isSyncing = true
        lastSyncErrorMessage = nil
        defer { isSyncing = false }

        let container = CKContainer(identifier: SharedAppGroup.iCloudContainerID)
        let db = activeDatabase(in: container)
        let zoneID = activeZoneID

        if !ADHOUSEDPreferences.shared.isAcceptedCloudShareParticipant {
            let zone = CKRecordZone(zoneID: zoneID)
            _ = try await db.modifyRecordZones(saving: [zone], deleting: [])
        }

        let rootRecordID = CKRecord.ID(recordName: "Household-Primary", zoneID: zoneID)
        let rootRecord: CKRecord
        if let fetched = try? await db.record(for: rootRecordID) {
            rootRecord = fetched
        } else {
            rootRecord = CKRecord(recordType: "Household", recordID: rootRecordID)
        }

        populateHouseholdRecord(rootRecord, from: household)

        // Reuse existing CKShare if already linked on the root record
        let share: CKShare
        if let shareRef = rootRecord.share,
           let existingShare = try? await db.record(for: shareRef.recordID) as? CKShare {
            share = existingShare
            share[CKShare.SystemFieldKey.title] = "\(household.name) — ADHOUSED Home" as CKRecordValue
        } else {
            let newShare = CKShare(rootRecord: rootRecord)
            newShare[CKShare.SystemFieldKey.title] = "\(household.name) — ADHOUSED Home" as CKRecordValue
            newShare.publicPermission = .readWrite
            share = newShare
        }

        var recordsToSave: [CKRecord] = [rootRecord, share]

        for member in members {
            let recID = CKRecord.ID(recordName: "Member-\(member.id.uuidString)", zoneID: zoneID)
            let rec = (try? await db.record(for: recID)) ?? CKRecord(recordType: "HouseholdMember", recordID: recID)
            rec.parent = CKRecord.Reference(recordID: rootRecordID, action: .none)
            populateMemberRecord(rec, from: member)
            recordsToSave.append(rec)
        }

        for task in tasks {
            let recID = CKRecord.ID(recordName: "ChoreTask-\(task.id.uuidString)", zoneID: zoneID)
            let rec = (try? await db.record(for: recID)) ?? CKRecord(recordType: "ChoreTask", recordID: recID)
            rec.parent = CKRecord.Reference(recordID: rootRecordID, action: .none)
            populateTaskRecord(rec, from: task)
            recordsToSave.append(rec)
        }

        let (saveResults, _) = try await db.modifyRecords(saving: recordsToSave, deleting: [], savePolicy: .allKeys)

        var savedShare: CKShare = share
        for (_, result) in saveResults {
            if let record = try? result.get(), let ckShare = record as? CKShare {
                savedShare = ckShare
            }
        }

        if let shareURL = savedShare.url?.absoluteString {
            ADHOUSEDPreferences.shared.cloudShareURLString = shareURL
        }
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        savedShare.encodeSystemFields(with: archiver)
        archiver.finishEncoding()
        household.cloudShareRecordData = archiver.encodedData

        await ensureDatabaseSubscription(in: db)

        lastSyncedAt = .now
        refreshAvailability(hasExistingShare: true)
        return (savedShare, container)
    }

    // MARK: - 2. Accept Incoming Partner iCloud Share Link (`windowScene(_:userDidAcceptCloudKitShareWith:)`)

    public func acceptShareInvitation(
        metadata: CKShare.Metadata,
        in context: ModelContext
    ) async throws {
        isSyncing = true
        lastSyncErrorMessage = nil
        defer { isSyncing = false }

        let container = CKContainer(identifier: metadata.containerIdentifier)
        _ = try await container.accept(metadata)

        let rootZoneID = metadata.hierarchicalRootRecordID?.zoneID ?? metadata.share.recordID.zoneID
        let prefs = ADHOUSEDPreferences.shared
        prefs.isAcceptedCloudShareParticipant = true
        prefs.cloudShareZoneOwnerName = rootZoneID.ownerName
        if let urlStr = metadata.share.url?.absoluteString {
            prefs.cloudShareURLString = urlStr
        }

        await ensureDatabaseSubscription(in: container.sharedCloudDatabase)
        try await syncWithCloud(in: context)
        refreshAvailability(hasExistingShare: true)
    }

    // MARK: - 3. Bidirectional Live CloudKit Sync (Owner & Partner)

    public func pushChangesIfConnected(in context: ModelContext) {
        let prefs = ADHOUSEDPreferences.shared
        guard prefs.isAcceptedCloudShareParticipant || prefs.cloudShareURLString != nil else { return }
        Task { @MainActor in
            try? await self.syncWithCloud(in: context)
        }
    }

    public func syncWithCloud(in context: ModelContext) async throws {
        refreshAvailability()
        guard Self.binaryHasCloudKitContainerEntitlement(),
              FileManager.default.ubiquityIdentityToken != nil else {
            return
        }

        let prefs = ADHOUSEDPreferences.shared
        // If user hasn't started or accepted a share yet, locate any shared zone in sharedCloudDatabase automatically!
        let container = CKContainer(identifier: SharedAppGroup.iCloudContainerID)
        if !prefs.isAcceptedCloudShareParticipant && prefs.cloudShareURLString == nil {
            if let discoveredSharedZone = try? await container.sharedCloudDatabase.allRecordZones().first(where: { $0.zoneID.zoneName == Self.zoneName }) {
                prefs.isAcceptedCloudShareParticipant = true
                prefs.cloudShareZoneOwnerName = discoveredSharedZone.zoneID.ownerName
                refreshAvailability(hasExistingShare: true)
            } else {
                // Not actively sharing yet
                return
            }
        }

        isSyncing = true
        lastSyncErrorMessage = nil
        defer { isSyncing = false }

        do {
            let db = activeDatabase(in: container)
            let zoneID = activeZoneID

            // Ensure zone exists if owner
            if !prefs.isAcceptedCloudShareParticipant {
                let zone = CKRecordZone(zoneID: zoneID)
                _ = try? await db.modifyRecordZones(saving: [zone], deleting: [])
            }

            let rootRecordID = CKRecord.ID(recordName: "Household-Primary", zoneID: zoneID)

            // 1. Pull remote records in zone
            let remoteHousehold = try? await db.record(for: rootRecordID)
            let remoteMembers = await queryAllRecords(ofType: "HouseholdMember", in: zoneID, database: db)
            let remoteTasks = await queryAllRecords(ofType: "ChoreTask", in: zoneID, database: db)

            // 2. Reconcile Household
            let localHouseholds = try context.fetch(FetchDescriptor<Household>())
            let localHousehold: Household
            if let first = localHouseholds.first {
                localHousehold = first
            } else {
                let created = Household(name: "Shared Home")
                context.insert(created)
                localHousehold = created
            }

            var recordsToPush: [CKRecord] = []

            if let remoteH = remoteHousehold {
                let remoteUpdated = (remoteH["updatedAt"] as? Date) ?? remoteH.modificationDate ?? .distantPast
                if remoteUpdated > localHousehold.updatedAt.addingTimeInterval(1) || prefs.isAcceptedCloudShareParticipant && localHousehold.name == "Our Home" {
                    applyHouseholdRecord(remoteH, to: localHousehold)
                } else if localHousehold.updatedAt > remoteUpdated.addingTimeInterval(1) {
                    populateHouseholdRecord(remoteH, from: localHousehold)
                    recordsToPush.append(remoteH)
                }
            } else if !prefs.isAcceptedCloudShareParticipant {
                let newRoot = CKRecord(recordType: "Household", recordID: rootRecordID)
                populateHouseholdRecord(newRoot, from: localHousehold)
                recordsToPush.append(newRoot)
            }

            // 3. Reconcile Members
            let existingMembers = try context.fetch(FetchDescriptor<HouseholdMember>())
            var localMembersByID = Dictionary(uniqueKeysWithValues: existingMembers.map { ($0.id, $0) })
            var seenRemoteMemberIDs: Set<UUID> = []

            for rec in remoteMembers {
                guard let idStr = rec["memberUUID"] as? String ?? rec.recordID.recordName.replacingOccurrences(of: "Member-", with: "") as String?,
                      let uuid = UUID(uuidString: idStr) else { continue }
                seenRemoteMemberIDs.insert(uuid)

                if let existing = localMembersByID[uuid] {
                    existing.displayName = (rec["displayName"] as? String) ?? existing.displayName
                    existing.emoji = (rec["emoji"] as? String) ?? existing.emoji
                    existing.accentHex = (rec["accentHex"] as? String) ?? existing.accentHex
                } else {
                    let member = HouseholdMember(
                        id: uuid,
                        householdID: localHousehold.id,
                        displayName: (rec["displayName"] as? String) ?? "Partner",
                        emoji: (rec["emoji"] as? String) ?? "🦦",
                        accentHex: (rec["accentHex"] as? String) ?? "#3B66FF",
                        sortOrder: (rec["sortOrder"] as? Int) ?? localMembersByID.count
                    )
                    context.insert(member)
                    localMembersByID[uuid] = member
                }
            }

            for (uuid, member) in localMembersByID where !seenRemoteMemberIDs.contains(uuid) {
                let recID = CKRecord.ID(recordName: "Member-\(uuid.uuidString)", zoneID: zoneID)
                let rec = CKRecord(recordType: "HouseholdMember", recordID: recID)
                rec.parent = CKRecord.Reference(recordID: rootRecordID, action: .none)
                populateMemberRecord(rec, from: member)
                recordsToPush.append(rec)
            }

            // 4. Reconcile ChoreTasks (bidirectional merge by `updatedAt`)
            let existingTasks = try context.fetch(FetchDescriptor<ChoreTask>())
            var localTasksByID = Dictionary(uniqueKeysWithValues: existingTasks.map { ($0.id, $0) })
            var remoteTasksByID: [UUID: CKRecord] = [:]

            for rec in remoteTasks {
                let rawID = (rec["taskUUID"] as? String) ?? rec.recordID.recordName.replacingOccurrences(of: "ChoreTask-", with: "")
                guard let uuid = UUID(uuidString: rawID) else { continue }
                remoteTasksByID[uuid] = rec

                let remoteUpdated = (rec["updatedAt"] as? Date) ?? rec.modificationDate ?? .distantPast
                if let local = localTasksByID[uuid] {
                    if remoteUpdated > local.updatedAt.addingTimeInterval(0.5) {
                        applyTaskRecord(rec, to: local)
                    } else if local.updatedAt > remoteUpdated.addingTimeInterval(0.5) {
                        populateTaskRecord(rec, from: local)
                        recordsToPush.append(rec)
                    }
                } else {
                    let newTask = makeLocalTask(from: rec, uuid: uuid, householdID: localHousehold.id)
                    context.insert(newTask)
                    localTasksByID[uuid] = newTask
                }
            }

            for (uuid, localTask) in localTasksByID where remoteTasksByID[uuid] == nil {
                let recID = CKRecord.ID(recordName: "ChoreTask-\(uuid.uuidString)", zoneID: zoneID)
                let rec = CKRecord(recordType: "ChoreTask", recordID: recID)
                rec.parent = CKRecord.Reference(recordID: rootRecordID, action: .none)
                populateTaskRecord(rec, from: localTask)
                recordsToPush.append(rec)
            }

            if !recordsToPush.isEmpty {
                _ = try await db.modifyRecords(saving: recordsToPush, deleting: [], savePolicy: .allKeys)
            }

            if prefs.activeMemberID == nil, let firstMember = localMembersByID.values.sorted(by: { $0.sortOrder < $1.sortOrder }).first {
                prefs.activeMemberID = firstMember.id
            }

            try context.save()
            lastSyncedAt = .now
            TaskActionService.awaitableReconcileAndReloadWidgets(in: context)
        } catch {
            lastSyncErrorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - CloudKit Record Mapping Helpers

    private func queryAllRecords(ofType recordType: String, in zoneID: CKRecordZone.ID, database: CKDatabase) async -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        guard let (matchResults, _) = try? await database.records(matching: query, inZoneWith: zoneID) else {
            return []
        }
        return matchResults.compactMap { try? $0.1.get() }
    }

    private func ensureDatabaseSubscription(in database: CKDatabase) async {
        let subID = database.databaseScope == .shared ? "adhoused-shared-changes" : "adhoused-private-changes"
        let sub = CKDatabaseSubscription(subscriptionID: subID)
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        sub.notificationInfo = info
        _ = try? await database.modifySubscriptions(saving: [sub], deleting: [])
    }

    private func populateHouseholdRecord(_ record: CKRecord, from household: Household) {
        let prefs = ADHOUSEDPreferences.shared
        record["householdUUID"] = household.id.uuidString as CKRecordValue
        record["name"] = household.name as CKRecordValue
        record["awakeStartMinutes"] = household.awakeStartMinutes as CKRecordValue
        record["awakeEndMinutes"] = household.awakeEndMinutes as CKRecordValue
        record["updatedAt"] = household.updatedAt as CKRecordValue
        record["awayPauseUntil"] = household.awayPauseUntil as CKRecordValue?
        if let breaksData = try? JSONEncoder().encode(prefs.vacationBreaks) {
            record["vacationBreaksJSON"] = breaksData as CKRecordValue
        }
        if let catalogData = try? JSONEncoder().encode(prefs.customCatalogTemplates) {
            record["customCatalogJSON"] = catalogData as CKRecordValue
        }
    }

    private func applyHouseholdRecord(_ record: CKRecord, to household: Household) {
        if let name = record["name"] as? String { household.name = name }
        if let start = record["awakeStartMinutes"] as? Int { household.awakeStartMinutes = start }
        if let end = record["awakeEndMinutes"] as? Int { household.awakeEndMinutes = end }
        household.awayPauseUntil = record["awayPauseUntil"] as? Date
        household.updatedAt = (record["updatedAt"] as? Date) ?? .now

        let prefs = ADHOUSEDPreferences.shared
        if let breaksData = record["vacationBreaksJSON"] as? Data,
           let breaks = try? JSONDecoder().decode([VacationBreakWindow].self, from: breaksData) {
            prefs.vacationBreaks = breaks
        }
        if let catalogData = record["customCatalogJSON"] as? Data,
           let templates = try? JSONDecoder().decode([StarterChoreTemplate].self, from: catalogData),
           !templates.isEmpty {
            prefs.customCatalogTemplates = templates
        }
        prefs.hasCompletedOnboarding = true
    }

    private func populateMemberRecord(_ record: CKRecord, from member: HouseholdMember) {
        record["memberUUID"] = member.id.uuidString as CKRecordValue
        record["displayName"] = member.displayName as CKRecordValue
        record["emoji"] = member.emoji as CKRecordValue
        record["accentHex"] = member.accentHex as CKRecordValue
        record["sortOrder"] = member.sortOrder as CKRecordValue
    }

    private func populateTaskRecord(_ record: CKRecord, from task: ChoreTask) {
        record["taskUUID"] = task.id.uuidString as CKRecordValue
        record["title"] = task.title as CKRecordValue
        record["iconSymbol"] = task.iconSymbol as CKRecordValue
        record["roomRaw"] = task.roomRaw as CKRecordValue
        record["isArchived"] = (task.isArchived ? 1 : 0) as CKRecordValue
        record["scheduleModeRaw"] = task.scheduleModeRaw as CKRecordValue
        record["intervalUnitRaw"] = task.intervalUnitRaw as CKRecordValue
        record["intervalCount"] = task.intervalCount as CKRecordValue
        record["fixedRuleKindRaw"] = task.fixedRuleKindRaw as CKRecordValue
        record["fixedWeekdaysCSV"] = task.fixedWeekdaysCSV as CKRecordValue
        record["fixedDayOfMonth"] = task.fixedDayOfMonth as CKRecordValue
        record["energyLevelRaw"] = task.energyLevelRaw as CKRecordValue
        record["estimatedMinutes"] = task.estimatedMinutes as CKRecordValue
        record["sprintDurationMinutes"] = task.sprintDurationMinutes as CKRecordValue
        record["remindersEnabled"] = (task.remindersEnabled ? 1 : 0) as CKRecordValue
        record["nagIntervalMinutes"] = task.nagIntervalMinutes as CKRecordValue
        record["intensityTierRaw"] = task.intensityTierRaw as CKRecordValue
        record["alarmCutoffMinutes"] = task.alarmCutoffMinutes as CKRecordValue
        record["assignmentModeRaw"] = task.assignmentModeRaw as CKRecordValue
        record["assignedMemberIDsCSV"] = task.assignedMemberIDsCSV as CKRecordValue
        record["currentTurnIndex"] = task.currentTurnIndex as CKRecordValue
        record["totalCompletionsCount"] = task.totalCompletionsCount as CKRecordValue
        record["deferralCount"] = task.deferralCount as CKRecordValue
        record["updatedAt"] = task.updatedAt as CKRecordValue
        record["lastCompletedAt"] = task.lastCompletedAt as CKRecordValue?
        record["lastCompletedByMemberID"] = task.lastCompletedByMemberID?.uuidString as CKRecordValue?
        record["pausedUntil"] = task.pausedUntil as CKRecordValue?
        record["deferredUntilDate"] = task.deferredUntilDate as CKRecordValue?
    }

    private func applyTaskRecord(_ record: CKRecord, to task: ChoreTask) {
        if let title = record["title"] as? String { task.title = title }
        if let sym = record["iconSymbol"] as? String { task.iconSymbol = sym }
        if let room = record["roomRaw"] as? String { task.roomRaw = room }
        if let archived = record["isArchived"] as? Int { task.isArchived = (archived != 0) }
        if let mode = record["scheduleModeRaw"] as? String { task.scheduleModeRaw = mode }
        if let unit = record["intervalUnitRaw"] as? String { task.intervalUnitRaw = unit }
        if let count = record["intervalCount"] as? Int { task.intervalCount = count }
        if let fk = record["fixedRuleKindRaw"] as? String { task.fixedRuleKindRaw = fk }
        if let csv = record["fixedWeekdaysCSV"] as? String { task.fixedWeekdaysCSV = csv }
        if let dom = record["fixedDayOfMonth"] as? Int { task.fixedDayOfMonth = dom }
        if let energy = record["energyLevelRaw"] as? String { task.energyLevelRaw = energy }
        if let mins = record["estimatedMinutes"] as? Int { task.estimatedMinutes = mins }
        if let sprint = record["sprintDurationMinutes"] as? Int { task.sprintDurationMinutes = sprint }
        if let rem = record["remindersEnabled"] as? Int { task.remindersEnabled = (rem != 0) }
        if let nag = record["nagIntervalMinutes"] as? Int { task.nagIntervalMinutes = nag }
        if let tier = record["intensityTierRaw"] as? String { task.intensityTierRaw = tier }
        if let cutoff = record["alarmCutoffMinutes"] as? Int { task.alarmCutoffMinutes = cutoff }
        if let assign = record["assignmentModeRaw"] as? String { task.assignmentModeRaw = assign }
        if let assignedCSV = record["assignedMemberIDsCSV"] as? String { task.assignedMemberIDsCSV = assignedCSV }
        if let turn = record["currentTurnIndex"] as? Int { task.currentTurnIndex = turn }
        if let comps = record["totalCompletionsCount"] as? Int { task.totalCompletionsCount = comps }
        if let defs = record["deferralCount"] as? Int { task.deferralCount = defs }
        task.lastCompletedAt = record["lastCompletedAt"] as? Date
        if let actorStr = record["lastCompletedByMemberID"] as? String {
            task.lastCompletedByMemberID = UUID(uuidString: actorStr)
        }
        task.pausedUntil = record["pausedUntil"] as? Date
        task.deferredUntilDate = record["deferredUntilDate"] as? Date
        task.updatedAt = (record["updatedAt"] as? Date) ?? .now
    }

    private func makeLocalTask(from record: CKRecord, uuid: UUID, householdID: UUID) -> ChoreTask {
        let task = ChoreTask(
            id: uuid,
            householdID: householdID,
            title: (record["title"] as? String) ?? "Shared Chore",
            iconSymbol: (record["iconSymbol"] as? String) ?? "sparkles",
            room: RoomCategory(rawValue: (record["roomRaw"] as? String) ?? "") ?? .general
        )
        applyTaskRecord(record, to: task)
        return task
    }

    // MARK: - 4. Portable Household Snapshot Export & Import (Works Offline & via iMessage/AirDrop)

    public func exportHouseholdJSON(in context: ModelContext) throws -> Data {
        let household = try context.fetch(FetchDescriptor<Household>()).first ?? Household()
        let members = try context.fetch(FetchDescriptor<HouseholdMember>(sortBy: [SortDescriptor(\.sortOrder)]))
        let tasks = try context.fetch(FetchDescriptor<ChoreTask>())
        let prefs = ADHOUSEDPreferences.shared

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
                    isArchived: $0.isArchived,
                    scheduleModeRaw: $0.scheduleModeRaw,
                    intervalUnitRaw: $0.intervalUnitRaw,
                    intervalCount: $0.intervalCount,
                    fixedRuleKindRaw: $0.fixedRuleKindRaw,
                    fixedWeekdaysCSV: $0.fixedWeekdaysCSV,
                    fixedDayOfMonth: $0.fixedDayOfMonth,
                    lastCompletedAt: $0.lastCompletedAt,
                    lastCompletedByMemberID: $0.lastCompletedByMemberID,
                    updatedAt: $0.updatedAt,
                    pausedUntil: $0.pausedUntil,
                    deferredUntilDate: $0.deferredUntilDate,
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
            },
            vacationBreaks: prefs.vacationBreaks,
            customCatalogTemplates: prefs.customCatalogTemplates
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

        let existingMembersByID = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<HouseholdMember>()).map { ($0.id, $0) }
        )
        for m in payload.members {
            if let existing = existingMembersByID[m.id] {
                existing.displayName = m.displayName
                existing.emoji = m.emoji
                existing.accentHex = m.accentHex
                existing.sortOrder = m.sortOrder
            } else {
                context.insert(HouseholdMember(
                    id: m.id,
                    householdID: household.id,
                    displayName: m.displayName,
                    emoji: m.emoji,
                    accentHex: m.accentHex,
                    sortOrder: m.sortOrder
                ))
            }
        }

        let existingTasksByID = Dictionary(
            uniqueKeysWithValues: try context.fetch(FetchDescriptor<ChoreTask>()).map { ($0.id, $0) }
        )
        for dto in payload.tasks {
            if let existing = existingTasksByID[dto.id] {
                existing.title = dto.title
                existing.iconSymbol = dto.iconSymbol
                existing.roomRaw = dto.roomRaw
                existing.isArchived = dto.isArchived
                existing.lastCompletedAt = dto.lastCompletedAt
                existing.lastCompletedByMemberID = dto.lastCompletedByMemberID
                existing.currentTurnIndex = dto.currentTurnIndex
                existing.pausedUntil = dto.pausedUntil
                existing.deferredUntilDate = dto.deferredUntilDate
                existing.updatedAt = dto.updatedAt ?? .now
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
                t.isArchived = dto.isArchived
                t.fixedWeekdaysCSV = dto.fixedWeekdaysCSV
                t.fixedDayOfMonth = dto.fixedDayOfMonth
                t.assignedMemberIDsCSV = dto.assignedMemberIDsCSV
                t.totalCompletionsCount = dto.totalCompletionsCount
                t.deferralCount = dto.deferralCount
                t.pausedUntil = dto.pausedUntil
                t.deferredUntilDate = dto.deferredUntilDate
                context.insert(t)
            }
        }

        let prefs = ADHOUSEDPreferences.shared
        if let breaks = payload.vacationBreaks {
            prefs.vacationBreaks = breaks
        }
        if let customCatalog = payload.customCatalogTemplates, !customCatalog.isEmpty {
            prefs.customCatalogTemplates = customCatalog
        }
        prefs.hasCompletedOnboarding = true

        try context.save()
        lastSyncedAt = .now
    }
}
