import SwiftUI
import SwiftData

struct WeeklyScheduleGridView: View {
    @Bindable var program: Program
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allTemplates: [WorkoutTemplate]

    private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        List {
            ForEach(1...7, id: \.self) { day in
                if let slot = program.scheduleSlots.first(where: { $0.dayOfWeek == day }) {
                    NavigationLink(destination: ScheduleSlotEditorView(slot: slot, templates: allTemplates)) {
                        HStack {
                            Text(dayNames[day - 1])
                                .frame(width: 40, alignment: .leading)
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            SlotTypeBadge(type: slot.type)
                        }
                    }
                } else {
                    HStack {
                        Text(dayNames[day - 1])
                            .frame(width: 40, alignment: .leading)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                        Text("Not set")
                            .font(Theme.Fonts.rajdhani(12))
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.bg.ignoresSafeArea())
        .navigationTitle("Weekly Schedule")
        .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear { ensureAllSlotsExist() }
    }

    private func ensureAllSlotsExist() {
        for day in 1...7 {
            guard !program.scheduleSlots.contains(where: { $0.dayOfWeek == day }) else { continue }
            let slot = WeeklyScheduleSlot(dayOfWeek: day, type: .rest)
            context.insert(slot)
            program.scheduleSlots.append(slot)
        }
    }
}

private struct SlotTypeBadge: View {
    let type: SessionType

    private var color: Color {
        switch type {
        case .gym:         return Theme.Colors.purple
        case .sport:       return Theme.Colors.cyan
        case .competition: return Color(hex: "FF6B00")
        case .rest:        return Theme.Colors.textMuted
        }
    }

    var body: some View {
        NeonBadge(text: type.rawValue.uppercased(), color: color)
    }
}

struct ScheduleSlotEditorView: View {
    @Bindable var slot: WeeklyScheduleSlot
    let templates: [WorkoutTemplate]
    @Query private var sessions: [TrainingSession]

    private var previousActivities: [String] {
        Array(Set(sessions.compactMap { $0.type == .sport ? $0.activityName : nil })).sorted()
    }

    private var previousCompetitions: [String] {
        Array(Set(sessions.compactMap { $0.type == .competition ? $0.activityName : nil })).sorted()
    }

    private var activityNameBinding: Binding<String> {
        Binding(
            get: { slot.activityName ?? "" },
            set: { slot.activityName = $0.isEmpty ? nil : $0 }
        )
    }

    var body: some View {
        Form {
            Section("Session Type") {
                Picker("Session type", selection: $slot.typeRaw) {
                    ForEach([SessionType.gym, .sport, .competition, .rest], id: \.rawValue) { type in
                        Text(type.rawValue.capitalized).tag(type.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            if slot.type == .gym {
                Section("Workout Template") {
                    Picker("Template", selection: $slot.workoutTemplate) {
                        Text("None").tag(Optional<WorkoutTemplate>.none)
                        ForEach(templates) { template in
                            Text(template.name).tag(Optional(template))
                        }
                    }
                }
            }

            if slot.type == .sport || slot.type == .competition {
                let previous = slot.type == .sport ? previousActivities : previousCompetitions
                Section("Activity Details") {
                    HStack {
                        TextField("Activity name", text: activityNameBinding)
                        if !previous.isEmpty {
                            Menu {
                                ForEach(previous, id: \.self) { name in
                                    Button(name) { slot.activityName = name }
                                }
                            } label: {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    Picker("Intensity", selection: Binding(
                        get: { slot.intensityRaw },
                        set: { slot.intensityRaw = $0 }
                    )) {
                        ForEach([Intensity.low, .moderate, .high], id: \.rawValue) { i in
                            Text(i.rawValue.capitalized).tag(i.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Muscle Groups") {
                    ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                        Toggle(muscle.rawValue.capitalized, isOn: Binding(
                            get: { slot.muscleGroups.contains(muscle) },
                            set: { isOn in
                                if isOn {
                                    if !slot.muscleGroups.contains(muscle) {
                                        slot.muscleGroups.append(muscle)
                                    }
                                } else {
                                    slot.muscleGroups.removeAll { $0 == muscle }
                                }
                            }
                        ))
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.bg.ignoresSafeArea())
        .navigationTitle("Edit Day")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
