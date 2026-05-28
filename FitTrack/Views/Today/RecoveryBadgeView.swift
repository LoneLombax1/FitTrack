import SwiftUI

struct RecoveryBadgeView: View {
    let score: Int

    private var color: Color { Theme.Colors.recovery(score) }

    private var recommendation: String {
        switch score {
        case 75...: return "Optimal · push for overload targets"
        case 50..<75: return "Moderate · maintain current weights"
        default: return "Low · consider deload today"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            GlowRing(
                value: Double(score) / 100.0,
                size: 64,
                lineWidth: 5,
                color: color,
                label: "\(score)"
            )
            VStack(alignment: .leading, spacing: 4) {
                SectionHeader(title: "Whoop Recovery", color: color)
                Text(recommendation)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(Theme.Layout.screenPadding)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Layout.cardRadius)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}
