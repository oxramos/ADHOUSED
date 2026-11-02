import SwiftUI
import SwiftData
import ADHOUSEDCore

struct DeferTaskSheet: View {
    @Environment(\.adhousedTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let task: ChoreTask
    let onStartTwoMinuteSprintInstead: () -> Void
    var onOpenVacationBreakMode: (() -> Void)? = nil

    @State private var selectedReason: String = "Low energy or busy today"
    @State private var useCustomPauseDate: Bool = false
    @State private var customPauseUntil: Date = Date.now.addingTimeInterval(2 * 86_400)

    private let reasons = [
        "Low energy or busy today",
        "Away from home tonight",
        "Missing supplies right now",
        "Planning to do it tomorrow"
    ]

    var body: some View {
        ZStack {
            theme.canvasBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Label("MOVE TO TOMORROW", systemImage: "sunrise.fill")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(theme.warmingColor)
                        Spacer()
                        Button("Cancel") { dismiss() }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(theme.secondaryInk)
                    }

                    SalientText(
                        "Move \"\(task.title)\" to Tomorrow Morning?",
                        font: .title3.weight(.heavy),
                        color: theme.primaryInk
                    )

                    Text("Moving a chore to tomorrow pauses reminders for the rest of today and brings it back tomorrow morning.")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)

                    // Quick 2-Minute Focus Option
                    Button {
                        onStartTwoMinuteSprintInstead()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "timer")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Or try just 2 minutes right now?")
                                    .font(.subheadline.weight(.heavy))
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Even a quick 2-minute tidy counts — tap to start a 2m timer.")
                                    .font(.caption2)
                                    .opacity(0.9)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(14)
                    }
                    .buttonStyle(
                        TactileActionButtonStyle(
                            fill: theme.accentPrimary,
                            foreground: theme.onAccentPrimary
                        )
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why tomorrow works better:")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.secondaryInk)

                        ForEach(reasons, id: \.self) { reason in
                            let chosen = selectedReason == reason
                            Button {
                                selectedReason = reason
                            } label: {
                                HStack {
                                    Text(reason)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(theme.primaryInk)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                    Image(systemName: chosen ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(chosen ? theme.warmingColor : theme.secondaryInk)
                                }
                                .padding(11)
                                .background(
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .fill(chosen ? theme.warmingColor.opacity(0.16) : theme.cardSurface)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let onOpenVacationBreakMode {
                        Button {
                            HapticsEngine.shared.playMechanicalTap()
                            onOpenVacationBreakMode()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "tree.fill")
                                    .font(.headline)
                                    .foregroundStyle(theme.warmingColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Going out of town or on a weekend trip?")
                                        .font(.caption.weight(.heavy))
                                        .foregroundStyle(theme.primaryInk)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text("Pause ALL chores & notifications from Date & Time → Date & Time")
                                        .font(.caption2)
                                        .foregroundStyle(theme.secondaryInk)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(theme.secondaryInk)
                            }
                            .padding(12)
                            .adhousedCard(highlightTint: theme.warmingColor, compact: true)
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $useCustomPauseDate) {
                            Text("Pause this chore until a specific Date & Time")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(theme.primaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .tint(theme.warmingColor)

                        if useCustomPauseDate {
                            DatePicker(
                                "Resume Chore At",
                                selection: $customPauseUntil,
                                in: Date.now.addingTimeInterval(900)...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .font(.caption.weight(.bold))
                        }
                    }
                    .padding(12)
                    .adhousedCard(compact: true)

                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        if useCustomPauseDate {
                            try? TaskActionService.pauseSingleTaskUntil(
                                taskID: task.id,
                                resumeDate: customPauseUntil,
                                in: modelContext
                            )
                        } else {
                            try? TaskActionService.deferTaskToTomorrow(
                                taskID: task.id,
                                reasonTag: selectedReason,
                                byMemberID: ADHOUSEDPreferences.shared.activeMemberID,
                                in: modelContext
                            )
                        }
                        dismiss()
                    } label: {
                        Text(
                            useCustomPauseDate
                                ? "Pause Chore Until \(customPauseUntil.formatted(date: .abbreviated, time: .shortened))"
                                : "Move to Tomorrow Morning"
                        )
                        .font(.subheadline.weight(.heavy))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 10)
                    }
                    .buttonStyle(TactileActionButtonStyle(fill: theme.cardElevatedSurface, foreground: theme.primaryInk))
                }
                .padding(20)
            }
        }
        .presentationDetents([.fraction(0.86), .large])
    }
}
