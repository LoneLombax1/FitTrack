import SwiftUI
import SwiftData

private struct ActiveSessionContext: Identifiable {
    let id = UUID()
    let session: TrainingSession
    let template: WorkoutTemplate
}

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var whoopService: WhoopService
    @AppStorage("deloadThreshold") private var deloadThreshold: Int = 50

    @Query(filter: #Predicate<Program> { $0.isActive }) private var activePrograms: [Program]
    @Query(sort: \TrainingSession.date, order: .reverse) private var recentSessions: [TrainingSession]
    @Query(sort: \WhoopCycleCache.date, order: .reverse) private var cachedCycles: [WhoopCycleCache]

    @State private var sessionContext: ActiveSessionContext?
    @State private var showProgramComplete = false
    @State private var showSettings = false

    private var activeProgram: Program? { activePrograms.first }

    private var todaySlot: WeeklyScheduleSlot? {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let mondayBased = weekday == 1 ? 7 : weekday - 1
        return activeProgram?.scheduleSlots.first { $0.dayOfWeek == mondayBased }
    }

    private var todayCycle: WhoopCycleCache? {
        let today = Calendar.current.startOfDay(for: Date())
        return cachedCycles.first { Calendar.current.startOfDay(for: $0.date) == today }
    }

    private var dateLabel: String {
        Date().formatted(.dateTime.weekday(.wide).day().month(.abbreviated)).uppercased()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Layout.cardGap) {
                        // Date header
                        HStack {
                            Text(dateLabel)
                                .font(Theme.Fonts.rajdhani(12))
                                .kerning(2)
                                .foregroundStyle(Theme.Colors.textMuted)
                            Spacer()
                            Button { showSettings = true } label: {
                                Image(systemName: "gearshape")
                                    .foregroundStyle(Theme.Colors.textMuted)
                                    .font(.system(size: 18))
                            }
                        }
                        .padding(.horizontal, Theme.Layout.screenPadding)
                        .padding(.top, 8)
                        .appearAnimation(delay: 0)

                        // Recovery card
                        if let cycle = todayCycle {
                            RecoveryBadgeView(score: cycle.recoveryScore)
                                .padding(.horizontal, Theme.Layout.screenPadding)
                                .appearAnimation(delay: 0.05)
                        }

                        // Today's session card
                        sessionCard
                            .padding(.horizontal, Theme.Layout.screenPadding)
                            .appearAnimation(delay: 0.1)

                        // Stats row
                        if let program = activeProgram {
                            statsRow(program: program)
                                .padding(.horizontal, Theme.Layout.screenPadding)
                                .appearAnimation(delay: 0.15)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 4)
                }
            }
            .navigationBarHidden(true)
            .task { await refreshWhoop() }
            .fullScreenCover(item: $sessionContext) { ctx in
                ActiveSessionView(
                    session: ctx.session,
                    template: ctx.template,
                    recoveryScore: todayCycle?.recoveryScore
                )
            }
            .onChange(of: activeProgram?.id) {
                if activeProgram?.isComplete == true && !showProgramComplete {
                    showProgramComplete = true
                }
            }
            .sheet(isPresented: $showProgramComplete) {
                if let program = activeProgram {
                    ProgramCompleteView(program: program)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(WhoopService.shared)
            }
        }
    }

    @ViewBuilder private var sessionCard: some View {
        if let slot = todaySlot {
            slotCard(slot)
        } else {
            NeonCard(borderColor: Theme.Colors.borderSubtle) {
                VStack(alignment: .leading, spacing: 6) {
                    SectionHeader(title: "Today")
                    Text("No program active")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Text("Create one in the Program tab.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textMuted)
                }
            }
        }
    }

    @ViewBuilder private func slotCard(_ slot: WeeklyScheduleSlot) -> some View {
        switch slot.type {
        case .gym:
            if let template = slot.workoutTemplate {
                NeonCard(borderColor: Theme.Colors.borderPurple) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Today's Session", color: Theme.Colors.purple)
                        Text(template.name)
                            .font(Theme.Fonts.orbitron(18))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(template.sortedExercises.prefix(3)) { ex in
                                let key = "suggested_\(ex.name)_\(template.id)"
                                let w = UserDefaults.standard.double(forKey: key)
                                Text("· \(ex.name)  \(ex.targetSets)×\(ex.targetReps)\(w > 0 ? " @ \(w.formatted()) lbs" : "")")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                            if template.sortedExercises.count > 3 {
                                Text("+ \(template.sortedExercises.count - 3) more")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.Colors.textMuted)
                            }
                        }
                        CyberButton(title: "START SESSION ›") {
                            startGymSession(template: template)
                        }
                    }
                }
            } else {
                NeonCard(borderColor: Theme.Colors.borderPurple) {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionHeader(title: "Gym Day", color: Theme.Colors.purple)
                        Text("No template assigned")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        case .sport:
            NeonCard(borderColor: Theme.Colors.borderCyan) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Sport")
                    Text(slot.activityName ?? "Sport Session")
                        .font(Theme.Fonts.orbitron(16))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    CyberButton(title: "LOG ACTIVITY ›", color: Theme.Colors.cyan) {
                        logActivity(slot: slot)
                    }
                }
            }
        case .competition:
            NeonCard(borderColor: Color(hex: "FF6B00").opacity(0.3)) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Competition", color: Color(hex: "FF6B00"))
                    Text(slot.activityName ?? "Game Day")
                        .font(Theme.Fonts.orbitron(16))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    CyberButton(title: "LOG GAME ›", color: Color(hex: "FF6B00")) {
                        logActivity(slot: slot)
                    }
                }
            }
        case .rest:
            NeonCard(borderColor: Theme.Colors.borderSubtle) {
                HStack(spacing: 14) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.Colors.textMuted)
                    VStack(alignment: .leading, spacing: 3) {
                        SectionHeader(title: "Rest Day", color: Theme.Colors.textMuted)
                        Text("Recovery in progress")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                }
            }
        }
    }

    @ViewBuilder private func statsRow(program: Program) -> some View {
        HStack(spacing: 8) {
            if let week = program.currentWeek {
                StatTile(value: "W\(week)", label: "OF \(program.durationWeeks)")
            }
            if let cycle = todayCycle {
                StatTile(value: "\(cycle.recoveryScore)%", label: "RECOVERY", color: Theme.Colors.recovery(cycle.recoveryScore))
            }
            StatTile(
                value: "\(recentSessions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) && ($0.type != .gym || $0.durationMinutes != nil) }.count)",
                label: "THIS WEEK",
                color: Theme.Colors.purple
            )
        }
    }

    private func startGymSession(template: WorkoutTemplate) {
        let session = TrainingSession(date: Date(), type: .gym)
        session.workoutTemplateId = template.id
        session.workoutTemplateName = template.name
        session.programId = activeProgram?.id
        session.weekNumber = activeProgram?.currentWeek
        context.insert(session)
        prepareSession(session, template: template, recoveryScore: todayCycle?.recoveryScore, deloadThreshold: deloadThreshold, context: context)
        sessionContext = ActiveSessionContext(session: session, template: template)
    }

    private func logActivity(slot: WeeklyScheduleSlot) {
        let session = TrainingSession(date: Date(), type: slot.type)
        session.activityName = slot.activityName
        session.muscleGroups = slot.muscleGroups
        session.intensity = slot.intensity
        session.programId = activeProgram?.id
        session.weekNumber = activeProgram?.currentWeek
        context.insert(session)
    }

    @MainActor private func refreshWhoop() async {
        guard whoopService.isConnected else { return }
        guard todayCycle?.isStale != false else { return }
        guard let result = try? await whoopService.fetchTodayCycle() else { return }
        if let score = result.recoveryScore, let strain = result.strainScore {
            let cache = WhoopCycleCache(date: Date(), recoveryScore: score, strainScore: strain)
            context.insert(cache)
        }
    }
}
