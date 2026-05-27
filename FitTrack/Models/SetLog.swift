import Foundation
import SwiftData

@Model
final class SetLog {
    var id: UUID
    var exerciseName: String
    var setNumber: Int
    var targetReps: Int
    var repsCompleted: Int
    var weight: Double       // kg
    var completed: Bool

    @Relationship(inverse: \TrainingSession.setLogs) var session: TrainingSession?

    init(exerciseName: String, setNumber: Int, targetReps: Int, weight: Double) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.targetReps = targetReps
        self.repsCompleted = 0
        self.weight = weight
        self.completed = false
    }
}
