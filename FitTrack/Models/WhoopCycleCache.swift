import Foundation
import SwiftData

@Model
final class WhoopCycleCache {
    var id: UUID
    var date: Date           // day key — store start of day
    var recoveryScore: Int   // 0–100
    var strainScore: Double  // 0.0–21.0
    var fetchedAt: Date

    init(date: Date, recoveryScore: Int, strainScore: Double) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.recoveryScore = recoveryScore
        self.strainScore = strainScore
        self.fetchedAt = Date()
    }

    var isStale: Bool {
        Date().timeIntervalSince(fetchedAt) > 1800  // 30 minutes
    }
}
