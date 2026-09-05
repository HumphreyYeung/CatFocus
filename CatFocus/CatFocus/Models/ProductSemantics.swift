import Foundation
import Combine

@MainActor
final class CFEntitlementStore: ObservableObject {
    private static let accessKey = "hasPremiumAccess"
    private static let selectedPlanKey = "selectedPremiumPlan"

    @Published private(set) var hasPremiumAccess: Bool
    @Published private(set) var selectedPlan: OnboardingPlan

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, arguments: [String] = ProcessInfo.processInfo.arguments) {
        self.defaults = defaults

        if arguments.contains("UITEST_RESET_PREMIUM") {
            defaults.removeObject(forKey: Self.accessKey)
            defaults.removeObject(forKey: Self.selectedPlanKey)
        }

        hasPremiumAccess = defaults.bool(forKey: Self.accessKey)
        selectedPlan = OnboardingPlan(rawValue: defaults.string(forKey: Self.selectedPlanKey) ?? "") ?? .lifetime

        if arguments.contains("UITEST_PREMIUM") {
            hasPremiumAccess = true
            defaults.set(true, forKey: Self.accessKey)
        }
    }

    @discardableResult
    func purchase(plan: OnboardingPlan) -> Bool {
        selectedPlan = plan
        hasPremiumAccess = true
        defaults.set(true, forKey: Self.accessKey)
        defaults.set(plan.rawValue, forKey: Self.selectedPlanKey)
        return true
    }

    @discardableResult
    func restorePurchases() -> Bool {
        hasPremiumAccess = defaults.bool(forKey: Self.accessKey)
        return hasPremiumAccess
    }
}

enum PresetSound: String, CaseIterable, Identifiable, Sendable {
    case none
    case purring
    case campfire
    case cicada
    case rain
    case ocean

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "None"
        case .purring: "Purring"
        case .campfire: "Campfire"
        case .cicada: "Cicada"
        case .rain: "Rain"
        case .ocean: "Ocean"
        }
    }

    var icon: CFIcon {
        switch self {
        case .none: .ban
        case .purring: .myCat
        case .campfire: .flame
        case .cicada: .spark
        case .rain: .rain
        case .ocean: .wave
        }
    }

    var resource: (name: String, ext: String)? {
        switch self {
        case .none: nil
        case .purring: ("CatPurr", "caf")
        case .campfire: ("campfire", "m4a")
        case .cicada: ("Cicada", "caf")
        case .rain: ("rain", "m4a")
        case .ocean: ("ocean", "m4a")
        }
    }
}

enum PoseAccess: Sendable {
    case free
    case premium
}

enum TrainingPose: String, CaseIterable, Identifiable, Sendable, Hashable {
    case resting
    case training
    case kettlebell
    case lifting
    case jumpRope
    case sitUp
    case highKnees
    case victory
    case trial

