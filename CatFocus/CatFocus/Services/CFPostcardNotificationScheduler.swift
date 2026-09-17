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

        guard let postcard else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
                || settings.authorizationStatus == .ephemeral else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "A letter from Luna"
        content.body = "Something new just arrived in your CatFocus mailbox."
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
