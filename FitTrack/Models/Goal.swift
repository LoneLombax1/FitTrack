import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID
    var typeRaw: String
    var title: String
    var targetValue: Double
    var targetDate: Date?
    var linkedExerciseName: String?   // strength goals
    var linkedMetricRaw: String?      // body comp goals
    var isAchieved: Bool
    var achievedDate: Date?
    var createdAt: Date

    var type: GoalType {
        get { GoalType(rawValue: typeRaw) ?? .strength }
        set { typeRaw = newValue.rawValue }
    }

    var linkedMetric: GoalMetric? {
        get { linkedMetricRaw.flatMap { GoalMetric(rawValue: $0) } }
        set { linkedMetricRaw = newValue?.rawValue }
    }

    init(type: GoalType, title: String, targetValue: Double) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.title = title
        self.targetValue = targetValue
        self.isAchieved = false
        self.createdAt = Date()
    }
}
