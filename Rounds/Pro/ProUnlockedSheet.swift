import SwiftUI
import UIWorkouts

/// Shown once, the moment a purchase completes — wherever it happened (the
/// locked History tab or the Settings paywall sheet). A compact confirmation,
/// not a full screen: what just unlocked, and a one-tap way to turn on the one
/// feature that needs its own OS permission (Health) without a trip to
/// Settings. Declining leaves everything exactly as it is — the same toggle is
/// always there in Settings, whenever.
struct ProUnlockedSheet: View {
    @AppStorage("rounds.healthKitEnabled") private var healthKitEnabled = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: WKSpace.xl) {
            VStack(spacing: WKSpace.sm) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(WKColor.accent)
                Text(Copy.Pro.unlockedTitle)
                    .wkFont(.titleL)
                    .foregroundStyle(WKColor.textPrimary)
            }

            VStack(alignment: .leading, spacing: WKSpace.md) {
                unlockedRow(Copy.Pro.historyTitle)
                unlockedRow(Copy.Pro.calendarTitle)
                unlockedRow(Copy.Pro.healthTitle)
                unlockedRow(Copy.Pro.shareTitle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            VStack(spacing: WKSpace.md) {
                WKButton(Copy.Pro.unlockedEnableHealth, style: .primary) { enableHealth() }
                WKButton(Copy.Common.notNow, style: .quiet) { dismiss() }
            }
        }
        .padding(WKSpace.xl)
        .padding(.top, WKSpace.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WKColor.bg)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func unlockedRow(_ title: String) -> some View {
        HStack(spacing: WKSpace.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(WKPhase.walk.color)
            Text(title)
                .wkFont(.body)
                .foregroundStyle(WKColor.textPrimary)
        }
    }

    /// Turns Health sync on and fires the real permission request right here —
    /// still an explicit tap, just without the detour through Settings. Denied
    /// reverts the toggle. Deliberately no catch-up for workouts recorded before
    /// this moment — only ones done from here on ever reach Health.
    private func enableHealth() {
        healthKitEnabled = true
        Task {
            if await HealthWriter.shared.requestAuthorization() == .denied {
                healthKitEnabled = false
            }
            dismiss()
        }
    }
}

#if DEBUG
#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        ProUnlockedSheet()
    }
}
#endif
