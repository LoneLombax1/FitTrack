import Foundation
import SwiftData

@Model
final class TrainingSession {
    var id: UUID
    var date: Date
    var type: SessionType
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
    var intensity: Intensity?

    var muscleGroups: [MuscleGroup] {
        get { muscleGroupsRaw.compactMap { MuscleGroup(rawValue: $0) } }
        set { muscleGroupsRaw = newValue.map { $0.rawValue } }
    }

    init(date: Date, type: SessionType) {
        self.id = UUID()
        self.date = date
        self.type = type
        self.setLogs = []
        self.muscleGroupsRaw = []
    }
}
