import SwiftUI
import UIWorkouts

/// The whole of Settings for the MVP: appearance, and whether cues dim music.
struct SettingsView: View {
    @AppStorage("rounds.theme") private var theme: WKThemeMode = .system
    @AppStorage("rounds.dimOtherAudio") private var dimOtherAudio = true
    @AppStorage(FreeWorkoutStore.saveKey) private var saveFreeWorkout = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WKSpace.xl) {
                    VStack(alignment: .leading, spacing: WKSpace.md) {
                        WKSectionHeader(Copy.Settings.appearance)
                        WKThemePicker(selection: $theme)
                    }

                    VStack(alignment: .leading, spacing: WKSpace.md) {
                        WKSectionHeader(Copy.Settings.freeWorkout)
                        WKToggleRow(Copy.Settings.saveFreeWorkout, isOn: $saveFreeWorkout)
                            .background(WKColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: WKRadius.card, style: .continuous))
                        Text(Copy.Settings.saveFreeWorkoutCaption)
                            .wkFont(.caption)
                            .foregroundStyle(WKColor.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .onChange(of: saveFreeWorkout) { _, _ in
                        // Switched off → forget the current Free setup now.
                        FreeWorkoutStore.resetIfNotSaving()
                    }

                    VStack(alignment: .leading, spacing: WKSpace.md) {
                        WKSectionHeader(Copy.Settings.audio)
                        WKToggleRow(Copy.Settings.dimOtherAudio, isOn: $dimOtherAudio)
                            .background(WKColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: WKRadius.card, style: .continuous))
                        Text(Copy.Settings.dimOtherAudioCaption)
                            .wkFont(.caption)
                            .foregroundStyle(WKColor.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(WKSpace.lg)
            }
            .background(WKColor.bg)
            .navigationTitle(Copy.Settings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Copy.Settings.done) { dismiss() }
                        .tint(WKColor.accent)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
