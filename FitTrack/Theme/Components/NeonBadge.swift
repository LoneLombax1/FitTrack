import SwiftUI

struct NeonBadge: View {
    let text: String
    var color: Color = Theme.Colors.cyan

    var body: some View {
        Text(text)
            .font(Theme.Fonts.rajdhani(11))
            .kerning(1.5)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}
