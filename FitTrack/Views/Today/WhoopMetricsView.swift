import SwiftUI

struct WhoopMetricsView: View {
    let cycle: WhoopCycleCache

    var body: some View {
        NeonCard(borderColor: Theme.Colors.borderSubtle) {
            HStack(spacing: 0) {
                metricRing(
                    value: cycle.strainScore / 21.0,
                    label: String(format: "%.1f", cycle.strainScore),
                    title: "STRAIN",
                    color: Theme.Colors.cyan
                )
                Divider()
                    .background(Theme.Colors.borderSubtle)
                    .frame(height: 60)
                metricRing(
                    value: Double(cycle.recoveryScore) / 100.0,
                    label: "\(cycle.recoveryScore)",
                    title: "RECOVERY",
                    color: Theme.Colors.recovery(cycle.recoveryScore)
                )
                Divider()
                    .background(Theme.Colors.borderSubtle)
                    .frame(height: 60)
                metricRing(
                    value: cycle.sleepScore.map { Double($0) / 100.0 } ?? 0,
                    label: cycle.sleepScore.map { "\($0)" } ?? "—",
                    title: "SLEEP",
                    color: Theme.Colors.purple
                )
            }
        }
    }

    @ViewBuilder private func metricRing(value: Double, label: String, title: String, color: Color) -> some View {
        VStack(spacing: 8) {
            GlowRing(value: value, size: 68, lineWidth: 5, color: color, label: label)
            Text(title)
                .font(Theme.Fonts.rajdhani(10))
                .kerning(1.5)
                .foregroundStyle(Theme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}
