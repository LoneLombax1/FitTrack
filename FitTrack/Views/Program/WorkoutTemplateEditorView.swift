import SwiftUI
import SwiftData

struct WorkoutTemplateEditorView: View {
    @Bindable var template: WorkoutTemplate
    @Environment(\.modelContext) private var context
    @State private var showAddExercise = false

    var body: some View {
        List {
            ForEach(template.sortedExercises) { exercise in
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.headline)
                    Text("\(exercise.targetSets) sets × \(exercise.targetReps) reps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete(perform: deleteExercises)
            .onMove(perform: moveExercises)
        }
        .navigationTitle(template.name)
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
    @State private var primaryMuscles: Set<MuscleGroup> = []
    @State private var secondaryMuscles: Set<MuscleGroup> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Exercise name", text: $name)
                    Stepper("Sets: \(sets)", value: $sets, in: 1...10)
                    Stepper("Reps: \(reps)", value: $reps, in: 1...50)
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
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveExercise() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveExercise() {
        let exercise = TemplateExercise(
            name: name.trimmingCharacters(in: .whitespaces),
            targetSets: sets,
            targetReps: reps,
            orderIndex: template.exercises.count
        )
        exercise.primaryMuscles = Array(primaryMuscles)
        exercise.secondaryMuscles = Array(secondaryMuscles)
        template.exercises.append(exercise)
        context.insert(exercise)
        dismiss()
    }
}
