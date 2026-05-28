import SwiftUI
import SwiftData

struct ActiveSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let session: TrainingSession
    let template: WorkoutTemplate
    let recoveryScore: Int?

    @State private var showFinishConfirm = false
    @State private var showPRBurst = false
    @State private var prsHit = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Layout.cardGap) {
                        HStack {
                            Text("STARTED")
                                .font(Theme.Fonts.rajdhani(11))
                                .kerning(1.5)
                                .foregroundStyle(Theme.Colors.textMuted)
                            Spacer()
                            Text(session.date.formatted(.dateTime.hour().minute()))
                                .font(Theme.Fonts.mono(13, bold: true))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .padding(.horizontal, Theme.Layout.screenPadding)
                        .padding(.top, 4)
                        .appearAnimation(delay: 0)

                        if let recovery = recoveryScore {
                            RecoveryBadgeView(score: recovery)
                                .padding(.horizontal, Theme.Layout.screenPadding)
                                .appearAnimation(delay: 0.03)
                        }

                        ForEach(Array(template.sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                            exerciseCard(exercise, delay: Double(index) * 0.05 + 0.05)
                        }

                        CyberButton(title: "FINISH SESSION") { showFinishConfirm = true }
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .padding(.bottom, 32)
                            .appearAnimation(delay: Double(template.sortedExercises.count) * 0.05 + 0.1)
                    }
                    .padding(.top, 8)
                }

                // PR burst overlay
                if showPRBurst {
                    PRBurstOverlay(count: prsHit)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation { showPRBurst = false }
                            }
                        }
                }
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .confirmationDialog("Finish session?", isPresented: $showFinishConfirm) {
                Button("Finish Session") { finishSession() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    @ViewBuilder private func exerciseCard(_ exercise: TemplateExercise, delay: Double) -> some View {
        NeonCard(borderColor: Theme.Colors.borderPurple) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(exercise.name)
                        .font(Theme.Fonts.orbitron(14))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    NeonBadge(text: "\(exercise.targetSets)×\(exercise.targetReps)", color: Theme.Colors.purple)
                }
                .padding(.bottom, 10)

                CyberDivider()

                VStack(spacing: 0) {
                    ForEach(logsFor(exercise)) { log in
                        SetLogRowView(log: log)
                        if log.setNumber < logsFor(exercise).count {
                            CyberDivider().padding(.horizontal, Theme.Layout.screenPadding)
                        }
                    }
                }
                .padding(.horizontal, -Theme.Layout.screenPadding)
            }
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
        .appearAnimation(delay: delay)
    }

    private func logsFor(_ exercise: TemplateExercise) -> [SetLog] {
        session.setLogs
            .filter { $0.exerciseName == exercise.name }
            .sorted { $0.setNumber < $1.setNumber }
    }

    private func finishSession() {
        session.durationMinutes = max(1, Int(Date().timeIntervalSince(session.date) / 60))
        var newPRs = 0
        for exercise in template.sortedExercises {
            let snapshots = logsFor(exercise).map { $0.toSnapshot() }
            if let next = ProgressionEngine.nextWeight(for: exercise.name, logs: snapshots, increment: exercise.incrementLbs) {
                let key = "suggested_\(exercise.name)_\(template.id)"
                let previous = UserDefaults.standard.double(forKey: key)
                if next > previous { newPRs += 1 }
                UserDefaults.standard.set(next, forKey: key)
            }
        }
        if newPRs > 0 {
            prsHit = newPRs
            withAnimation(Theme.Anim.bounce) { showPRBurst = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { dismiss() }
        } else {
            dismiss()
        }
    }
}

struct PRBurstOverlay: View {
    let count: Int
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 1

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            ZStack {
                Circle()
                    .stroke(Theme.Colors.cyan, lineWidth: 3)
                    .frame(width: 200, height: 200)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
                    .neonGlow(Theme.Colors.cyan, radius: 12)
                VStack(spacing: 4) {
                    Text("PR")
                        .font(Theme.Fonts.orbitron(48))
                        .foregroundStyle(Theme.Colors.cyan)
                        .neonGlow(Theme.Colors.cyan, radius: 16)
                    if count > 1 {
                        Text("\(count) NEW PRs")
                            .font(Theme.Fonts.rajdhani(14))
                            .kerning(2)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .onAppear {
                withAnimation(Theme.Anim.spring) { ringScale = 1.4 }
                withAnimation(Theme.Anim.spring.delay(0.3)) { ringOpacity = 0 }
            }
        }
    }
}

func prepareSession(
    _ session: TrainingSession,
    template: WorkoutTemplate,
    recoveryScore: Int?,
    deloadThreshold: Int,
    context: ModelContext
) {
    for exercise in template.sortedExercises {
        let key = "suggested_\(exercise.name)_\(template.id)"
        var suggestedWeight = UserDefaults.standard.double(forKey: key)
        if suggestedWeight == 0 { suggestedWeight = 45.0 }
        if let recovery = recoveryScore {
            suggestedWeight = ProgressionEngine.applyRecoveryModifier(baseWeight: suggestedWeight, recoveryScore: recovery, deloadThreshold: deloadThreshold)
        }
        guard exercise.targetSets > 0 else { continue }
        for i in 1...exercise.targetSets {
            let log = SetLog(exerciseName: exercise.name, setNumber: i, targetReps: exercise.targetReps, weight: suggestedWeight)
            session.setLogs.append(log)
            context.insert(log)
        }
    }
}
