import SwiftUI
import SwiftData

struct ActiveSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let session: TrainingSession
    let template: WorkoutTemplate
    let incrementKg: Double
    let recoveryScore: Int?

    @State private var showFinishConfirm = false

    var body: some View {
        NavigationStack {
            List {
                if let recovery = recoveryScore {
                    Section {
                        RecoveryBadgeView(score: recovery)
                    }
                }
                ForEach(template.sortedExercises) { exercise in
                    Section(exercise.name) {
                        ForEach(logsFor(exercise)) { log in
                            SetLogRowView(log: log)
                        }
                    }
                }
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") { showFinishConfirm = true }
                }
            }
            .confirmationDialog("Finish session?", isPresented: $showFinishConfirm) {
                Button("Finish Session") { finishSession() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func logsFor(_ exercise: TemplateExercise) -> [SetLog] {
        session.setLogs
            .filter { $0.exerciseName == exercise.name }
            .sorted { $0.setNumber < $1.setNumber }
    }

    private func finishSession() {
        for exercise in template.sortedExercises {
            let snapshots = logsFor(exercise).map { $0.toSnapshot() }
            if let next = ProgressionEngine.nextWeight(for: exercise.name, logs: snapshots, increment: incrementKg) {
                let key = "suggested_\(exercise.name)_\(template.id)"
                UserDefaults.standard.set(next, forKey: key)
            }
        }
        dismiss()
    }
}

func prepareSession(
    _ session: TrainingSession,
    template: WorkoutTemplate,
    incrementKg: Double,
    recoveryScore: Int?,
    deloadThreshold: Int,
    context: ModelContext
) {
    for exercise in template.sortedExercises {
        let key = "suggested_\(exercise.name)_\(template.id)"
        var suggestedWeight = UserDefaults.standard.double(forKey: key)
        if suggestedWeight == 0 { suggestedWeight = 20.0 }
        if let recovery = recoveryScore {
            suggestedWeight = ProgressionEngine.applyRecoveryModifier(
                baseWeight: suggestedWeight,
                recoveryScore: recovery,
                deloadThreshold: deloadThreshold
            )
        }
        for i in 1...exercise.targetSets {
            let log = SetLog(exerciseName: exercise.name, setNumber: i, targetReps: exercise.targetReps, weight: suggestedWeight)
            session.setLogs.append(log)
            context.insert(log)
        }
    }
}
