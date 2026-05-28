import SwiftUI

struct CyberDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Colors.borderSubtle)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
