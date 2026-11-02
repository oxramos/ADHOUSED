import SwiftUI
import SwiftData
import ADHOUSEDCore

struct ChoreCatalogSheet: View {
    @Environment(\.adhousedTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var existingTasks: [ChoreTask]

    @Bindable var session: AppSessionViewModel
    @Bindable var prefs: ADHOUSEDPreferences
    let members: [HouseholdMember]
    let householdID: UUID

    private enum CatalogScopeFilter: Equatable {
        case all
        case customOnly
        case room(RoomCategory)
    }

    @State private var searchText: String = ""
    @State private var scopeFilter: CatalogScopeFilter = .all
    @State private var showingNewCatalogItemCreator: Bool = false
    @State private var toastBanner: String? = nil

    // Custom Catalog Item Creator State
    @State private var draftTitle: String = ""
    @State private var draftIcon: String = "sparkles"
    @State private var draftRoom: RoomCategory = .general
    @State private var draftIntervalCount: Int = 7
    @State private var draftIntervalUnit: IntervalUnit = .days
    @State private var draftEnergy: EnergyLevel = .lowSpoons
    @State private var draftMinutes: Int = 5
    @State private var draftNagMinutes: Int = 60
    @State private var alsoAddToActiveHomeNow: Bool = true

    private var activeTaskTitlesLowercased: Set<String> {
        Set(existingTasks.filter { !$0.isArchived }.map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
    }

    private var allCatalogItems: [StarterChoreTemplate] {
        prefs.customCatalogTemplates + StarterCatalog.allTemplates
    }

    private var filteredCatalogItems: [StarterChoreTemplate] {
        allCatalogItems.filter { item in
            switch scopeFilter {
            case .all:
                break
            case .customOnly:
                if !item.isCustom { return false }
            case .room(let room):
                if item.room != room { return false }
            }

            let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedSearch.isEmpty {
                let q = trimmedSearch.lowercased()
                let matchesTitle = item.title.lowercased().contains(q)
                let matchesRoom = item.room.title.lowercased().contains(q)
                if !matchesTitle && !matchesRoom {
                    return false
                }
            }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.canvasBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        if let banner = toastBanner {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(theme.freshColor)
                                Text(banner)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(theme.primaryInk)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .padding(12)
                            .adhousedCard(highlightTint: theme.freshColor, compact: true)
                        }

                        createCustomCatalogCard

                        searchAndFilterHeader

                        catalogItemsListSection

                        Spacer(minLength: 40)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Chore & Activity Catalog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.heavy)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        HapticsEngine.shared.playMechanicalTap()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                            showingNewCatalogItemCreator.toggle()
                        }
                    } label: {
                        Label("New Item", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.bold))
                    }
                }
            }
        }
    }

    // MARK: - 1. Create & Save Custom Chore / Activity to Catalog

    private var createCustomCatalogCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                HapticsEngine.shared.playMechanicalTap()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                    showingNewCatalogItemCreator.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ChoreIconBadgeView(
                        iconSymbol: theme.preset.isOmarchyQuattroStyle ? "omarchy:spark" : "plus.square.on.square",
                        tint: theme.accentPrimary,
                        size: 40
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add Your Own Chore or Activity to Catalog")
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(theme.primaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Save custom routines, hobbies, pet care, or home tasks permanently in your catalog.")
                            .font(.caption)
                            .foregroundStyle(theme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: showingNewCatalogItemCreator ? "chevron.up.circle.fill" : "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(theme.accentPrimary)
                }
            }
            .buttonStyle(.plain)

            if showingNewCatalogItemCreator {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    TextField("Activity or chore name (e.g., Water balcony plants, Clean espresso bar)…", text: $draftTitle)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 8 : 12, style: .continuous)
                                .fill(theme.canvasSecondary)
                        )

                    // Room / Category Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Room or Category")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.secondaryInk)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 7) {
                                ForEach(RoomCategory.allCases) { room in
                                    let selected = draftRoom == room
                                    Button {
                                        HapticsEngine.shared.playMechanicalTap()
                                        draftRoom = room
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: room.symbolName)
                                            Text(room.shortTitle)
                                        }
                                        .font(.caption.weight(.bold))
                                        .padding(.horizontal, 11)
                                        .padding(.vertical, 7)
                                        .background(
                                            Capsule().fill(selected ? theme.roomAccent(for: room) : theme.canvasSecondary)
                                        )
                                        .foregroundStyle(selected ? .white : theme.primaryInk)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Multi-Pack Icon Picker (Includes Omarchy Pixel Icons!)
                    ChoreIconPickerView(
                        selectedIcon: $draftIcon,
                        accentTint: theme.roomAccent(for: draftRoom)
                    )

                    // Frequency Presets
                    VStack(alignment: .leading, spacing: 6) {
                        Text("How Often")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.secondaryInk)

                        FlowChipLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                            ForEach(
                                [
                                    (1, IntervalUnit.days, "Every day"),
                                    (2, IntervalUnit.days, "Every 2 days"),
                                    (3, IntervalUnit.days, "Every 3 days"),
                                    (7, IntervalUnit.days, "Weekly"),
                                    (14, IntervalUnit.days, "Every 2 weeks"),
                                    (30, IntervalUnit.days, "Monthly")
                                ],
                                id: \.2
                            ) { count, unit, label in
                                let active = draftIntervalCount == count && draftIntervalUnit == unit
                                Button(label) {
                                    HapticsEngine.shared.playMechanicalTap()
                                    draftIntervalCount = count
                                    draftIntervalUnit = unit
                                }
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule().fill(active ? theme.accentPrimary : theme.canvasSecondary)
                                )
                                .foregroundStyle(active ? theme.onAccentPrimary : theme.primaryInk)
                                .buttonStyle(.plain)
                            }
                        }

                        Stepper(
                            "Custom interval: Every **\(draftIntervalCount)** \(draftIntervalCount == 1 ? draftIntervalUnit.singularLabel : draftIntervalUnit.pluralLabel)",
                            value: $draftIntervalCount,
                            in: 1...90
                        )
                        .font(.caption)
                    }

                    // Effort & Minutes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Effort & Time")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.secondaryInk)

                        HStack(spacing: 8) {
                            ForEach(EnergyLevel.allCases) { level in
                                let active = draftEnergy == level
                                Button {
                                    draftEnergy = level
                                } label: {
                                    Text(level.badgeText)
                                        .font(.caption.weight(.bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                                .fill(active ? theme.accentPrimary : theme.canvasSecondary)
                                        )
                                        .foregroundStyle(active ? theme.onAccentPrimary : theme.primaryInk)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack(spacing: 6) {
                            Text("Approx time:")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryInk)
                            ForEach([2, 5, 10, 15, 30], id: \.self) { mins in
                                Button("\(mins) min") {
                                    draftMinutes = mins
                                }
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(draftMinutes == mins ? theme.warmingColor : theme.canvasSecondary)
                                )
                                .foregroundStyle(draftMinutes == mins ? Color(hex: "#121317") : theme.primaryInk)
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Toggle(isOn: $alsoAddToActiveHomeNow) {
                        Text("Also add to my active home chores right now")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.primaryInk)
                    }
                    .tint(theme.accentPrimary)

                    Button {
                        saveCustomCatalogTemplate()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text(alsoAddToActiveHomeNow ? "Save to Catalog & Add to Home" : "Save to Catalog")
                        }
                        .font(.subheadline.weight(.heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(TactileActionButtonStyle(fill: theme.accentPrimary, foreground: theme.onAccentPrimary))
                    .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(15)
        .adhousedCard(highlightTint: showingNewCatalogItemCreator ? theme.accentPrimary : nil)
    }

    // MARK: - 2. Search & Category Filter

    private var searchAndFilterHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.secondaryInk)
                TextField("Search chores & activities…", text: $searchText)
                    .font(.subheadline)
                    .foregroundStyle(theme.primaryInk)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.secondaryInk)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .adhousedCard(compact: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    filterChip(
                        label: "All (\(allCatalogItems.count))",
                        isSelected: scopeFilter == .all,
                        tint: theme.accentPrimary
                    ) {
                        scopeFilter = .all
                    }

                    filterChip(
                        label: "My Custom (\(prefs.customCatalogTemplates.count))",
                        isSelected: scopeFilter == .customOnly,
                        tint: theme.accentSecondary
                    ) {
                        scopeFilter = .customOnly
                    }

                    ForEach(RoomCategory.allCases) { room in
                        filterChip(
                            label: room.shortTitle,
                            symbol: room.symbolName,
                            isSelected: scopeFilter == .room(room),
                            tint: theme.roomAccent(for: room)
                        ) {
                            scopeFilter = .room(room)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func filterChip(
        label: String,
        symbol: String? = nil,
        isSelected: Bool,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            HapticsEngine.shared.playMechanicalTap()
            action()
        } label: {
            HStack(spacing: 5) {
                if let symbol {
                    Image(systemName: symbol)
                }
                Text(label)
            }
            .font(.caption.weight(.bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isSelected ? tint : theme.cardSurface)
            )
            .foregroundStyle(isSelected ? .white : theme.primaryInk)
            .overlay {
                if !isSelected {
                    Capsule().strokeBorder(theme.borderInk, lineWidth: 0.9)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3. Catalog Rows

    private var catalogItemsListSection: some View {
        VStack(spacing: 10) {
            if filteredCatalogItems.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(theme.secondaryInk)
                    Text(scopeFilter == .customOnly
                         ? "You haven't saved any custom catalog items yet."
                         : "No catalog items match \"\(searchText)\".")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                        .multilineTextAlignment(.center)
                    Button("Create Custom Item Above") {
                        showingNewCatalogItemCreator = true
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accentPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .adhousedCard(compact: true)
            } else {
                ForEach(filteredCatalogItems) { tpl in
                    catalogRow(tpl)
                }
            }
        }
    }

    private func catalogRow(_ tpl: StarterChoreTemplate) -> some View {
        let alreadyActive = activeTaskTitlesLowercased.contains(tpl.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
        let roomTint = theme.roomAccent(for: tpl.room)

        return HStack(alignment: .center, spacing: 12) {
            ChoreIconBadgeView(
                iconSymbol: tpl.iconSymbol,
                tint: roomTint,
                size: 40
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(tpl.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)

                    if tpl.isCustom {
                        Text("CUSTOM")
                            .font(.system(size: 9, weight: .black, design: theme.fontDesign))
                            .foregroundStyle(theme.onAccentSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(theme.accentSecondary))
                    }
                }

                Text("\(tpl.room.shortTitle) · \(tpl.cadenceTag) · ~\(tpl.estimatedMinutes) min · \(tpl.energyLevel.badgeText)")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            HStack(spacing: 6) {
                if tpl.isCustom {
                    Button(role: .destructive) {
                        HapticsEngine.shared.playMechanicalTap()
                        prefs.removeCustomCatalogTemplate(id: tpl.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.secondaryInk)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(theme.canvasSecondary))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete custom catalog item")
                }

                if alreadyActive {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("Added")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.freshColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(theme.freshColor.opacity(0.14)))
                } else {
                    Button {
                        adoptSingleTemplate(tpl)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Add")
                        }
                        .font(.caption.weight(.heavy))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(TactileActionButtonStyle(fill: theme.accentPrimary, foreground: theme.onAccentPrimary))
                }
            }
        }
        .padding(13)
        .adhousedCard(compact: true)
    }

    // MARK: - Actions

    private func adoptSingleTemplate(_ tpl: StarterChoreTemplate) {
        let mode: AssignmentMode = members.count > 1 ? .alternating : .anyone
        _ = try? TaskActionService.adoptCatalogTemplates(
            [(tpl, .autoStagger, mode)],
            in: modelContext
        )
        HapticsEngine.shared.playCompletionCelebration()
        withAnimation {
            toastBanner = "Added \"\(tpl.title)\" to \(tpl.room.shortTitle)!"
        }
    }

    private func saveCustomCatalogTemplate() {
        let trimmed = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let customTemplate = StarterChoreTemplate(
            title: trimmed,
            iconSymbol: draftIcon,
            room: draftRoom,
            scheduleMode: .rollingFromLastDone,
            intervalUnit: draftIntervalUnit,
            intervalCount: draftIntervalCount,
            energyLevel: draftEnergy,
            estimatedMinutes: draftMinutes,
            suggestedNagMinutes: draftNagMinutes,
            suggestedTier: .gentlePings,
            recommendedByDefault: false,
            isCustom: true
        )
        prefs.addOrUpdateCustomCatalogTemplate(customTemplate)

        if alsoAddToActiveHomeNow {
            let mode: AssignmentMode = members.count > 1 ? .alternating : .anyone
            _ = try? TaskActionService.adoptCatalogTemplates(
                [(customTemplate, .dueNow, mode)],
                in: modelContext
            )
        }

        HapticsEngine.shared.playCompletionCelebration()
        draftTitle = ""
        showingNewCatalogItemCreator = false
        withAnimation {
            toastBanner = alsoAddToActiveHomeNow
                ? "Saved \"\(trimmed)\" to your Catalog & active chores!"
                : "Saved \"\(trimmed)\" to your Catalog!"
        }
    }
}
