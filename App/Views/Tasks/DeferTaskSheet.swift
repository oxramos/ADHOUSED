import SwiftUI
import SwiftData
import ADHOUSEDCore

struct DeferTaskSheet: View {
    @Environment(\.adhousedTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let task: ChoreTask
    let onStartTwoMinuteSprintInstead: () -> Void

    @State private var selectedReason: String = "Out of spoons today"

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

                Spacer()

                Button {
                    HapticsEngine.shared.playMechanicalTap()
                    try? TaskActionService.deferTaskToTomorrow(
                        taskID: task.id,
                        reasonTag: selectedReason,
                        byMemberID: ADHOUSEDPreferences.shared.activeMemberID,
                        in: modelContext
                    )
                    dismiss()
                } label: {
                    Text("Silence Today & Resume Tomorrow Morning")
                        .font(.subheadline.weight(.heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.cardElevatedSurface, foreground: theme.primaryInk))
            }
            .padding(20)
        }
        .presentationDetents([.fraction(0.72), .large])
    }
}
