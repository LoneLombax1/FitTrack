import Foundation

struct SetLogSnapshot {
    let exerciseName: String
    let setNumber: Int
    let targetReps: Int
    let repsCompleted: Int
    let weight: Double
    let isCompleted: Bool
}

enum ProgressionEngine {

    /// Returns the suggested weight for `exerciseName` based on the last session's logs.
    /// Returns nil if no completed logs exist for the exercise.
    static func nextWeight(for exerciseName: String, logs: [SetLogSnapshot], increment: Double) -> Double? {
        let relevant = logs.filter { $0.exerciseName == exerciseName && $0.isCompleted }
        guard !relevant.isEmpty else { return nil }
        let lastWeight = relevant.map(\.weight).max() ?? 0
        let allMet = relevant.allSatisfy { $0.repsCompleted >= $0.targetReps }
        return allMet ? lastWeight + increment : lastWeight
    }

    /// Applies recovery-based modifier. Below deloadThreshold reduces by 10%; above returns base unchanged.
    static func applyRecoveryModifier(baseWeight: Double, recoveryScore: Int, deloadThreshold: Int) -> Double {
        recoveryScore < deloadThreshold ? (baseWeight * 0.9).rounded(toPlaces: 1) : baseWeight
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - SwiftData bridge
extension SetLog {
    func toSnapshot() -> SetLogSnapshot {
        SetLogSnapshot(
            exerciseName: exerciseName,
            setNumber: setNumber,
            targetReps: targetReps,
            repsCompleted: repsCompleted,
            weight: weight,
            isCompleted: completed
        )
    }
}