    static var allCases: [TrainingPose] {
        [.training, .jumpRope, .sitUp, .highKnees, .kettlebell, .lifting]
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .resting:
            "Resting"
        case .training:
            "Run"
        case .kettlebell:
            "Kettlebell"
        case .lifting:
            "Lifting"
        case .jumpRope:
            "Jump Rope"
        case .sitUp:
            "Sit Up"
        case .highKnees:
            "High Knees"
        case .victory:
            "Victory"
        case .trial:
            "Trial"
        }
    }

    var assetName: String {
        switch self {
        case .resting:
            "luna-break-poster"
        case .training:
            "luna-pose-run-poster"
        case .kettlebell:
            "luna-pose-kettlebell-poster"
        case .lifting:
            "luna-pose-lifting-poster"
        case .jumpRope:
            "luna-pose-jump-rope-poster"
        case .sitUp:
            "luna-pose-sit-up-poster"
        case .highKnees:
            "luna-pose-high-knees-poster"
        case .victory:
            "luna-success"
        case .trial:
            "luna-onboarding-trial"
        }
    }

    var posterAssetName: String {
        assetName
    }

    var catAsset: CFCatAsset {
        switch self {
        case .resting:
            .video(name: "luna-break", poster: "luna-break-poster")
        case .training:
            .video(name: "luna-pose-run", poster: "luna-pose-run-poster")
        case .kettlebell:
            .video(name: "luna-pose-kettlebell", poster: "luna-pose-kettlebell-poster")
        case .lifting:
            .video(name: "luna-pose-lifting", poster: "luna-pose-lifting-poster")
        case .jumpRope:
            .video(name: "luna-pose-jump-rope", poster: "luna-pose-jump-rope-poster")
        case .sitUp:
            .video(name: "luna-pose-sit-up", poster: "luna-pose-sit-up-poster")
        case .highKnees:
            .video(name: "luna-pose-high-knees", poster: "luna-pose-high-knees-poster")
        case .victory:
            .staticImage(name: "luna-success")
        case .trial:
            .staticImage(name: "luna-onboarding-trial")
        }
    }

    var isLocked: Bool {
        access == .premium
    }

    var access: PoseAccess {
        switch self {
        case .kettlebell, .lifting, .trial:
            .premium
        default:
            .free
        }
    }

    static let `default`: TrainingPose = .training
}

/// Home-only mascot states. New videos can be added to this catalog without
/// changing the rotation or persistence logic below.
struct CFHomeCatVideo: Identifiable, Equatable {
    let id: String
    let videoName: String
    let posterName: String

    var asset: CFCatAsset {
        .video(name: videoName, poster: posterName)
    }

    static let catalog: [CFHomeCatVideo] = [
        CFHomeCatVideo(
            id: "cup",
            videoName: "cup_01",
            posterName: "cup_01-poster"
        ),
        CFHomeCatVideo(
            id: "lying",
            videoName: "lying_01",
            posterName: "lying_01-poster"
        ),
        CFHomeCatVideo(
            id: "reading",
            videoName: "reading_01",
            posterName: "reading_01-poster"
        ),
        CFHomeCatVideo(
            id: "napping",
            videoName: "napping_01",
            posterName: "napping_01-poster"
        )
    ]

    static func random(excluding id: String? = nil) -> CFHomeCatVideo {
        let candidates = catalog.filter { $0.id != id }
        return (candidates.isEmpty ? catalog : candidates).randomElement() ?? catalog[0]
    }
}

@MainActor
final class CFHomeCatRotationStore: ObservableObject {
    private static let stateKey = "homeCatVideoState"
    private static let startedAtKey = "homeCatVideoStartedAt"
    static let minimumDisplayDuration: TimeInterval = 60 * 60

    @Published private(set) var current: CFHomeCatVideo
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let savedID = defaults.string(forKey: Self.stateKey)
        let savedDate = defaults.object(forKey: Self.startedAtKey) as? Date
        let savedState = CFHomeCatVideo.catalog.first { $0.id == savedID }

        if let savedState, let savedDate,
           Date().timeIntervalSince(savedDate) < Self.minimumDisplayDuration {
            current = savedState
        } else {
            current = CFHomeCatVideo.random(excluding: savedID)
            persist(current, startedAt: Date())
        }
    }

    func refreshIfNeeded(now: Date = Date()) {
        guard let startedAt = defaults.object(forKey: Self.startedAtKey) as? Date,
              now.timeIntervalSince(startedAt) >= Self.minimumDisplayDuration else {
            return
        }

        let next = CFHomeCatVideo.random(excluding: current.id)
        current = next
        persist(next, startedAt: now)
    }

    private func persist(_ state: CFHomeCatVideo, startedAt: Date) {
        defaults.set(state.id, forKey: Self.stateKey)
        defaults.set(startedAt, forKey: Self.startedAtKey)
    }
}

struct CatProfile: Equatable, Sendable {
    var name: String
    var fitnessScore: FitnessScore
    var fitPoints: Int

    static let `default` = CatProfile(
        name: "Luna",
        fitnessScore: FitnessScore(42),
        fitPoints: 0
    )
}

