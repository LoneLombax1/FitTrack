import SwiftUI
import SwiftData

struct ProgramCompleteView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let program: Program

    @Query(sort: \TrainingSession.date, order: .forward) private var sessions: [TrainingSession]
    @State private var showNewProgram = false

    private var programSessions: [TrainingSession] {
        sessions.filter { $0.programId == program.id }
    }

    private var prsHit: Int {
        let gymSessions = programSessions.filter { $0.type == .gym }
        var prs = 0
        for name in Set(gymSessions.flatMap { $0.setLogs.map(\.exerciseName) }) {
            let weights = gymSessions.flatMap { $0.setLogs.filter { $0.exerciseName == name } }.map(\.weight)
            if let first = weights.first, let last = weights.last, last > first { prs += 1 }
        }
        return prs
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.yellow)
                Text("Program Complete!")
                    .font(.largeTitle.bold())
                Text(program.name)
                    .font(.title2)
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    Label("\(programSessions.count) sessions completed", systemImage: "checkmark.circle")
                    Label("\(prsHit) personal records hit", systemImage: "arrow.up.circle")
                }
                .font(.headline)

                Spacer()

                VStack(spacing: 12) {
                    Button("Start New Program") {
                        program.isActive = false
                        showNewProgram = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Extend This Program") {
                        program.durationWeeks += 4
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.bottom)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") { dismiss() }
                }
            }
            .sheet(isPresented: $showNewProgram) {
                ProgramBuilderView()
            }
        }
    }
}
