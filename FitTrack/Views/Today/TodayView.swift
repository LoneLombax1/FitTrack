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
    @AppStorage("progressionIncrement") private var incrementKg: Double = 2.5
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

    var body: some View {
        NavigationStack {
            List {
                if let cycle = todayCycle {
                    Section { RecoveryBadgeView(score: cycle.recoveryScore) }
                }
                Section("Today") {
                    if let slot = todaySlot {
                        slotView(slot)
                    } else {
                        Text("No program active. Create one in the Program tab.")
                            .foregroundStyle(.secondary)
                    }
                }
                if let week = activeProgram?.currentWeek,
                   let duration = activeProgram?.durationWeeks {
                    Section {
                        Label("Week \(week) of \(duration)", systemImage: "calendar")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Today")
            .task { await refreshWhoop() }
            .fullScreenCover(item: $sessionContext) { ctx in
                ActiveSessionView(
                    session: ctx.session,
                    template: ctx.template,
                    incrementKg: incrementKg,
                    recoveryScore: todayCycle?.recoveryScore
                )
            }
            .onAppear {
                if activeProgram?.isComplete == true {
                    showProgramComplete = true
                }
            }
            .sheet(isPresented: $showProgramComplete) {
                if let program = activeProgram {
                    ProgramCompleteView(program: program)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(WhoopService.shared)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { showSettings = true }
                }
            }
        }
    }

    @ViewBuilder
    private func slotView(_ slot: WeeklyScheduleSlot) -> some View {
        switch slot.type {
        case .gym:
            if let template = slot.workoutTemplate {
                VStack(alignment: .leading, spacing: 6) {
                    Text(template.name).font(.headline)
                    ForEach(template.sortedExercises.prefix(3)) { ex in
                        let key = "suggested_\(ex.name)_\(template.id)"
                        let suggestedWeight = UserDefaults.standard.double(forKey: key)
                        Text("• \(ex.name) — \(ex.targetSets)×\(ex.targetReps) @ \(suggestedWeight > 0 ? "\(suggestedWeight, format: .number)kg" : "—")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Button("Start Session") { startGymSession(template: template) }
                    .buttonStyle(.borderedProminent)
            } else {
                Text("Gym day — no template assigned").foregroundStyle(.secondary)
            }
        case .sport:
            Label(slot.activityName ?? "Sport", systemImage: "figure.run")
            Button("Log Activity") { logActivity(slot: slot) }.buttonStyle(.bordered)
        case .competition:
            Label(slot.activityName ?? "Game Day", systemImage: "trophy")
            Button("Log Game") { logActivity(slot: slot) }.buttonStyle(.bordered)
        case .rest:
            Label("Rest Day", systemImage: "moon.zzz")
        }
    }

    private func startGymSession(template: WorkoutTemplate) {
        let session = TrainingSession(date: Date(), type: .gym)
        session.workoutTemplateId = template.id
        session.workoutTemplateName = template.name
        session.programId = activeProgram?.id
        session.weekNumber = activeProgram?.currentWeek
        context.insert(session)
        prepareSession(
            session,
            template: template,
            incrementKg: incrementKg,
            recoveryScore: todayCycle?.recoveryScore,
            deloadThreshold: deloadThreshold,
            context: context
        )
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
