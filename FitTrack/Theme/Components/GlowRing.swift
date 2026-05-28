import SwiftUI

struct GlowRing: View {
    let value: Double   // 0.0 – 1.0
    var size: CGFloat = 72
    var lineWidth: CGFloat = 6
    var color: Color = Theme.Colors.cyan
    var label: String = ""

    @State private var animatedValue: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animatedValue)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .neonGlow(color, radius: 6)
            if !label.isEmpty {
                Text(label)
                    .font(Theme.Fonts.mono(size * 0.22, bold: true))
                    .foregroundStyle(color)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(Theme.Anim.spring.delay(0.1)) {
                animatedValue = min(max(value, 0), 1)
            }
        }
        .onChange(of: value) { _, newVal in
            withAnimation(Theme.Anim.spring) {
                animatedValue = min(max(newVal, 0), 1)
            }
        }
    }
}
