import SwiftUI
import SwiftData

struct ProgramView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Program.startDate, order: .reverse) private var programs: [Program]
    @State private var showBuilder = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Layout.cardGap) {
                        ForEach(Array(programs.enumerated()), id: \.element.id) { index, program in
                            NavigationLink(destination: ProgramDetailView(program: program)) {
                                ProgramRow(program: program)
                            }
                            .buttonStyle(.plain)
                            .appearAnimation(delay: Double(index) * 0.05)
                        }
                        if programs.isEmpty {
                            NeonCard(borderColor: Theme.Colors.borderSubtle) {
                                VStack(spacing: 8) {
                                    SectionHeader(title: "No Programs")
                                    Text("Tap + to create your first training program.")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }
                            }
                            .appearAnimation()
                        }
                    }
                    .padding(.horizontal, Theme.Layout.screenPadding)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Programs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showBuilder = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.Colors.cyan)
                    }
                }
            }
            .sheet(isPresented: $showBuilder) { ProgramBuilderView() }
        }
    }
}

private struct ProgramRow: View {
    let program: Program

    var body: some View {
        NeonCard(borderColor: program.isActive ? Theme.Colors.borderPurple : Theme.Colors.borderSubtle) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(program.name)
                            .font(Theme.Fonts.orbitron(14))
                            .foregroundStyle(Theme.Colors.textPrimary)
                        if program.isActive {
                            NeonBadge(text: "ACTIVE", color: Theme.Colors.purple)
                        }
                    }
                    if let week = program.currentWeek {
                        HStack(spacing: 6) {
                            Text("Week \(week) of \(program.durationWeeks)")
                                .font(Theme.Fonts.mono(12))
                                .foregroundStyle(Theme.Colors.textSecondary)
                            let progress = Double(week) / Double(program.durationWeeks)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Theme.Colors.borderSubtle)
                                        .frame(height: 3)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Theme.Colors.cyan)
                                        .frame(width: geo.size.width * progress, height: 3)
                                }
                            }
                            .frame(height: 3)
                        }
                    } else {
                        Text(program.startDate.formatted(date: .abbreviated, time: .omitted))
                            .font(Theme.Fonts.mono(11))
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textMuted)
            }
        }
    }
}

struct ProgramDetailView: View {
    @Bindable var program: Program
    @Environment(\.modelContext) private var context
    @Query private var allTemplates: [WorkoutTemplate]
    @State private var showAddTemplate = false

    var body: some View {
        ZStack {
            Theme.Colors.bg.ignoresSafeArea()
            List {
                Section {
                    NavigationLink("Edit schedule") {
                        WeeklyScheduleGridView(program: program)
                    }
                    .foregroundStyle(Theme.Colors.cyan)
                } header: { SectionHeader(title: "Weekly Schedule") }

                Section {
                    ForEach(allTemplates) { template in
                        NavigationLink(template.name) {
                            WorkoutTemplateEditorView(template: template)
                        }
                        .foregroundStyle(Theme.Colors.textPrimary)
                    }
                    Button("Add workout template") { showAddTemplate = true }
                        .foregroundStyle(Theme.Colors.cyan)
                } header: { SectionHeader(title: "Workout Templates") }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(program.name)
        .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showAddTemplate) { AddTemplateView(program: program) }
    }
}

struct AddTemplateView: View {
    let program: Program
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var templateName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                VStack(spacing: Theme.Layout.cardGap) {
                    NeonCard(borderColor: Theme.Colors.borderCyan) {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Template Name")
                            TextField("e.g. Push A", text: $templateName)
                                .font(Theme.Fonts.mono(16))
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .padding(.vertical, 6)
                        }
                    }
                    .padding(.horizontal, Theme.Layout.screenPadding)

                    CyberButton(title: "CREATE TEMPLATE") {
                        createTemplate()
                    }
                    .disabled(templateName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, Theme.Layout.screenPadding)

                    Spacer()
                }
                .padding(.top, 12)
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
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
