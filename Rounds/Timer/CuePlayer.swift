import AudioToolbox
import AVFoundation
import CoreHaptics

/// The timer's out-of-screen feedback — sound plus vibration. A protocol so the
/// engine can be driven silently in tests and previews.
protocol CuePlaying {
    /// Bell — a round is starting (the first round, or after a rest).
    func roundStarted()
    /// Bell — the work period ended, rest begins.
    func roundEnded()
    /// Wooden clap — ten seconds left in the work period.
    func tenSecondWarning()
    /// End-of-fight bell — the last round finished.
    func sessionFinished()
    /// The timer screen appeared — grab the audio session, prime the haptics.
    func sessionDidBegin()
    /// The timer screen went away — release the audio session.
    func sessionDidEnd()
}

extension CuePlaying {
    func sessionFinished() { roundEnded() }
    func sessionDidBegin() {}
    func sessionDidEnd() {}
}

/// Plays the recorded bell / synthesised clap through the `.playback` session —
/// heard with the ringer muted, riding the media-volume buttons — and fires a
/// strong vibration alongside each cue.
///
/// The audio session is activated **once** for the whole workout and released
/// once at the end (with `.notifyOthersOnDeactivation`, so any lowered music
/// jumps straight back up) — but never while the closing bell is still ringing:
/// ``sessionDidEnd()`` waits for it to finish first, holding this object alive
/// past the timer screen's dismissal if the fighter taps Done mid-bell. Every
/// session call is on a background queue — `setActive` on the main thread stalls
/// the UI — and Core Haptics is told `playsHapticsOnly` so it never touches the
/// audio session itself.
///
/// A **silent keep-alive loop** plays for the whole workout so the timer keeps
/// ticking (and bells keep firing) with the screen locked or the app in the
/// background — that's why the target declares `UIBackgroundModes: audio`.
/// Audio-session interruptions (a phone call) re-activate the session and
/// restart the loop when they end.
final class CuePlayer: NSObject, CuePlaying, AVAudioPlayerDelegate {
    /// When `true`, other apps' audio (music, podcasts) is lowered *while a cue
    /// is sounding* and released the moment it finishes — not for the whole
    /// workout. When `false`, cues just mix in at full volume.
    private let dimsOtherAudio: Bool

    /// When `true`, no cue sound is played at all (crowded gym, quiet room). The
    /// vibration for every cue still fires, and the silent keep-alive loop still
    /// runs so the timer keeps ticking in the background.
    private let muted: Bool

    private let audioQueue = DispatchQueue(label: "com.padillatomas.rounds.audio-session")

    /// How many cue sounds are currently holding the duck open. Only ever
    /// touched on `audioQueue`.
    private var duckHolds = 0

    /// Set when the workout ended while the closing bell was still playing —
    /// the audio-session teardown is then deferred to `audioPlayerDidFinishPlaying`.
    private var endAfterBell = false
    /// A static hold so a bell that outlives the timer screen (Done tapped
    /// mid-ring) still plays to the end before the session is released.
    private static var ringingOut: CuePlayer?

    private var interruptionObserver: NSObjectProtocol?

    init(dimsOtherAudio: Bool = true, muted: Bool = false) {
        self.dimsOtherAudio = dimsOtherAudio
        self.muted = muted
        super.init()
    }

    deinit { stopObservingInterruptions() }

    /// Every bell — round start, round end, end of fight — is the same recorded
    /// double bell-hit. Synth fallback only if the bundled file is missing.
    private lazy var bell: AVAudioPlayer? = {
        let player = BundledSound.player("final-bell", ext: "mp3", volume: 0.85)
            ?? ToneSynth.bell(strikes: 3, gap: 0.01, decay: 1, volume: 1)
        player?.delegate = self
        return player
    }()
    private lazy var warnClap = ToneSynth.clap(volume: 1)

    /// Inaudible; loops forever. Keeps the run loop alive in the background.
    private lazy var keepAlive: AVAudioPlayer? = {
        let player = ToneSynth.silence(seconds: 2)
        player?.numberOfLoops = -1
        return player
    }()

    /// Play one cue sound. No-op when muted. When dimming is on, other audio is
    /// ducked just for the length of this sound (plus a short tail) and released
    /// once every overlapping cue has finished.
    private func play(_ player: AVAudioPlayer?) {
        guard !muted, let player else { return }
        // Off the main thread: when the audio server is stalled or absent (a
        // wedged Simulator, a device mid-route-change) `play()` can block the
        // caller for seconds — and cues arrive on the timer's run loop.
        audioQueue.async { [weak self] in
            guard let self else { return }
            if self.dimsOtherAudio {
                self.duckHolds += 1
                self.setDuck(true)
                let hold = max(0.4, player.duration) + 0.3
                self.audioQueue.asyncAfter(deadline: .now() + hold) { [weak self] in
                    guard let self else { return }
                    self.duckHolds = max(0, self.duckHolds - 1)
                    if self.duckHolds == 0 { self.setDuck(false) }
                }
            }
            player.currentTime = 0
            player.play()
        }
    }

    /// Toggle `.duckOthers` on the live session. Always called on `audioQueue`.
    private func setDuck(_ on: Bool) {
        let session = AVAudioSession.sharedInstance()
        var options: AVAudioSession.CategoryOptions = [.mixWithOthers]
        if on { options.insert(.duckOthers) }
        try? session.setCategory(.playback, mode: .default, options: options)
        try? session.setActive(true)
    }

    // MARK: CuePlaying

