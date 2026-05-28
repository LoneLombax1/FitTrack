import SwiftUI
import SwiftData

struct SetLogRowView: View {
    @Bindable var log: SetLog

    @State private var weightText = ""
    @State private var repsText = ""
    @FocusState private var weightFocused: Bool
    @FocusState private var repsFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text("SET \(log.setNumber)")
                .font(Theme.Fonts.rajdhani(11))
                .kerning(1.5)
                .foregroundStyle(Theme.Colors.textMuted)
                .frame(width: 46, alignment: .leading)

            HStack(spacing: 3) {
                TextField("0", text: $weightText)
                    .keyboardType(.decimalPad)
                    .frame(width: 58)
                    .font(Theme.Fonts.mono(15, bold: true))
                    .foregroundStyle(Theme.Colors.cyan)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.surfaceDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .focused($weightFocused)
                    .onChange(of: weightFocused) { _, focused in
                        if focused {
                            weightText = ""
                        } else {
                            if let v = Double(weightText), v > 0 { log.weight = v }
                            weightText = log.weight.formatted()
                        }
                    }
                Text("lbs")
                    .font(Theme.Fonts.rajdhani(10))
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            HStack(spacing: 3) {
                TextField("0", text: $repsText)
                    .keyboardType(.numberPad)
                    .frame(width: 36)
                    .font(Theme.Fonts.mono(15, bold: true))
                    .foregroundStyle(Theme.Colors.purple)
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 5)
                    .background(Theme.Colors.surfaceDeep)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .focused($repsFocused)
                    .onChange(of: repsFocused) { _, focused in
                        if focused {
                            repsText = ""
                        } else {
                            if let v = Int(repsText), v > 0 { log.repsCompleted = v }
                            repsText = "\(log.repsCompleted)"
                        }
                    }
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
                        repsText = "\(log.targetReps)"
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
        .onAppear {
            weightText = log.weight.formatted()
            repsText = "\(log.repsCompleted)"
        }
    }
}
