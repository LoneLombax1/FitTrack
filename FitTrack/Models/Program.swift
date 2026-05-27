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
    var type: SessionType
    var activityName: String?
    var muscleGroupsRaw: [String]
    var intensity: Intensity
    @Relationship var workoutTemplate: WorkoutTemplate?

    var muscleGroups: [MuscleGroup] {
        get { muscleGroupsRaw.compactMap { MuscleGroup(rawValue: $0) } }
        set { muscleGroupsRaw = newValue.map { $0.rawValue } }
    }

    init(dayOfWeek: Int, type: SessionType) {
        self.id = UUID()
        self.dayOfWeek = dayOfWeek
        self.type = type
        self.muscleGroupsRaw = []
        self.intensity = .moderate
    }
}
