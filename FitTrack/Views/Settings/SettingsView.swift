import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @EnvironmentObject private var whoopService: WhoopService
    @AppStorage("progressionIncrement") private var incrementKg: Double = 2.5
    @AppStorage("deloadThreshold") private var deloadThreshold: Int = 50
    @AppStorage("programDurationWeeks") private var programDurationWeeks: Int = 8
    @State private var windowContext = WindowContextProvider()

    var body: some View {
        NavigationStack {
            Form {
                Section("Whoop") {
                    if whoopService.isConnected {
                        Label("Connected", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                        Button("Disconnect", role: .destructive) { whoopService.disconnect() }
                    } else {
                        Label("Not connected", systemImage: "xmark.circle").foregroundStyle(.secondary)
                        Button("Connect Whoop") {
                            Task {
                                try? await whoopService.connect(presentationContext: windowContext)
                            }
                        }
                    }
                }
                Section("Progressive Overload") {
                    HStack {
                        Text("Weight increment")
                        Spacer()
                        TextField("2.5", value: $incrementKg, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                        Text("kg").foregroundStyle(.secondary)
                    }
                    Stepper("Deload below: \(deloadThreshold)% recovery", value: $deloadThreshold, in: 10...90, step: 5)
                }
                Section("Programs") {
                    Stepper("Default duration: \(programDurationWeeks) weeks", value: $programDurationWeeks, in: 1...52)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

final class WindowContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
