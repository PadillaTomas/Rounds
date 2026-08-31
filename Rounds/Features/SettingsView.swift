import SwiftUI
import UIWorkouts

/// The whole of Settings for the MVP: appearance, and whether cues dim music.
struct SettingsView: View {
    @AppStorage("rounds.theme") private var theme: WKThemeMode = .system
    @AppStorage("rounds.dimOtherAudio") private var dimOtherAudio = true
    @AppStorage(FreeWorkoutStore.saveKey) private var saveWorkout = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WKSpace.xl) {
                    VStack(alignment: .leading, spacing: WKSpace.md) {
                        WKSectionHeader(Copy.Settings.appearance)
                        WKThemePicker(selection: $theme)
                    }

                    VStack(alignment: .leading, spacing: WKSpace.md) {
                        WKSectionHeader(Copy.Settings.workout)
                        WKToggleRow(Copy.Settings.saveWorkout, isOn: $saveWorkout)
                            .background(WKColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: WKRadius.card, style: .continuous))
                        Text(Copy.Settings.saveWorkoutCaption)
                            .wkFont(.caption)
                            .foregroundStyle(WKColor.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .onChange(of: saveWorkout) { _, _ in
                        // Switched off → forget the current setup now.
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
        }
    }
}

#Preview {
    SettingsView()
}
