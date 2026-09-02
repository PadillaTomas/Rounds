import Foundation
import SwiftData

/// The app's SwiftData stack. One on-device store, no CloudKit — consistent with
/// 1.0's "nothing leaves your phone" stance. 1.0 persisted nothing beyond
/// `UserDefaults`, so there is no migration: a first 2.0 launch just creates it.
enum RoundsStore {
    static let schema = Schema([CompletedActivity.self])

    /// The container the app runs on. A failure here is unrecoverable (the store
    /// is the 2.0 foundation), so we trap rather than limp along storeless.
    static func makeContainer() -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create the Rounds store: \(error)")
        }
    }

    #if DEBUG
    /// In-memory container for `#Preview`s, seeded with a couple of activities.
    @MainActor static let preview: ModelContainer = {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let ctx = container.mainContext
        ctx.insert(CompletedActivity(startedAt: .now.addingTimeInterval(-3600),
                                     elapsedSeconds: 1980, completedRounds: 12,
                                     plannedRounds: 12, roundSeconds: 180, restSeconds: 60,
                                     sourceName: "Full Card"))
        ctx.insert(CompletedActivity(startedAt: .now.addingTimeInterval(-3 * 86_400),
                                     elapsedSeconds: 720, completedRounds: 3,
                                     plannedRounds: 0, roundSeconds: 180, restSeconds: 60))
        return container
    }()
    #endif
}
