import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents
import ADHOUSEDCore
#if canImport(AlarmKit)
import AlarmKit
#endif

// MARK: - 1. Sticky Lock Screen Persistent Reminder Live Activity (Tier 2 & Tier 3)

struct ChoreNagLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChoreNagActivityAttributes.self) { context in
            let preset = ThemePreset(rawValue: context.state.themePresetRaw) ?? .warmTactileBento
            let theme = ADHOUSEDThemeTokens.resolve(preset: preset, colorScheme: .dark)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: context.attributes.iconSymbol)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(theme.dueNowColor)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(context.attributes.roomTitle.uppercased())
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(theme.dueNowColor)
                            if let emoji = context.state.responsibleMemberEmoji,
                               let name = context.state.responsibleMemberName {
                                Text("· \(emoji) \(name)'s Turn")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        Text(context.attributes.taskTitle)
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text("~\(context.attributes.estimatedMinutes)m")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.white.opacity(0.14)))
                }

                HStack(spacing: 8) {
                    Button(intent: CompleteTaskIntent(taskIDString: context.attributes.taskIDString, fromWidgetUndoable: false)) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark Done")
                        }
                        .font(.subheadline.weight(.heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: theme.pillCornerRadius).fill(theme.accentPrimary))
                        .foregroundStyle(theme.onAccentPrimary)
                    }
                    .buttonStyle(.plain)

                    Button(intent: PauseTaskRemindersIntent(taskIDString: context.attributes.taskIDString, pauseMinutes: 60)) {
                        HStack(spacing: 4) {
                            Image(systemName: "pause.fill")
                            Text(context.state.isPaused ? "Paused" : "Pause 1h")
                        }
                        .font(.caption.weight(.heavy))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 11).fill(.white.opacity(0.16)))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    Button(intent: PauseTaskRemindersIntent(taskIDString: "", pauseMinutes: 180)) {
                        Text("Away 3h")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 11).fill(.white.opacity(0.12)))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .activityBackgroundTint(Color(hex: "#151210"))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.attributes.iconSymbol)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("q\(context.state.nagIntervalMinutes)m")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.orange)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.taskTitle)
                        .font(.subheadline.weight(.heavy))
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        Button(intent: CompleteTaskIntent(taskIDString: context.attributes.taskIDString, fromWidgetUndoable: false)) {
                            Label("Done", systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.heavy))
                                .frame(maxWidth: .infinity)
                        }
                        Button(intent: PauseTaskRemindersIntent(taskIDString: context.attributes.taskIDString, pauseMinutes: 60)) {
                            Label("Pause 1h", systemImage: "pause.circle")
                                .font(.caption.weight(.bold))
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: context.attributes.iconSymbol)
                    .foregroundStyle(.orange)
            } compactTrailing: {
                Text("\(context.attributes.estimatedMinutes)m")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.orange)
            } minimal: {
                Image(systemName: context.attributes.iconSymbol)
                    .foregroundStyle(.orange)
            }
        }
    }
}

// MARK: - 2. "Beat the Clock" Sprint Countdown Live Activity

struct SprintTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SprintTimerActivityAttributes.self) { context in
            HStack(spacing: 14) {
                Image(systemName: "bolt.badge.clock.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: 3) {
                    Text("BEAT THE CLOCK SPRINT")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.yellow)
                    Text(context.attributes.taskTitle)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(timerInterval: context.state.startDate...context.state.targetEndDate, countsDown: true)
                        .font(.title3.weight(.black).monospacedDigit())
                        .foregroundStyle(.white)
                }

                Spacer()

                Button(intent: CompleteTaskIntent(taskIDString: context.attributes.taskIDString, fromWidgetUndoable: false)) {
                    VStack(spacing: 2) {
                        Image(systemName: "flag.checkered")
                            .font(.headline.weight(.bold))
                        Text("Done!")
                            .font(.caption2.weight(.heavy))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.green))
                    .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .activityBackgroundTint(Color(hex: "#141418"))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .foregroundStyle(.yellow)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.startDate...context.state.targetEndDate, countsDown: true)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.yellow)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button(intent: CompleteTaskIntent(taskIDString: context.attributes.taskIDString, fromWidgetUndoable: false)) {
                        Label("Finished Early — Mark Done!", systemImage: "checkmark.seal.fill")
                            .font(.caption.weight(.heavy))
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(.yellow)
            } compactTrailing: {
                Text(timerInterval: context.state.startDate...context.state.targetEndDate, countsDown: true)
                    .font(.caption2.monospacedDigit())
                    .frame(width: 42)
                    .foregroundStyle(.yellow)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(.yellow)
            }
        }
    }
}

// MARK: - 3. AlarmKit Tier-3 Cutoff System Alarm Live Activity Configuration

#if canImport(AlarmKit)
@available(iOS 26.1, *)
struct ChoreCutoffAlarmLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<ChoreAlarmMetadata>.self) { context in
            HStack(spacing: 12) {
                Image(systemName: "alarm.waves.left.and.right.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("ADHOUSED CUTOFF ALARM")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.orange)
                    Text(context.attributes.metadata?.taskTitle ?? "Critical Household Chore")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(14)
            .activityBackgroundTint(Color(hex: "#1A1210"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.metadata?.taskTitle ?? "Cutoff Alarm")
                        .font(.subheadline.weight(.heavy))
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                Text("Alarm")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.orange)
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(.orange)
            }
        }
    }
}
#endif
