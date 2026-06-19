import SwiftUI
import ServiceManagement

class KeyboardSettings: ObservableObject {
    static let shared = KeyboardSettings()

    static let allCharacterKeys: [String] = [
        "`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=",
        "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]", "\\",
        "a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'",
        "z", "x", "c", "v", "b", "n", "m", ",", ".", "/"
    ]

    @Published var keySize: CGFloat = 30 {
        didSet { UserDefaults.standard.set(keySize, forKey: "keySize") }
    }
    @Published var keyboardWidth: CGFloat = 490 {
        didSet { UserDefaults.standard.set(keyboardWidth, forKey: "keyboardWidth") }
    }
    @Published var keyCornerRadius: CGFloat = 6 {
        didSet { UserDefaults.standard.set(keyCornerRadius, forKey: "keyCornerRadius") }
    }
    @Published var keySpacing: CGFloat = 4 {
        didSet { UserDefaults.standard.set(keySpacing, forKey: "keySpacing") }
    }
    @Published var showBrokenKeyHighlight: Bool = true {
        didSet { UserDefaults.standard.set(showBrokenKeyHighlight, forKey: "showBrokenKeyHighlight") }
    }
    @Published var brokenKeyColor: String = "blue" {
        didSet { UserDefaults.standard.set(brokenKeyColor, forKey: "brokenKeyColor") }
    }
    @Published var brokenKeys: Set<String> = ["t", "T", "5", "%"] {
        didSet { UserDefaults.standard.set(Array(brokenKeys), forKey: "brokenKeys") }
    }
    @Published var keyOpacity: Double = 0.35 {
        didSet { UserDefaults.standard.set(keyOpacity, forKey: "keyOpacity") }
    }
    @Published var panelCornerRadius: CGFloat = 22 {
        didSet { UserDefaults.standard.set(panelCornerRadius, forKey: "panelCornerRadius") }
    }
    @Published var showKeyShadow: Bool = true {
        didSet { UserDefaults.standard.set(showKeyShadow, forKey: "showKeyShadow") }
    }
    @Published var fontFamily: String = "rounded" {
        didSet { UserDefaults.standard.set(fontFamily, forKey: "fontFamily") }
    }
    @Published var showDecorativeKeys: Bool = true {
        didSet { UserDefaults.standard.set(showDecorativeKeys, forKey: "showDecorativeKeys") }
    }
    @Published var neomorphismEnabled: Bool = true {
        didSet { UserDefaults.standard.set(neomorphismEnabled, forKey: "neomorphismEnabled") }
    }
    @Published var neomorphismIntensity: Double = 0.85 {
        didSet { UserDefaults.standard.set(neomorphismIntensity, forKey: "neomorphismIntensity") }
    }
    @Published var collapsedKeys: [String] = [] {
        didSet { UserDefaults.standard.set(collapsedKeys, forKey: "collapsedKeys") }
    }
    @Published var useCustomCollapsedKeys: Bool = false {
        didSet { UserDefaults.standard.set(useCustomCollapsedKeys, forKey: "useCustomCollapsedKeys") }
    }
    @Published var collapsedKeyCount: Int = 5 {
        didSet { UserDefaults.standard.set(collapsedKeyCount, forKey: "collapsedKeyCount") }
    }
    @Published var fontSize: CGFloat = 13 {
        didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") }
    }
    @Published var startMode: String = "expanded" {
        didSet { UserDefaults.standard.set(startMode, forKey: "startMode") }
    }
    @Published var launchAtLogin: Bool = false {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLoginItem()
        }
    }
    @Published var hasSeenWelcome: Bool = false {
        didSet { UserDefaults.standard.set(hasSeenWelcome, forKey: "hasSeenWelcome") }
    }
    @Published var clipboardMaxItems: Int = 500 {
        didSet { UserDefaults.standard.set(clipboardMaxItems, forKey: "clipboardMaxItems") }
    }
    @Published var clipboardMonitorEnabled: Bool = true {
        didSet { UserDefaults.standard.set(clipboardMonitorEnabled, forKey: "clipboardMonitorEnabled") }
    }
    @Published var soundEnabled: Bool = true {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    @Published var soundStyle: String = SoundManager.SoundStyle.keyClick.rawValue {
        didSet { UserDefaults.standard.set(soundStyle, forKey: "soundStyle") }
    }
    @Published var soundVolume: Float = 0.5 {
        didSet { UserDefaults.standard.set(soundVolume, forKey: "soundVolume") }
    }

    static let defaults: [String: Any] = [
        "keySize": 30,
        "keyboardWidth": 490,
        "keyCornerRadius": 6,
        "keySpacing": 4,
        "showBrokenKeyHighlight": true,
        "brokenKeyColor": "blue",
        "brokenKeys": ["t", "T", "5", "%"],
        "keyOpacity": 0.35,
        "panelCornerRadius": 22,
        "showKeyShadow": true,
        "fontFamily": "rounded",
        "showDecorativeKeys": true,
        "neomorphismEnabled": true,
        "neomorphismIntensity": 0.85,
        "collapsedKeys": [String](),
        "useCustomCollapsedKeys": false,
        "collapsedKeyCount": 5,
        "fontSize": 13,
        "startMode": "expanded",
        "launchAtLogin": false
    ]

    private init() {
        let d = UserDefaults.standard
        self.keySize = d.object(forKey: "keySize") as? CGFloat ?? 30
        self.keyboardWidth = d.object(forKey: "keyboardWidth") as? CGFloat ?? 490
        self.keyCornerRadius = d.object(forKey: "keyCornerRadius") as? CGFloat ?? 6
        self.keySpacing = d.object(forKey: "keySpacing") as? CGFloat ?? 4
        self.showBrokenKeyHighlight = d.object(forKey: "showBrokenKeyHighlight") as? Bool ?? true
        self.brokenKeyColor = d.string(forKey: "brokenKeyColor") ?? "blue"
        self.brokenKeys = Set(d.stringArray(forKey: "brokenKeys") ?? ["t", "T", "5", "%"])
        self.keyOpacity = d.object(forKey: "keyOpacity") as? Double ?? 0.35
        self.panelCornerRadius = d.object(forKey: "panelCornerRadius") as? CGFloat ?? 22
        self.showKeyShadow = d.object(forKey: "showKeyShadow") as? Bool ?? true
        self.fontFamily = d.string(forKey: "fontFamily") ?? "rounded"
        self.showDecorativeKeys = d.object(forKey: "showDecorativeKeys") as? Bool ?? true
        self.neomorphismEnabled = d.object(forKey: "neomorphismEnabled") as? Bool ?? true
        self.neomorphismIntensity = d.object(forKey: "neomorphismIntensity") as? Double ?? 0.85
        self.collapsedKeys = d.stringArray(forKey: "collapsedKeys") ?? []
        self.useCustomCollapsedKeys = d.object(forKey: "useCustomCollapsedKeys") as? Bool ?? false
        self.collapsedKeyCount = d.object(forKey: "collapsedKeyCount") as? Int ?? 5
        self.fontSize = d.object(forKey: "fontSize") as? CGFloat ?? 13
        self.startMode = d.string(forKey: "startMode") ?? "expanded"
        self.launchAtLogin = d.object(forKey: "launchAtLogin") as? Bool ?? false
        self.hasSeenWelcome = d.object(forKey: "hasSeenWelcome") as? Bool ?? false
        self.clipboardMaxItems = d.object(forKey: "clipboardMaxItems") as? Int ?? 500
        self.clipboardMonitorEnabled = d.object(forKey: "clipboardMonitorEnabled") as? Bool ?? true
        self.soundVolume = d.object(forKey: "soundVolume") as? Float ?? 0.5
        let savedStyle = d.string(forKey: "soundStyle") ?? SoundManager.SoundStyle.keyClick.rawValue
        if SoundManager.SoundStyle(rawValue: savedStyle) != nil {
            self.soundStyle = savedStyle
        } else {
            self.soundStyle = SoundManager.SoundStyle.keyClick.rawValue
            d.set(self.soundStyle, forKey: "soundStyle")
        }
    }

    func effectiveCollapsedKeys() -> [String] {
        let count = collapsedKeyCount
        if useCustomCollapsedKeys && collapsedKeys.count >= 2 {
            return Array(collapsedKeys.prefix(count))
        }
        return KeyUsageTracker.shared.topKeys(count)
    }

    func resetToDefaults() {
        let d = UserDefaults.standard
        for (key, value) in Self.defaults { d.set(value, forKey: key) }
        keySize = 30
        keyboardWidth = 490
        keyCornerRadius = 6
        keySpacing = 4
        showBrokenKeyHighlight = true
        brokenKeyColor = "blue"
        brokenKeys = ["t", "T", "5", "%"]
        keyOpacity = 0.35
        panelCornerRadius = 22
        showKeyShadow = true
        fontFamily = "rounded"
        showDecorativeKeys = true
        neomorphismEnabled = true
        neomorphismIntensity = 0.85
        collapsedKeys = []
        useCustomCollapsedKeys = false
        collapsedKeyCount = 5
        fontSize = 13
        startMode = "expanded"
        launchAtLogin = false
        clipboardMaxItems = 500
        clipboardMonitorEnabled = true
        soundEnabled = true
        soundStyle = SoundManager.SoundStyle.keyClick.rawValue
        soundVolume = 0.5
    }

    private func updateLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update login item: \(error)")
            }
        }
    }
}
