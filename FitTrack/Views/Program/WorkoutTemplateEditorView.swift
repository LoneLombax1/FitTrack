import SwiftUI
import SwiftData

struct WorkoutTemplateEditorView: View {
    @Bindable var template: WorkoutTemplate
    @Environment(\.modelContext) private var context
    @State private var showAddExercise = false

    var body: some View {
        List {
            ForEach(template.sortedExercises) { exercise in
                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(Theme.Fonts.orbitron(13))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("\(exercise.targetSets)×\(exercise.targetReps)  ·  +\(exercise.incrementLbs.formatted()) lbs")
                        .font(Theme.Fonts.mono(11))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteExercises)
            .onMove(perform: moveExercises)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.bg.ignoresSafeArea())
        .navigationTitle(template.name)
        .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Exercise") { showAddExercise = true }
            }
        }
        .sheet(isPresented: $showAddExercise) {
            AddExerciseView(template: template)
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        let sorted = template.sortedExercises
        for index in offsets {
            let exercise = sorted[index]
            template.exercises.removeAll { $0.id == exercise.id }
            context.delete(exercise)
        }
        reindex()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var sorted = template.sortedExercises
        sorted.move(fromOffsets: source, toOffset: destination)
        reindex(from: sorted)
    }

    private func reindex(from sorted: [TemplateExercise]? = nil) {
        let list = sorted ?? template.sortedExercises
        for (i, exercise) in list.enumerated() {
            exercise.orderIndex = i
        }
    }
}

// MARK: - AddExerciseView

struct AddExerciseView: View {
    let template: WorkoutTemplate
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var sets = 3
    @State private var reps = 8
    @State private var incrementLbs: Double = 5.0
    @State private var primaryMuscles: Set<MuscleGroup> = []
    @State private var secondaryMuscles: Set<MuscleGroup> = []
    @State private var showExercisePicker = false

    private let incrementOptions: [Double] = [1.25, 2.5, 5.0, 10.0]

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    Button(action: { showExercisePicker = true }) {
                        HStack {
                            Text(name.isEmpty ? "Select exercise" : name)
                                .foregroundStyle(name.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    Stepper("Sets: \(sets)", value: $sets, in: 1...10)
                    Stepper("Reps: \(reps)", value: $reps, in: 1...50)
                    Picker("Weight increment", selection: $incrementLbs) {
                        ForEach(incrementOptions, id: \.self) { val in
                            Text("\(val.formatted()) lbs").tag(val)
                        }
                    }
                }

                Section("Primary Muscles") {
                    ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                        Toggle(muscle.rawValue.capitalized, isOn: Binding(
                            get: { primaryMuscles.contains(muscle) },
                            set: { isOn in
                                if isOn { primaryMuscles.insert(muscle) }
                                else { primaryMuscles.remove(muscle) }
                            }
                        ))
                    }
                }

                Section("Secondary Muscles") {
                    ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                        Toggle(muscle.rawValue.capitalized, isOn: Binding(
                            get: { secondaryMuscles.contains(muscle) },
                            set: { isOn in
                                if isOn { secondaryMuscles.insert(muscle) }
                                else { secondaryMuscles.remove(muscle) }
                            }
                        ))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.bg.ignoresSafeArea())
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveExercise() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerSheet(selectedName: $name)
            }
        }
    }

    private func saveExercise() {
        let exercise = TemplateExercise(
            name: name.trimmingCharacters(in: .whitespaces),
            targetSets: sets,
            targetReps: reps,
            orderIndex: template.exercises.count,
            incrementLbs: incrementLbs
        )
        exercise.primaryMuscles = Array(primaryMuscles)
        exercise.secondaryMuscles = Array(secondaryMuscles)
        template.exercises.append(exercise)
        context.insert(exercise)
        dismiss()
    }
}

// MARK: - ExercisePickerSheet

struct ExercisePickerSheet: View {
    @Binding var selectedName: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredGroups: [(group: String, exercises: [String])] {
        guard !searchText.isEmpty else { return ExerciseDirectory.byGroup }
        let query = searchText.lowercased()
        return ExerciseDirectory.byGroup.compactMap { section in
            let filtered = section.exercises.filter { $0.lowercased().contains(query) }
            return filtered.isEmpty ? nil : (group: section.group, exercises: filtered)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredGroups, id: \.group) { section in
                    Section(section.group) {
                        ForEach(section.exercises, id: \.self) { exercise in
                            Button {
                                selectedName = exercise
                                dismiss()
                            } label: {
                                HStack {
                                    Text(exercise)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if exercise == selectedName {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
