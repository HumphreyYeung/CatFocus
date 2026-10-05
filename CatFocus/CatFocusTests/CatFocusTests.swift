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
        #expect(store.purchase(plan: .annual) == true)
        #expect(store.hasPremiumAccess == true)
        #expect(store.selectedPlan == .annual)
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

    @Test func postcardActiveDaysIgnoreFailuresDuplicatesAndSameDaySessions() {
        let calendar = postcardCalendar
        let firstSuccess = trainingRecord(.success, date: postcardDate(day: 1, hour: 10, calendar: calendar))
        let secondSuccess = trainingRecord(.success, date: postcardDate(day: 1, hour: 18, calendar: calendar))
        let failure = trainingRecord(.failure, date: postcardDate(day: 2, hour: 10, calendar: calendar))
        var progress = PostcardProgressV1(hasCompletedMigration: true)

        progress = PostcardProgressEngine.record(
            firstSuccess,
            progress: progress,
            hasPremiumAccess: true,
            calendar: calendar,
            randomDelayHours: 12
        )
        progress = PostcardProgressEngine.record(
            secondSuccess,
            progress: progress,
            hasPremiumAccess: true,
            calendar: calendar,
            randomDelayHours: 12
        )
        progress = PostcardProgressEngine.record(
            failure,
            progress: progress,
            hasPremiumAccess: true,
            calendar: calendar,
            randomDelayHours: 12
        )
        progress = PostcardProgressEngine.record(
            firstSuccess,
            progress: progress,
            hasPremiumAccess: true,
            calendar: calendar,
            randomDelayHours: 12
        )

        #expect(progress.activeDayCount == 1)
        #expect(progress.processedSessionIDs == [firstSuccess.id, secondSuccess.id])
        #expect(progress.queuedPostcardIDs.isEmpty)
        #expect(progress.pendingPostcard == nil)
        #expect(progress.deliveredPostcardIDs.count == 1)
        #expect(PostcardCatalog.all.contains { progress.deliveredPostcardIDs.contains($0.id) })

        let firstTier = PostcardCatalog.tiers[0]
        let starterID = progress.deliveredPostcardIDs[0]
        #expect(progress.requiredActiveDays(for: PostcardCatalog.definition(id: starterID)!) == 1)
        #expect(firstTier.postcards
            .filter { $0.id != starterID }
            .map { progress.requiredActiveDays(for: $0) }
            .sorted() == [4, 11])
    }

    @Test func postcardMilestonesGenerateEveryCardOnceAndPersistTierOrder() {
        let calendar = postcardCalendar
        let now = postcardDate(day: 1, hour: 10, calendar: calendar)
        var progress = PostcardProgressV1(hasCompletedMigration: true)

        for day in 1...37 {
            progress = PostcardProgressEngine.record(
                trainingRecord(.success, date: postcardDate(day: day, hour: 10, calendar: calendar)),
                progress: progress,
                hasPremiumAccess: true,
                now: now,
                calendar: calendar,
                randomDelayHours: 12
            )
        }

        let scheduledIDs = [progress.pendingPostcard?.postcardID].compactMap { $0 }
            + progress.queuedPostcardIDs
            + progress.deliveredPostcardIDs
        #expect(scheduledIDs.count == 12)
        #expect(Set(scheduledIDs).count == 12)
        #expect(Set(scheduledIDs) == Set(PostcardCatalog.all.map(\.id)))

        for tier in PostcardCatalog.tiers {
            let storedOrder = progress.tierOrders[tier.threshold] ?? []
            #expect(storedOrder.count == 3)
            #expect(Set(storedOrder) == Set(tier.postcards.map(\.id)))
        }

        let roundTrip = PostcardProgressStore.load(from: PostcardProgressStore.save(progress))
        #expect(roundTrip.tierOrders == progress.tierOrders)
        #expect(roundTrip == progress)
    }

    @Test func postcardDeliveryWindowUsesLocalNineToTwentyOneBoundary() {
        let calendar = postcardCalendar
        let early = postcardDate(day: 4, hour: 7, minute: 30, calendar: calendar)
        let daytime = postcardDate(day: 4, hour: 15, minute: 45, calendar: calendar)
        let closingTime = postcardDate(day: 4, hour: 21, minute: 0, calendar: calendar)
        let late = postcardDate(day: 4, hour: 21, minute: 1, calendar: calendar)

        let normalizedEarly = PostcardProgressEngine.normalizedDeliveryDate(from: early, calendar: calendar)
        let normalizedDaytime = PostcardProgressEngine.normalizedDeliveryDate(from: daytime, calendar: calendar)
        let normalizedClosingTime = PostcardProgressEngine.normalizedDeliveryDate(from: closingTime, calendar: calendar)
        let normalizedLate = PostcardProgressEngine.normalizedDeliveryDate(from: late, calendar: calendar)

        #expect(calendar.component(.hour, from: normalizedEarly) == 9)
        #expect(normalizedDaytime == daytime)
        #expect(normalizedClosingTime == closingTime)
        #expect(calendar.component(.day, from: normalizedLate) == 5)
        #expect(calendar.component(.hour, from: normalizedLate) == 9)
    }

    @Test func expiredAccessKeepsDeliveriesButDoesNotCreateProgress() {
        let calendar = postcardCalendar
        let now = postcardDate(day: 10, hour: 12, calendar: calendar)
        let duePostcard = PostcardCatalog.all[0].id
        let queuedPostcard = PostcardCatalog.all[1].id
        var progress = PostcardProgressV1(
            hasEverUnlockedCatalog: true,
            hasCompletedMigration: true,
            activeDayKeys: ["2026-08-01", "2026-08-02"],
            queuedPostcardIDs: [queuedPostcard],
            pendingPostcard: ScheduledPostcard(
                postcardID: duePostcard,
                deliverAt: postcardDate(day: 10, hour: 11, calendar: calendar)
            )
        )

        progress = PostcardProgressEngine.record(
            trainingRecord(.success, date: now),
            progress: progress,
            hasPremiumAccess: false,
            now: now,
            calendar: calendar,
            randomDelayHours: 12
        )
        #expect(progress.activeDayCount == 2)

        progress = PostcardProgressEngine.prepare(
            progress: progress,
            existingRecords: [],
            hasPremiumAccess: false,
            now: now,
            calendar: calendar,
            randomDelayHours: 12
        )

        #expect(progress.deliveredPostcardIDs == [duePostcard])
        #expect(progress.pendingPostcard?.postcardID == queuedPostcard)
        #expect(progress.pendingPostcard?.deliverAt == postcardDate(day: 11, hour: 11, calendar: calendar))
        #expect(progress.activeDayCount == 2)
    }

    @Test func expiredAccessDoesNotBackfillUnqueuedMilestones() {
        var progress = PostcardProgressV1(
            hasEverUnlockedCatalog: true,
            hasCompletedMigration: true,
            activeDayKeys: Set((1...10).map { "2026-08-\(String(format: "%02d", $0))" })
        )

        progress = PostcardProgressEngine.prepare(
            progress: progress,
            existingRecords: [],
            hasPremiumAccess: false
        )

        #expect(progress.tierOrders.isEmpty)
        #expect(progress.queuedPostcardIDs.isEmpty)
        #expect(progress.pendingPostcard == nil)
    }

    private var postcardCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
        return calendar
    }

    private func postcardDate(
        day: Int,
        hour: Int,
        minute: Int = 0,
        calendar: Calendar
    ) -> Date {
        let firstDay = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 1, hour: hour, minute: minute)
        )!
        return calendar.date(byAdding: .day, value: day - 1, to: firstDay)!
    }

    private func trainingRecord(_ state: TrainingResultState, date: Date) -> TrainingSessionRecord {
        TrainingSessionRecord(
            outcome: TrainingSessionOutcome(
                state: state,
                plannedMinutes: 25,
                elapsedSeconds: state == .success ? 1_500 : 90
            ),
            date: date
        )
    }

}
