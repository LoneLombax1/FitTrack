import Foundation

enum SessionType: String, Codable {
    case gym, sport, competition, rest
}

enum MuscleGroup: String, Codable, CaseIterable {
    case chest, back, shoulders, biceps, triceps, legs, core, fullBody
}

enum Intensity: String, Codable {
    case low, moderate, high
}

enum GoalType: String, Codable {
    case strength, bodyComposition
}

enum GoalMetric: String, Codable {
    case bodyWeight, bodyFatPercent
}
