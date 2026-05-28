import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @State private var selectedExercise: String?
    @State private var sessionToDelete: TrainingSession?

    private var gymSessions: [TrainingSession] { sessions.filter { $0.type == .gym } }
    private var allExerciseNames: [String] {
        Array(Set(gymSessions.flatMap { $0.setLogs.map(\.exerciseName) })).sorted()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Layout.cardGap) {
                        if !allExerciseNames.isEmpty {
                            NeonCard(borderColor: Theme.Colors.borderCyan) {
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionHeader(title: "Exercise Progress")
                                    Picker("Exercise", selection: $selectedExercise) {
                                        Text("Select…").tag(String?.none)
                                        ForEach(allExerciseNames, id: \.self) { name in
                                            Text(name).tag(String?.some(name))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Theme.Colors.cyan)

                                    if let name = selectedExercise {
                                        ExerciseChartView(exerciseName: name, sessions: gymSessions)
                                            .frame(height: 140)
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .appearAnimation(delay: 0)
                        }

                        ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                SessionRowView(session: session)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .appearAnimation(delay: Double(min(index, 8)) * 0.04 + 0.05)
                            .contextMenu {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                } label: {
                                    Label("Delete Session", systemImage: "trash")
                                }
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("History")
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .confirmationDialog("Delete this session? This cannot be undone.", isPresented: Binding(
                get: { sessionToDelete != nil },
                set: { if !$0 { sessionToDelete = nil } }
            ), titleVisibility: .visible) {
                Button("Delete Session", role: .destructive) {
                    if let s = sessionToDelete { context.delete(s) }
                    sessionToDelete = nil
                }
                Button("Cancel", role: .cancel) { sessionToDelete = nil }
            }
        }
    }
}

struct SessionRowView: View {
    let session: TrainingSession

    private var typeColor: Color {
        switch session.type {
        case .gym: return Theme.Colors.purple
        case .sport: return Theme.Colors.cyan
        case .competition: return Color(hex: "FF6B00")
        case .rest: return Theme.Colors.textMuted
        }
    }

    var body: some View {
        NeonCard(borderColor: typeColor.opacity(0.2)) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(session.workoutTemplateName ?? session.activityName ?? session.type.rawValue.capitalized)
                        .font(Theme.Fonts.orbitron(13))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    if session.type == .gym {
                        Text("\(session.setLogs.filter(\.completed).count) sets completed")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    NeonBadge(text: session.type.rawValue.uppercased(), color: typeColor)
                    Text(session.date.formatted(date: .abbreviated, time: .omitted))
                        .font(Theme.Fonts.mono(10))
                        .foregroundStyle(Theme.Colors.textMuted)
                }
            }
        }
    }
}

struct SessionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let session: TrainingSession
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()
            List {
                let grouped = Dictionary(grouping: session.setLogs, by: \.exerciseName)
                ForEach(grouped.keys.sorted(), id: \.self) { name in
                    Section {
                        ForEach(grouped[name, default: []].sorted { $0.setNumber < $1.setNumber }) { log in
                            HStack {
                                Text("Set \(log.setNumber)")
                                    .font(Theme.Fonts.rajdhani(12))
                                    .foregroundStyle(Theme.Colors.textMuted)
                                Spacer()
                                Text("\(log.weight, format: .number) lbs × \(log.repsCompleted) reps")
                                    .font(Theme.Fonts.mono(13))
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Image(systemName: log.completed ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundStyle(log.completed ? Theme.Colors.cyan : Color(hex: "FF3B5C"))
                            }
                        }
                    } header: { SectionHeader(title: name) }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(session.workoutTemplateName ?? "Session")
        .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button { showDeleteConfirm = true } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(Color(hex: "FF3B5C"))
                }
            }
        }
        .confirmationDialog("Delete this session? This cannot be undone.", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Session", role: .destructive) {
                context.delete(session)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
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
            LineMark(x: .value("Date", point.date), y: .value("lbs", point.maxWeight))
                .foregroundStyle(Theme.Colors.cyan)
                .interpolationMethod(.catmullRom)
            PointMark(x: .value("Date", point.date), y: .value("lbs", point.maxWeight))
                .foregroundStyle(Theme.Colors.purple)
                .symbolSize(30)
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Theme.Colors.borderSubtle)
                AxisValueLabel().foregroundStyle(Theme.Colors.textMuted).font(Theme.Fonts.mono(9))
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) {
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Theme.Colors.borderSubtle)
                AxisValueLabel().foregroundStyle(Theme.Colors.textMuted).font(Theme.Fonts.mono(9))
            }
        }
        .chartBackground { _ in Theme.Colors.surface }
    }
}
