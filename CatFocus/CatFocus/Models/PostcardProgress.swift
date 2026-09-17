import Foundation

struct PostcardDefinition: Identifiable, Equatable, Sendable {
    let id: String
    let tierThreshold: Int
    let title: String
    let imageName: String
    let dateLine: String
    let letter: String
    let accessibilityDescription: String
}

enum PostcardCatalog {
    static let deliveryOffsets = [0, 3, 7]
    static let tierThresholds = [3, 7, 14, 30]

    static let welcome = PostcardDefinition(
        id: "welcome-letter",
        tierThreshold: 0,
        title: "Our Little Pact",
        imageName: "luna-onboarding-pact",
        dateLine: "Today · Luna's desk",
        letter: "Dear human, you keep showing up and I will keep writing. This is our little pact. I cannot promise perfect handwriting, but I can promise excellent stories. — Luna",
        accessibilityDescription: "Luna writing the first letter at her desk"
    )

    // MVP placeholders reuse bundled Luna artwork until the 12 launch photos
    // and final handwritten copy are delivered.
    static let all: [PostcardDefinition] = [
        PostcardDefinition(
            id: "first-scoop",
            tierThreshold: 3,
            title: "The Missing Scoop",
            imageName: "CollectionPoster01",
            dateLine: "Day 3 · The kitchen",
            letter: "Dear human, I investigated the ice cream very carefully. It disappeared. A mystery! Please stay focused while I continue the case. — Luna",
            accessibilityDescription: "Luna investigating a treat in the kitchen"
        ),
        PostcardDefinition(
            id: "tiny-workout",
            tierThreshold: 3,
            title: "Tiny Workout",
            imageName: "CollectionPoster02",
            dateLine: "Day 3 · Luna's gym",
            letter: "I trained today too. Mine looked more impressive, obviously. We are getting stronger one quiet session at a time. — Luna",
            accessibilityDescription: "Luna doing an enthusiastic first workout"
        ),
        PostcardDefinition(
            id: "window-nap",
            tierThreshold: 3,
            title: "A Very Brief Nap",
            imageName: "CollectionPoster03",
            dateLine: "Day 3 · The sunny window",
            letter: "I saved you the warmest patch of sunlight. I may have used it first, but the thought still counts. — Luna",
            accessibilityDescription: "Luna napping beside a sunny window"
        ),
        PostcardDefinition(
            id: "bookstore-helper",
            tierThreshold: 7,
            title: "Bookstore Helper",
            imageName: "CollectionPoster04",
            dateLine: "Day 7 · The corner bookstore",
            letter: "I found a book about discipline. I sat on it until the lesson made sense. Your week of practice is working. — Luna",
            accessibilityDescription: "Luna reading at a quiet bookstore"
        ),
        PostcardDefinition(
            id: "rainy-day",
            tierThreshold: 7,
            title: "Rainy Day Report",
            imageName: "CollectionPoster05",
            dateLine: "Day 7 · Home",
            letter: "Rain outside, warm paws inside. You kept your promise this week, so I kept your seat warm. — Luna",
            accessibilityDescription: "Luna resting indoors on a rainy day"
        ),
        PostcardDefinition(
            id: "jump-rope-club",
            tierThreshold: 7,
            title: "Jump Rope Club",
            imageName: "CollectionPoster06",
            dateLine: "Day 7 · The neighborhood gym",
            letter: "I joined a club. There is only one member and the rules include frequent snacks. You would fit right in. — Luna",
            accessibilityDescription: "Luna practicing jump rope at the gym"
        ),
        PostcardDefinition(
            id: "pool-day",
            tierThreshold: 14,
            title: "Pool Day",
            imageName: "CollectionPoster07",
            dateLine: "Day 14 · The community pool",
            letter: "Two whole weeks! I celebrated by learning to swim without getting my whiskers wet. Mostly. — Luna",
            accessibilityDescription: "Luna swimming at a community pool"
        ),
        PostcardDefinition(
            id: "friends-night",
            tierThreshold: 14,
            title: "Friends Night",
            imageName: "CollectionPoster08",
            dateLine: "Day 14 · A friend's place",
            letter: "I told everyone about my focused human. They were impressed. I pretended this happens all the time. — Luna",
            accessibilityDescription: "Luna spending an evening with friends"
        ),
        PostcardDefinition(
            id: "bike-lane",
            tierThreshold: 14,
            title: "The Long Way Home",
            imageName: "CollectionPoster09",
            dateLine: "Day 14 · The riverside path",
            letter: "I took the long way home. It turns out steady progress has excellent scenery. Keep going. — Luna",
            accessibilityDescription: "Luna cycling along a riverside path"
        ),
        PostcardDefinition(
            id: "victory-photo",
            tierThreshold: 30,
            title: "Victory Photo",
            imageName: "CollectionPoster10",
            dateLine: "Day 30 · Our favorite spot",
            letter: "Thirty days of showing up deserves a dramatic photograph. I am proud of us, but especially of you. — Luna",
            accessibilityDescription: "Luna proudly celebrating thirty active days"
        ),
        PostcardDefinition(
            id: "boxing-morning",
            tierThreshold: 30,
            title: "Morning Champion",
            imageName: "CollectionPoster11",
            dateLine: "Day 30 · The old gym",
            letter: "Consistency is a strange superpower. You built it quietly, one session at a time. I brought the gloves. — Luna",
            accessibilityDescription: "Luna training like a champion in a boxing gym"
        ),
        PostcardDefinition(
            id: "peak-form",
            tierThreshold: 30,
            title: "Peak Form",
            imageName: "CollectionPoster12",
            dateLine: "Day 30 · Somewhere impressive",
            letter: "Look how far we came. The view is excellent and so is your focus. We should still take a nap, though. — Luna",
            accessibilityDescription: "Luna celebrating at peak fitness"
        )
    ]

