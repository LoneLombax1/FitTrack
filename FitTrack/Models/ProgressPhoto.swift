import Foundation
import SwiftData

@Model
final class ProgressPhoto {
    var id: UUID
    var date: Date
    var weighInId: UUID?
    var fileName: String     // stored in app documents directory
    var notes: String?

    init(date: Date, fileName: String) {
        self.id = UUID()
        self.date = date
        self.fileName = fileName
    }

    var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("progress_photos")
            .appendingPathComponent(fileName)
    }
}
