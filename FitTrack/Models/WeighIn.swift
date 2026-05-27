import Foundation
import SwiftData

@Model
final class WeighIn {
    var id: UUID
    var date: Date
    var bodyWeightKg: Double
    var bodyFatPercent: Double?

    init(date: Date, bodyWeightKg: Double, bodyFatPercent: Double? = nil) {
        self.id = UUID()
        self.date = date
        self.bodyWeightKg = bodyWeightKg
        self.bodyFatPercent = bodyFatPercent
    }
}
