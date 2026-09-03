import SwiftUI
import UIWorkouts

/// Rounds' paywall — binds the design-system ``WKPaywall`` to ``ProStore`` and
/// the copy catalog. Fills a locked tab when `onClose` is nil; pass `onClose`
/// to present it as a sheet (from Settings).
struct RoundsProPaywall: View {
    var onClose: (() -> Void)?

    @Environment(ProStore.self) private var pro

    var body: some View {
        WKPaywall(
            title: Copy.Pro.title,
            subtitle: Copy.Pro.subtitle,
            features: [
                .init(systemImage: "clock.arrow.circlepath",
                      title: Copy.Pro.historyTitle, detail: Copy.Pro.historyDetail),
                .init(systemImage: "calendar",
                      title: Copy.Pro.calendarTitle, detail: Copy.Pro.calendarDetail),
                .init(systemImage: "heart.fill",
                      title: Copy.Pro.healthTitle, detail: Copy.Pro.healthDetail),
                .init(systemImage: "square.and.arrow.up",
                      title: Copy.Pro.shareTitle, detail: Copy.Pro.shareDetail),
            ],
            priceLabel: Copy.Pro.price(pro.displayPrice),
            ctaLabel: Copy.Pro.cta,
            restoreLabel: Copy.Pro.restore,
            legalLinks: [
                // The terms page cross-links to the privacy page and back.
                // Goes live when feature/RO-20-legal-pages merges to develop.
                .init(Copy.Pro.legal,
                      URL(string: "https://padillatomas.github.io/Rounds/terms.html")!),
            ],
            isPurchasing: pro.purchaseInFlight,
            onPurchase: { Task { await pro.purchase() } },
            onRestore: { Task { await pro.restore() } },
            onClose: onClose
        )
        .task {
            if pro.product == nil { await pro.loadProduct() }
        }
        .onChange(of: pro.isPro) { _, isPro in
            // Presented as a sheet (from Settings): once the unlock lands there's
            // nothing left to show — close it. As a locked tab (`onClose == nil`)
            // `ProGate` swaps to the real content on its own.
            if isPro { onClose?() }
        }
        // The error alert lives once, on RootView — not here (this view can be
        // alive twice: the locked History tab plus a Settings sheet).
    }
}

#Preview {
    RoundsProPaywall(onClose: {})
        .environment(ProStore())
        .preferredColorScheme(.dark)
}
