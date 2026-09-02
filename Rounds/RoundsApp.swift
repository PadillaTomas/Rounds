import SwiftUI
import SwiftData

@main
struct RoundsApp: App {
    private let container = RoundsStore.makeContainer()
    @State private var pro = ProStore()

    init() {
        FreeWorkoutStore.clampToMinimums()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(pro)
        }
        .modelContainer(container)
    }
}