    func roundStarted()     { play(bell); Haptics.buzz(0.45) }
    func roundEnded()       { play(bell); Haptics.buzz(0.55) }
    func tenSecondWarning() { play(warnClap); Haptics.tap(times: 3) }
    func sessionFinished()  { play(bell); Haptics.buzz(0.6, times: 4) }

    func sessionDidBegin() {
        // Resolve the lazy players on the calling thread (so their initialisers
        // aren't raced), but do every audio-server call on the background queue —
        // `setActive` / `prepareToPlay` / `play` all block while the server is
        // starting, and none of it may stall the UI.
        let players = [bell, warnClap, keepAlive]
        let loop = keepAlive
        audioQueue.async {
            let session = AVAudioSession.sharedInstance()
            // `.playback` ignores the mute switch; `.mixWithOthers` keeps the
            // fighter's music going. `.duckOthers` is *not* set here — it is
            // toggled per cue in `play(_:)` so music only dips as a bell rings.
            try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try? session.setActive(true)
            players.forEach { $0?.prepareToPlay() }
            loop?.play()
        }
        observeInterruptions()
        Haptics.prepare()
    }

    func sessionDidEnd() {
        // On the serial audio queue, so it runs *after* any queued cue playback
        // and `isPlaying` reflects a bell that has actually started. Never cut a
        // ringing bell — most of all the closing one: defer teardown to the
        // delegate, holding this object alive even if the timer screen is gone.
        audioQueue.async { [weak self] in
            guard let self else { return }
            if self.bell?.isPlaying == true {
                self.endAfterBell = true
                CuePlayer.ringingOut = self
            } else {
                self.teardown()
            }
        }
    }

    /// Always called on `audioQueue`.
    private func teardown() {
        duckHolds = 0
        keepAlive?.stop()
        try? AVAudioSession.sharedInstance()
            .setActive(false, options: .notifyOthersOnDeactivation)
        CuePlayer.ringingOut = nil
        DispatchQueue.main.async { [weak self] in
            self?.stopObservingInterruptions()
            Haptics.stop()
        }
    }

    // MARK: AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioQueue.async { [weak self] in
            guard let self, self.endAfterBell else { return }
            self.endAfterBell = false
            self.teardown()
        }
    }

    // MARK: Interruptions

    /// A phone call etc. deactivates our session and stops every player. When it
    /// ends, bring the session and the keep-alive loop back so the workout keeps
    /// running. (Cues missed *during* the call are caught up by the engine, which
    /// is deadline-based — see `RoundTimerEngine`.)
    private func observeInterruptions() {
        guard interruptionObserver == nil else { return }
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] note in
            guard let self,
                  let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended
            else { return }
            let bell = self.bell, loop = self.keepAlive
            self.audioQueue.async {
                try? AVAudioSession.sharedInstance().setActive(true)
                bell?.prepareToPlay()
                loop?.play()
            }
        }
    }

    private func stopObservingInterruptions() {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        interruptionObserver = nil
    }
}

/// Loads a bundled audio file (`Rounds/Rounds/Resources/Sounds/`).
enum BundledSound {
    static func player(_ name: String, ext: String, volume: Float) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.volume = volume
        // `prepareToPlay()` touches the audio server and can block — the caller
        // does it on a background queue in `sessionDidBegin()`.
        return player
    }
}

/// No-op — the default in tests and previews.
struct SilentCuePlayer: CuePlaying {
    func roundStarted() {}
    func roundEnded() {}
    func tenSecondWarning() {}
    func sessionFinished() {}
}

// MARK: - Haptics

/// A full-strength rumble per cue, with the classic system vibration as a
/// fallback on devices without Core Haptics.
///
/// One long-lived engine (Apple's recommended shape): created lazily, marked
/// `playsHapticsOnly` so it never manages an audio session, and
/// `isAutoShutdownEnabled` so Core Haptics powers the hardware down between cues
/// and back up on the next `start()`. We never call `engine.stop()` ourselves —
/// doing that while a pattern was still playing logged
/// `_Haptic_Check … stopWithCompletionHandler … error -4810` at the end of a
/// workout. ``stop()`` only cancels an in-flight pattern.
enum Haptics {
    private static let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private static var engine: CHHapticEngine?
    private static var activePlayer: CHHapticPatternPlayer?

    static func prepare() {
        guard supported else { return }
        if engine == nil {
            guard let created = try? CHHapticEngine() else { return }
            created.playsHapticsOnly = true          // never touches the audio session
            created.isAutoShutdownEnabled = true
            created.resetHandler = { try? engine?.start() }
            engine = created
        }
        try? engine?.start()
    }

    static func stop() {
        try? activePlayer?.stop(atTime: CHHapticTimeImmediate)
        activePlayer = nil
    }

    /// One or more sustained buzzes — low sharpness so it reads as a vibration.
    static func buzz(_ seconds: TimeInterval, times: Int = 1) {
        let events = (0..<max(1, times)).map { i in
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35),
            ], relativeTime: Double(i) * (seconds + 0.12), duration: seconds)
        }
        emit(events, fallbackCount: times)
    }

    /// Sharp taps — used for the ten-second clap.
    static func tap(times: Int) {
        let events = (0..<max(1, times)).map { i in
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7),
            ], relativeTime: Double(i) * 0.09)
        }
        emit(events, fallbackCount: times)
    }

    private static func emit(_ events: [CHHapticEvent], fallbackCount: Int) {
        guard supported, let engine else { return systemFallback(fallbackCount) }
        do {
            try engine.start()          // no-op if running; restarts after auto-shutdown
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            activePlayer = player
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            systemFallback(fallbackCount)
        }
    }

    private static func systemFallback(_ times: Int) {
        for i in 0..<max(1, times) {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
    }
}
