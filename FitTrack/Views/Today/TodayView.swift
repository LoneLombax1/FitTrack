import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var whoopService: WhoopService
    @AppStorage("progressionIncrement") private var incrementKg: Double = 2.5
    @AppStorage("deloadThreshold") private var deloadThreshold: Int = 50

    @Query(filter: #Predicate<Program> { $0.isActive }) private var activePrograms: [Program]
    @Query(sort: \TrainingSession.date, order: .reverse) private var recentSessions: [TrainingSession]
    @Query(sort: \WhoopCycleCache.date, order: .reverse) private var cachedCycles: [WhoopCycleCache]

    @State private var activeSession: TrainingSession?
    @State private var activeTemplate: WorkoutTemplate?
    @State private var showSession = false

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
            .fullScreenCover(isPresented: $showSession) {
                if let session = activeSession, let template = activeTemplate {
                    ActiveSessionView(
                        session: session,
                        template: template,
                        incrementKg: incrementKg,
                        recoveryScore: todayCycle?.recoveryScore
                    )
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
        activeSession = session
        activeTemplate = template
        showSession = true
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

    private func refreshWhoop() async {
        guard whoopService.isConnected else { return }
        guard todayCycle == nil || todayCycle!.isStale else { return }
        guard let result = try? await whoopService.fetchTodayCycle() else { return }
        if let score = result.recoveryScore, let strain = result.strainScore {
            let cache = WhoopCycleCache(date: Date(), recoveryScore: score, strainScore: strain)
            context.insert(cache)
        }
    }
}
