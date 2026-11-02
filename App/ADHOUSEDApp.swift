import SwiftUI
import SwiftData
import UserNotifications
import CloudKit
import ADHOUSEDCore
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class SharedContainerRegistry {
    static let shared = SharedContainerRegistry()
    var modelContainer: ModelContainer?
}

#if canImport(UIKit)
final class ADHOUSEDSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let metadata = connectionOptions.cloudKitShareMetadata {
            acceptIncomingCloudShare(metadata)
        }
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        acceptIncomingCloudShare(cloudKitShareMetadata)
    }

    private func acceptIncomingCloudShare(_ metadata: CKShare.Metadata) {
        Task { @MainActor in
            guard let container = SharedContainerRegistry.shared.modelContainer else { return }
            try? await HouseholdCloudSyncService.shared.acceptShareInvitation(
                metadata: metadata,
                in: container.mainContext
            )
            await ReminderCoordinator.shared.reconcileAll(in: container.mainContext)
        }
    }
}

final class ADHOUSEDAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = ADHOUSEDSceneDelegate.self
        return config
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        if CKNotification(fromRemoteNotificationDictionary: userInfo) != nil {
            if let container = SharedContainerRegistry.shared.modelContainer {
                try? await HouseholdCloudSyncService.shared.syncWithCloud(in: container.mainContext)
                await ReminderCoordinator.shared.reconcileAll(in: container.mainContext)
                return .newData
            }
        }
        return .noData
    }
}
#endif

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
            break
        }
        await ReminderCoordinator.shared.reconcileAll(in: context)
    }
}

@main
struct ADHOUSEDApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(ADHOUSEDAppDelegate.self) private var appDelegate
    #endif
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
        SharedContainerRegistry.shared.modelContainer = resolvedContainer
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
                .onOpenURL { url in
                    guard url.pathExtension.lowercased() == "json" else { return }
                    let accessed = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessed { url.stopAccessingSecurityScopedResource() }
                    }
                    if let data = try? Data(contentsOf: url) {
                        try? HouseholdCloudSyncService.shared.importHouseholdJSON(data, in: container.mainContext)
                        session.refreshWidgetsAndReminders(in: container.mainContext)
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        prefs.reloadFromSharedDefaults()
                        Task { @MainActor in
                            try? await HouseholdCloudSyncService.shared.syncWithCloud(in: container.mainContext)
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
        let activeOverrides = prefs.colorOverrides(for: prefs.themePreset)
        let tokens = ADHOUSEDThemeTokens.resolve(
            preset: prefs.themePreset,
            colorScheme: effectiveColorScheme,
            overrides: activeOverrides
        )

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
