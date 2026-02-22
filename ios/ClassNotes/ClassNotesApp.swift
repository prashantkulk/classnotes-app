import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if !AppMode.isDemo {
            FirebaseApp.configure()

            // Push notification setup
            Messaging.messaging().delegate = self
            UNUserNotificationCenter.current().delegate = self

            // Request notification permission
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                if granted {
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                }
            }
        }
        return true
    }

    // Forward APNs token to Firebase Auth (required for phone auth) and Messaging
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
        Messaging.messaging().apnsToken = deviceToken
    }

    // Forward remote notifications to Firebase Auth (handles silent push for phone verification)
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        completionHandler(.noData)
    }

    // Handle URL callbacks (reCAPTCHA fallback for phone auth)
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        }
        return false
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        // Post notification so AuthService can save the token
        NotificationCenter.default.post(
            name: .fcmTokenRefreshed,
            object: nil,
            userInfo: ["token": fcmToken]
        )
    }

    // MARK: - Badge clearing

    func applicationDidBecomeActive(_ application: UIApplication) {
        clearBadge()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        clearBadge()
    }

    private func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Show notification when app is in foreground — but do NOT re-increment the badge
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Clear badge when user taps a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        clearBadge()
        completionHandler()
    }
}

extension Notification.Name {
    static let fcmTokenRefreshed = Notification.Name("FCMTokenRefreshed")
}

@main
struct ClassNotesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService: AuthService
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Enable demo mode for simulator testing
        #if targetEnvironment(simulator)
        AppMode.isDemo = true
        #endif

        if AppMode.isDemo {
            _authService = StateObject(wrappedValue: DemoAuthService())
        } else {
            _authService = StateObject(wrappedValue: AuthService())
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Belt-and-suspenders: clear badge via SwiftUI scenePhase as well,
            // since applicationDidBecomeActive can be unreliable in SwiftUI apps.
            if newPhase == .active {
                UNUserNotificationCenter.current().setBadgeCount(0)
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                if authService.needsOnboarding {
                    OnboardingView()
                } else {
                    GroupsListView()
                }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}
