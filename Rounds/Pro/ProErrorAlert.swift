import SwiftUI

extension View {
    /// Surface ``ProStore/lastError`` as an alert, clearing it on dismiss. Used
    /// wherever a purchase or restore can be triggered (the paywall, Settings).
    func proErrorAlert(_ pro: ProStore) -> some View {
        modifier(ProErrorAlert(pro: pro))
    }
}

private struct ProErrorAlert: ViewModifier {
    @Bindable var pro: ProStore
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .onChange(of: pro.lastError) { _, error in isPresented = error != nil }
            .alert(Copy.Pro.errorTitle, isPresented: $isPresented) {
                Button(Copy.Common.ok) { pro.lastError = nil }
            } message: {
                Text(pro.lastError ?? "")
            }
    }
}
