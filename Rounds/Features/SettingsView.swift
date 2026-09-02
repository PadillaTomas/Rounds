import SwiftUI
import UIWorkouts

/// Settings: Rounds Pro, appearance, whether the setup is remembered, and audio.
struct SettingsView: View {
    @AppStorage("rounds.theme") private var theme: WKAppearance = .dark
    @AppStorage("rounds.dimOtherAudio") private var dimOtherAudio = true
    @AppStorage("rounds.muteCues") private var muteCues = false

    @Environment(ProStore.self) private var pro
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WKSpace.xl) {
                    proRow

                    VStack(alignment: .leading, spacing: WKSpace.md) {
                        WKSectionHeader(Copy.Settings.appearance)
                        WKThemePicker(selection: $theme)
                    }

                    VStack(alignment: .leading, spacing: WKSpace.md) {
                        WKSectionHeader(Copy.Settings.audio)

                        WKToggleRow(Copy.Settings.muteCues, isOn: $muteCues)
                            .background(WKColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: WKRadius.card, style: .continuous))
                        Text(Copy.Settings.muteCuesCaption)
                            .wkFont(.caption)
                            .foregroundStyle(WKColor.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)

                        WKToggleRow(Copy.Settings.dimOtherAudio, isOn: $dimOtherAudio)
                            .background(WKColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: WKRadius.card, style: .continuous))
                            .disabled(muteCues)
                            .opacity(muteCues ? 0.4 : 1)
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
        .sheet(isPresented: $showPaywall) {
            RoundsProPaywall(onClose: { showPaywall = false })
        }
        .proErrorAlert(pro)
    }

    // MARK: - Rounds Pro

    @ViewBuilder private var proRow: some View {
        VStack(alignment: .leading, spacing: WKSpace.md) {
            WKSectionHeader(Copy.Settings.pro)

            if pro.isPro {
                HStack(spacing: WKSpace.sm) {
                    Text(Copy.Settings.proOwned)
                        .wkFont(.body)
                        .foregroundStyle(WKColor.textPrimary)
                    Spacer(minLength: WKSpace.sm)
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(WKColor.accent)
                }
                .wkRowMetrics()
                .background(WKColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: WKRadius.card, style: .continuous))
            } else {
                WKNavRow(Copy.Settings.proUnlock, value: pro.displayPrice) { showPaywall = true }
                    .background(WKColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: WKRadius.card, style: .continuous))
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(ProStore())
}
