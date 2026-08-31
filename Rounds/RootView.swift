import SwiftUI
import UIWorkouts

/// The app root. Persisted appearance is applied exactly once, here. Two tabs:
/// set up / run the workout, and settings.
struct RootView: View {
    @AppStorage("rounds.theme") private var theme: WKThemeMode = .system

    var body: some View {
        MainTabView()
            .tint(WKColor.accent)
            .wkThemeMode(theme)
    }
}

/// The 2-tab shell — Workout and Settings. Same plain `TabView` as C2H.
struct MainTabView: View {
    var body: some View {
        TabView {
            SetupView()
                .tabItem { Label(Copy.Tabs.workout, systemImage: "figure.boxing") }
            SettingsView()
                .tabItem { Label(Copy.Tabs.settings, systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootView()
}
