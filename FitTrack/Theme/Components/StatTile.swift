import SwiftUI

struct StatTile: View {
    let value: String
    let label: String
    var color: Color = Theme.Colors.cyan

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.Fonts.mono(18, bold: true))
                .foregroundStyle(color)
            Text(label)
                .font(Theme.Fonts.rajdhani(10))
                .kerning(1.5)
                .foregroundStyle(Theme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.innerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.innerRadius)
                .stroke(Theme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}
