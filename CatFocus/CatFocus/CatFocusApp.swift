//
//  CatFocusApp.swift
//  CatFocus
//
//  Created by Humphrey Yeung on 6/14/26.
//

import SwiftUI
import UIKit

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

final class CFAppDelegate: NSObject, UIApplicationDelegate {
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
