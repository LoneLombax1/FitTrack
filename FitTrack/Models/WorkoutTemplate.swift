import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade) var exercises: [TemplateExercise]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.exercises = []
    }

    var sortedExercises: [TemplateExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}

@Model
final class TemplateExercise {
    var id: UUID
    var name: String
    var targetSets: Int
    var targetReps: Int
    var orderIndex: Int
    var incrementLbs: Double
    var primaryMusclesRaw: [String]
    var secondaryMusclesRaw: [String]

    var primaryMuscles: [MuscleGroup] {
        get { primaryMusclesRaw.compactMap { MuscleGroup(rawValue: $0) } }
        set { primaryMusclesRaw = newValue.map { $0.rawValue } }
    }

    var secondaryMuscles: [MuscleGroup] {
        get { secondaryMusclesRaw.compactMap { MuscleGroup(rawValue: $0) } }
        set { secondaryMusclesRaw = newValue.map { $0.rawValue } }
    }

    @Relationship(inverse: \WorkoutTemplate.exercises) var workoutTemplate: WorkoutTemplate?

    init(name: String, targetSets: Int, targetReps: Int, orderIndex: Int, incrementLbs: Double = 5.0) {
        self.id = UUID()
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.orderIndex = orderIndex
        self.incrementLbs = incrementLbs
        self.primaryMusclesRaw = []
        self.secondaryMusclesRaw = []
    }
}
