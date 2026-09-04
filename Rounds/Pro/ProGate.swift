import SwiftUI

/// Gates a Pro-only feature. A Pro user sees `content`; a free user sees the
/// paywall in its place. Generic on purpose — every Pro feature (History now,
/// Calendar / Health / Share next) wraps its screen in this and nothing else
/// changes.
///
/// ```swift
/// ProGate { HistoryView() }
/// ```
struct ProGate<Content: View>: View {
    @Environment(ProStore.self) private var pro
    @ViewBuilder var content: () -> Content

    var body: some View {
        if pro.isPro {
            content()
        } else {
            RoundsProPaywall()
        }
    }
}
