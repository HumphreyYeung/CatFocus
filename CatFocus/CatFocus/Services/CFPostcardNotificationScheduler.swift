import Foundation
import UserNotifications

enum CFPostcardNotificationCenter {
    static let didTapNotification = Notification.Name("catfocus.postcard.didTapNotification")
    static let pendingPostcardIDKey = "catfocus.postcard.pendingPresentationID"
    static let categoryIdentifier = "catfocus.postcard.arrival"
    static let threadIdentifier = "catfocus.postcard.mailbox"
}

enum CFPostcardNotificationScheduler {
    private static let requestID = "catfocus.postcard.pending"

    static func schedule(_ postcard: ScheduledPostcard?) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestID])

        guard let postcard, CFRemoteConfigService.shared.postcardNotificationsEnabled else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = CFLocalization.text(CFRemoteConfigService.shared.postcardNotificationTitle)
        content.body = CFLocalization.text(CFRemoteConfigService.shared.postcardNotificationBody)
        content.sound = .default
        content.categoryIdentifier = CFPostcardNotificationCenter.categoryIdentifier
        content.threadIdentifier = CFPostcardNotificationCenter.threadIdentifier
        content.relevanceScore = 0.7
        content.userInfo = ["postcardID": postcard.postcardID]

        let delay = max(1, postcard.deliverAt.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: requestID,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }
}

enum CFDailyReminderScheduler {
    private static let requestID = "catfocus.daily-reminder"

    static func setDefaultPreference(for reminderTimeID: String) {
        guard let time = ReminderTime(rawValue: reminderTimeID) else { return }
        UserDefaults.standard.set(true, forKey: Preference.enabledKey)
        UserDefaults.standard.set(time.hour, forKey: Preference.hourKey)
        UserDefaults.standard.set(time.minute, forKey: Preference.minuteKey)
    }

    static func schedule(hasCompletedToday: Bool) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestID])

        guard UserDefaults.standard.bool(forKey: Preference.enabledKey),
              !hasCompletedToday,
              CFRemoteConfigService.shared.dailyReminderEnabled else { return }

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral else { return }

        let hour = min(max(UserDefaults.standard.integer(forKey: Preference.hourKey), 0), 23)
        let minute = min(max(UserDefaults.standard.integer(forKey: Preference.minuteKey), 0), 59)
        guard CFRemoteConfigService.shared.dailyReminderQuietHours.contains(hour) else { return }

        let content = UNMutableNotificationContent()
        content.title = CFLocalization.text(CFRemoteConfigService.shared.dailyReminderTitle)
        content.body = CFLocalization.text(CFRemoteConfigService.shared.dailyReminderBody)
        content.sound = .default
        content.categoryIdentifier = CFPostcardNotificationCenter.categoryIdentifier
        content.threadIdentifier = "catfocus.daily-reminder"
        content.relevanceScore = 0.4
        content.userInfo = ["notificationType": "daily_reminder"]

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private enum Preference {
        static let enabledKey = "catfocus.dailyReminder.enabled"
        static let hourKey = "catfocus.dailyReminder.hour"
        static let minuteKey = "catfocus.dailyReminder.minute"
    }

    private enum ReminderTime: String {
        case morning
        case midday
        case afternoon
        case evening

        var hour: Int {
            switch self {
            case .morning: 8
            case .midday: 12
            case .afternoon: 15
            case .evening: 19
            }
        }

        var minute: Int {
            self == .midday ? 30 : 0
        }
    }
}
