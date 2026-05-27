import XCTest
@testable import FitTrack

final class ProgressionEngineTests: XCTestCase {

    // Helpers — plain structs, not SwiftData models, to avoid needing a container
    private func makeLog(exercise: String, set: Int, target: Int, completed: Int, weight: Double) -> SetLogSnapshot {
        SetLogSnapshot(exerciseName: exercise, setNumber: set, targetReps: target, repsCompleted: completed, weight: weight, isCompleted: completed > 0)
    }

    func test_allSetsMetTarget_incrementsByDefaultAmount() {
        let logs = [
            makeLog(exercise: "Bench Press", set: 1, target: 8, completed: 8, weight: 80.0),
            makeLog(exercise: "Bench Press", set: 2, target: 8, completed: 9, weight: 80.0),
            makeLog(exercise: "Bench Press", set: 3, target: 8, completed: 8, weight: 80.0),
        ]
        let result = ProgressionEngine.nextWeight(for: "Bench Press", logs: logs, increment: 2.5)
        XCTAssertEqual(result, 82.5)
    }

    func test_oneSetBelowTarget_holdsWeight() {
        let logs = [
            makeLog(exercise: "Bench Press", set: 1, target: 8, completed: 8, weight: 80.0),
            makeLog(exercise: "Bench Press", set: 2, target: 8, completed: 5, weight: 80.0),
            makeLog(exercise: "Bench Press", set: 3, target: 8, completed: 8, weight: 80.0),
        ]
        let result = ProgressionEngine.nextWeight(for: "Bench Press", logs: logs, increment: 2.5)
        XCTAssertEqual(result, 80.0)
    }

    func test_noLogsForExercise_returnsNil() {
        let result = ProgressionEngine.nextWeight(for: "Squat", logs: [], increment: 2.5)
        XCTAssertNil(result)
    }

    func test_recoveryModifier_deloadBelowThreshold() {
        let base = 100.0
        let adjusted = ProgressionEngine.applyRecoveryModifier(baseWeight: base, recoveryScore: 45, deloadThreshold: 50)
        XCTAssertEqual(adjusted, 90.0, accuracy: 0.01)  // -10%
    }

    func test_recoveryModifier_noChangeAboveThreshold() {
        let base = 100.0
        let adjusted = ProgressionEngine.applyRecoveryModifier(baseWeight: base, recoveryScore: 75, deloadThreshold: 50)
        XCTAssertEqual(adjusted, 100.0, accuracy: 0.01)
    }
}
