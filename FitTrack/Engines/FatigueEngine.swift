import Foundation

enum FatigueColor: Equatable {
    case green, yellow, red
}

enum FatigueEngine {

    /// Colour-coded fatigue status based on days since last training.
    static func fatigueColor(lastTrained: Date?, today: Date) -> FatigueColor {
        guard let last = lastTrained else { return .red }
        let days = Calendar.current.dateComponents([.day], from: last, to: today).day ?? 999
        switch days {
        case ...4:  return .green
        case 5...7: return .yellow
        default:    return .red
        }
    }

    /// Volume contribution from a gym exercise to a specific muscle group.
    static func volume(isPrimary: Bool, sets: Int, reps: Int) -> Double {
        let base = Double(sets * reps)
        return isPrimary ? base : base * 0.5
    }

    /// Flat volume contribution from a sport/competition session by intensity.
    static func activityVolume(intensity: Intensity) -> Double {
        switch intensity {
        case .low:      return 20.0
        case .moderate: return 40.0
        case .high:     return 60.0
        }
    }

    /// Returns the most recent training date per muscle group across a rolling window.
    static func lastTrainedDates(from sessions: [TrainingSessionSnapshot], windowDays: Int = 7, today: Date = Date()) -> [MuscleGroup: Date] {
        let cutoffRaw = Calendar.current.date(byAdding: .day, value: -windowDays, to: today) ?? today
        let cutoff = Calendar.current.startOfDay(for: cutoffRaw)
        var result: [MuscleGroup: Date] = [:]
        for session in sessions where session.date >= cutoff {
            for muscle in session.musclesWorked {
                if let existing = result[muscle] {
                    if session.date > existing { result[muscle] = session.date }
                } else {
                    result[muscle] = session.date
                }
            }
        }
        return result
    }
}

// Plain value type for sessions — avoids SwiftData dependency in engine
struct TrainingSessionSnapshot {
    let date: Date
    let musclesWorked: [MuscleGroup]
}

// MARK: - SwiftData bridge
extension TrainingSession {
    func toFatigueSnapshot(template: WorkoutTemplate?) -> TrainingSessionSnapshot {
        var muscles: [MuscleGroup] = []
        switch type {
        case .gym:
            if let template {
                for ex in template.exercises {
                    muscles.append(contentsOf: ex.primaryMuscles)
                    muscles.append(contentsOf: ex.secondaryMuscles)
                }
            }
        case .sport, .competition:
            muscles = muscleGroups
        case .rest:
            break
        }
        return TrainingSessionSnapshot(date: date, musclesWorked: Array(Set(muscles)))
    }
}
