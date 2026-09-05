import Foundation

struct TrainingSessionOutcome: Equatable, Sendable {
    let state: TrainingResultState
    let plannedMinutes: Int
    let elapsedSeconds: TimeInterval

    var points: FitPoints {
        switch state {
        case .success:
            FitPoints.trainingSuccess(durationMinutes: plannedMinutes)
        case .failure:
            .trainingFailure
        }
    }
}

struct TrainingSessionRecord: Codable, Equatable, Identifiable, Sendable {
    enum Result: String, Codable, Sendable {
        case success
        case failure
    }

    let id: UUID
    let date: Date
    let result: Result
    let plannedMinutes: Int
    let elapsedSeconds: TimeInterval
    let fitPoints: Int

    init(outcome: TrainingSessionOutcome, date: Date = .now) {
        id = UUID()
        self.date = date
        result = outcome.state == .success ? .success : .failure
        plannedMinutes = max(1, outcome.plannedMinutes)
        elapsedSeconds = max(0, outcome.elapsedSeconds)
        fitPoints = outcome.points.value
    }

    var completedMinutes: Int {
        max(0, Int((elapsedSeconds / 60).rounded(.down)))
    }

    /// The single duration used by Stats, charts, and summaries.
    /// A successful session earns its planned duration; an abandoned session
    /// reports only the whole minutes actually completed.
    var focusMinutes: Int {
        result == .success ? max(plannedMinutes, completedMinutes) : completedMinutes
    }
}

enum TrainingRecordsStore {
    static let storageKey = "trainingSessionRecords.v1"

    static func load(from data: Data) -> [TrainingSessionRecord] {
        guard !data.isEmpty else { return [] }
        return (try? JSONDecoder().decode([TrainingSessionRecord].self, from: data)) ?? []
    }

    static func save(_ records: [TrainingSessionRecord]) -> Data {
        (try? JSONEncoder().encode(records)) ?? Data()
    }

    static func append(_ record: TrainingSessionRecord, to data: Data) -> Data {
        var records = load(from: data)
        records.insert(record, at: 0)
        return save(Array(records.prefix(100)))
    }
}

enum CatHealthCalculator {
    static let baselineScore = 42
    static let minimumScore = 20
    static let gracePeriodDays = 1
    static let dailyDecay = 2

    static func score(records: [TrainingSessionRecord], now: Date = .now) -> FitnessScore {
        let earnedScore = baselineScore + records.reduce(0) { $0 + $1.fitPoints } / 10
        let decay = inactivityDecay(records: records, now: now)
        return FitnessScore(max(minimumScore, earnedScore - decay))
    }

    private static func inactivityDecay(records: [TrainingSessionRecord], now: Date) -> Int {
        guard let lastSuccessfulSession = records
            .filter({ $0.result == .success })
            .max(by: { $0.date < $1.date }) else {
            return 0
        }

        let calendar = Calendar.current
        let lastSessionDay = calendar.startOfDay(for: lastSuccessfulSession.date)
        let today = calendar.startOfDay(for: now)
        let elapsedDays = calendar.dateComponents([.day], from: lastSessionDay, to: today).day ?? 0
        let inactiveDays = max(0, elapsedDays - gracePeriodDays)
        return inactiveDays * dailyDecay
    }
}
