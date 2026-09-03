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

    enum Tabs {
        static var workout: String { t("tabs.workout", "Workout") }
        static var history: String { t("tabs.history", "History") }
        static var settings: String { t("tabs.settings", "Settings") }
    }

    enum Common {
        static var cancel: String { t("common.cancel", "Cancel") }
        static var ok: String { t("common.ok", "OK") }
    }

    enum Setup {
        static var eyebrow: String { t("setup.eyebrow", "Workout") }
        static var title: String { t("setup.title", "Set up your rounds") }
        static var start: String { t("setup.start", "Start") }
        static var rounds: String { t("setup.rounds", "Rounds") }
        static var infinite: String { t("setup.infinite", "Non-Stop") }
        static var roundLength: String { t("setup.roundLength", "Round length") }
        static var restLength: String { t("setup.restLength", "Rest length") }
        static var unitMinutes: String { t("setup.unit.minutes", "min") }
        static var unitSeconds: String { t("setup.unit.seconds", "sec") }
    }

    enum Presets {
        static var heading: String { t("presets.heading", "Default workouts") }
        static var fullCardTitle: String { t("presets.fullCard.title", "Full Card") }
        static var fullCardSummary: String {
            t("presets.fullCard.summary", "12 rounds · 3:00 work · 1:00 rest")
        }
        static var fullCardDetail: String {
            t("presets.fullCard.detail",
              "A full championship fight — twelve three-minute rounds with a minute of rest between each.")
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
        static func tally(_ round: Int, _ total: Int) -> String {
            String(localized: "timer.tally", defaultValue: "\(round) of \(total)")
        }
        static func nextUp(_ phase: String, _ clock: String) -> String {
            String(localized: "timer.nextUp", defaultValue: "Next · \(phase) \(clock)")
        }
        static var lastRound: String { t("timer.lastRound", "Last round") }

        static var getReady: String { t("timer.getReady", "Get ready") }

        static var stopTitle: String { t("timer.stop.title", "Stop this workout?") }
        static var stopMessage: String { t("timer.stop.message", "The workout ends here.") }
        static var stopMessageSave: String {
            t("timer.stop.message.save", "You can keep the rounds you've done in your history.")
        }
        static var stopConfirm: String { t("timer.stop.confirm", "Stop") }
        static var stopSave: String { t("timer.stop.save", "Save & finish") }
        static var stopDiscard: String { t("timer.stop.discard", "Discard") }
        static var stopResume: String { t("timer.stop.resume", "Keep going") }
    }

    enum History {
        static var title: String { t("history.title", "History") }
        static var recent: String { t("history.recent", "Recent") }
        static var empty: String {
            t("history.empty", "Your finished workouts show up here.")
        }
        static var thisWeek: String { t("history.thisWeek", "This week") }
        static var totalRounds: String { t("history.totalRounds", "Total rounds") }
        static var delete: String { t("history.delete", "Delete") }
        static var deleteTitle: String { t("history.delete.title", "Delete this activity?") }
        static var deleteMessage: String {
            t("history.delete.message", "It's removed from your history for good.")
        }

        /// "1 round" / "12 rounds".
        static func roundsCount(_ n: Int) -> String {
            n == 1 ? t("history.rounds.one", "1 round")
                   : String(localized: "history.rounds.many", defaultValue: "\(n) rounds")
        }
        /// "8 of 12 rounds" — a workout stopped before the final bell.
        static func roundsOf(_ done: Int, _ planned: Int) -> String {
            String(localized: "history.rounds.of", defaultValue: "\(done) of \(planned) rounds")
        }
        /// "12 rounds · 3:00 / 1:00".
        static func line(_ rounds: String, _ work: String, _ rest: String) -> String {
            String(localized: "history.line", defaultValue: "\(rounds) · \(work) / \(rest)")
        }
    }

    enum Pro {
        static var title: String { t("pro.title", "Track your training with Rounds Pro") }
        static var subtitle: String {
            t("pro.subtitle", "Every workout you finish, remembered — on your phone, nowhere else.")
        }
        static var historyTitle: String { t("pro.feat.history.title", "Activity history") }
        static var historyDetail: String {
            t("pro.feat.history.detail", "Every finished workout, with weekly and total counts.")
        }
        static var calendarTitle: String { t("pro.feat.calendar.title", "Calendar") }
        static var calendarDetail: String {
            t("pro.feat.calendar.detail", "Your training on a month grid.")
        }
        static var healthTitle: String { t("pro.feat.health.title", "Apple Health") }
        static var healthDetail: String {
            t("pro.feat.health.detail", "Send finished workouts to the Health app.")
        }
        static var shareTitle: String { t("pro.feat.share.title", "Share card") }
        static var shareDetail: String {
            t("pro.feat.share.detail", "A clean summary image to post anywhere.")
        }
        static var cta: String { t("pro.cta", "Unlock Rounds Pro") }
        static var restore: String { t("pro.restore", "Restore Purchase") }
        static var terms: String { t("pro.terms", "Terms of Use") }
        static var privacy: String { t("pro.privacy", "Privacy Policy") }

        static var nudgeTitle: String { t("pro.nudge.title", "Keep your history") }
        static var nudgeDetail: String {
            t("pro.nudge.detail", "Rounds Pro remembers every workout — weekly totals, streaks, and a calendar of your training.")
        }
        static var nudgeCta: String { t("pro.nudge.cta", "See Rounds Pro") }
        static func price(_ displayPrice: String) -> String {
            String(localized: "pro.price", defaultValue: "\(displayPrice) · one-time, yours forever")
        }

        static var errorTitle: String { t("pro.error.title", "Something went wrong") }
        static var errorPending: String {
            t("pro.error.pending", "Your purchase is waiting for approval. Rounds Pro unlocks once it goes through.")
        }
        static var errorFailed: String {
            t("pro.error.failed", "The purchase didn't go through — you haven't been charged.")
        }
        static var errorRestoreNone: String {
            t("pro.error.restoreNone", "No previous purchase found on this Apple ID.")
        }
        static var errorNetwork: String {
            t("pro.error.network", "Couldn't reach the App Store. Check your connection and try again.")
        }
    }

    enum Settings {
        static var title: String { t("settings.title", "Settings") }
        static var appearance: String { t("settings.appearance", "Appearance") }
        static var audio: String { t("settings.audio", "Audio") }
        static var muteCues: String { t("settings.muteCues", "Silent workout") }
        static var muteCuesCaption: String {
            t("settings.muteCuesCaption", "No bell or clap — just the vibration for every round and warning. For a crowded gym or a quiet room.")
        }
        static var dimOtherAudio: String {
            t("settings.dimOtherAudio", "Dim other audio during cues")
        }
        static var dimOtherAudioCaption: String {
            t("settings.dimOtherAudioCaption", "Cues always play alongside your music, even on silent. When on, your music dips just for the moment a bell or clap sounds, then comes straight back.")
        }

        static var pro: String { t("settings.pro", "Rounds Pro") }
        static var proUnlock: String { t("settings.pro.unlock", "Unlock") }
        static var proOwned: String { t("settings.pro.owned", "Unlocked") }
    }
}
