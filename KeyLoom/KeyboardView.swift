import SwiftUI
import AppKit
import Carbon.HIToolbox
import ServiceManagement

// MARK: - Keystroke Sender
struct KeystrokeSender {
    static let shared = KeystrokeSender()

    func paste(_ text: String) {
        FocusManager.shared.restore()

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let src = CGEventSource(stateID: .combinedSessionState)
            let vKeyCode: CGKeyCode = 9 // V
            let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true)
            let cmdUp   = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false)
            cmdDown?.flags = .maskCommand
            cmdUp?.flags   = .maskCommand
            cmdDown?.post(tap: .cghidEventTap)
            cmdUp?.post(tap: .cghidEventTap)
        }
    }

    func sendBackspace() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 51, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: src, virtualKey: 51, keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    func sendTab() { paste("\t") }
    func sendReturn() { paste("\n") }
}

// MARK: - Physical Keyboard Shift Monitor
class PhysicalShiftMonitor: ObservableObject {
    static let shared = PhysicalShiftMonitor()
    @Published var isPhysicalShiftDown = false
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        let eventMask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)
        var selfRef = Unmanaged.passUnretained(self).toOpaque()

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { _, _, event, ref -> Unmanaged<CGEvent>? in
                guard let ref = ref else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<PhysicalShiftMonitor>.fromOpaque(ref).takeUnretainedValue()
                let flags = event.flags
                let isShift = flags.contains(.maskShift)
                DispatchQueue.main.async {
                    monitor.isPhysicalShiftDown = isShift
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: &selfRef
        ) else { return }

        self.eventTap = eventTap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    deinit {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
        }
    }
}

// MARK: - Key Usage Tracker
class KeyUsageTracker: ObservableObject {
    static let shared = KeyUsageTracker()
    @Published var usageCounts: [String: Int] = [:]

    private init() {
        if let saved = UserDefaults.standard.dictionary(forKey: "keyUsageCounts") as? [String: Int] {
            usageCounts = saved
        }
    }

    func recordUse(_ key: String) {
        usageCounts[key, default: 0] += 1
        UserDefaults.standard.set(usageCounts, forKey: "keyUsageCounts")
    }

    func topKeys(_ count: Int) -> [String] {
        let allKeys = KeyboardSettings.allCharacterKeys
        let sorted = allKeys.sorted { (usageCounts[$0] ?? 0) > (usageCounts[$1] ?? 0) }
        return Array(sorted.prefix(count))
    }
}

// MARK: - Keyboard Settings
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

// MARK: - Settings Window
var settingsWindow: NSWindow?

