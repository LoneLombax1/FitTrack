import SwiftUI

struct RecoveryBadgeView: View {
    let score: Int

    private var color: Color {
        switch score {
        case 75...: return .green
        case 50..<75: return .yellow
        default: return .red
        }
    }

    private var label: String {
        switch score {
        case 75...: return "Green — push for overload targets"
        case 50..<75: return "Moderate — maintain current weights"
        default: return "Low — consider deload today"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 52, height: 52)
                Text("\(score)%")
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Whoop Recovery")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(label).font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }
}
