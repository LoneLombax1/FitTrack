import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @State private var selectedExercise: String?

    private var gymSessions: [TrainingSession] { sessions.filter { $0.type == .gym } }
    private var allExerciseNames: [String] {
        Array(Set(gymSessions.flatMap { $0.setLogs.map(\.exerciseName) })).sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                if !allExerciseNames.isEmpty {
                    Section("Exercise Progress") {
                        Picker("Exercise", selection: $selectedExercise) {
                            Text("Select…").tag(String?.none)
                            ForEach(allExerciseNames, id: \.self) { name in
                                Text(name).tag(String?.some(name))
                            }
                        }
                        if let name = selectedExercise {
                            ExerciseChartView(exerciseName: name, sessions: gymSessions)
                                .frame(height: 160)
                        }
                    }
                }
                Section("Sessions") {
                    ForEach(sessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionRowView(session: session)
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct SessionRowView: View {
    let session: TrainingSession
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(session.workoutTemplateName ?? session.activityName ?? session.type.rawValue.capitalized)
                    .font(.headline)
                Spacer()
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundStyle(.secondary)
            }
            if session.type == .gym {
                Text("\(session.setLogs.filter(\.completed).count) sets completed")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct SessionDetailView: View {
    let session: TrainingSession
    var body: some View {
        List {
            let grouped = Dictionary(grouping: session.setLogs, by: \.exerciseName)
            ForEach(grouped.keys.sorted(), id: \.self) { name in
                Section(name) {
                    ForEach(grouped[name, default: []].sorted { $0.setNumber < $1.setNumber }) { log in
                        HStack {
                            Text("Set \(log.setNumber)").foregroundStyle(.secondary)
                            Spacer()
                            Text("\(log.weight, format: .number)kg × \(log.repsCompleted) reps")
                            Image(systemName: log.completed ? "checkmark.circle.fill" : "xmark.circle")
                                .foregroundStyle(log.completed ? .green : .red)
                        }
                    }
                }
            }
        }
        .navigationTitle(session.workoutTemplateName ?? "Session")
    }
}

struct ExerciseChartView: View {
    let exerciseName: String
    let sessions: [TrainingSession]

    private var dataPoints: [(date: Date, maxWeight: Double)] {
        sessions.compactMap { session in
            let relevant = session.setLogs.filter { $0.exerciseName == exerciseName && $0.completed }
            guard let max = relevant.map(\.weight).max() else { return nil }
            return (date: session.date, maxWeight: max)
        }
        .sorted { $0.date < $1.date }
        .suffix(12)
        .map { $0 }
    }

    var body: some View {
        Chart(dataPoints, id: \.date) { point in
            LineMark(x: .value("Date", point.date), y: .value("kg", point.maxWeight))
            PointMark(x: .value("Date", point.date), y: .value("kg", point.maxWeight))
        }
        .chartYAxisLabel("kg")
    }
}
