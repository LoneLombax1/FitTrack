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
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                VStack(spacing: Theme.Layout.cardGap) {
                    NeonCard(borderColor: Theme.Colors.borderCyan) {
                        VStack(spacing: 16) {
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .colorScheme(.dark)
                                .foregroundStyle(Theme.Colors.textPrimary)

                            CyberDivider()

                            HStack {
                                Text("WEIGHT")
                                    .font(Theme.Fonts.rajdhani(12))
                                    .kerning(2)
                                    .foregroundStyle(Theme.Colors.textMuted)
                                Spacer()
                                TextField("0.0", text: $bodyWeight)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(Theme.Fonts.mono(22, bold: true))
                                    .foregroundStyle(Theme.Colors.cyan)
                                    .frame(width: 80)
                                Text("lbs")
                                    .font(Theme.Fonts.rajdhani(13))
                                    .foregroundStyle(Theme.Colors.textMuted)
                            }

                            CyberDivider()

                            HStack {
                                Text("BODY FAT")
                                    .font(Theme.Fonts.rajdhani(12))
                                    .kerning(2)
                                    .foregroundStyle(Theme.Colors.textMuted)
                                Spacer()
                                TextField("optional", text: $bodyFat)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(Theme.Fonts.mono(22, bold: true))
                                    .foregroundStyle(Theme.Colors.purple)
                                    .frame(width: 80)
                                Text("%")
                                    .font(Theme.Fonts.rajdhani(13))
                                    .foregroundStyle(Theme.Colors.textMuted)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Layout.screenPadding)

                    CyberButton(title: "SAVE WEIGH-IN", action: save)
                        .disabled(bodyWeight.isEmpty)
                        .padding(.horizontal, Theme.Layout.screenPadding)

                    Spacer()
                }
                .padding(.top, 12)
            }
            .navigationTitle("Log Weigh-In")
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

    private func save() {
        guard let weight = Double(bodyWeight) else { return }
        let fatPercent = Double(bodyFat)
        let weighIn = WeighIn(date: date, bodyWeightLbs: weight, bodyFatPercent: fatPercent)
        context.insert(weighIn)
        dismiss()
    }
}
