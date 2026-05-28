import SwiftUI

struct NeonCard<Content: View>: View {
    var borderColor: Color = Theme.Colors.borderCyan
    var glow: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(Theme.Layout.screenPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .if(glow) { $0.neonGlow(borderColor, radius: 10) }
    }
}
