//
//  CatFocusApp.swift
//  CatFocus
//
//  Created by Humphrey Yeung on 6/14/26.
//

import SwiftUI
import UIKit
import UserNotifications

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
        }

        UIViewController.attemptRotationToDeviceOrientation()
    }
}

final class CFAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
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
