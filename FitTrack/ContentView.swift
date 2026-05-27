import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "house.fill") }
            ProgramView()
                .tabItem { Label("Program", systemImage: "list.clipboard.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
            MusclesView()
                .tabItem { Label("Muscles", systemImage: "figure.strengthtraining.traditional") }
            ProgressView_()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
    }
}
