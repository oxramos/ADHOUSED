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
        ("Alex", "🦊", "#3E9B6C"),
        ("Sam", "🦦", "#3B66FF")
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

                    antiAvalancheBannerSection
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
                Text(isInitialOnboarding ? "WELCOME TO ADHOUSED" : "STARTER CHORE CATALOG")
                    .font(.caption.weight(.black))
                    .tracking(1.1)
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
                    ? "Pick your recurring chores — zero blank-page overwhelm."
                    : "Tap common chores to add to your rooms",
                font: .title2.weight(.heavy),
                color: theme.primaryInk
            )

            Text("Pre-filled with realistic frequencies, Spoons tags, and Anti-Avalanche staggering so Day 1 never dumps 20 alarms on you.")
                .font(.footnote)
                .foregroundStyle(theme.secondaryInk)
        }
    }

    private var householdMembersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HOUSEHOLD & MEMBERS")
                .font(.caption.weight(.heavy))
                .tracking(0.8)
                .foregroundStyle(theme.secondaryInk)

            TextField("Household Name", text: $householdName)
                .font(.headline.weight(.bold))
                .foregroundStyle(theme.primaryInk)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(theme.canvasSecondary))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
                        Text("Alternating Turns").tag(AssignmentMode.alternating)
                        Text("Up for Grabs").tag(AssignmentMode.anyone)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding(15)
        .adhousedCard()
    }

    private var antiAvalancheBannerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                .font(.title2)
                .foregroundStyle(theme.accentPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Anti-Avalanche Staggering")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(theme.primaryInk)
                Text(
                    autoStaggerEnabled
                        ? "Caps Day 1 to just 2 due tasks and spreads the rest smoothly across the week."
                        : "Manual mode: tap Fresh / Soon / Due Now on each selected chore below."
                )
                .font(.caption)
                .foregroundStyle(theme.secondaryInk)
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

                ForEach(RoomCategory.allCases.filter { $0 != .general }) { room in
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
        let items = StarterCatalog.allTemplates.filter { tpl in
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

                            Image(systemName: tpl.iconSymbol)
                                .font(.headline)
                                .foregroundStyle(roomColor)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(tpl.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(theme.primaryInk)
                                    .multilineTextAlignment(.leading)
                                Text("\(tpl.room.shortTitle) · \(tpl.cadenceTag) · ⚡ \(tpl.estimatedMinutes)m · \(tpl.energyLevel.badgeText)")
                                    .font(.caption2)
                                    .foregroundStyle(theme.secondaryInk)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    if isSelected && !autoStaggerEnabled {
                        HStack(spacing: 6) {
                            Text("Initial state:")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(theme.secondaryInk)
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
                                        .foregroundStyle(chosen ? .white : theme.primaryInk)
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
                            ? "Start with Clean Slate"
                            : "Launch with \(selectedIDs.count) Chores"
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
        let chosenTemplates = StarterCatalog.allTemplates.filter { selectedIDs.contains($0.id) }
        let mapped: [(StarterChoreTemplate, InitialFreshnessSeed, AssignmentMode)] = chosenTemplates.map { tpl in
            let seed: InitialFreshnessSeed = autoStaggerEnabled
                ? .autoStagger
                : (seedOverrides[tpl.id] ?? .fresh)
            return (tpl, seed, defaultMultiMemberMode)
        }

        _ = try? TaskActionService.bootstrapHousehold(
            householdName: householdName,
            memberSpecs: memberDrafts,
            selectedTemplates: mapped,
            in: modelContext
        )

        Task {
            _ = await NagBudgetScheduler.shared.requestNotificationAuthorization()
            await ReminderCoordinator.shared.reconcileAll(in: modelContext)
        }

        if !isInitialOnboarding {
            dismiss()
        }
    }
}
