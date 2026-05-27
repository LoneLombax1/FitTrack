import SwiftUI
import SwiftData

struct ProgramBuilderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var durationWeeks = 8
    @State private var setAsActive = true
    @State private var createdProgram: Program?
    @State private var showScheduleEditor = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Program name", text: $name)
                    Stepper("Duration: \(durationWeeks) weeks", value: $durationWeeks, in: 1...52)
                    Toggle("Set as active program", isOn: $setAsActive)
                }
            }
            .navigationTitle("New Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") { createProgram() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationDestination(isPresented: $showScheduleEditor) {
                if let program = createdProgram {
                    WeeklyScheduleGridView(program: program)
                }
            }
        }
    }

    private func createProgram() {
        if setAsActive {
            let descriptor = FetchDescriptor<Program>(predicate: #Predicate { $0.isActive })
            let active = (try? context.fetch(descriptor)) ?? []
            for p in active { p.isActive = false }
        }

        let program = Program(
            name: name.trimmingCharacters(in: .whitespaces),
            startDate: Date(),
            durationWeeks: durationWeeks
        )
        program.isActive = setAsActive
        context.insert(program)

        createdProgram = program
        showScheduleEditor = true
    }
}