struct SettingsView: View {
    @ObservedObject private var settings = KeyboardSettings.shared
    @State private var selectedTab = "layout"
    @State private var brokenKeysInput: String = ""

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                layoutTab.tag("layout")
                    .tabItem { Label("Layout", systemImage: "rectangle.3.group") }
                    .help("Key sizes, spacing, and keyboard width")
                appearanceTab.tag("appearance")
                    .tabItem { Label("Style", systemImage: "paintbrush") }
                    .help("Colors, shadows, fonts, and visual effects")
                behaviorTab.tag("behavior")
                    .tabItem { Label("Behavior", systemImage: "hand.tap") }
                    .help("Key visibility, quick keys, and broken keys")
            }
            .tabViewStyle(.automatic)

            Divider()

            HStack {
                Button(action: { settings.resetToDefaults() }) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .help("Restore all settings to defaults")
                Spacer()
                Button(action: { closeSettings() }) {
                    Text("Done")
                        .frame(minWidth: 60)
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(width: 460, height: 420)
    }

    var layoutTab: some View {
        Form {
            Section(header: Text("Dimensions"), footer: Text("Keyboard width auto-adjusts the overall panel size.")) {
                settingRow("Key Height", icon: "rectangle", value: settings.keySize, range: 24...40, step: 2, tip: "Height of each key in points") {
                    settings.keySize = $0
                }
                settingRow("Keyboard Width", icon: "arrow.left.and.right", value: settings.keyboardWidth, range: 400...600, step: 10, tip: "Total width of the keyboard") {
                    settings.keyboardWidth = $0
                }
                settingRow("Key Spacing", icon: "arrow.up.arrow.down", value: settings.keySpacing, range: 2...8, step: 1, tip: "Gap between adjacent keys") {
                    settings.keySpacing = $0
                }
                settingRow("Corner Radius", icon: "rectangle.roundedtop", value: settings.keyCornerRadius, range: 0...12, step: 1, tip: "Roundness of key corners") {
                    settings.keyCornerRadius = $0
                }
                settingRow("Font Size", icon: "textformat.size", value: settings.fontSize, range: 10...18, step: 1, tip: "Size of key label text") {
                    settings.fontSize = $0
                }
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 4)
    }

    var appearanceTab: some View {
        Form {
            Section(header: Text("Panel"), footer: Text("Controls the outer container shape.")) {
                settingRow("Panel Radius", icon: "rectangle.roundedtop", value: settings.panelCornerRadius, range: 12...32, step: 2, tip: "Corner radius of the floating panel") {
                    settings.panelCornerRadius = $0
                }
            }
            Section(header: Text("Keys"), footer: Text("Font affects all key labels.")) {
                HStack {
                    Label("Key Opacity", systemImage: "circle.lefthalf.filled")
                    Spacer()
                    Slider(value: $settings.keyOpacity, in: 0.1...0.8, step: 0.05)
                        .frame(width: 150)
                    Text("\(Int(settings.keyOpacity * 100))%")
                        .monospacedDigit()
                        .frame(width: 40)
                }
                .help("Transparency of key backgrounds")
                Toggle(isOn: $settings.showKeyShadow) {
                    Label("Key Shadows", systemImage: "shadow")
                }
                .help("Drop shadow beneath each key")
                HStack {
                    Label("Font", systemImage: "textformat")
                    Spacer()
                    Picker("", selection: $settings.fontFamily) {
                        Text("Rounded").tag("rounded")
                        Text("System").tag("system")
                        Text("Mono").tag("mono")
                        Text("Georgia").tag("georgia")
                        Text("Courier").tag("courier")
                        Text("Zapfino").tag("zapfino")
                        Text("Papyrus").tag("papyrus")
                        Text("Marker Felt").tag("markerfelt")
                    }
                    .frame(width: 120)
                }
            }
            Section(header: Text("Neomorphism"), footer: Text("Higher intensity creates a more pronounced 3D bevel effect.")) {
                Toggle(isOn: $settings.neomorphismEnabled) {
                    Label("Enable Neomorphism", systemImage: "circle.hexagongrid.fill")
                }
                .help("Adds raised 3D appearance with light/shadow edges")
                if settings.neomorphismEnabled {
                    HStack {
                        Label("Intensity", systemImage: "slider.horizontal.3")
                        Spacer()
                        Slider(value: $settings.neomorphismIntensity, in: 0.2...1.0, step: 0.05)
                            .frame(width: 150)
                        Text("\(Int(settings.neomorphismIntensity * 100))%")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                    .help("Strength of the raised bevel effect")
                }
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 4)
    }

    var behaviorTab: some View {
        Form {
            Section(header: Text("Key Visibility"), footer: Text("Shift remains functional even when decorative keys are hidden.")) {
                Toggle(isOn: $settings.showDecorativeKeys) {
                    Label("Show All Keys", systemImage: "keyboard")
                }
                .help("Show or hide caps, tab, backspace, and enter keys")
                if !settings.showDecorativeKeys {
                    Label("Shift stays active for physical keyboard", systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Section(header: Text("Startup"), footer: Text("Which panel shows when KeyLoom launches.")) {
                HStack {
                    Label("Start Mode", systemImage: "power")
                    Spacer()
                    Picker("", selection: $settings.startMode) {
                        Text("Expanded").tag("expanded")
                        Text("Quick Keys").tag("collapsed")
                    }
                    .frame(width: 120)
                }
                .help("Choose which keyboard view appears on launch")
                Toggle(isOn: $settings.launchAtLogin) {
                    Label("Launch at Login", systemImage: "power.circle")
                }
                .help("Automatically start KeyLoom when you log in")
            }
            Section(header: Text("Quick Keys Panel"), footer: Text("Opens as a separate small panel sized to your keys.")) {
                Toggle(isOn: $settings.useCustomCollapsedKeys) {
                    Label("Use Custom Keys", systemImage: "hand.raised.fingers.spread")
                }
                .help("Pick 2-5 keys instead of auto-selecting by usage")
                HStack {
                    Label("Number of Keys", systemImage: "number")
                    Spacer()
                    Picker("", selection: $settings.collapsedKeyCount) {
                        Text("2").tag(2)
                        Text("3").tag(3)
                        Text("4").tag(4)
                        Text("5").tag(5)
                    }
                    .frame(width: 80)
                }
                .help("How many keys to show in quick keys (2-5)")
            }
            if settings.useCustomCollapsedKeys {
                Section(header: Text("Select \(settings.collapsedKeyCount) Keys")) {
                    CollapsedKeyPicker(selectedKeys: $settings.collapsedKeys, maxCount: settings.collapsedKeyCount)
                    HStack {
                        Label("Active:", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if settings.collapsedKeys.count >= 2 {
                            Text(Array(settings.collapsedKeys.prefix(settings.collapsedKeyCount)).joined(separator: "  "))
                                .font(.caption)
                                .monospaced()
                        } else {
                            Text("Select at least 2 keys")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            Section(header: Text("Broken Keys"), footer: Text("Mark keys that don't paste correctly. They'll be highlighted on the keyboard.")) {
                Toggle(isOn: $settings.showBrokenKeyHighlight) {
                    Label("Highlight Broken Keys", systemImage: "exclamationmark.triangle")
                }
                .help("Marks non-functional keys with a colored background")
                if settings.showBrokenKeyHighlight {
                    HStack {
                        Label("Color", systemImage: "paintpalette")
                        Spacer()
                        Picker("", selection: $settings.brokenKeyColor) {
                            Text("Blue").tag("blue")
                            Text("Red").tag("red")
                            Text("Orange").tag("orange")
                            Text("Purple").tag("purple")
                        }
                        .frame(width: 120)
                    }
                }
                HStack {
                    TextField("e.g. t, T, 5, %", text: $brokenKeysInput)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { saveBrokenKeys() }
                    Button(action: { saveBrokenKeys() }) {
                        Text("Apply")
                    }
                }
                Text("Current: \(settings.brokenKeys.sorted().joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                BrokenKeyPicker(selectedKeys: $settings.brokenKeys)
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 4)
        .onAppear {
            brokenKeysInput = settings.brokenKeys.sorted().joined(separator: ", ")
        }
    }

    var selectedKeysFooter: some View {
        Group {
            if settings.collapsedKeys.count < 2 {
                Text("Select at least 2 keys (\(settings.collapsedKeys.count)/\(settings.collapsedKeyCount))")
                    .foregroundColor(.red)
            } else if settings.collapsedKeys.count < settings.collapsedKeyCount {
                Text("Select \(settings.collapsedKeyCount) keys (\(settings.collapsedKeys.count)/\(settings.collapsedKeyCount))")
                    .foregroundColor(.orange)
            } else {
                Text("\(settings.collapsedKeyCount) keys selected")
                    .foregroundColor(.green)
            }
        }
    }

    func saveBrokenKeys() {
        let keys = brokenKeysInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        settings.brokenKeys = Set(keys)
    }

    func settingRow(_ label: String, icon: String, value: CGFloat, range: ClosedRange<CGFloat>, step: CGFloat, tip: String, onChange: @escaping (CGFloat) -> Void) -> some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            Slider(value: Binding(
                get: { value },
                set: { onChange($0) }
            ), in: range, step: step)
                .frame(width: 150)
                .help(tip)
            Text("\(Int(value))pt")
                .monospacedDigit()
                .frame(width: 40)
        }
    }

    func closeSettings() {
        settingsWindow?.orderOut(nil)
        settingsWindow = nil
    }
}

// MARK: - Broken Key Picker
struct BrokenKeyPicker: View {
    @Binding var selectedKeys: Set<String>
    let allKeys = KeyboardSettings.allCharacterKeys
    let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(allKeys, id: \.self) { key in
                Button(action: { toggleKey(key) }) {
                    Text(key)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .frame(width: 32, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(selectedKeys.contains(key) ? Color.red : Color(NSColor.controlColor).opacity(0.3))
                        )
                        .foregroundColor(selectedKeys.contains(key) ? .white : .primary)
                }
                .buttonStyle(.plain)
                .help(selectedKeys.contains(key) ? "Mark \(key) as working" : "Mark \(key) as broken")
            }
        }
    }

    func toggleKey(_ key: String) {
        if selectedKeys.contains(key) {
            selectedKeys.remove(key)
        } else {
            selectedKeys.insert(key)
        }
    }
}

// MARK: - Collapsed Key Picker
struct CollapsedKeyPicker: View {
    @Binding var selectedKeys: [String]
    let maxCount: Int
    let allKeys = KeyboardSettings.allCharacterKeys
    let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(allKeys, id: \.self) { key in
                Button(action: { toggleKey(key) }) {
                    Text(key)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .frame(width: 32, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(selectedKeys.contains(key) ? Color.accentColor : Color(NSColor.controlColor).opacity(0.3))
                        )
                        .foregroundColor(selectedKeys.contains(key) ? .white : .primary)
                }
                .buttonStyle(.plain)
                .help(selectedKeys.contains(key) ? "Remove \(key) from quick keys" : "Add \(key) to quick keys")
            }
        }
    }

    func toggleKey(_ key: String) {
        if selectedKeys.contains(key) {
            selectedKeys.removeAll { $0 == key }
        } else if selectedKeys.count < maxCount {
            selectedKeys.append(key)
        }
    }
}

func openSettings() {
    if let existing = settingsWindow {
        existing.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return
    }

    let settingsView = SettingsView()
    let hostingView = NSHostingView(rootView: settingsView)

    let window = NSPanel(
        contentRect: NSRect(x: 0, y: 0, width: 460, height: 420),
        styleMask: [.titled, .closable, .nonactivatingPanel],
        backing: .buffered,
        defer: false
    )
    window.contentView = hostingView
    window.title = "KeyLoom Settings"
    window.level = .floating
    window.center()
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    settingsWindow = window
}

// MARK: - Keyboard State (shared between panels)
class KeyboardState: ObservableObject {
    static let shared = KeyboardState()
    @Published var isShifted: Bool = false
    @Published var isCaps: Bool = false

    private init() {
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            DispatchQueue.main.async {
                self?.isShifted = event.modifierFlags.contains(.shift)
            }
        }
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            DispatchQueue.main.async {
                self?.isShifted = event.modifierFlags.contains(.shift)
            }
            return event
        }
    }
}

// MARK: - Full Keyboard View
struct KeyboardView: View {
    @ObservedObject private var settings = KeyboardSettings.shared
    @ObservedObject private var keyboardState = KeyboardState.shared
    @ObservedObject private var usageTracker = KeyUsageTracker.shared

    private let sender = KeystrokeSender.shared

    var brokenKeyColor: Color {
        switch settings.brokenKeyColor {
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        default: return .blue
        }
    }

    var resolvedFont: Font.Design {
        switch settings.fontFamily {
        case "system": return .default
        case "mono": return .monospaced
        case "georgia": return .serif
        case "courier": return .monospaced
        case "zapfino": return .default
        case "papyrus": return .default
        case "markerfelt": return .default
        default: return .rounded
        }
    }

    var customFontName: String? {
        switch settings.fontFamily {
        case "georgia": return "Georgia"
        case "courier": return "Courier"
        case "zapfino": return "Zapfino"
        case "papyrus": return "Papyrus"
        case "markerfelt": return "Marker Felt"
        default: return nil
        }
    }

    func keyFont(size: CGFloat) -> Font {
        if let name = customFontName {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: .medium, design: resolvedFont)
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(width: 0, height: 0)
                .focusable(false)
            pillHandle
            VStack(spacing: 10) {
                fullKeyboard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: settings.panelCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 8)
    }

    var pillHandle: some View {
        HStack {
            Image(systemName: "keyboard")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Text("KeyLoom")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
            Button(action: { showHelp() }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Open help guide")
            Button(action: { openCollapsedPanel() }) {
                Image(systemName: "rectangle.compress.vertical")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Open quick keys panel")
            Button(action: { openSettings() }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Open settings")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    var fullKeyboard: some View {
        let visibleRows = settings.showDecorativeKeys ? keyRows : filteredKeyRows
        return VStack(spacing: settings.keySpacing) {
            ForEach(visibleRows, id: \.self) { row in
                let widths = calculateWidths(for: row)
                HStack(spacing: settings.keySpacing) {
                    ForEach(Array(row.enumerated()), id: \.element.id) { index, key in
                        let isDecorative = settings.showDecorativeKeys && (key.type == .backspace || key.type == .tab || key.type == .caps || key.type == .enter)
                        KeyButton(
                            key: key,
                            width: widths[index],
                            height: settings.keySize,
                            cornerRadius: settings.keyCornerRadius,
                            isShifted: keyboardState.isShifted,
                            isCaps: keyboardState.isCaps,
                            isBroken: settings.brokenKeys.contains(key.label),
                            isDecorative: isDecorative,
                            showHighlight: settings.showBrokenKeyHighlight,
                            highlightColor: brokenKeyColor,
                            showShadow: settings.showKeyShadow,
                            opacity: settings.keyOpacity,
                            fontDesign: resolvedFont,
                            customFontName: customFontName,
                            neomorphism: settings.neomorphismEnabled,
                            neoIntensity: settings.neomorphismIntensity,
                            action: { if !isDecorative { handleKey(key) } }
                        )
                    }
                }
            }
        }
    }

    var filteredKeyRows: [[Key]] {
        keyRows.map { row in
            row.filter { key in
                switch key.type {
                case .backspace, .tab, .caps, .enter:
                    return false
                default:
                    return true
                }
            }
        }.filter { !$0.isEmpty }
    }

    func calculateWidths(for row: [Key]) -> [CGFloat] {
        let numKeys = row.count
        let totalSpacing = CGFloat(numKeys - 1) * settings.keySpacing

        if row.count == 1 && row[0].type == .space {
            return [settings.keyboardWidth]
        }

        let totalUnits = row.map(\.relativeWidth).reduce(0, +)
        let unitWidth = (settings.keyboardWidth - totalSpacing) / totalUnits
        return row.map { $0.relativeWidth * unitWidth }
    }

    func handleKey(_ key: Key) {
        usageTracker.recordUse(key.label)
        switch key.type {
        case .character:
            let useShift = keyboardState.isShifted || (keyboardState.isCaps && key.label.count == 1 && key.label.first?.isLetter == true)
            let char: String = useShift ? (key.shiftLabel ?? key.label.uppercased()) : key.label
            sender.paste(char)
        case .space:
            sender.paste(" ")
        case .enter:
            sender.sendReturn()
        case .tab:
            sender.sendTab()
        case .backspace:
            sender.sendBackspace()
        case .shift:
            keyboardState.isShifted.toggle()
        case .caps:
            keyboardState.isCaps.toggle()
            keyboardState.isShifted = false
        }
    }
}

// MARK: - Collapsed Keyboard View
struct CollapsedKeyboardView: View {
    @ObservedObject private var settings = KeyboardSettings.shared
    @ObservedObject private var keyboardState = KeyboardState.shared
    @ObservedObject private var usageTracker = KeyUsageTracker.shared

    private let sender = KeystrokeSender.shared

    var brokenKeyColor: Color {
        switch settings.brokenKeyColor {
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        default: return .blue
        }
    }

    var resolvedFont: Font.Design {
        switch settings.fontFamily {
        case "system": return .default
        case "mono": return .monospaced
        case "georgia": return .serif
        case "courier": return .monospaced
        case "zapfino": return .default
        case "papyrus": return .default
        case "markerfelt": return .default
        default: return .rounded
        }
    }

    var customFontName: String? {
        switch settings.fontFamily {
        case "georgia": return "Georgia"
        case "courier": return "Courier"
        case "zapfino": return "Zapfino"
        case "papyrus": return "Papyrus"
        case "markerfelt": return "Marker Felt"
        default: return nil
        }
    }

    func keyFont(size: CGFloat) -> Font {
        if let name = customFontName {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: .medium, design: resolvedFont)
    }

    @State private var isHovering = false
    @State private var hoverWorkItem: DispatchWorkItem?
    @State private var mouseLocation: NSPoint?

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(width: 0, height: 0)
                .focusable(false)
            if isHovering {
                pillHandle
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            HStack(spacing: settings.keySpacing) {
                ForEach(collapsedKeys, id: \.self) { keyLabel in
                    let key = findKey(for: keyLabel)
                    let k = key ?? Key(keyLabel)
                    KeyButton(
                        key: k,
                        width: settings.keySize,
                        height: settings.keySize,
                        cornerRadius: settings.keyCornerRadius,
                        isShifted: keyboardState.isShifted,
                        isCaps: keyboardState.isCaps,
                        isBroken: settings.brokenKeys.contains(k.label),
                        isDecorative: false,
                        showHighlight: settings.showBrokenKeyHighlight,
                        highlightColor: brokenKeyColor,
                        showShadow: settings.showKeyShadow,
                        opacity: settings.keyOpacity,
                        fontDesign: resolvedFont,
                        customFontName: customFontName,
                        neomorphism: settings.neomorphismEnabled,
                        neoIntensity: settings.neomorphismIntensity,
                        action: { handleKey(k) }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .padding(.top, isHovering ? 0 : 8)
        }
        .onHover { hovering in
            if hovering {
                let currentMouse = NSEvent.mouseLocation
                if let lastMouse = mouseLocation {
                    let distance = hypot(currentMouse.x - lastMouse.x, currentMouse.y - lastMouse.y)
                    if distance > 5 {
                        mouseLocation = currentMouse
                        return
                    }
                }
                mouseLocation = currentMouse
                guard hoverWorkItem == nil else { return }
                let workItem = DispatchWorkItem { [self] in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovering = true
                    }
                }
                hoverWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
            } else {
                hoverWorkItem?.cancel()
                hoverWorkItem = nil
                mouseLocation = nil
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = false
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: settings.panelCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 8)
    }

    var collapsedKeys: [String] {
        settings.effectiveCollapsedKeys()
    }

    var pillHandle: some View {
        HStack {
            Image(systemName: "bolt.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text("Quick Keys")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
            Button(action: { closeCollapsedPanel() }) {
                Image(systemName: "rectangle.expand.vertical")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Expand to full keyboard")
            Button(action: { closeCollapsedPanel() }) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Close quick keys")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    func findKey(for label: String) -> Key? {
        for row in keyRows {
            for key in row {
                if key.label == label { return key }
            }
        }
        return nil
    }

    func handleKey(_ key: Key) {
        usageTracker.recordUse(key.label)
        switch key.type {
        case .character:
            let useShift = keyboardState.isShifted || (keyboardState.isCaps && key.label.count == 1 && key.label.first?.isLetter == true)
            let char: String = useShift ? (key.shiftLabel ?? key.label.uppercased()) : key.label
            sender.paste(char)
        case .space:
            sender.paste(" ")
        case .enter:
            sender.sendReturn()
        case .tab:
            sender.sendTab()
        case .backspace:
            sender.sendBackspace()
        case .shift:
            keyboardState.isShifted.toggle()
        case .caps:
            keyboardState.isCaps.toggle()
            keyboardState.isShifted = false
        }
    }
}

// MARK: - Collapsed Panel Window
var collapsedWindow: NSWindow?
var mainWindow: NSWindow?

func openCollapsedPanel() {
    if let existing = collapsedWindow {
        existing.makeKeyAndOrderFront(nil)
        return
    }

    let settings = KeyboardSettings.shared
    let keys = settings.effectiveCollapsedKeys()
    let keyCount = keys.count
    let panelWidth = CGFloat(keyCount) * settings.keySize + CGFloat(keyCount - 1) * settings.keySpacing + 32
    let panelHeight = settings.keySize + 70

    let panel = NSPanel(
        contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
        styleMask: [.borderless, .nonactivatingPanel],
        backing: .buffered,
        defer: false
    )
    panel.isFloatingPanel = true
    panel.level = .floating
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    panel.isMovableByWindowBackground = true
    panel.backgroundColor = .clear
    panel.isOpaque = false
    panel.hasShadow = true

    let hostingView = NSHostingView(rootView: CollapsedKeyboardView())
    panel.contentView = hostingView

    // Restore saved position or use default
    if let savedFrame = UserDefaults.standard.dictionary(forKey: "collapsedPanelFrame") as? [String: CGFloat],
       let x = savedFrame["x"], let y = savedFrame["y"] {
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    } else if let screen = NSScreen.main {
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - panelWidth - 20
        let y = screenFrame.maxY - panelHeight - 20
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // Save position when moved
    NotificationCenter.default.addObserver(
        forName: NSWindow.didMoveNotification,
        object: panel,
        queue: .main
    ) { _ in
        let origin = panel.frame.origin
        UserDefaults.standard.set(["x": origin.x, "y": origin.y], forKey: "collapsedPanelFrame")
    }

    panel.orderFront(nil)
    collapsedWindow = panel
    mainWindow?.orderOut(nil)
}

func closeCollapsedPanel() {
    collapsedWindow?.orderOut(nil)
    collapsedWindow = nil
    mainWindow?.orderFront(nil)
}

// MARK: - Key Model
struct Key: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let shiftLabel: String?
    let type: KeyType
    let relativeWidth: CGFloat

    init(_ label: String, shift: String? = nil, type: KeyType = .character, relativeWidth: CGFloat = 1) {
        self.label = label
        self.shiftLabel = shift
        self.type = type
        self.relativeWidth = relativeWidth
    }
}

enum KeyType { case character, space, enter, backspace, shift, caps, tab }

// MARK: - Key Rows (relative widths: 1 = regular key)
let keyRows: [[Key]] = [
    [
        Key("`",shift: "~"), Key("1",shift: "!"), Key("2",shift: "@"), Key("3",shift: "#"), Key("4",shift: "$"),
        Key("5",shift: "%"), Key("6",shift: "^"), Key("7",shift: "&"), Key("8",shift: "*"), Key("9",shift: "("),
        Key("0",shift: ")"), Key("-",shift: "_"), Key("=",shift: "+"),
        Key("⌫", type: .backspace, relativeWidth: 1.5)
    ],
    [
        Key("⇥", type: .tab, relativeWidth: 1.5),
        Key("q",shift: "Q"), Key("w",shift: "W"), Key("e",shift: "E"), Key("r",shift: "R"), Key("t",shift: "T"),
        Key("y",shift: "Y"), Key("u",shift: "U"), Key("i",shift: "I"), Key("o",shift: "O"), Key("p",shift: "P"),
        Key("[",shift: "{"), Key("]",shift: "}"), Key("\\",shift: "|")
    ],
    [
        Key("⇪", type: .caps, relativeWidth: 1.8),
        Key("a",shift: "A"), Key("s",shift: "S"), Key("d",shift: "D"), Key("f",shift: "F"), Key("g",shift: "G"),
        Key("h",shift: "H"), Key("j",shift: "J"), Key("k",shift: "K"), Key("l",shift: "L"),
        Key(";",shift: ":"), Key("'",shift: "\""),
        Key("↩", type: .enter, relativeWidth: 1.8)
    ],
    [
        Key("⇧", type: .shift, relativeWidth: 2.3),
        Key("z",shift: "Z"), Key("x",shift: "X"), Key("c",shift: "C"), Key("v",shift: "V"), Key("b",shift: "B"),
        Key("n",shift: "N"), Key("m",shift: "M"), Key(",",shift: "<"), Key(".",shift: ">"), Key("/",shift: "?"),
        Key("⇧", type: .shift, relativeWidth: 2.3)
    ],
    [
        Key("space", type: .space)
    ]
]

// MARK: - Key Button
struct KeyButton: View {
    let key: Key
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let isShifted: Bool
    let isCaps: Bool
    let isBroken: Bool
    let isDecorative: Bool
    let showHighlight: Bool
    let highlightColor: Color
    let showShadow: Bool
    let opacity: Double
    let fontDesign: Font.Design
    let customFontName: String?
    let neomorphism: Bool
    let neoIntensity: Double
    let action: () -> Void

    @State private var isPressed = false

    var displayLabel: String {
        if key.type == .space { return "space" }
        if key.type == .shift { return "⇧" }
        if key.type == .caps { return "⇪" }
        if key.type == .tab { return "⇥" }
        if key.type == .backspace { return "⌫" }
        if key.type == .enter { return "↩" }
        let useShift = isShifted || (isCaps && key.label.count == 1 && key.label.first?.isLetter == true)
        return useShift ? (key.shiftLabel ?? key.label) : key.label
    }

    var pressScale: CGFloat {
        if key.type == .space { return 0.96 }
        let baseScale: CGFloat = 0.92
        let widthFactor = width / 40.0
        let reduction = (widthFactor - 1.0) * 0.008
        return max(baseScale - reduction, 0.90)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if neomorphism && !isPressed {
                    neomorphismBase
                }
                content
            }
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isDecorative ? Color(NSColor.controlColor).opacity(0.3) : keyBackground)
            )
            .overlay(
                neomorphism && !isPressed && !isDecorative ?
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25 * neoIntensity),
                                    Color.black.opacity(0.15 * neoIntensity)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        ) : nil
            )
            .shadow(color: (isPressed || !showShadow || isDecorative) ? .clear : .black.opacity(0.45 * neoIntensity), radius: 5, x: 0, y: 3)
            .shadow(color: (isPressed || !showShadow || !neomorphism || isDecorative) ? .clear : .white.opacity(0.35 * neoIntensity), radius: 3, x: 0, y: -2)
            .scaleEffect(isPressed ? pressScale : 1.0)
            .opacity(isDecorative ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDecorative)
        .allowsHitTesting(!isDecorative)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isDecorative { withAnimation(.easeInOut(duration: 0.08)) { isPressed = true } } }
                .onEnded   { _ in if !isDecorative { withAnimation(.easeInOut(duration: 0.12)) { isPressed = false } } }
        )
    }

    var content: some View {
        let size = key.type == .character ? KeyboardSettings.shared.fontSize : KeyboardSettings.shared.fontSize - 2
        return Text(displayLabel)
            .font(customFontName != nil ? .custom(customFontName!, size: size) : .system(size: size, weight: .medium, design: fontDesign))
            .foregroundColor(isBroken && showHighlight ? .white : .primary)
    }

    var neomorphismBase: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.12 * neoIntensity),
                        Color.clear,
                        Color.black.opacity(0.08 * neoIntensity)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    var keyBackground: Color {
        if isBroken && showHighlight { return highlightColor }
        if isPressed { return Color(NSColor.controlColor).opacity(0.6) }
        return Color(NSColor.controlColor).opacity(opacity)
    }
}
