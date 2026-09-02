import SwiftUI
import UIWorkouts

/// The app root. Persisted appearance is applied exactly once, here. Three tabs:
/// set up / run the workout, history (Pro), and settings.
struct RootView: View {
    @AppStorage("rounds.theme") private var theme: WKAppearance = .dark
    @Environment(ProStore.self) private var pro

    var body: some View {
        MainTabView()
            .tint(WKColor.accent)
            .preferredColorScheme(theme.colorScheme)
            .task { await pro.start() }
    }
}

/// The 3-tab shell — Workout, History and Settings. The History tab is always in
/// the bar; for a free user its content is the paywall (``ProGate``).
struct MainTabView: View {
    var body: some View {
        TabView {
            SetupView()
                .tabItem { Label(Copy.Tabs.workout, systemImage: "figure.boxing") }
            ProGate { HistoryView() }
                .tabItem { Label(Copy.Tabs.history, systemImage: "clock.arrow.circlepath") }
            SettingsView()
                .tabItem { Label(Copy.Tabs.settings, systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootView()
        .environment(ProStore())
        .modelContainer(RoundsStore.preview)
}
