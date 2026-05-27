import SwiftUI
import SwiftData

struct WeighInEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var bodyWeight = ""
    @State private var bodyFat = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                HStack {
                    TextField("Weight", text: $bodyWeight).keyboardType(.decimalPad)
                    Text("kg").foregroundStyle(.secondary)
                }
                HStack {
                    TextField("Body fat % (optional)", text: $bodyFat).keyboardType(.decimalPad)
                    Text("%").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Log Weigh-In")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(bodyWeight.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard let weight = Double(bodyWeight) else { return }
        let fatPercent = Double(bodyFat)
        let weighIn = WeighIn(date: date, bodyWeightKg: weight, bodyFatPercent: fatPercent)
        context.insert(weighIn)
        dismiss()
    }
}
