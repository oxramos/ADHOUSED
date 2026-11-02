import SwiftUI
import SwiftData
import ADHOUSEDCore

struct SprintTimerOverlayView: View {
    @Environment(\.adhousedTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var session: AppSessionViewModel
    let task: ChoreTask

    private let presetMinutes = [2, 5, 10, 15]

    var body: some View {
        ZStack {
            theme.canvasBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Label("BEAT THE CLOCK SPRINT", systemImage: "bolt.badge.clock.fill")
                        .font(.caption.weight(.heavy))
                        .tracking(1.0)
                        .foregroundStyle(theme.warmingColor)
                    Spacer()
                    Button("Minimize") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.secondaryInk)
                }

                VStack(spacing: 6) {
                    SalientText(
                        task.title,
                        font: .title2.weight(.heavy),
                        color: theme.primaryInk
                    )
                    .multilineTextAlignment(.center)

                    Text("Turn a boring chore into a quick dopamine race — pinned to your Lock Screen while active.")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryInk)
                        .multilineTextAlignment(.center)
                }

                // Live Animated Countdown Ring
                TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
                    let active = session.activeSprint?.taskID == task.id ? session.activeSprint : nil
                    let totalSec = Double(active?.durationSeconds ?? (task.sprintDurationMinutes * 60))
                    let remSec = active != nil ? max(0, active!.targetEndDate.timeIntervalSince(timeline.date)) : totalSec
                    let progress = totalSec > 0 ? (remSec / totalSec) : 1.0
                    let mins = Int(remSec) / 60
                    let secs = Int(remSec) % 60

                    ZStack {
                        Circle()
                            .stroke(theme.canvasSecondary, lineWidth: 18)
                            .frame(width: 215, height: 215)

                        Circle()
                            .trim(from: 0, to: max(0.02, progress))
                            .stroke(
                                progress > 0.3 ? theme.accentPrimary : theme.dueNowColor,
                                style: StrokeStyle(lineWidth: 18, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 215, height: 215)
                            .animation(.linear(duration: 0.25), value: progress)

                        VStack(spacing: 4) {
                            Image(systemName: task.iconSymbol)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(theme.accentPrimary)
                            Text(String(format: "%02d:%02d", mins, secs))
                                .font(.system(size: 46, weight: .black, design: theme.isTerminalHUD ? .monospaced : .rounded))
                                .monospacedDigit()
                                .foregroundStyle(theme.primaryInk)
                            Text(remSec > 0 ? "RACING" : "TIME'S UP!")
                                .font(.caption2.weight(.heavy))
                                .tracking(1.2)
                                .foregroundStyle(theme.secondaryInk)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Sprint Duration Switcher Chips
                HStack(spacing: 10) {
                    ForEach(presetMinutes, id: \.self) { mins in
                        let isCurrent = (session.activeSprint?.durationSeconds ?? (task.sprintDurationMinutes * 60)) == mins * 60
                        Button {
                            task.sprintDurationMinutes = mins
                            try? modelContext.save()
                            session.startBeatTheClockSprint(for: task, minutes: mins)
                        } label: {
                            Text("\(mins) min")
                                .font(.subheadline.weight(.bold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                        }
                        .buttonStyle(
                            TactileActionButtonStyle(
                                fill: isCurrent ? theme.warmingColor : theme.cardSurface,
                                foreground: isCurrent ? .black : theme.primaryInk
                            )
                        )
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        let elapsed: Int? = {
                            guard let started = session.activeSprint?.startedAt else { return nil }
                            return max(1, Int(Date().timeIntervalSince(started)))
                        }()
                        session.triggerCompletionWithToast(task: task, sprintSeconds: elapsed, in: modelContext)
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "flag.checkered.2.crossed")
                            Text("Beat the Clock — Mark Done!")
                        }
                        .font(.headline.weight(.heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(
                        TactileActionButtonStyle(
                            fill: theme.accentPrimary,
                            foreground: theme.onAccentPrimary
                        )
                    )

                    Button("Stop Timer Without Completing") {
                        session.cancelActiveSprint()
                        dismiss()
                    }
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(theme.secondaryInk)
                }
            }
            .padding(22)
        }
        .presentationDetents([.fraction(0.76), .large])
    }
}
