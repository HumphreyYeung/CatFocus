import SwiftUI
import OSLog

enum CFPaywallSource: Equatable {
    case startTraining
    case premiumPose(TrainingPose)
    case myCatPostcards
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
        logger.debug("Paywall event: \(String(describing: event), privacy: .public)")

        switch event {
        case let .paywallViewed(source):
            CFAnalytics.log(.paywallViewed(source: String(describing: source)))
        case let .purchaseStarted(plan):
            CFAnalytics.log(.purchaseStarted(productID: String(describing: plan)))
        case let .purchaseSucceeded(plan):
            CFAnalytics.log(.purchaseSucceeded(productID: String(describing: plan)))
        case .restoreAttempted:
            CFAnalytics.log(.restoreAttempted)
        case .planSelected, .paywallDismissed:
            break
        }
    }
}
