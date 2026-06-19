import AppKit

class SoundManager {
    static let shared = SoundManager()

    private var cache: [String: NSSound] = [:]

    enum SoundStyle: String, CaseIterable {
        case keyClick = "keyClick"
        case soft = "soft"
        case mechanical = "mechanical"
        case glass = "glass"
        case minimal = "minimal"
        case bottle = "bottle"

        var displayName: String {
            switch self {
            case .keyClick: return "Key Click"
            case .soft: return "Soft"
            case .mechanical: return "Mechanical"
            case .glass: return "Glass"
            case .minimal: return "Minimal"
            case .bottle: return "Bottle"
            }
        }

        var spec: (frequencies: [Double], duration: Double, volume: Double) {
            switch self {
            case .keyClick: return ([1200, 1800], 0.03, 0.35)
            case .soft: return ([800], 0.02, 0.30)
            case .mechanical: return ([2000, 2500], 0.025, 0.35)
            case .glass: return ([3000, 4200], 0.03, 0.30)
            case .minimal: return ([1400], 0.015, 0.25)
            case .bottle: return ([600, 900], 0.04, 0.35)
            }
        }
    }

    private init() {
        for style in SoundStyle.allCases {
            if let s = generateSound(frequencies: style.spec.frequencies, duration: style.spec.duration, volume: style.spec.volume, name: "keyloom_\(style.rawValue)") {
                cache[style.rawValue] = s
            }
        }
        if let paste = generateSound(frequencies: [800, 1200], duration: 0.08, volume: 0.25, name: "keyloom_clipboard_paste") {
            cache["clipboard_paste"] = paste
        }
        if let pin = generateSound(frequencies: [1200, 1600], duration: 0.06, volume: 0.25, name: "keyloom_clipboard_pin") {
            cache["clipboard_pin"] = pin
        }
        if let del = generateSound(frequencies: [400, 200], duration: 0.08, volume: 0.25, name: "keyloom_clipboard_delete") {
            cache["clipboard_delete"] = del
        }
    }

    private func generateSound(frequencies: [Double], duration: Double, volume: Double, name: String) -> NSSound? {
        let sampleRate: Double = 44100
        let numSamples = Int(sampleRate * duration)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).wav")
        if FileManager.default.fileExists(atPath: tempURL.path) { return NSSound(contentsOf: tempURL, byReference: false) }

        var samples = [Int16](repeating: 0, count: numSamples)
        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * (4.0 / duration))
            var sample: Double = 0
            for f in frequencies {
                sample += sin(2.0 * .pi * f * t)
            }
            sample /= Double(frequencies.count)
            samples[i] = Int16(clamping: Int(sample * envelope * volume * Double(Int16.max)))
        }

        var header = Data()
        let bytesPerSample = 2
        let numChannels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let sampleRateU32 = UInt32(sampleRate)
        let byteRate = UInt32(sampleRate * Double(bytesPerSample))
        let blockAlign = UInt16(bytesPerSample)
        let dataSize = Int32(numSamples * bytesPerSample)

        header.append(contentsOf: "RIFF".utf8)
        var riffSize = UInt32(36 + dataSize).littleEndian
        header.append(Data(bytes: &riffSize, count: 4))
        header.append(contentsOf: "WAVE".utf8)
        header.append(contentsOf: "fmt ".utf8)
        var fmtSize = UInt32(16).littleEndian
        header.append(Data(bytes: &fmtSize, count: 4))
        var audioFormat = UInt16(1).littleEndian
        header.append(Data(bytes: &audioFormat, count: 2))
        var channels = numChannels.littleEndian
        header.append(Data(bytes: &channels, count: 2))
        var srate = sampleRateU32.littleEndian
        header.append(Data(bytes: &srate, count: 4))
        var bRate = byteRate.littleEndian
        header.append(Data(bytes: &bRate, count: 4))
        var bAlign = blockAlign.littleEndian
        header.append(Data(bytes: &bAlign, count: 2))
        var bps = UInt16(bitsPerSample).littleEndian
        header.append(Data(bytes: &bps, count: 2))
        header.append(contentsOf: "data".utf8)
        var dSize = dataSize.littleEndian
        header.append(Data(bytes: &dSize, count: 4))

        let wavData = header + Data(bytes: &samples, count: Int(dataSize))
        try? wavData.write(to: tempURL)
        return NSSound(contentsOf: tempURL, byReference: false)
    }

    func playKeyPress() {
        guard KeyboardSettings.shared.soundEnabled else { return }
        play(KeyboardSettings.shared.soundStyle)
    }

    func playClipboard() { playIfEnabled("clipboard_paste") }
    func playClipboardPin() { playIfEnabled("clipboard_pin") }
    func playClipboardDelete() { playIfEnabled("clipboard_delete") }

    func previewStyle(_ style: SoundStyle) {
        play(style.rawValue)
    }

    private func playIfEnabled(_ name: String) {
        guard KeyboardSettings.shared.soundEnabled else { return }
        play(name)
    }

    private func play(_ name: String) {
        guard let sound = cache[name] else { return }
        sound.volume = KeyboardSettings.shared.soundVolume
        sound.currentTime = 0
        sound.play()
    }
}