    static var tiers: [(threshold: Int, postcards: [PostcardDefinition])] {
        tierThresholds.map { threshold in
            (threshold, all.filter { $0.tierThreshold == threshold })
        }
    }

    static func definition(id: String) -> PostcardDefinition? {
        id == welcome.id ? welcome : all.first { $0.id == id }
    }
}

struct ScheduledPostcard: Codable, Equatable, Sendable {
    let postcardID: String
    let deliverAt: Date
}

struct PostcardProgressV1: Codable, Equatable, Sendable {
    var hasEverUnlockedCatalog = false
    var hasCompletedMigration = false
    var activeDayKeys: Set<String> = []
    var processedSessionIDs: Set<UUID> = []
    var tierOrders: [Int: [String]] = [:]
    var queuedPostcardIDs: [String] = []
    var pendingPostcard: ScheduledPostcard?
    var deliveredPostcardIDs: [String] = []
    var readPostcardIDs: Set<String> = []
    var lastDeliveredAt: Date?

    var activeDayCount: Int { activeDayKeys.count }

    func isDelivered(_ postcardID: String) -> Bool {
        deliveredPostcardIDs.contains(postcardID)
    }

    func isUnread(_ postcardID: String) -> Bool {
        isDelivered(postcardID) && !readPostcardIDs.contains(postcardID)
    }

    func requiredActiveDays(for postcard: PostcardDefinition) -> Int {
        guard let order = tierOrders[postcard.tierThreshold],
              let index = order.firstIndex(of: postcard.id),
              PostcardCatalog.deliveryOffsets.indices.contains(index) else {
            return postcard.tierThreshold
        }

        // The first successful Focus delivers the first tier's first card
        // immediately. Continue that tier relative to the starter reward:
        // day 1, then three more active days, then seven more.
        if postcard.tierThreshold == (PostcardCatalog.tierThresholds.first ?? 3),
           let firstTier = PostcardCatalog.tiers.first,
           deliveredPostcardIDs.contains(where: { firstTier.postcards.map(\.id).contains($0) }) {
            return [1, 4, 11][index]
        }

        return postcard.tierThreshold + PostcardCatalog.deliveryOffsets[index]
    }

    var nextRequiredActiveDays: Int? {
        PostcardCatalog.all
            .filter { postcard in
                !isDelivered(postcard.id)
                    && pendingPostcard?.postcardID != postcard.id
                    && !queuedPostcardIDs.contains(postcard.id)
            }
            .map(requiredActiveDays(for:))
            .filter { $0 > activeDayCount }
            .min()
    }
}

enum PostcardProgressStore {
    static let storageKey = "postcardProgress.v1"

    static func load(from data: Data) -> PostcardProgressV1 {
        guard !data.isEmpty else { return PostcardProgressV1() }
        return (try? JSONDecoder().decode(PostcardProgressV1.self, from: data)) ?? PostcardProgressV1()
    }

    static func save(_ progress: PostcardProgressV1) -> Data {
        (try? JSONEncoder().encode(progress)) ?? Data()
    }
}

enum PostcardProgressEngine {
    static func prepare(
        progress: PostcardProgressV1,
        existingRecords: [TrainingSessionRecord],
        hasPremiumAccess: Bool,
        now: Date = .now,
        calendar: Calendar = .current,
        randomDelayHours: Int? = nil
    ) -> PostcardProgressV1 {
        var updated = progress
        var shouldSyncEligiblePostcards = hasPremiumAccess

        if hasPremiumAccess {
            updated.hasEverUnlockedCatalog = true
        }

        if !updated.hasCompletedMigration {
            let successfulRecords = existingRecords.filter { $0.result == .success }
            if hasPremiumAccess || !successfulRecords.isEmpty {
                updated.hasEverUnlockedCatalog = true
            }
            shouldSyncEligiblePostcards = shouldSyncEligiblePostcards || !successfulRecords.isEmpty
            for record in successfulRecords {
                updated.processedSessionIDs.insert(record.id)
                updated.activeDayKeys.insert(dayKey(for: record.date, calendar: calendar))
            }
            updated.hasCompletedMigration = true
        }

        if shouldSyncEligiblePostcards {
            syncEligiblePostcards(progress: &updated)
        }
        deliverAndSchedule(progress: &updated, now: now, calendar: calendar, randomDelayHours: randomDelayHours)
        return updated
    }

