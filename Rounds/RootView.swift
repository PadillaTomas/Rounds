import SwiftUI
import UIWorkouts

/// The app root. Persisted appearance is applied exactly once, here. Three tabs:
/// set up / run the workout, history (Pro), and settings.
struct RootView: View {
    @AppStorage("rounds.theme") private var theme: WKAppearance = .dark
    /// Set the first time the "You're Pro" confirmation is shown, so it never
    /// shows again — even if `pro.justUnlocked` fires again on a later launch.
    /// `ProStore` is recreated fresh every launch, so `justUnlocked` alone
    /// isn't a reliable "only once, ever" signal: StoreKit's `Transaction.updates`
    /// can redeliver an already-owned transaction on a fresh launch (more so
    /// against the local `.storekit` config used for testing), which would
    /// otherwise flip `justUnlocked` true again and reopen this sheet.
    @AppStorage("rounds.proUnlockedShown") private var proUnlockedShown = false
    @Environment(ProStore.self) private var pro
    @State private var showProUnlocked = false

    var body: some View {
        MainTabView()
            .tint(WKColor.accent)
            .preferredColorScheme(theme.colorScheme)
            .task { await pro.start() }
            .proErrorAlert(pro)   // one owner for the whole app — see ProErrorAlert
            .onChange(of: pro.justUnlocked) { _, unlocked in
                guard unlocked, !proUnlockedShown else { return }
                showProUnlocked = true
                proUnlockedShown = true
            }
            .sheet(isPresented: $showProUnlocked) {
                ProUnlockedSheet()
            }
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

#if DEBUG
#Preview {
    RootView()
        .environment(ProStore())
        .modelContainer(RoundsStore.preview)
}
#endif
