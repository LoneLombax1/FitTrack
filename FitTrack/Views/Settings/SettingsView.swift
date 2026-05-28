import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @EnvironmentObject private var whoopService: WhoopService
    @AppStorage("deloadThreshold") private var deloadThreshold: Int = 50
    @AppStorage("programDurationWeeks") private var programDurationWeeks: Int = 8
    @State private var windowContext = WindowContextProvider()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.bg.ignoresSafeArea()
                List {
                    Section {
                        if whoopService.isConnected {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: "00FF88"))
                                Text("Connected")
                                    .foregroundStyle(Theme.Colors.textPrimary)
                            }
                            Button("Disconnect", role: .destructive) { whoopService.disconnect() }
                                .foregroundStyle(Color(hex: "FF3B5C"))
                        } else {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .foregroundStyle(Theme.Colors.textMuted)
                                Text("Not connected")
                                    .foregroundStyle(Theme.Colors.textMuted)
                            }
                            Button("Connect Whoop") {
                                Task { try? await whoopService.connect(presentationContext: windowContext) }
                            }
                            .foregroundStyle(Theme.Colors.cyan)
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
