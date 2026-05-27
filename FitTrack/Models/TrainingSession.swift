import Foundation
import SwiftData

@Model
final class TrainingSession {
    var id: UUID
    var date: Date
    var typeRaw: String
    var programId: UUID?
    var weekNumber: Int?

    // Gym session fields
    var workoutTemplateId: UUID?
    var workoutTemplateName: String?   // denormalised snapshot
    var durationMinutes: Int?
    @Relationship(deleteRule: .cascade) var setLogs: [SetLog]

    // Activity session fields
    var activityName: String?
    var muscleGroupsRaw: [String]
    var intensityRaw: String?

    var type: SessionType {
        get { SessionType(rawValue: typeRaw) ?? .rest }
        set { typeRaw = newValue.rawValue }
    }

    var intensity: Intensity? {
        get { intensityRaw.flatMap { Intensity(rawValue: $0) } }
        set { intensityRaw = newValue?.rawValue }
    }

    var muscleGroups: [MuscleGroup] {
        get { muscleGroupsRaw.compactMap { MuscleGroup(rawValue: $0) } }
        set { muscleGroupsRaw = newValue.map { $0.rawValue } }
    }

    init(date: Date, type: SessionType) {
        self.id = UUID()
        self.date = date
        self.typeRaw = type.rawValue
        self.setLogs = []
        self.muscleGroupsRaw = []
    }
}
