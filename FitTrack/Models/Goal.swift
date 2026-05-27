import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID
    var type: GoalType
    var title: String
    var targetValue: Double
    var targetDate: Date?
    var linkedExerciseName: String?   // strength goals
    var linkedMetric: GoalMetric?     // body comp goals
    var isAchieved: Bool
    var achievedDate: Date?
    var createdAt: Date

    init(type: GoalType, title: String, targetValue: Double) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.targetValue = targetValue
        self.isAchieved = false
        self.createdAt = Date()
    }
}
