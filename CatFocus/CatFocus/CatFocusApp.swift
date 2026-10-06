//
//  CatFocusApp.swift
//  CatFocus
//
//  Created by Humphrey Yeung on 6/14/26.
//

import SwiftUI
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import OSLog

@MainActor
final class CFOrientationCoordinator {
    static let shared = CFOrientationCoordinator()

    private(set) var allowsLandscape = false

    var supportedOrientations: UIInterfaceOrientationMask {
        allowsLandscape ? [.portrait, .landscapeLeft, .landscapeRight] : .portrait
    }

    func setTrainingOrientationEnabled(_ enabled: Bool) {
        allowsLandscape = enabled

        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }

        if #available(iOS 16.0, *) {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: supportedOrientations))
            windowScene.windows
                .first(where: \.isKeyWindow)?
                .rootViewController?
                .setNeedsUpdateOfSupportedInterfaceOrientations()
        }

    }
}

final class CFAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        CFRemoteConfigService.shared.configure()
        CFRemoteConfigService.shared.refresh()
        CFAnalytics.log(.appOpened)

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        application.registerForRemoteNotifications()
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: CFPostcardNotificationCenter.categoryIdentifier,
                actions: [],
                intentIdentifiers: [],
                options: []
            )
        ])
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let postcardID = response.notification.request.content.userInfo["postcardID"] as? String
        // A cold-start notification can arrive before SwiftUI has installed
        // AppFlowView's observer, so persist the intent before posting it.
        if let postcardID {
            UserDefaults.standard.set(
                postcardID,
                forKey: CFPostcardNotificationCenter.pendingPostcardIDKey
            )
        }
        CFAnalytics.log(.notificationTapped)
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: CFPostcardNotificationCenter.didTapNotification,
                object: postcardID
            )
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        CFOrientationCoordinator.shared.supportedOrientations
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
        Logger(subsystem: "com.catfocus.app", category: "push")
            .debug("APNs registration succeeded")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Logger(subsystem: "com.catfocus.app", category: "push")
            .error("APNs registration failed: \(error.localizedDescription, privacy: .public)")
    }
}

@main
struct CatFocusApp: App {
    @UIApplicationDelegateAdaptor(CFAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
