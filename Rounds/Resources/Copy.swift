import Foundation

/// Typed access to every user-facing string, backed by the
/// **`Localizable.xcstrings`** String Catalog (edit copy there, or in Xcode's
/// catalog editor).
///
/// Why a wrapper instead of `Text("literal")`: the UIWorkouts components take
/// plain `String`, not `LocalizedStringKey`, so a call site has to resolve the
/// string itself. Centralising that keeps the keys in one list and call sites
/// readable (`Copy.Setup.start`). See `LOCALIZATION.md`.
///
/// Every accessor passes a `defaultValue` — that English is only a *fallback*
/// (the catalog value wins at runtime), but it guarantees the app never renders
/// a raw key if a catalog entry is ever lost.
private func t(_ key: StaticString, _ fallback: String.LocalizationValue) -> String {
    String(localized: key, defaultValue: fallback)
}

enum Copy {

    enum Setup {
        static var eyebrow: String { t("setup.eyebrow", "Rounds") }
        static var title: String { t("setup.title", "Set up your rounds") }
        static var body: String {
            t("setup.body", "A boxing-style interval timer — bell every round, a clap ten seconds before the bell.")
        }
        static var start: String { t("setup.start", "Start") }
        static var rounds: String { t("setup.rounds", "Rounds") }
        static var infinite: String { t("setup.infinite", "Infinite") }
        static var roundLength: String { t("setup.roundLength", "Round length") }
        static var restLength: String { t("setup.restLength", "Rest length") }
        static var unitMinutes: String { t("setup.unit.minutes", "min") }
        static var unitSeconds: String { t("setup.unit.seconds", "sec") }
    }

    enum Mode {
        static var fullCardTitle: String { t("mode.fullCard.title", "Full Card") }
        static var fullCardDetail: String {
            t("mode.fullCard.detail", "Twelve 3-minute rounds, 1-minute rest. Fixed.")
        }
        static var freeTitle: String { t("mode.free.title", "Free") }
        static var freeDetail: String {
            t("mode.free.detail", "Set your own rounds, round length and rest.")
        }
    }

    enum Timer {
        static var pause: String { t("timer.pause", "Pause") }
        static var resume: String { t("timer.resume", "Resume") }
        static var stop: String { t("timer.stop", "Stop") }
        static var done: String { t("timer.done", "Done") }
        static var work: String { t("timer.phase.work", "Round") }
        static var rest: String { t("timer.phase.rest", "Rest") }

        static func roundOfTotal(_ round: Int, _ total: Int) -> String {
            String(localized: "timer.roundOfTotal",
                   defaultValue: "Round \(round) of \(total)")
        }
        static func round(_ round: Int) -> String {
            String(localized: "timer.round", defaultValue: "Round \(round)")
        }
    }

    enum Settings {
        static var title: String { t("settings.title", "Settings") }
        static var done: String { t("settings.done", "Done") }
        static var appearance: String { t("settings.appearance", "Appearance") }
        static var freeWorkout: String { t("settings.freeWorkout", "Free workout") }
        static var saveFreeWorkout: String {
            t("settings.saveFreeWorkout", "Save last used free workout")
        }
        static var saveFreeWorkoutCaption: String {
            t("settings.saveFreeWorkoutCaption", "When on, your Free setup — rounds, round length and rest — is remembered for next time. When off, it always opens at 12 rounds of 3:00 with 1:00 rest.")
        }
        static var audio: String { t("settings.audio", "Audio") }
        static var dimOtherAudio: String {
            t("settings.dimOtherAudio", "Dim other audio during cues")
        }
        static var dimOtherAudioCaption: String {
            t("settings.dimOtherAudioCaption", "Cues always play alongside your music, even on silent. When on, your music is lowered for the whole workout so every bell and clap stands out.")
        }
    }

    enum A11y {
        static var settings: String { t("a11y.settings", "Settings") }
    }
}
