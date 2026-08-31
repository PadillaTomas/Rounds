import SwiftUI

@main
struct RoundsApp: App {
    init() {
        // If "save last used free workout" is off, start from the defaults.
        FreeWorkoutStore.resetIfNotSaving()
        FreeWorkoutStore.clampToMinimums()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
