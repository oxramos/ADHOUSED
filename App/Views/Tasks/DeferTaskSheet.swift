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

    @State private var selectedReason: String = "Out of spoons today"
    @State private var useCustomPauseDate: Bool = false
    @State private var customPauseUntil: Date = Date.now.addingTimeInterval(2 * 86_400)

    private let reasons = [
        "Out of spoons today",
        "Away from home tonight",
        "Missing cleaning supplies",
        "Doing a bigger reset tomorrow"
    ]

    var body: some View {
        ZStack {
            theme.canvasBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label("INTENTIONAL DEFERRAL", systemImage: "sunrise.fill")
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

                Text("Skipping to tomorrow is tucked inside the app on purpose so Lock Screen swipes can't hide chores. Persistent reminders will resume tomorrow morning.")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryInk)

                // ADHD Task-Initiation Pivot ("Just 2 minutes?")
                Button {
                    onStartTwoMinuteSprintInstead()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "bolt.circle.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wait — race just 2 minutes instead?")
                                .font(.subheadline.weight(.heavy))
                            Text("Half-doing a chore beats avoiding it! Tap to start a 2m timer.")
                                .font(.caption2)
                                .opacity(0.9)
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
                    Text("Or pick why tomorrow fits better:")
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
                                Spacer()
                                Image(systemName: chosen ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(chosen ? theme.warmingColor : theme.secondaryInk)
                            }
                            .padding(11)
                            .background(
                                RoundedRectangle(cornerRadius: 11)
                                    .fill(chosen ? theme.warmingColor.opacity(0.16) : theme.cardSurface)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Vacation / Countryside Break Pivot
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
                                Text("Going out of town or on a weekend break?")
                                    .font(.caption.weight(.heavy))
                                    .foregroundStyle(theme.primaryInk)
                                Text("Pause ALL chores & notifications from Date & Time → Date & Time")
                                    .font(.caption2)
                                    .foregroundStyle(theme.secondaryInk)
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

                // Single-chore custom Date & Time pause option
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $useCustomPauseDate) {
                        Text("Pause this chore until a specific Date & Time")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(theme.primaryInk)
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

                Spacer(minLength: 4)

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
                            : "Silence Today & Resume Tomorrow Morning"
                    )
                    .font(.subheadline.weight(.heavy))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.cardElevatedSurface, foreground: theme.primaryInk))
            }
            .padding(20)
        }
        .presentationDetents([.fraction(0.85), .large])
    }
}
