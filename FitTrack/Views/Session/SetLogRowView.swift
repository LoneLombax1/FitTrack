import SwiftUI
import SwiftData

struct SetLogRowView: View {
    @Bindable var log: SetLog

    var body: some View {
        HStack(spacing: 10) {
            Text("SET \(log.setNumber)")
                .font(Theme.Fonts.rajdhani(11))
                .kerning(1.5)
                .foregroundStyle(Theme.Colors.textMuted)
                .frame(width: 46, alignment: .leading)

            HStack(spacing: 3) {
                TextField("0", value: $log.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 58)
                    .font(Theme.Fonts.mono(15, bold: true))
                    .foregroundStyle(Theme.Colors.cyan)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.surfaceDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text("lbs")
                    .font(Theme.Fonts.rajdhani(10))
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            HStack(spacing: 3) {
                TextField("\(log.targetReps)", value: $log.repsCompleted, format: .number)
                    .keyboardType(.numberPad)
                    .frame(width: 36)
                    .font(Theme.Fonts.mono(15, bold: true))
                    .foregroundStyle(Theme.Colors.purple)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.surfaceDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Text("/ \(log.targetReps)")
                    .font(Theme.Fonts.rajdhani(10))
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            Spacer()

            Button {
                withAnimation(Theme.Anim.bounce) {
                    log.completed.toggle()
                    if log.completed && log.repsCompleted == 0 {
                        log.repsCompleted = log.targetReps
                    }
                }
            } label: {
                Image(systemName: log.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(log.completed ? Theme.Colors.cyan : Theme.Colors.textMuted)
                    .font(.system(size: 22))
                    .neonGlow(Theme.Colors.cyan, radius: log.completed ? 6 : 0)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Layout.screenPadding)
        .padding(.vertical, 10)
        .background(log.completed ? Theme.Colors.cyan.opacity(0.05) : Color.clear)
        .animation(Theme.Anim.spring, value: log.completed)
    }
}
