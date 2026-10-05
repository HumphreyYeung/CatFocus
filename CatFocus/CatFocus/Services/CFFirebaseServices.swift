import Foundation
import FirebaseAnalytics
import FirebaseMessaging
import FirebaseRemoteConfig
import OSLog

enum CFAnalyticsEvent {
    case appOpened
    case onboardingStarted
    case onboardingStepCompleted(stepName: String)
    case onboardingCompleted
    case paywallViewed(source: String)
    case purchaseStarted(productID: String)
    case purchaseSucceeded(productID: String)
    case restoreAttempted
    case notificationPermissionResult(granted: Bool)
    case notificationTapped
    case focusSessionStarted(durationMinutes: Int, isFirstSession: Bool)
    case focusSessionCompleted(plannedDurationMinutes: Int, actualDurationSeconds: Int)
    case focusSessionEndedEarly(plannedDurationMinutes: Int, elapsedSeconds: Int)

    var name: String {
        switch self {
        case .appOpened: return "app_opened"
        case .onboardingStarted: return "onboarding_started"
        case .onboardingStepCompleted: return "onboarding_step_completed"
        case .onboardingCompleted: return "onboarding_completed"
        case .paywallViewed: return "paywall_viewed"
        case .purchaseStarted: return "purchase_started"
        case .purchaseSucceeded: return "purchase_succeeded"
        case .restoreAttempted: return "restore_attempted"
        case .notificationPermissionResult: return "notification_permission_result"
        case .notificationTapped: return "notification_tapped"
        case .focusSessionStarted: return "focus_session_started"
        case .focusSessionCompleted: return "focus_session_completed"
        case .focusSessionEndedEarly: return "focus_session_ended_early"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .appOpened, .onboardingStarted, .onboardingCompleted, .restoreAttempted, .notificationTapped:
            return nil
        case let .onboardingStepCompleted(stepName):
            return ["step_name": stepName]
        case let .paywallViewed(source):
            return ["source": source]
        case let .purchaseStarted(productID), let .purchaseSucceeded(productID):
            return ["product_id": productID]
        case let .notificationPermissionResult(granted):
            return ["granted": granted]
        case let .focusSessionStarted(durationMinutes, isFirstSession):
            return ["duration_minutes": durationMinutes, "is_first_session": isFirstSession]
        case let .focusSessionCompleted(plannedDurationMinutes, actualDurationSeconds):
            return [
                "planned_duration_minutes": plannedDurationMinutes,
                "actual_duration_seconds": actualDurationSeconds
            ]
        case let .focusSessionEndedEarly(plannedDurationMinutes, elapsedSeconds):
            return [
                "planned_duration_minutes": plannedDurationMinutes,
                "elapsed_seconds": elapsedSeconds
            ]
        }
    }
}

enum CFAnalytics {
    private static let logger = Logger(subsystem: "com.catfocus.app", category: "analytics")

    static func log(_ event: CFAnalyticsEvent) {
        if let parameters = event.parameters {
            Analytics.logEvent(event.name, parameters: parameters)
        } else {
            Analytics.logEvent(event.name, parameters: nil)
        }
        logger.debug("Firebase event: \(event.name, privacy: .public)")
    }
}

enum CFRemoteConfigKey: String {
    case postcardNotificationsEnabled = "notification_postcard_enabled"
    case postcardNotificationTitle = "notification_postcard_title"
    case postcardNotificationBody = "notification_postcard_body"
    case dailyReminderEnabled = "notification_daily_enabled"
    case dailyReminderTitle = "notification_daily_title"
    case dailyReminderBody = "notification_daily_body"
    case dailyReminderQuietStart = "notification_quiet_start"
    case dailyReminderQuietEnd = "notification_quiet_end"
}

final class CFRemoteConfigService {
    static let shared = CFRemoteConfigService()
    static let didRefreshNotification = Notification.Name("catfocus.remoteConfig.didRefresh")

    private let remoteConfig = RemoteConfig.remoteConfig()

    private init() {}

    func configure() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 12 * 60 * 60
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults([
            CFRemoteConfigKey.postcardNotificationsEnabled.rawValue: NSNumber(value: true),
            CFRemoteConfigKey.postcardNotificationTitle.rawValue: NSString(string: "A letter from Luna"),
            CFRemoteConfigKey.postcardNotificationBody.rawValue: NSString(string: "Something new just arrived in your CatFocus mailbox."),
            CFRemoteConfigKey.dailyReminderEnabled.rawValue: NSNumber(value: true),
            CFRemoteConfigKey.dailyReminderTitle.rawValue: NSString(string: "Luna is ready when you are"),
            CFRemoteConfigKey.dailyReminderBody.rawValue: NSString(string: "A small focus moment is waiting for you."),
            CFRemoteConfigKey.dailyReminderQuietStart.rawValue: NSNumber(value: 8),
            CFRemoteConfigKey.dailyReminderQuietEnd.rawValue: NSNumber(value: 21)
        ] as [String: NSObject])
    }

    func refresh() {
        remoteConfig.fetchAndActivate { _, error in
            if let error {
                Logger(subsystem: "com.catfocus.app", category: "remote-config")
                    .error("Remote Config refresh failed: \(error.localizedDescription, privacy: .public)")
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.didRefreshNotification, object: nil)
            }
        }
    }

    var postcardNotificationsEnabled: Bool {
        remoteConfig[CFRemoteConfigKey.postcardNotificationsEnabled.rawValue].boolValue
    }

    var postcardNotificationTitle: String {
        remoteConfig[CFRemoteConfigKey.postcardNotificationTitle.rawValue].stringValue
    }

    var postcardNotificationBody: String {
        remoteConfig[CFRemoteConfigKey.postcardNotificationBody.rawValue].stringValue
    }

    var dailyReminderEnabled: Bool {
        remoteConfig[CFRemoteConfigKey.dailyReminderEnabled.rawValue].boolValue
    }

    var dailyReminderTitle: String {
        remoteConfig[CFRemoteConfigKey.dailyReminderTitle.rawValue].stringValue
    }

    var dailyReminderBody: String {
        remoteConfig[CFRemoteConfigKey.dailyReminderBody.rawValue].stringValue
    }

    var dailyReminderQuietHours: Range<Int> {
        let start = min(max(remoteConfig[CFRemoteConfigKey.dailyReminderQuietStart.rawValue].numberValue.intValue, 0), 23)
        let end = min(max(remoteConfig[CFRemoteConfigKey.dailyReminderQuietEnd.rawValue].numberValue.intValue, 1), 24)
        return start..<max(start + 1, end)
    }
}

extension CFAppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        Logger(subsystem: "com.catfocus.app", category: "messaging")
            .debug("FCM token refreshed: \(fcmToken.prefix(8), privacy: .public)…")
    }
}
