import Foundation
import SwiftData

@Model
final class Program {
    var id: UUID
    var name: String
    var startDate: Date
    var durationWeeks: Int
    var isActive: Bool
    @Relationship(deleteRule: .cascade) var scheduleSlots: [WeeklyScheduleSlot]

    init(name: String, startDate: Date, durationWeeks: Int = 8) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.durationWeeks = durationWeeks
        self.isActive = false
        self.scheduleSlots = []
    }

    var currentWeek: Int? {
        guard isActive else { return nil }
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let week = (days / 7) + 1
        return week <= durationWeeks ? week : nil
    }

    var isComplete: Bool {
        guard isActive else { return false }
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let week = (days / 7) + 1
        return week > durationWeeks
    }
}

@Model
final class WeeklyScheduleSlot {
    var id: UUID
    var dayOfWeek: Int          // 1=Mon, 7=Sun
    var typeRaw: String
    var activityName: String?
    var muscleGroupsRaw: [String]
    var intensityRaw: String
    @Relationship var workoutTemplate: WorkoutTemplate?
    @Relationship(inverse: \Program.scheduleSlots) var program: Program?

    var type: SessionType {
        get { SessionType(rawValue: typeRaw) ?? .rest }
        set { typeRaw = newValue.rawValue }
    }

    var intensity: Intensity {
        get { Intensity(rawValue: intensityRaw) ?? .moderate }
        set { intensityRaw = newValue.rawValue }
    }

    var muscleGroups: [MuscleGroup] {
        get { muscleGroupsRaw.compactMap { MuscleGroup(rawValue: $0) } }
        set { muscleGroupsRaw = newValue.map { $0.rawValue } }
    }

    init(dayOfWeek: Int, type: SessionType) {
        self.id = UUID()
        self.dayOfWeek = dayOfWeek
        self.typeRaw = type.rawValue
        self.muscleGroupsRaw = []
        self.intensityRaw = Intensity.moderate.rawValue
    }
}
