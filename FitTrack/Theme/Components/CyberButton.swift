import SwiftUI

struct CyberButton: View {
    let title: String
    let action: () -> Void
    var color: Color = Theme.Colors.purple

    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(Theme.Anim.bounce) { pressed = true }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(Theme.Anim.bounce) { pressed = false }
            }
        }) {
            Text(title)
                .font(Theme.Fonts.rajdhani(15))
                .kerning(2)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.buttonRadius))
                .neonGlow(color, radius: 6)
                .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
