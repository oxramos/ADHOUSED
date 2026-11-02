import SwiftUI
import SwiftData
import CloudKit
import UniformTypeIdentifiers
import ADHOUSEDCore
#if canImport(UIKit)
import UIKit
#endif

struct PartnerSharingSheet: View {
    @Environment(\.adhousedTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var households: [Household]
    @Query(sort: \HouseholdMember.sortOrder) private var members: [HouseholdMember]
    @Query private var tasks: [ChoreTask]

    @Bindable var session: AppSessionViewModel
    @Bindable var prefs: ADHOUSEDPreferences

    @State private var householdNameDraft: String = ""
    @State private var newPartnerName: String = ""
    @State private var newPartnerEmoji: String = "🦦"
    @State private var editingMemberID: UUID? = nil
    @State private var editingMemberNameDraft: String = ""

    @State private var activeSharePayload: CloudShareSheetPayload? = nil
    @State private var exportedFileURL: URL? = nil
    @State private var showingFileImporter: Bool = false
    @State private var statusBanner: String? = nil
    @State private var isErrorBanner: Bool = false

    private let avatarEmojis = ["🦊", "🦦", "🐝", "🐻", "🐙", "🦉", "🐢", "🦄", "🐈‍⬛", "🐕", "🌿", "⚡️"]

    private var household: Household? { households.first }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.canvasBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if let statusBanner {
                            HStack(spacing: 10) {
                                Image(systemName: isErrorBanner ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                    .foregroundStyle(isErrorBanner ? theme.warmingColor : theme.freshColor)
                                Text(statusBanner)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(theme.primaryInk)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .padding(12)
                            .adhousedCard(highlightTint: isErrorBanner ? theme.warmingColor : theme.freshColor, compact: true)
                        }

                        iCloudCollaborationCard
                        householdAndPeopleCard
                        portableSnapshotBackupCard

                        Spacer(minLength: 32)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Partner & iCloud Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        commitHouseholdNameIfNeeded()
                        dismiss()
                    }
                    .fontWeight(.heavy)
                }
            }
            .sheet(item: $activeSharePayload) { payload in
                CloudSharingControllerRepresentable(
                    share: payload.share,
                    container: payload.container,
                    householdName: household?.name ?? "Our Home"
                )
                .ignoresSafeArea()
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportedFile(result)
            }
            .onAppear {
                householdNameDraft = household?.name ?? "Our Home"
                HouseholdCloudSyncService.shared.refreshAvailability()
            }
        }
    }

    // MARK: - 1. Live iCloud Household Sharing Card

    private var iCloudCollaborationCard: some View {
        let sync = HouseholdCloudSyncService.shared

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ChoreIconBadgeView(
                    iconSymbol: "icloud.and.arrow.up.fill",
                    tint: theme.accentPrimary,
                    size: 40
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud Shared Home")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Work together from both iPhones — completions, turns & new chores sync via iCloud.")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Current Status Pill
            HStack(spacing: 8) {
                switch sync.availabilityState {
                case .localMultiMemberMode(let reason):
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(theme.warmingColor)
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)

                case .readyForCloudShare:
                    Image(systemName: "checkmark.icloud.fill")
                        .foregroundStyle(theme.freshColor)
                    Text("Ready to invite your partner via iMessage or iCloud link.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.primaryInk)
                        .fixedSize(horizontal: false, vertical: true)

                case .activelySharedHousehold(let roleSummary):
                    Image(systemName: "person.2.wave.2.fill")
                        .foregroundStyle(theme.freshColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(roleSummary)
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(theme.freshColor)
                        if let lastSync = sync.lastSyncedAt {
                            Text("Last synced \(lastSync.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(theme.secondaryInk)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(11)
            .background(
                RoundedRectangle(cornerRadius: theme.isTerminalHUD ? 8 : 12, style: .continuous)
                    .fill(theme.canvasSecondary)
            )

            // Primary Action: Invite Partner via Apple's iCloud Sharing Sheet
            Button {
                startCloudSharingInvite()
            } label: {
                HStack(spacing: 8) {
                    if sync.isSyncing {
                        ProgressView()
                            .tint(theme.onAccentPrimary)
                    } else {
                        Image(systemName: "person.crop.circle.badge.plus")
                    }
                    Text(
                        prefs.cloudShareURLString != nil
                            ? "Manage Share / Re-Send Partner Invite"
                            : "Invite Partner via iCloud…"
                    )
                    .fixedSize(horizontal: false, vertical: true)
                }
                .font(.subheadline.weight(.heavy))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
            }
            .buttonStyle(TactileActionButtonStyle(fill: theme.accentPrimary, foreground: theme.onAccentPrimary))
            .disabled(sync.isSyncing)

            // Sync Now + Copy Invite Link
            HStack(spacing: 10) {
                Button {
                    triggerManualSync()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath.icloud")
                        Text("Sync Now")
                    }
                    .font(.caption.weight(.heavy))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.cardElevatedSurface, foreground: theme.primaryInk))
                .disabled(sync.isSyncing)

                if let urlStr = prefs.cloudShareURLString, let url = URL(string: urlStr) {
                    ShareLink(item: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "message.fill")
                            Text("Send Link")
                        }
                        .font(.caption.weight(.heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: theme.pillCornerRadius, style: .continuous)
                                .fill(theme.accentSecondary)
                        )
                        .foregroundStyle(theme.onAccentSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Helpful Step-by-Step Guide
            VStack(alignment: .leading, spacing: 4) {
                Text("How Partner Sharing Works:")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(theme.primaryInk)
                Text("1. Add your partner's name below so you both have profiles.\n2. Tap **Invite Partner via iCloud** and send via iMessage.\n3. Once your partner installs ADHOUSED and taps the invite, they pick their name in the top-right avatar menu!")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 2)
        }
        .padding(15)
        .adhousedCard(highlightTint: theme.accentPrimary)
    }

    // MARK: - 2. Household Name & Members (Who Is Using This iPhone)

    private var householdAndPeopleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HOUSEHOLD NAME & PEOPLE")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            VStack(alignment: .leading, spacing: 6) {
                Text("Home Name")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.secondaryInk)

                HStack(spacing: 8) {
                    TextField("Our Home", text: $householdNameDraft)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.primaryInk)
                        .padding(11)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(theme.canvasSecondary)
                        )
                        .onSubmit {
                            commitHouseholdNameIfNeeded()
                        }

                    if householdNameDraft.trimmingCharacters(in: .whitespacesAndNewlines) != (household?.name ?? "") {
                        Button("Save") {
                            commitHouseholdNameIfNeeded()
                        }
                        .font(.caption.weight(.heavy))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .buttonStyle(TactileActionButtonStyle(fill: theme.accentPrimary, foreground: theme.onAccentPrimary))
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Who is using THIS iPhone?")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.primaryInk)
                Text("Tap a person to make this their active view, or tap the pencil icon to rename.")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(members) { member in
                    let isThisPhone = prefs.activeMemberID == member.id
                    let isEditing = editingMemberID == member.id

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Menu {
                                ForEach(avatarEmojis, id: \.self) { em in
                                    Button(em) {
                                        member.emoji = em
                                        try? modelContext.save()
                                        TaskActionService.awaitableReconcileAndReloadWidgets(in: modelContext)
                                    }
                                }
                            } label: {
                                Text(member.emoji)
                                    .font(.title3)
                                    .frame(width: 38, height: 38)
                                    .background(Circle().fill(theme.cardSurface))
                            }

                            if isEditing {
                                TextField("Name", text: $editingMemberNameDraft)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(theme.primaryInk)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(theme.cardSurface))

                                Button("Save") {
                                    let trimmed = editingMemberNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !trimmed.isEmpty {
                                        member.displayName = trimmed
                                        try? modelContext.save()
                                        TaskActionService.awaitableReconcileAndReloadWidgets(in: modelContext)
                                    }
                                    editingMemberID = nil
                                }
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(theme.accentPrimary)
                            } else {
                                Button {
                                    HapticsEngine.shared.playMechanicalTap()
                                    prefs.activeMemberID = member.id
                                    session.refreshWidgetsAndReminders(in: modelContext)
                                } label: {
                                    HStack {
                                        Text(member.displayName)
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(theme.primaryInk)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer()
                                        if isThisPhone {
                                            Text("THIS IPHONE")
                                                .font(.system(size: 9.5, weight: .black, design: theme.fontDesign))
                                                .foregroundStyle(theme.onAccentPrimary)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Capsule().fill(theme.accentPrimary))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)

                                Button {
                                    editingMemberID = member.id
                                    editingMemberNameDraft = member.displayName
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(theme.secondaryInk)
                                        .frame(width: 30, height: 30)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Rename \(member.displayName)")
                            }
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isThisPhone ? theme.accentPrimary.opacity(0.14) : theme.canvasSecondary)
                    )
                }

                // Add Partner Row
                HStack(spacing: 8) {
                    Menu {
                        ForEach(avatarEmojis, id: \.self) { em in
                            Button(em) { newPartnerEmoji = em }
                        }
                    } label: {
                        Text(newPartnerEmoji)
                            .font(.title3)
                            .frame(width: 40, height: 40)
                            .background(RoundedRectangle(cornerRadius: 10).fill(theme.canvasSecondary))
                    }

                    TextField("Add partner's name…", text: $newPartnerName)
                        .font(.subheadline)
                        .foregroundStyle(theme.primaryInk)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(theme.canvasSecondary))

                    Button {
                        addPartnerMember()
                    } label: {
                        Text("Add")
                            .font(.subheadline.weight(.heavy))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(TactileActionButtonStyle(fill: theme.accentPrimary, foreground: theme.onAccentPrimary))
                    .disabled(newPartnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.top, 4)
            }
        }
        .padding(15)
        .adhousedCard()
    }

    // MARK: - 3. Portable Household File Share / Import

    private var portableSnapshotBackupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PORTABLE SNAPSHOT BACKUP (AIRDROP / FILE)")
                .font(.caption.weight(.heavy))
                .foregroundStyle(theme.secondaryInk)

            Text("You can also AirDrop or iMessage a snapshot file of all chores, rooms, custom catalog items, and members at any time.")
                .font(.caption)
                .foregroundStyle(theme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Button {
                    prepareExportFile()
                } label: {
                    Label("Export Home File", systemImage: "square.and.arrow.up")
                        .font(.caption.weight(.heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.cardElevatedSurface, foreground: theme.primaryInk))

                Button {
                    showingFileImporter = true
                } label: {
                    Label("Import Home File", systemImage: "square.and.arrow.down")
                        .font(.caption.weight(.heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(TactileActionButtonStyle(fill: theme.cardElevatedSurface, foreground: theme.primaryInk))
            }

            if let url = exportedFileURL {
                ShareLink(item: url) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Tap Here to Send ADHOUSED-Home.json to Partner")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.weight(.heavy))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(theme.accentPrimary.opacity(0.15))
                    )
                    .foregroundStyle(theme.accentPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(15)
        .adhousedCard()
    }

    // MARK: - Actions

    private func commitHouseholdNameIfNeeded() {
        let trimmed = householdNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let household else { return }
        if household.name != trimmed {
            household.name = trimmed
            household.updatedAt = .now
            try? modelContext.save()
            TaskActionService.awaitableReconcileAndReloadWidgets(in: modelContext)
        }
    }

    private func addPartnerMember() {
        let trimmed = newPartnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let hid: UUID
        if let existingH = household {
            hid = existingH.id
        } else {
            let newH = Household(name: householdNameDraft.isEmpty ? "Our Home" : householdNameDraft)
            modelContext.insert(newH)
            hid = newH.id
        }

        let partner = HouseholdMember(
            householdID: hid,
            displayName: trimmed,
            emoji: newPartnerEmoji,
            accentHex: "#3B66FF",
            sortOrder: members.count
        )
        modelContext.insert(partner)
        try? modelContext.save()
        newPartnerName = ""
        HapticsEngine.shared.playCompletionCelebration()
        TaskActionService.awaitableReconcileAndReloadWidgets(in: modelContext)
    }

    private func startCloudSharingInvite() {
        commitHouseholdNameIfNeeded()
        Task { @MainActor in
            let targetHousehold: Household
            if let existing = household {
                targetHousehold = existing
            } else {
                let created = Household(name: householdNameDraft.isEmpty ? "Our Home" : householdNameDraft)
                modelContext.insert(created)
                try? modelContext.save()
                targetHousehold = created
            }

            do {
                let result = try await HouseholdCloudSyncService.shared.prepareHouseholdCloudShare(
                    for: targetHousehold,
                    tasks: tasks,
                    members: members
                )
                isErrorBanner = false
                statusBanner = "iCloud Household ready — choose iMessage or Copy Link to invite your partner!"
                activeSharePayload = CloudShareSheetPayload(share: result.share, container: result.container)
            } catch {
                isErrorBanner = true
                statusBanner = error.localizedDescription
            }
        }
    }

    private func triggerManualSync() {
        Task { @MainActor in
            do {
                try await HouseholdCloudSyncService.shared.syncWithCloud(in: modelContext)
                session.refreshWidgetsAndReminders(in: modelContext)
                isErrorBanner = false
                statusBanner = "Synced latest household chores & completions with iCloud!"
            } catch {
                isErrorBanner = true
                statusBanner = error.localizedDescription
            }
        }
    }

    private func prepareExportFile() {
        commitHouseholdNameIfNeeded()
        do {
            let data = try HouseholdCloudSyncService.shared.exportHouseholdJSON(in: modelContext)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ADHOUSED-Home.json")
            try data.write(to: url, options: .atomic)
            exportedFileURL = url
            isErrorBanner = false
            statusBanner = "Home snapshot ready! Tap the Send button below."
        } catch {
            isErrorBanner = true
            statusBanner = error.localizedDescription
        }
    }

    private func handleImportedFile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let firstURL = urls.first else { return }
            let accessed = firstURL.startAccessingSecurityScopedResource()
            defer {
                if accessed { firstURL.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: firstURL)
                try HouseholdCloudSyncService.shared.importHouseholdJSON(data, in: modelContext)
                session.refreshWidgetsAndReminders(in: modelContext)
                householdNameDraft = households.first?.name ?? householdNameDraft
                HapticsEngine.shared.playCompletionCelebration()
                isErrorBanner = false
                statusBanner = "Imported shared household chores, people & catalog items!"
            } catch {
                isErrorBanner = true
                statusBanner = "Could not import file: \(error.localizedDescription)"
            }
        case .failure(let error):
            isErrorBanner = true
            statusBanner = error.localizedDescription
        }
    }
}

private struct CloudShareSheetPayload: Identifiable {
    let id = UUID()
    let share: CKShare
    let container: CKContainer
}

#if canImport(UIKit)
private struct CloudSharingControllerRepresentable: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let householdName: String

    func makeCoordinator() -> Coordinator {
        Coordinator(householdName: householdName)
    }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let householdName: String

        init(householdName: String) {
            self.householdName = householdName
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "\(householdName) — ADHOUSED Shared Chores"
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            // Handled via sync status banner
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            if let urlStr = csc.share?.url?.absoluteString {
                Task { @MainActor in
                    ADHOUSEDPreferences.shared.cloudShareURLString = urlStr
                }
            }
        }
    }
}
#endif