    static func record(
        _ record: TrainingSessionRecord,
        progress: PostcardProgressV1,
        hasPremiumAccess: Bool,
        now: Date = .now,
        calendar: Calendar = .current,
        randomDelayHours: Int? = nil
    ) -> PostcardProgressV1 {
        var updated = progress
        guard hasPremiumAccess, record.result == .success else { return updated }
        guard updated.processedSessionIDs.insert(record.id).inserted else { return updated }

        updated.hasEverUnlockedCatalog = true
        updated.activeDayKeys.insert(dayKey(for: record.date, calendar: calendar))
        deliverStarterPostcardIfNeeded(progress: &updated, now: now)
        syncEligiblePostcards(progress: &updated)
        deliverAndSchedule(progress: &updated, now: now, calendar: calendar, randomDelayHours: randomDelayHours)
        return updated
    }

    static func refresh(
        progress: PostcardProgressV1,
        now: Date = .now,
        calendar: Calendar = .current,
        randomDelayHours: Int? = nil
    ) -> PostcardProgressV1 {
        var updated = progress
        deliverAndSchedule(progress: &updated, now: now, calendar: calendar, randomDelayHours: randomDelayHours)
        return updated
    }

    static func markRead(_ postcardID: String, progress: PostcardProgressV1) -> PostcardProgressV1 {
        var updated = progress
        guard updated.isDelivered(postcardID) else { return updated }
        updated.readPostcardIDs.insert(postcardID)
        return updated
    }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    static func normalizedDeliveryDate(
        from date: Date,
        calendar: Calendar = .current
    ) -> Date {
        let hour = calendar.component(.hour, from: date)
        if hour < 9 {
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        }
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        if hour > 21 || (hour == 21 && (minute > 0 || second > 0)) {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        }
        return date
    }

    private static func syncEligiblePostcards(progress: inout PostcardProgressV1) {
        for tier in PostcardCatalog.tiers where progress.activeDayCount >= tier.threshold {
            let order: [String]
            if let existingOrder = progress.tierOrders[tier.threshold], existingOrder.count == tier.postcards.count {
                order = existingOrder
            } else {
                order = tier.postcards.map(\.id).shuffled()
                progress.tierOrders[tier.threshold] = order
            }

            for (index, postcardID) in order.enumerated() {
                let requiredDays = progress.requiredActiveDays(for: tier.postcards[index])
                guard progress.activeDayCount >= requiredDays else { continue }
                let alreadyKnown = progress.isDelivered(postcardID)
                    || progress.pendingPostcard?.postcardID == postcardID
                    || progress.queuedPostcardIDs.contains(postcardID)
                if !alreadyKnown {
                    progress.queuedPostcardIDs.append(postcardID)
                }
            }
        }
    }

    /// The first successful focus is the user's first clear reward for subscribing.
    /// It uses the first card in the persisted first-tier order so the catalog
    /// remains exactly twelve cards and later milestones stay deterministic.
    private static func deliverStarterPostcardIfNeeded(
        progress: inout PostcardProgressV1,
        now: Date
    ) {
        guard progress.deliveredPostcardIDs.isEmpty,
              progress.pendingPostcard == nil,
              progress.queuedPostcardIDs.isEmpty,
              let firstTier = PostcardCatalog.tiers.first,
              !firstTier.postcards.isEmpty else { return }

        let order: [String]
        if let existingOrder = progress.tierOrders[firstTier.threshold],
           existingOrder.count == firstTier.postcards.count {
            order = existingOrder
        } else {
            order = firstTier.postcards.map(\.id).shuffled()
            progress.tierOrders[firstTier.threshold] = order
        }

        guard let starterID = order.first else { return }
        progress.deliveredPostcardIDs.insert(starterID, at: 0)
        progress.lastDeliveredAt = now
    }

    private static func deliverAndSchedule(
        progress: inout PostcardProgressV1,
        now: Date,
        calendar: Calendar,
        randomDelayHours: Int?
    ) {
        if let pending = progress.pendingPostcard, pending.deliverAt <= now {
            if !progress.deliveredPostcardIDs.contains(pending.postcardID) {
                progress.deliveredPostcardIDs.insert(pending.postcardID, at: 0)
            }
            progress.lastDeliveredAt = pending.deliverAt
            progress.pendingPostcard = nil
        }

        guard progress.pendingPostcard == nil, !progress.queuedPostcardIDs.isEmpty else { return }
        let postcardID = progress.queuedPostcardIDs.removeFirst()
        let delayHours = min(72, max(12, randomDelayHours ?? Int.random(in: 12...72)))
        let candidate = calendar.date(byAdding: .hour, value: delayHours, to: now) ?? now
        let minimumSpacing = progress.lastDeliveredAt.flatMap {
            calendar.date(byAdding: .hour, value: 24, to: $0)
        } ?? candidate
        let spacedCandidate = max(candidate, minimumSpacing)
        progress.pendingPostcard = ScheduledPostcard(
            postcardID: postcardID,
            deliverAt: normalizedDeliveryDate(from: spacedCandidate, calendar: calendar)
        )
    }
}