struct FitnessScore: Equatable, Sendable {
    let value: Int

    init(_ value: Int) {
        self.value = min(100, max(0, value))
    }

    var healthStatus: HealthStatus {
        switch value {
        case 0..<25:
            .lowEnergy
        case 25..<50:
            .needsTraining
        case 50..<75:
            .healthy
        case 75..<90:
            .strong
        default:
            .peakForm
        }
    }

    var catHealthState: CatHealthState {
        CatHealthState(score: value)
    }
}

enum CatHealthState: String, CaseIterable, Sendable, Hashable {
    case sick
    case sleeping
    case lively
    case strong
    case peak

    init(score: Int) {
        switch score {
        case 0..<25:
            self = .sick
        case 25..<50:
            self = .sleeping
        case 50..<75:
            self = .lively
        case 75..<90:
            self = .strong
        default:
            self = .peak
        }
    }

    var assetName: String {
        switch self {
        case .sick:
            "luna-health-sick"
        case .sleeping:
            "luna-health-sleeping"
        case .lively:
            "luna-health-lively"
        case .strong:
            "luna-health-strong"
        case .peak:
            "luna-health-peak"
        }
    }

    var fallbackAssetName: String {
        switch self {
        case .sick:
            "luna-training"
        case .sleeping:
            "luna-focus"
        case .lively, .strong:
            "luna-success"
        case .peak:
            // Reuse Luna's strongest existing artwork until a dedicated Peak
            // illustration is added to the asset catalog.
            "luna-success"
        }
    }
}

enum CatBubbleMoment: String, Sendable, Hashable {
    case home
    case idle
    case active
    case halfway
    case almostDone
    case paused
}

struct CatBubbleContext: Equatable, Sendable {
    var pose: TrainingPose?
    var health: CatHealthState
    var moment: CatBubbleMoment

    init(
        pose: TrainingPose? = nil,
        health: CatHealthState,
        moment: CatBubbleMoment
    ) {
        self.pose = pose
        self.health = health
        self.moment = moment
    }
}

/// Central catalog for contextual mascot messages. Add a pose or moment here
/// without changing the Home or Training view layout.
enum CatBubbleCatalog {
    private static let fallbackMessage = "LET'S MAKE TODAY COUNT!"

    private static let homeMessages: [CatHealthState: [String]] = [
        .sick: [
            "I WOULD PREFER A NAP, BUT... FINE.",
            "MY LEGS HAVE FILED A COMPLAINT."
        ],
        .sleeping: [
            "CAN WE TRAIN AFTER ONE MORE NAP?",
            "I WAS VERY BUSY DOING NOTHING."
        ],
        .lively: [
            "I AM READY. EVENTUALLY.",
            "FINE, LET'S MAKE THIS LOOK EASY."
        ],
        .strong: [
            "I DID NOT GET THIS STRONG BY ACCIDENT.",
            "A LITTLE WORK, THEN A BIG NAP."
        ]
    ]

    private static let momentMessages: [CatBubbleMoment: String] = [
        .idle: "READY WHEN YOU ARE?",
        .active: "NO PAIN, NO GAIN!",
        .halfway: "HALFWAY THERE. KEEP PUSHING!",
        .almostDone: "ONE LAST PUSH!",
        .paused: "TAKE A BREATH. WE'LL BE HERE.",
        .home: fallbackMessage
    ]

