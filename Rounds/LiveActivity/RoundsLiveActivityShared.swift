import ActivityKit
import AppIntents
import Foundation

/// Compiled into both the app and the widget extension.
struct RoundsActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isWork: Bool
        var phaseLabel: String
        var roundText: String
        var phaseEnd: Date
        var phaseDuration: TimeInterval
        var remaining: Int
        var pausedAt: Date?
        var isFinished: Bool
        var canControl: Bool
        var canSkip: Bool
        var revision = 0

        var phaseStart: Date { phaseEnd.addingTimeInterval(-phaseDuration) }
    }
}

enum WorkoutCommand {
    case togglePause, skip
}

/// Where the Live Activity buttons land. The app installs the handler while a
/// workout is on screen; `LiveActivityIntent`s run in the app's process.
@MainActor
final class WorkoutRemote {
    static let shared = WorkoutRemote()
    var handler: ((WorkoutCommand, Int) async -> Void)?
    func send(_ command: WorkoutCommand, revision: Int) async { await handler?(command, revision) }
}

struct TogglePauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause or resume"
    static var isDiscoverable = false

    @Parameter(title: "Revision") var revision: Int

    init() {}
    init(revision: Int) { self.revision = revision }

    func perform() async throws -> some IntentResult {
        await WorkoutRemote.shared.send(.togglePause, revision: revision)
        return .result()
    }
}

struct SkipIntervalIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip interval"
    static var isDiscoverable = false

    @Parameter(title: "Revision") var revision: Int

    init() {}
    init(revision: Int) { self.revision = revision }

    func perform() async throws -> some IntentResult {
        await WorkoutRemote.shared.send(.skip, revision: revision)
        return .result()
    }
}
