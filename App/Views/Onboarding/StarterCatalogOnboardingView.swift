import SwiftUI
import SwiftData
import ADHOUSEDCore

struct StarterCatalogOnboardingView: View {
    @Environment(\.adhousedTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var existingTasks: [ChoreTask]
    @Bindable var session: AppSessionViewModel
    let isInitialOnboarding: Bool

    @State private var householdName: String = "Our Home"
    @State private var memberDrafts: [(name: String, emoji: String, hex: String)] = [
        ("Me", "🦊", "#3E9B6C")
    ]
    @State private var newMemberName: String = ""
    @State private var selectedIDs: Set<String> = Set(
        StarterCatalog.allTemplates.filter(\.recommendedByDefault).map(\.id)
    )
    @State private var seedOverrides: [String: InitialFreshnessSeed] = [:]
    @State private var autoStaggerEnabled: Bool = true
    @State private var defaultMultiMemberMode: AssignmentMode = .alternating
    @State private var selectedRoomFilter: RoomCategory? = nil

    private let avatarChoices = ["🦊", "🦦", "🐝", "🐻", "🐙", "🦉", "🐢", "🦄"]

    var body: some View {
        ZStack(alignment: .bottom) {
            theme.canvasBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    headerIntroSection

                    if isInitialOnboarding {
                        householdMembersSection
                    }

                    spreadStartDatesBannerSection
                    roomFilterPillsSection
                    catalogListSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }

            bottomAdoptBar
        }
    }

