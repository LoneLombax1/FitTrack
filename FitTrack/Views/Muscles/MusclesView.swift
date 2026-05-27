import SwiftUI
import SwiftData

struct MusclesView: View {
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @Query private var templates: [WorkoutTemplate]

    private var snapshots: [TrainingSessionSnapshot] {
        sessions.map { session in
            let template = templates.first { $0.id == session.workoutTemplateId }
            return session.toFatigueSnapshot(template: template)
        }
    }

    private var lastTrained: [MuscleGroup: Date] {
        FatigueEngine.lastTrainedDates(from: snapshots)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("7-day muscle status") {
                    ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                        MuscleRowView(muscle: muscle, lastTrained: lastTrained[muscle])
                    }
                }
            }
            .navigationTitle("Muscles")
        }
    }
}

struct MuscleRowView: View {
    let muscle: MuscleGroup
    let lastTrained: Date?

    private var fatigueColor: FatigueColor {
        FatigueEngine.fatigueColor(lastTrained: lastTrained, today: Date())
    }

    private var swiftUIColor: Color {
        switch fatigueColor {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }

    private var subtitle: String {
        guard let date = lastTrained else { return "Never trained" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return days == 0 ? "Trained today" : "\(days) day\(days == 1 ? "" : "s") ago"
    }

    var body: some View {
        HStack {
            Circle().fill(swiftUIColor).frame(width: 10, height: 10)
            Text(muscle.rawValue.capitalized).font(.body)
            Spacer()
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
    }
}
