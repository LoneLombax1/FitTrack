import SwiftUI
import UIKit

struct ContentView: View {
    init() {
        // Tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.Colors.surface)
        appearance.shadowColor = UIColor(Theme.Colors.borderSubtle)

        let normal = UITabBarItemAppearance()
        normal.normal.iconColor = UIColor(Theme.Colors.textMuted)
        normal.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.textMuted),
            .font: UIFont.systemFont(ofSize: 10)
        ]
        normal.selected.iconColor = UIColor(Theme.Colors.cyan)
        normal.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.cyan),
            .font: UIFont.systemFont(ofSize: 10)
        ]
        appearance.stackedLayoutAppearance = normal
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Theme.Colors.bg)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.textPrimary)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.textPrimary)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // List / table view background
        UITableView.appearance().backgroundColor = UIColor(Theme.Colors.bg)
        UITableViewCell.appearance().backgroundColor = UIColor(Theme.Colors.surface)
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "bolt.fill") }
            ProgramView()
                .tabItem { Label("Program", systemImage: "list.clipboard.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
            MusclesView()
                .tabItem { Label("Muscles", systemImage: "figure.strengthtraining.traditional") }
            ProgressView_()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .background(Theme.Colors.bg.ignoresSafeArea())
    }
}
