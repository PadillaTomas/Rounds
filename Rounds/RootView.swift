import SwiftUI
import UIWorkouts

/// The app root. Persisted appearance is applied exactly once, here. The whole
/// MVP is a single flow: set up your rounds, then run the timer.
struct RootView: View {
    @AppStorage("rounds.theme") private var theme: WKThemeMode = .system

    var body: some View {
        SetupView()
            .tint(WKColor.accent)
            .wkThemeMode(theme)
    }
}

#Preview {
    RootView()
}
