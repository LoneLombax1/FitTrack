import SwiftUI
import SwiftData
import Charts

struct ProgressView_: View {
    @Query(sort: \WeighIn.date, order: .forward) private var weighIns: [WeighIn]
    @Query private var goals: [Goal]
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]

    @State private var showWeighIn = false
    @State private var showGoalEditor = false

    var body: some View {
        NavigationStack {
            List {
                weightSection
                goalsSection
                Section("Photos") {
                    NavigationLink("View progress photos") {
                        ProgressPhotoGridView()
                    }
                }
            }
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Log Weight", systemImage: "scalemass") { showWeighIn = true }
                }
            }
            .sheet(isPresented: $showWeighIn) { WeighInEntryView() }
            .sheet(isPresented: $showGoalEditor) { GoalEditorView() }
        }
    }

    @ViewBuilder private var weightSection: some View {
        if weighIns.count > 1 {
            Section("Weight") {
                Chart(weighIns) { entry in
                    LineMark(x: .value("Date", entry.date), y: .value("kg", entry.bodyWeightKg))
                    PointMark(x: .value("Date", entry.date), y: .value("kg", entry.bodyWeightKg))
                }
                .frame(height: 140)
                .chartYAxisLabel("kg")
                if let latest = weighIns.last {
                    Text("Latest: \(latest.bodyWeightKg, format: .number)kg")
                        .font(.caption).foregroundStyle(.secondary)
                    if let bf = latest.bodyFatPercent {
                        Text("Body fat: \(bf, format: .number)%")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        } else {
            Section("Weight") {
                Text("No weigh-ins yet").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var goalsSection: some View {
        Section("Goals") {
            ForEach(goals.filter { !$0.isAchieved }) { goal in
                GoalRowView(goal: goal, sessions: sessions, weighIns: weighIns)
            }
            if !goals.filter({ $0.isAchieved }).isEmpty {
                DisclosureGroup("Achieved") {
                    ForEach(goals.filter { $0.isAchieved }) { goal in
                        GoalRowView(goal: goal, sessions: sessions, weighIns: weighIns)
                    }
                }
            }
            Button("Add Goal", systemImage: "plus") { showGoalEditor = true }
        }
    }
}

struct GoalRowView: View {
    @Bindable var goal: Goal
    let sessions: [TrainingSession]
    let weighIns: [WeighIn]

    private var currentValue: Double? {
        switch goal.type {
        case .strength:
            guard let name = goal.linkedExerciseName else { return nil }
            let allLogs = sessions.flatMap(\.setLogs).filter { $0.exerciseName == name && $0.completed }
            return allLogs.map(\.weight).max()
        case .bodyComposition:
            switch goal.linkedMetric {
            case .bodyWeight: return weighIns.last?.bodyWeightKg
            case .bodyFatPercent: return weighIns.compactMap(\.bodyFatPercent).last
            case nil: return nil
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(goal.title).font(.headline)
                Spacer()
                if goal.isAchieved {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                }
            }
            if let current = currentValue {
                let progress = min(current / goal.targetValue, 1.0)
                ProgressView(value: progress)
                    .tint(progress >= 1.0 ? .green : .blue)
                HStack {
                    Text("Current: \(current, format: .number)").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("Target: \(goal.targetValue, format: .number)").font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("No data yet").font(.caption).foregroundStyle(.secondary)
            }
            if let date = goal.targetDate {
                Text("By \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .onChange(of: currentValue) { _, newValue in
            if let value = newValue, value >= goal.targetValue, !goal.isAchieved {
                goal.isAchieved = true
                goal.achievedDate = Date()
            }
        }
    }
}
