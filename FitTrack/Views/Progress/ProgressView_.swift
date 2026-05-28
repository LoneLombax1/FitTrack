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
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Layout.cardGap) {
                        weightCard
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .appearAnimation(delay: 0)

                        goalsCard
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .appearAnimation(delay: 0.05)

                        photosCard
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .appearAnimation(delay: 0.1)

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showWeighIn = true } label: {
                        Image(systemName: "scalemass.fill")
                            .foregroundStyle(Theme.Colors.cyan)
                    }
                }
            }
            .sheet(isPresented: $showWeighIn) { WeighInEntryView() }
            .sheet(isPresented: $showGoalEditor) { GoalEditorView() }
        }
    }

    @ViewBuilder private var weightCard: some View {
        NeonCard(borderColor: Theme.Colors.borderCyan) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Weight Trend")
                if weighIns.count > 1 {
                    Chart(weighIns) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("lbs", entry.bodyWeightLbs)
                        )
                        .foregroundStyle(Theme.Colors.cyan)
                        .interpolationMethod(.catmullRom)
                        AreaMark(
                            x: .value("Date", entry.date),
                            y: .value("lbs", entry.bodyWeightLbs)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.Colors.cyan.opacity(0.15), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("lbs", entry.bodyWeightLbs)
                        )
                        .foregroundStyle(Theme.Colors.purple)
                        .symbolSize(30)
                    }
                    .frame(height: 130)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Theme.Colors.borderSubtle)
                            AxisValueLabel()
                                .foregroundStyle(Theme.Colors.textMuted)
                                .font(Theme.Fonts.mono(9))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Theme.Colors.borderSubtle)
                            AxisValueLabel()
                                .foregroundStyle(Theme.Colors.textMuted)
                                .font(Theme.Fonts.mono(9))
                        }
                    }
                    .chartBackground { _ in Theme.Colors.surface }

                    if let latest = weighIns.last {
                        HStack {
                            Text("\(latest.bodyWeightLbs, format: .number) lbs")
                                .font(Theme.Fonts.mono(20, bold: true))
                                .foregroundStyle(Theme.Colors.cyan)
                            if let bf = latest.bodyFatPercent {
                                Spacer()
                                Text("\(bf, format: .number)% BF")
                                    .font(Theme.Fonts.mono(14))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    }
                } else {
                    Text("No weigh-ins yet. Tap the scale icon to log your first.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(height: 60)
                }
            }
        }
    }

    @ViewBuilder private var goalsCard: some View {
        NeonCard(borderColor: Theme.Colors.borderPurple) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeader(title: "Goals", color: Theme.Colors.purple)
                    Spacer()
                    Button { showGoalEditor = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.Colors.purple)
                            .font(.system(size: 16))
                    }
                }
                let active = goals.filter { !$0.isAchieved }
                if active.isEmpty {
                    Text("No goals set yet.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textMuted)
                } else {
                    ForEach(active) { goal in
                        GoalRowView(goal: goal, sessions: sessions, weighIns: weighIns)
                        if goal.id != active.last?.id { CyberDivider() }
                    }
                }
                if !goals.filter({ $0.isAchieved }).isEmpty {
                    CyberDivider()
                    DisclosureGroup {
                        ForEach(goals.filter { $0.isAchieved }) { goal in
                            GoalRowView(goal: goal, sessions: sessions, weighIns: weighIns)
                                .opacity(0.6)
                        }
                    } label: {
                        Text("Achieved")
                            .font(Theme.Fonts.rajdhani(12))
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                    .tint(Theme.Colors.textMuted)
                }
            }
        }
    }

    @ViewBuilder private var photosCard: some View {
        NeonCard(borderColor: Theme.Colors.borderSubtle) {
            NavigationLink(destination: ProgressPhotoGridView()) {
                HStack {
                    SectionHeader(title: "Progress Photos")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textMuted)
                }
            }
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
            let allLogs = sessions.flatMap(\.setLogs).filter { $0.exerciseName == name && $0.completed && $0.repsCompleted >= 1 }
            return allLogs.map(\.weight).max()
        case .bodyComposition:
            switch goal.linkedMetric {
            case .bodyWeight: return weighIns.last?.bodyWeightLbs
            case .bodyFatPercent: return weighIns.compactMap(\.bodyFatPercent).last
            case nil: return nil
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                if goal.isAchieved {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.Colors.cyan)
                        .neonGlow(Theme.Colors.cyan, radius: 4)
                }
            }
            if let current = currentValue {
                let progress = min(current / goal.targetValue, 1.0)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.Colors.borderSubtle)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(progress >= 1.0 ? Theme.Colors.cyan : Theme.Colors.purple)
                            .frame(width: geo.size.width * progress, height: 6)
                            .neonGlow(progress >= 1.0 ? Theme.Colors.cyan : Theme.Colors.purple, radius: 4)
                            .animation(Theme.Anim.spring.delay(0.2), value: progress)
                    }
                }
                .frame(height: 6)
                HStack {
                    Text("\(current, format: .number)")
                        .font(Theme.Fonts.mono(11, bold: true))
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text("→ \(goal.targetValue, format: .number)")
                        .font(Theme.Fonts.mono(11))
                        .foregroundStyle(Theme.Colors.textMuted)
                    if let date = goal.targetDate {
                        Text("by \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                }
            } else {
                Text("No data yet")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textMuted)
            }
        }
        .padding(.vertical, 4)
        .onChange(of: currentValue) { _, newValue in
            if let value = newValue, value >= goal.targetValue, !goal.isAchieved {
                goal.isAchieved = true
                goal.achievedDate = Date()
            }
        }
    }
}
