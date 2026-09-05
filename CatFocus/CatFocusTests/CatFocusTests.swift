//
//  CatFocusTests.swift
//  CatFocusTests
//
//  Created by Humphrey Yeung on 6/14/26.
//

import Testing
import Foundation
@testable import CatFocus

struct CatFocusTests {

    @Test @MainActor func entitlementDefaultsToLockedAndCanPurchase() {
        let defaults = UserDefaults(suiteName: "CatFocusTests.entitlementDefaultsToLockedAndCanPurchase")!
        defaults.removePersistentDomain(forName: "CatFocusTests.entitlementDefaultsToLockedAndCanPurchase")
        let store = CFEntitlementStore(defaults: defaults, arguments: [])

        #expect(store.hasPremiumAccess == false)
        #expect(store.purchase(plan: .weekly) == true)
        #expect(store.hasPremiumAccess == true)
        #expect(store.selectedPlan == .weekly)
    }

    @Test @MainActor func entitlementPersistsAndRestoreDoesNotGrantAccess() {
        let suiteName = "CatFocusTests.entitlementPersistsAndRestoreDoesNotGrantAccess"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let purchasedStore = CFEntitlementStore(defaults: defaults, arguments: [])
        _ = purchasedStore.purchase(plan: .lifetime)

        let restartedStore = CFEntitlementStore(defaults: defaults, arguments: [])
        #expect(restartedStore.hasPremiumAccess == true)
        #expect(restartedStore.selectedPlan == .lifetime)

        defaults.removeObject(forKey: "hasPremiumAccess")
        let lockedStore = CFEntitlementStore(defaults: defaults, arguments: [])
        #expect(lockedStore.restorePurchases() == false)
        #expect(lockedStore.hasPremiumAccess == false)
    }

    @Test @MainActor func entitlementResetLaunchArgumentClearsAccess() {
        let suiteName = "CatFocusTests.entitlementResetLaunchArgumentClearsAccess"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(true, forKey: "hasPremiumAccess")

        let store = CFEntitlementStore(defaults: defaults, arguments: ["UITEST_RESET_PREMIUM"])
        #expect(store.hasPremiumAccess == false)
    }

    @Test func defaultCatNameIsLuna() {
        #expect(CatProfile.default.name == "Luna")
    }

    @Test func healthStatusMapsFromFitnessScoreThresholds() {
        #expect(FitnessScore(0).healthStatus == .lowEnergy)
        #expect(FitnessScore(24).healthStatus == .lowEnergy)
        #expect(FitnessScore(25).healthStatus == .needsTraining)
        #expect(FitnessScore(49).healthStatus == .needsTraining)
        #expect(FitnessScore(50).healthStatus == .healthy)
        #expect(FitnessScore(74).healthStatus == .healthy)
        #expect(FitnessScore(75).healthStatus == .strong)
        #expect(FitnessScore(89).healthStatus == .strong)
        #expect(FitnessScore(90).healthStatus == .peakForm)
        #expect(FitnessScore(100).healthStatus == .peakForm)

        #expect(FitnessScore(75).catHealthState == .strong)
        #expect(FitnessScore(89).catHealthState == .strong)
        #expect(FitnessScore(90).catHealthState == .peak)
        #expect(FitnessScore(100).catHealthState == .peak)
    }

    @Test func fitnessScoreClampsToValidRange() {
        #expect(FitnessScore(-10).value == 0)
        #expect(FitnessScore(42).value == 42)
        #expect(FitnessScore(140).value == 100)
    }

    @Test func fitPointsRepresentSignedImmediateFeedback() {
        #expect(FitPoints.trainingSuccess(durationMinutes: 25).value == 100)
        #expect(FitPoints.trainingSuccess(durationMinutes: 15).value == 60)
        #expect(FitPoints.trainingFailure.value == -50)
        #expect(FitPoints.onboardingTrial.value == 10)
    }

    @Test func trainingRecordUsesOneDurationRule() {
        let successful = TrainingSessionRecord(
            outcome: TrainingSessionOutcome(
                state: .success,
                plannedMinutes: 25,
                elapsedSeconds: 1_499
            )
        )
        let abandoned = TrainingSessionRecord(
            outcome: TrainingSessionOutcome(
                state: .failure,
                plannedMinutes: 25,
                elapsedSeconds: 89
            )
        )

        #expect(successful.focusMinutes == 25)
        #expect(abandoned.focusMinutes == 1)
    }

    @Test func defaultBrandingUsesDynamicCatFocusName() {
        let branding = CFBranding.default

        #expect(branding.productName == "CatFocus")
        #expect(branding.appStoreName == "CatFocus")
        #expect(branding.shareTagline == "Focus with Luna")
    }

}
