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
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(MuscleGroup.allCases.enumerated()), id: \.element) { index, muscle in
                            MuscleRowView(muscle: muscle, lastTrained: lastTrained[muscle])
                                .padding(.horizontal, Theme.Layout.screenPadding)
                                .appearAnimation(delay: Double(index) * 0.04)
                        }
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Muscles")
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct MuscleRowView: View {
    let muscle: MuscleGroup
    let lastTrained: Date?

    private var fatigueColor: FatigueColor {
        FatigueEngine.fatigueColor(lastTrained: lastTrained, today: Date())
    }

    private var themeColor: Color {
        switch fatigueColor {
        case .green:  return Color(hex: "00FF88")
        case .yellow: return Color(hex: "FFB800")
        case .red:    return Color(hex: "FF3B5C")
        }
    }

    private var subtitle: String {
        guard let date = lastTrained else { return "Never trained" }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return days == 0 ? "Trained today" : "\(days)d ago"
    }

    @State private var barWidth: CGFloat = 0
    private var barFraction: CGFloat {
        guard let date = lastTrained else { return 0.0 }
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return max(0, CGFloat(1.0 - Double(days) / 7.0))
    }

    var body: some View {
        NeonCard(borderColor: themeColor.opacity(0.2)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(muscle.rawValue.capitalized)
                        .font(Theme.Fonts.orbitron(13))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Text(subtitle)
                        .font(Theme.Fonts.mono(11))
                        .foregroundStyle(themeColor)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.Colors.borderSubtle)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(themeColor)
                            .frame(width: geo.size.width * barWidth, height: 4)
                            .neonGlow(themeColor, radius: 3)
                    }
                }
                .frame(height: 4)
                .onAppear {
                    withAnimation(Theme.Anim.spring.delay(0.2)) {
                        barWidth = barFraction
                    }
                }
            }
        }
    }
}
