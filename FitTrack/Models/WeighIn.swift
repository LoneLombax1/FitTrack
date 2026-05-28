import Foundation
import SwiftData

@Model
final class WeighIn {
    var id: UUID
    var date: Date
    var bodyWeightLbs: Double
    var bodyFatPercent: Double?

    init(date: Date, bodyWeightLbs: Double, bodyFatPercent: Double? = nil) {
        self.id = UUID()
        self.date = date
        self.bodyWeightLbs = bodyWeightLbs
        self.bodyFatPercent = bodyFatPercent
    }
}
