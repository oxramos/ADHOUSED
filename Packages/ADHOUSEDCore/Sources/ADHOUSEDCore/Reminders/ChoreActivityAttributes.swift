import Foundation
import SwiftUI
#if os(iOS)
import ActivityKit
#endif
#if canImport(AlarmKit) && os(iOS)
import AlarmKit
#endif

// MARK: - Live Activity Attributes (Tier 2 Sticky Lock Screen + Beat-the-Clock Sprint)

#if os(iOS)
public struct ChoreNagActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var stageLabel: String
        public var batteryFill: Double
        public var nagIntervalMinutes: Int
        public var responsibleMemberName: String?
        public var responsibleMemberEmoji: String?
        public var isPaused: Bool
        public var pausedUntil: Date?
        public var themePresetRaw: String

        public init(
            stageLabel: String,
            batteryFill: Double,
            nagIntervalMinutes: Int,
            responsibleMemberName: String?,
            responsibleMemberEmoji: String?,
            isPaused: Bool,
            pausedUntil: Date?,
            themePresetRaw: String
        ) {
            self.stageLabel = stageLabel
            self.batteryFill = batteryFill
            self.nagIntervalMinutes = nagIntervalMinutes
            self.responsibleMemberName = responsibleMemberName
            self.responsibleMemberEmoji = responsibleMemberEmoji
            self.isPaused = isPaused
            self.pausedUntil = pausedUntil
            self.themePresetRaw = themePresetRaw
        }
    }

    public var taskIDString: String
    public var taskTitle: String
    public var iconSymbol: String
    public var roomTitle: String
    public var estimatedMinutes: Int

    public init(
        taskIDString: String,
        taskTitle: String,
        iconSymbol: String,
        roomTitle: String,
        estimatedMinutes: Int
    ) {
        self.taskIDString = taskIDString
        self.taskTitle = taskTitle
        self.iconSymbol = iconSymbol
        self.roomTitle = roomTitle
        self.estimatedMinutes = estimatedMinutes
    }
}

public struct SprintTimerActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var startDate: Date
        public var targetEndDate: Date
        public var durationMinutes: Int
        public var themePresetRaw: String

        public init(
            startDate: Date,
            targetEndDate: Date,
            durationMinutes: Int,
            themePresetRaw: String
        ) {
            self.startDate = startDate
            self.targetEndDate = targetEndDate
            self.durationMinutes = durationMinutes
            self.themePresetRaw = themePresetRaw
        }
    }

    public var taskIDString: String
    public var taskTitle: String
    public var iconSymbol: String
    public var roomTitle: String

    public init(
        taskIDString: String,
        taskTitle: String,
        iconSymbol: String,
        roomTitle: String
    ) {
        self.taskIDString = taskIDString
        self.taskTitle = taskTitle
        self.iconSymbol = iconSymbol
        self.roomTitle = roomTitle
    }
}
#endif

// MARK: - AlarmKit Metadata (Tier 3 Un-ignorable Cutoff System Alarm)

#if canImport(AlarmKit) && os(iOS)
@available(iOS 26.0, *)
public struct ChoreAlarmMetadata: AlarmMetadata, Sendable {
    public var taskIDString: String
    public var taskTitle: String
    public var roomTitle: String

    public init(taskIDString: String, taskTitle: String, roomTitle: String) {
        self.taskIDString = taskIDString
        self.taskTitle = taskTitle
        self.roomTitle = roomTitle
    }
}
#endif