    private static let poseMessages: [TrainingPose: [CatBubbleMoment: [String]]] = [
        .resting: [
            .idle: ["A QUIET START IS STILL A START.", "I AM WARMING UP MY MOTIVATION."],
            .active: ["BREATHE IN. PRETEND THIS IS A NAP.", "LOOK AT ME, BEING RESPONSIBLE."],
            .halfway: ["NICE AND STEADY.", "HALFWAY TO THE GOOD PART: RESTING."],
            .almostDone: ["JUST A LITTLE LONGER.", "MY PAWS ARE NEGOTIATING."],
            .paused: ["REST IS PART OF THE WORK.", "THIS PAUSE HAS MY FULL SUPPORT."]
        ],
        .training: [
            .idle: ["LET'S GET TO WORK... I SUPPOSE.", "I WAS HOPING FOR A SNACK BREAK."],
            .active: ["I AM DOING IT. LOOK AWAY, IT IS EMBARRASSING.", "THIS BETTER COUNT AS A NAP LATER."],
            .halfway: ["HALFWAY THERE. I AM IMPRESSED WITH US.", "MY MOTIVATION IS RUNNING BEHIND ME."],
            .almostDone: ["ONE LAST PUSH. THEN WE FLOP.", "ALMOST DONE. KEEP YOUR PAWS MOVING."],
            .paused: ["A PAUSE? FINALLY, A GOOD IDEA.", "I WILL BE OVER HERE RECOVERING DRAMATICALLY."]
        ],
        .victory: [
            .idle: ["LET'S EARN THAT VICTORY.", "I CAN ALREADY TASTE THE NAP."],
            .active: ["YOU'RE LOOKING STRONG.", "I AM CASUALLY BEING IMPRESSIVE."],
            .halfway: ["THAT'S THE SPIRIT.", "MY PRIDE IS DOING MOST OF THE WORK."],
            .almostDone: ["VICTORY IS CLOSE.", "ONE LAST DRAMATIC EFFORT."],
            .paused: ["EVEN CHAMPIONS PAUSE.", "CHAMPIONS ALSO NEED SNACKS."]
        ],
        .trial: [
            .idle: ["READY TO TRY SOMETHING NEW? I AM NOT.", "THIS COUNTS AS AN ADVENTURE, RIGHT?"],
            .active: ["SHOW ME WHAT YOU'VE GOT.", "I AM BRAVER THAN I LOOK. SOMETIMES."],
            .halfway: ["KEEP GOING. I AM ALSO SURPRISED.", "HALFWAY IS BASICALLY A WIN."],
            .almostDone: ["ALMOST AT THE FINISH.", "THEN WE CELEBRATE HORIZONTALLY."],
            .paused: ["WE CAN PICK THIS UP WHEN YOU'RE READY.", "A TINY PAUSE FOR MY TINY DIGNITY."]
        ]
    ]

    static func message(for context: CatBubbleContext) -> String {
        messages(for: context).first ?? fallbackMessage
    }

    static func messages(for context: CatBubbleContext) -> [String] {
        if context.moment == .home {
            return homeMessages[context.health] ?? [fallbackMessage]
        }

        if let pose = context.pose,
           let poseMessage = poseMessages[pose]?[context.moment] {
            return poseMessage
        }

        return [momentMessages[context.moment] ?? fallbackMessage]
    }

    static func alternateMessages(for context: CatBubbleContext) -> [String] {
        Array(messages(for: context).dropFirst())
    }
}

enum HealthStatus: String, Equatable, Sendable {
    case lowEnergy = "LOW ENERGY"
    case needsTraining = "NEEDS TRAINING"
    case healthy = "HEALTHY"
    case strong = "STRONG"
    case peakForm = "PEAK FORM"

    var displayLabel: String {
        switch self {
        case .lowEnergy, .needsTraining:
            "LOW"
        case .healthy:
            "HEALTHY"
        case .strong:
            "STRONG"
        case .peakForm:
            "PEAK"
        }
    }
}

struct FitPoints: Equatable, Sendable {
    let value: Int

    static func trainingSuccess(durationMinutes: Int) -> FitPoints {
        FitPoints(value: max(0, durationMinutes * 4))
    }

    static let trainingFailure = FitPoints(value: -50)
    static let onboardingTrial = FitPoints(value: 10)
}

struct CFBranding: Equatable, Sendable {
    var productName: String
    var appStoreName: String
    var shareTagline: String
    var iconAssetName: String

    static let `default` = CFBranding(
        productName: "CatFocus",
        appStoreName: "CatFocus",
        shareTagline: "Focus with Luna",
        iconAssetName: "AppIcon"
    )
}
