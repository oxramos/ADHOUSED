import SwiftUI
import SwiftData
import UserNotifications
import ADHOUSEDCore

final class NotificationDelegateBridge: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    var modelContainer: ModelContainer?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        let userInfo = response.notification.request.content.userInfo
        let taskIDStr = userInfo["taskID"] as? String ?? ""

        switch response.actionIdentifier {
        case NagNotificationConstants.actionComplete:
            if let uuid = UUID(uuidString: taskIDStr) {
                _ = try? TaskActionService.completeTask(
                    taskID: uuid,
                    byMemberID: ADHOUSEDPreferences.shared.activeMemberID,
                    enableWidgetUndoWindow: false,
                    in: context
                )
            }
        case NagNotificationConstants.actionPause1Hour:
            if let uuid = UUID(uuidString: taskIDStr) {
                try? TaskActionService.pauseReminders(scope: .singleTask(uuid), durationMinutes: 60, in: context)
            }
        case NagNotificationConstants.actionAway3Hours:
            try? TaskActionService.pauseReminders(scope: .entireHousehold, durationMinutes: 180, in: context)
        default:
            // Note: Swiping/dismissing (`UNNotificationDismissActionIdentifier`) intentionally does NOT cancel remaining cascade!
            break
        }
        await ReminderCoordinator.shared.reconcileAll(in: context)
    }
}

@main
struct ADHOUSEDApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let container: ModelContainer
    private let notificationBridge = NotificationDelegateBridge()
    @State private var session = AppSessionViewModel()
    @State private var prefs = ADHOUSEDPreferences.shared

    init() {
        let resolvedContainer: ModelContainer
        do {
            resolvedContainer = try SharedAppGroup.makeModelContainer()
        } catch {
            resolvedContainer = try! SharedAppGroup.makeModelContainer(inMemory: true)
        }
        self.container = resolvedContainer
        self.notificationBridge.modelContainer = resolvedContainer
        UNUserNotificationCenter.current().delegate = self.notificationBridge
        NagBudgetScheduler.shared.registerInteractiveCategories()
    }

    var body: some Scene {
        WindowGroup {
            ThemedRootContainer(session: session, prefs: prefs)
                .modelContainer(container)
                .onAppear {
                    session.applyLaunchArgumentsIfPresent(ProcessInfo.processInfo.arguments, in: container.mainContext)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        prefs.reloadFromSharedDefaults()
                        Task { @MainActor in
                            await ReminderCoordinator.shared.reconcileAll(in: container.mainContext)
                        }
                    }
                }
        }
    }
}

private struct ThemedRootContainer: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [ChoreTask]
    @Bindable var session: AppSessionViewModel
    @Bindable var prefs: ADHOUSEDPreferences

    private var effectiveColorScheme: ColorScheme {
        ADHOUSEDThemeTokens.effectiveColorScheme(
            preset: prefs.themePreset,
            preference: prefs.colorSchemePreference,
            systemColorScheme: systemColorScheme
        )
    }

    private var preferredColorSchemeOverride: ColorScheme? {
        ADHOUSEDThemeTokens.preferredColorSchemeOverride(
            preset: prefs.themePreset,
            preference: prefs.colorSchemePreference
        )
    }

    var body: some View {
        let tokens = ADHOUSEDThemeTokens.resolve(preset: prefs.themePreset, colorScheme: effectiveColorScheme)

        Group {
            if !prefs.hasCompletedOnboarding && tasks.isEmpty {
                StarterCatalogOnboardingView(session: session, isInitialOnboarding: true)
            } else {
                RootDashboardView(session: session, prefs: prefs)
            }
        }
        .fontDesign(tokens.fontDesign)
        .environment(\.adhousedTheme, tokens)
        .preferredColorScheme(preferredColorSchemeOverride)
    }
}
