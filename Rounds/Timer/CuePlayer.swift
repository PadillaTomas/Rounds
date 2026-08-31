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
    /// When `true`, other apps' audio (music, podcasts) is lowered for the
    /// duration of the workout so the cues sit on top. When `false`, cues just
    /// mix in at full volume.
    private let dimsOtherAudio: Bool

    private let audioQueue = DispatchQueue(label: "com.padillatomas.rounds.audio-session")

    /// Set when the workout ended while the closing bell was still playing —
    /// the audio-session teardown is then deferred to `audioPlayerDidFinishPlaying`.
    private var endAfterBell = false
    /// A static hold so a bell that outlives the timer screen (Done tapped
    /// mid-ring) still plays to the end before the session is released.
    private static var ringingOut: CuePlayer?

    private var interruptionObserver: NSObjectProtocol?

    init(dimsOtherAudio: Bool = true) {
        self.dimsOtherAudio = dimsOtherAudio
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

    private func play(_ player: AVAudioPlayer?) {
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }

    // MARK: CuePlaying

    func roundStarted()     { play(bell); Haptics.buzz(0.45) }
    func roundEnded()       { play(bell); Haptics.buzz(0.55) }
    func tenSecondWarning() { play(warnClap); Haptics.tap(times: 3) }
    func sessionFinished()  { play(bell); Haptics.buzz(0.6, times: 4) }

    func sessionDidBegin() {
        let dims = dimsOtherAudio
        audioQueue.async {
            let session = AVAudioSession.sharedInstance()
            // `.playback` ignores the mute switch; `.mixWithOthers` keeps the
            // fighter's music going, `.duckOthers` lowers it under the cues.
            var options: AVAudioSession.CategoryOptions = [.mixWithOthers]
            if dims { options.insert(.duckOthers) }
            try? session.setCategory(.playback, mode: .default, options: options)
            try? session.setActive(true)
        }
        [bell, warnClap].forEach { $0?.prepareToPlay() }
        keepAlive?.prepareToPlay()
        keepAlive?.play()
        observeInterruptions()
        Haptics.prepare()
    }

    func sessionDidEnd() {
        // Never cut a ringing bell — most importantly the end-of-fight one.
        // Wait for it, keeping this object (and its player) alive even if the
        // timer screen that owns us is dismissed first.
        if bell?.isPlaying == true {
            endAfterBell = true
            CuePlayer.ringingOut = self
            return
        }
        teardown()
    }

    private func teardown() {
        keepAlive?.stop()
        stopObservingInterruptions()
        Haptics.stop()
        audioQueue.async {
            try? AVAudioSession.sharedInstance()
                .setActive(false, options: .notifyOthersOnDeactivation)
        }
        CuePlayer.ringingOut = nil
    }

    // MARK: AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard endAfterBell else { return }
        endAfterBell = false
        teardown()
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
            self.audioQueue.async { try? AVAudioSession.sharedInstance().setActive(true) }
            self.bell?.prepareToPlay()
            self.keepAlive?.play()
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
        player.prepareToPlay()
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