    private var headerIntroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(isInitialOnboarding ? "WELCOME TO ADHOUSED" : "CHORE CATALOG")
                    .font(.caption.weight(.black))
                    .tracking(1.0)
                    .foregroundStyle(theme.accentPrimary)
                Spacer()
                if !isInitialOnboarding {
                    Button("Close") { dismiss() }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.secondaryInk)
                }
            }

            SalientText(
                isInitialOnboarding
                    ? "Pick the household chores you want to track."
                    : "Tap chores to add to your rooms",
                font: .title2.weight(.heavy),
                color: theme.primaryInk
            )

            Text("Pre-filled with realistic schedules and quick time estimates. You can add custom chores or invite your partner via iCloud anytime.")
                .font(.footnote)
                .foregroundStyle(theme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var householdMembersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR HOME & PEOPLE")
                .font(.caption.weight(.heavy))
                .tracking(0.8)
                .foregroundStyle(theme.secondaryInk)

            TextField("Home Name (e.g., Our Home)", text: $householdName)
                .font(.headline.weight(.bold))
                .foregroundStyle(theme.primaryInk)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(theme.canvasSecondary))

            FlowChipLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(Array(memberDrafts.enumerated()), id: \.offset) { idx, member in
                    HStack(spacing: 6) {
                        Text(member.emoji)
                        Text(member.name)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(theme.primaryInk)
                        if memberDrafts.count > 1 {
                            Button {
                                memberDrafts.remove(at: idx)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(theme.secondaryInk)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(theme.canvasSecondary))
                }
            }

            HStack(spacing: 8) {
                TextField("Add partner or roommate…", text: $newMemberName)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 10).fill(theme.canvasSecondary))

                Button {
                    let trimmed = newMemberName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    let emoji = avatarChoices[memberDrafts.count % avatarChoices.count]
                    memberDrafts.append((trimmed, emoji, "#D97736"))
                    newMemberName = ""
                } label: {
                    Text("Add")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.accentPrimary, foreground: theme.onAccentPrimary))
                .disabled(newMemberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if memberDrafts.count > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Default sharing style:")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.secondaryInk)
                    Picker("Sharing", selection: $defaultMultiMemberMode) {
                        Text("Take Turns").tag(AssignmentMode.alternating)
                        Text("Anyone Can Do").tag(AssignmentMode.anyone)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding(15)
        .adhousedCard()
    }

    private var spreadStartDatesBannerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.title2)
                .foregroundStyle(theme.accentPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Spread Out First Due Dates")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(theme.primaryInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text(
                    autoStaggerEnabled
                        ? "Starts with only 2 chores due today and spreads the rest smoothly across the week."
                        : "Manual mode: choose Just Done, Due Soon, or Due Today on each chore below."
                )
                .font(.caption)
                .foregroundStyle(theme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
            Toggle("", isOn: $autoStaggerEnabled)
                .labelsHidden()
                .tint(theme.accentPrimary)
        }
        .padding(14)
        .adhousedCard(highlightTint: theme.accentPrimary, compact: true)
    }

    private var roomFilterPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedRoomFilter = nil
                } label: {
                    Text("All Rooms")
                        .font(.caption.weight(.heavy))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(
                    TactileActionButtonStyle(
                        fill: selectedRoomFilter == nil ? theme.accentPrimary : theme.cardSurface,
                        foreground: selectedRoomFilter == nil ? theme.onAccentPrimary : theme.primaryInk
                    )
                )

                ForEach(RoomCategory.allCases) { room in
                    Button {
                        selectedRoomFilter = room
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: room.symbolName)
                            Text(room.shortTitle)
                        }
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(
                        TactileActionButtonStyle(
                            fill: selectedRoomFilter == room ? theme.roomAccent(for: room) : theme.cardSurface,
                            foreground: selectedRoomFilter == room ? .white : theme.primaryInk
                        )
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var catalogListSection: some View {
        let existingTitles = Set(existingTasks.map { $0.title.lowercased() })
        let items = StarterCatalog.combinedTemplates.filter { tpl in
            if let room = selectedRoomFilter, tpl.room != room { return false }
            if !isInitialOnboarding && existingTitles.contains(tpl.title.lowercased()) { return false }
            return true
        }

        return VStack(spacing: 10) {
            ForEach(items) { tpl in
                let isSelected = selectedIDs.contains(tpl.id)
                let roomColor = theme.roomAccent(for: tpl.room)

                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        if isSelected {
                            selectedIDs.remove(tpl.id)
                        } else {
                            selectedIDs.insert(tpl.id)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(isSelected ? theme.accentPrimary : theme.secondaryInk)

                            ChoreIconBadgeView(
                                iconSymbol: tpl.iconSymbol,
                                tint: roomColor,
                                size: 36
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(tpl.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(theme.primaryInk)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("\(tpl.room.shortTitle) · \(tpl.cadenceTag) · ~\(tpl.estimatedMinutes) min · \(tpl.energyLevel.badgeText)")
                                    .font(.caption2)
                                    .foregroundStyle(theme.secondaryInk)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    if isSelected && !autoStaggerEnabled {
                        FlowChipLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                            Text("Start as:")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(theme.secondaryInk)
                                .padding(.vertical, 4)
                            ForEach([InitialFreshnessSeed.fresh, .dueSoon, .dueNow]) { seedOpt in
                                let chosen = (seedOverrides[tpl.id] ?? .fresh) == seedOpt
                                Button {
                                    seedOverrides[tpl.id] = seedOpt
                                } label: {
                                    Text(seedOpt.label)
                                        .font(.caption2.weight(.heavy))
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule().fill(chosen ? theme.accentPrimary : theme.canvasSecondary)
                                        )
                                        .foregroundStyle(chosen ? theme.onAccentPrimary : theme.primaryInk)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.leading, 34)
                    }
                }
                .padding(13)
                .adhousedCard(highlightTint: isSelected ? theme.accentPrimary : nil, compact: true)
            }
        }
    }

    private var bottomAdoptBar: some View {
        HStack {
            Button {
                HapticsEngine.shared.playCompletionCelebration()
                commitStarterSelection()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text(
                        selectedIDs.isEmpty
                            ? (isInitialOnboarding ? "Start with Clean Slate" : "Done")
                            : (isInitialOnboarding ? "Start with \(selectedIDs.count) Chores" : "Add \(selectedIDs.count) Chores")
                    )
                }
                .font(.headline.weight(.heavy))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
            }
            .buttonStyle(
                TactileActionButtonStyle(
                    fill: theme.accentPrimary,
                    foreground: theme.onAccentPrimary
                )
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(theme.canvasBackground.opacity(0.95))
    }

    private func commitStarterSelection() {
        let chosenTemplates = StarterCatalog.combinedTemplates.filter { selectedIDs.contains($0.id) }
        let mapped: [(StarterChoreTemplate, InitialFreshnessSeed, AssignmentMode)] = chosenTemplates.map { tpl in
            let seed: InitialFreshnessSeed = autoStaggerEnabled
                ? .autoStagger
                : (seedOverrides[tpl.id] ?? .fresh)
            return (tpl, seed, defaultMultiMemberMode)
        }

        if isInitialOnboarding {
            _ = try? TaskActionService.bootstrapHousehold(
                householdName: householdName,
                memberSpecs: memberDrafts,
                selectedTemplates: mapped,
                in: modelContext
            )
        } else {
            _ = try? TaskActionService.adoptCatalogTemplates(
                mapped,
                in: modelContext
            )
        }

        Task {
            _ = await NagBudgetScheduler.shared.requestNotificationAuthorization()
            await ReminderCoordinator.shared.reconcileAll(in: modelContext)
        }

        if !isInitialOnboarding {
            dismiss()
        }
    }
}
