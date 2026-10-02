import SwiftUI
import UIKit

@main
struct RoundsApp: App {
    init() {
        // If "save last used free workout" is off, start from the defaults.
        FreeWorkoutStore.resetIfNotSaving()
        FreeWorkoutStore.clampToMinimums()
        Task { await WorkoutLiveActivity.endAll() }
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification, object: nil, queue: nil
        ) { _ in WorkoutLiveActivity.endAllBlocking() }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
