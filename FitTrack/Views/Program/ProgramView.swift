import SwiftUI
import SwiftData

struct ProgramView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Program.startDate, order: .reverse) private var programs: [Program]
    @State private var showBuilder = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(programs) { program in
                    NavigationLink(destination: ProgramDetailView(program: program)) {
                        ProgramRow(program: program)
                    }
                }
                .onDelete(perform: deletePrograms)
            }
            .navigationTitle("Programs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showBuilder = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showBuilder) {
                ProgramBuilderView()
            }
        }
    }

    private func deletePrograms(at offsets: IndexSet) {
        for index in offsets {
            context.delete(programs[index])
        }
    }
}

private struct ProgramRow: View {
    let program: Program

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(program.name)
                        .font(.headline)
                    if program.isActive {
                        Text("ACTIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green, in: Capsule())
                    }
                }
                if let week = program.currentWeek {
                    Text("Week \(week) of \(program.durationWeeks)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(program.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}

struct ProgramDetailView: View {
    @Bindable var program: Program
    @Environment(\.modelContext) private var context
    @Query private var allTemplates: [WorkoutTemplate]
    @State private var showAddTemplate = false

    var body: some View {
        List {
            Section("Weekly Schedule") {
                NavigationLink("Edit schedule") {
                    WeeklyScheduleGridView(program: program)
                }
            }

            Section("Workout Templates") {
                ForEach(allTemplates) { template in
                    NavigationLink(template.name) {
                        WorkoutTemplateEditorView(template: template)
                    }
                }
                Button("Add workout template") {
                    showAddTemplate = true
                }
            }
        }
        .navigationTitle(program.name)
        .sheet(isPresented: $showAddTemplate) {
            AddTemplateView(program: program)
        }
    }
}

struct AddTemplateView: View {
    let program: Program
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var templateName = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Template name", text: $templateName)
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createTemplate() }
                        .disabled(templateName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func createTemplate() {
        let template = WorkoutTemplate(name: templateName.trimmingCharacters(in: .whitespaces))
        context.insert(template)
        dismiss()
    }
}
