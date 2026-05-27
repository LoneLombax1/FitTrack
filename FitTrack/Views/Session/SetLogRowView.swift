import SwiftUI
import SwiftData

struct SetLogRowView: View {
    @Bindable var log: SetLog

    var body: some View {
        HStack(spacing: 12) {
            Text("Set \(log.setNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)
            HStack(spacing: 4) {
                TextField("0", value: $log.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)
                Text("kg").foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                TextField("\(log.targetReps)", value: $log.repsCompleted, format: .number)
                    .keyboardType(.numberPad)
                    .frame(width: 44)
                    .textFieldStyle(.roundedBorder)
                Text("/ \(log.targetReps)").foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                log.completed.toggle()
                if log.completed && log.repsCompleted == 0 {
                    log.repsCompleted = log.targetReps
                }
            } label: {
                Image(systemName: log.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(log.completed ? .green : .secondary)
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .opacity(log.completed ? 1.0 : 0.7)
    }
}
