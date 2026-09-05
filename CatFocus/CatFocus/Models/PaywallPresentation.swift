import SwiftUI
import OSLog

enum CFPaywallSource: Equatable {
    case startTraining
    case premiumPose(TrainingPose)
    case settings
}

struct CFPaywallRequest: Identifiable {
    let id = UUID()
    let source: CFPaywallSource
}

enum CFPaywallEvent: Equatable {
    case paywallViewed(source: CFPaywallSource)
    case planSelected(OnboardingPlan)
    case purchaseStarted(OnboardingPlan)
    case purchaseSucceeded(OnboardingPlan)
    case restoreAttempted
    case paywallDismissed(source: CFPaywallSource)
}

enum CFPaywallEventLogger {
    private static let logger = Logger(subsystem: "com.catfocus.app", category: "paywall")

    static func record(_ event: CFPaywallEvent) {
        // Local-only during simulated purchases; replace this sink before production StoreKit.
        logger.debug("Paywall event: \(String(describing: event), privacy: .public)")
    }
}
