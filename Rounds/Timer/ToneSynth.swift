import AVFoundation

/// Builds tiny in-memory WAVs for the timer's cues — no bundled audio assets.
/// These are placeholder "default sounds": a struck-metal bell and a wooden
/// clapper, synthesised. A real sound bank replaces these later.
enum ToneSynth {
    private static let sampleRate: Double = 44_100

    /// A ringside bell: a cluster of inharmonic partials with exponential decay,
    /// struck `strikes` times.
    static func bell(strikes: Int, gap: Double, decay: Double, volume: Float) -> AVAudioPlayer? {
        let partials: [(mult: Double, gain: Double)] = [
            (1.0, 1.0), (2.02, 0.6), (2.99, 0.35), (4.21, 0.2), (5.43, 0.12),
        ]
        let base = 660.0
        let strikeCount = max(1, strikes)
        let strikeSamples = Int(sampleRate * decay)
        let gapSamples = Int(sampleRate * gap)
        var out = [Double](repeating: 0, count: (strikeSamples + gapSamples) * strikeCount)

        for s in 0..<strikeCount {
            let offset = s * (strikeSamples + gapSamples)
            for i in 0..<strikeSamples {
                let t = Double(i) / sampleRate
                let env = exp(-t / (decay * 0.3))
                var amp = 0.0
                for p in partials { amp += p.gain * sin(2 * .pi * base * p.mult * t) }
                out[offset + i] += amp / 2.5 * env
            }
        }
        return player(out, volume: volume)
    }

    /// A short buffer of pure silence. Looped, it keeps the audio session (and
    /// so the timer's run loop) alive while the app is backgrounded / locked,
    /// without making a sound.
    static func silence(seconds: Double) -> AVAudioPlayer? {
        player([Double](repeating: 0, count: Int(sampleRate * seconds)), volume: 1)
    }

    /// Three quick wooden knocks — the ringside "ten seconds" clapper.
    static func clap(volume: Float) -> AVAudioPlayer? {
        let knock = 0.05, gap = 0.30, knocks = 3
        let total = Int(sampleRate * (Double(knocks) * knock + Double(knocks - 1) * gap))
        var out = [Double](repeating: 0, count: total)
        var rng = SystemRandomNumberGenerator()

        for k in 0..<knocks {
            let start = Int(Double(k) * (knock + gap) * sampleRate)
            let n = Int(knock * sampleRate)
            for i in 0..<n {
                let t = Double(i) / sampleRate
                let env = exp(-t / 0.013)
                let thock = sin(2 * .pi * 190 * t)
                let noise = Double(Int16.random(in: .min ... .max, using: &rng)) / 32_768.0
                out[start + i] += (thock * 0.7 + noise * 0.5) * env
            }
        }
        return player(out, volume: volume)
    }

    // MARK: - Rendering

    private static func player(_ samples: [Double], volume: Float) -> AVAudioPlayer? {
        let pcm = samples.map { Int16(max(-1, min(1, $0)) * 30_000) }
        guard let data = wav(pcm), let p = try? AVAudioPlayer(data: data) else { return nil }
        p.volume = volume
        p.prepareToPlay()
        return p
    }

    private static func wav(_ samples: [Int16]) -> Data? {
        guard !samples.isEmpty else { return nil }
        let rate = Int(sampleRate)
        let dataSize = samples.count * 2
        var d = Data()
        func str(_ s: String) { d.append(s.data(using: .ascii)!) }
        func u32(_ v: Int) { withUnsafeBytes(of: UInt32(v).littleEndian) { d.append(contentsOf: $0) } }
        func u16(_ v: Int) { withUnsafeBytes(of: UInt16(v).littleEndian) { d.append(contentsOf: $0) } }

        str("RIFF"); u32(36 + dataSize); str("WAVE")
        str("fmt "); u32(16); u16(1); u16(1)              // PCM, mono
        u32(rate); u32(rate * 2); u16(2); u16(16)
        str("data"); u32(dataSize)
        samples.withUnsafeBufferPointer { d.append(Data(buffer: $0)) }
        return d
    }
}
