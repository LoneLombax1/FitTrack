import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @EnvironmentObject private var whoopService: WhoopService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("deloadThreshold") private var deloadThreshold: Int = 50
    @AppStorage("programDurationWeeks") private var programDurationWeeks: Int = 8
    @State private var windowContext = WindowContextProvider()
    @State private var whoopError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                List {
                    Section {
                        if whoopService.isConnected {
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: "00FF88"))
                            Button("Disconnect", role: .destructive) { whoopService.disconnect() }
                        } else {
                            Label("Not connected", systemImage: "xmark.circle")
                                .foregroundStyle(Theme.Colors.textMuted)
                            Button("Connect Whoop") {
                                Task {
                                    do {
                                        try await whoopService.connect(presentationContext: windowContext)
                                    } catch {
                                        whoopError = error.localizedDescription
                                    }
                                }
                            }
                            .foregroundStyle(Theme.Colors.cyan)
                        }
                        if let err = whoopError {
                            Text(err)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "FF3B5C"))
                        }
                    } header: { SectionHeader(title: "Whoop") }

                    Section {
                        HStack {
                            Text("Deload below")
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            Stepper("\(deloadThreshold)% recovery", value: $deloadThreshold, in: 10...90, step: 5)
                                .fixedSize()
                                .foregroundStyle(Theme.Colors.cyan)
                        }
                    } header: { SectionHeader(title: "Progressive Overload") }

                    Section {
                        HStack {
                            Text("Default duration")
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            Stepper("\(programDurationWeeks) weeks", value: $programDurationWeeks, in: 1...52)
                                .fixedSize()
                                .foregroundStyle(Theme.Colors.cyan)
                        }
                    } header: { SectionHeader(title: "Programs") }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.Colors.cyan)
                }
            }
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
