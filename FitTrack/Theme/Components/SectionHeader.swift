import SwiftUI

struct SectionHeader: View {
    let title: String
    var color: Color = Theme.Colors.cyan

    var body: some View {
        Text(title.uppercased())
            .font(Theme.Fonts.rajdhani(11))
            .kerning(2.5)
            .foregroundStyle(color)
    }
}
