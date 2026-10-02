import Foundation

enum SoundPalette: String, CaseIterable {
    case boxing, countdown

    static let storageKey = "rounds.soundPalette"
}
