import SwiftUI
import SwiftData

struct GoalEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var templates: [WorkoutTemplate]

    @State private var goalType: GoalType = .strength
    @State private var title = ""
    @State private var targetValue = ""
    @State private var targetDate = Date()
    @State private var hasDeadline = false
    @State private var linkedExercise = ""
    @State private var linkedMetric: GoalMetric = .bodyWeight

    private var allExerciseNames: [String] {
        Array(Set(templates.flatMap { $0.exercises.map(\.name) })).sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Goal type", selection: $goalType) {
                    Text("Strength").tag(GoalType.strength)
                    Text("Body composition").tag(GoalType.bodyComposition)
                }
                .pickerStyle(.segmented)

                TextField("Goal title (e.g. Bench 100kg)", text: $title)

                HStack {
                    TextField("Target value", text: $targetValue).keyboardType(.decimalPad)
                    Text(unitLabel).foregroundStyle(.secondary)
                }

                if goalType == .strength {
                    Picker("Linked exercise", selection: $linkedExercise) {
                        Text("None").tag("")
                        ForEach(allExerciseNames, id: \.self) { Text($0).tag($0) }
                    }
                } else {
                    Picker("Metric", selection: $linkedMetric) {
                        Text("Body weight").tag(GoalMetric.bodyWeight)
                        Text("Body fat %").tag(GoalMetric.bodyFatPercent)
                    }
                }

                Toggle("Set a deadline", isOn: $hasDeadline)
                if hasDeadline {
                    DatePicker("Deadline", selection: $targetDate, displayedComponents: .date)
                }
            }
            .navigationTitle("New Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.isEmpty || targetValue.isEmpty)
                }
            }
        }
    }

    private var unitLabel: String {
        if goalType == .strength { return "kg" }
        return linkedMetric == .bodyFatPercent ? "%" : "kg"
    }

    private func save() {
        guard let value = Double(targetValue) else { return }
        let goal = Goal(type: goalType, title: title, targetValue: value)
        goal.targetDate = hasDeadline ? targetDate : nil
        if goalType == .strength {
            goal.linkedExerciseName = linkedExercise.isEmpty ? nil : linkedExercise
        } else {
            goal.linkedMetric = linkedMetric
        }
        context.insert(goal)
        dismiss()
    }
}
