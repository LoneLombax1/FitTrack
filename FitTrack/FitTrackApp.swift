import SwiftUI
import SwiftData

@main
struct FitTrackApp: App {
    @StateObject private var whoopService = WhoopService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(whoopService)
        }
        .modelContainer(for: [
            Program.self,
            WeeklyScheduleSlot.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            TrainingSession.self,
            SetLog.self,
            WhoopCycleCache.self,
            WeighIn.self,
            ProgressPhoto.self,
            Goal.self,
        ])
    }
}
