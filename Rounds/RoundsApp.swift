import SwiftUI
import SwiftData

@main
struct RoundsApp: App {
    private let container = RoundsStore.makeContainer()

    init() {
        // If "save last used free workout" is off, start from the defaults.
        FreeWorkoutStore.resetIfNotSaving()
        FreeWorkoutStore.clampToMinimums()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
