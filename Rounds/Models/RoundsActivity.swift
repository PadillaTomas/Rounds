import Foundation

/// The two MVP activity options.
enum RoundsMode: String, CaseIterable, Identifiable {
    /// Twelve 3-minute rounds, 1-minute rest. Nothing editable.
    case fullCard
    /// User sets the number of rounds (or unlimited), round length and rest.
    case free

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullCard: return Copy.Mode.fullCardTitle
        case .free:     return Copy.Mode.freeTitle
        }
    }

    var detail: String {
        switch self {
        case .fullCard: return Copy.Mode.fullCardDetail
        case .free:     return Copy.Mode.freeDetail
        }
    }
}

/// A fully-resolved workout the timer can run. Value type — the timer engine
/// takes a snapshot of this at Start and never reads it again.
struct RoundsActivity: Identifiable {
    let id = UUID()
    var mode: RoundsMode
    /// Free mode only: number of rounds, or `0` for unlimited. Ignored for Full Card.
    var freeRounds: Int
    var freeRoundSeconds: Int
    var freeRestSeconds: Int

    /// Full Card is a fixed twelve 3:00 / 1:00 rounds.
    static let fullCardRounds = 12
    static let fullCardRoundSeconds = 180
    static let fullCardRestSeconds = 60

    static let `default` = RoundsActivity(
        mode: .fullCard, freeRounds: 6, freeRoundSeconds: 180, freeRestSeconds: 60
    )

    var roundSeconds: Int {
        mode == .fullCard ? Self.fullCardRoundSeconds : max(10, freeRoundSeconds)
    }

    var restSeconds: Int {
        mode == .fullCard ? Self.fullCardRestSeconds : max(5, freeRestSeconds)
    }

    /// Total rounds, or `nil` for an unbounded Free workout.
    var totalRounds: Int? {
        switch mode {
        case .fullCard: return Self.fullCardRounds
        case .free:     return freeRounds <= 0 ? nil : freeRounds
        }
    }
}
