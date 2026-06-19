import SwiftUI

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
                clipboardTab.tag("clipboard")
                    .tabItem { Label("Clipboard", systemImage: "clipboard") }
                    .help("Clipboard history settings")
                soundsTab.tag("sounds")
                    .tabItem { Label("Sounds", systemImage: "speaker.wave.2") }
                    .help("UI sounds and audio feedback")
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
        .frame(width: 560, height: 480)
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

    var clipboardTab: some View {
        Form {
            Section(header: Text("Monitoring"), footer: Text("When disabled, new clipboard items won't be captured automatically.")) {
                Toggle(isOn: Binding(
                    get: { settings.clipboardMonitorEnabled },
                    set: {
                        settings.clipboardMonitorEnabled = $0
                        if $0 {
                            ClipboardManager.shared.updateMonitoring()
                        } else {
                            ClipboardManager.shared.updateMonitoring()
                        }
                    }
                )) {
                    Label("Auto-Monitor Clipboard", systemImage: "eye")
                }
                .help("Automatically watch for new clipboard items")
            }
            Section(header: Text("Storage"), footer: Text("Oldest items are evicted first when limit is reached.")) {
                HStack {
                    Label("Max History", systemImage: "number")
                    Spacer()
                    Picker("", selection: $settings.clipboardMaxItems) {
                        Text("100").tag(100)
                        Text("200").tag(200)
                        Text("500").tag(500)
                        Text("1000").tag(1000)
                    }
                    .frame(width: 100)
                }
                .help("Maximum number of clipboard items to store")
                HStack {
                    Label("Current Items", systemImage: "tray.full")
                    Spacer()
                    Text("\(ClipboardManager.shared.items.count) / \(settings.clipboardMaxItems)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Button(action: { ClipboardManager.shared.clear() }) {
                    Label("Clear History", systemImage: "trash")
                }
                .help("Delete all clipboard history")
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 4)
    }

    var soundsTab: some View {
        Form {
            Section(header: Text("Audio"), footer: Text("Sounds play during keyboard and clipboard actions.")) {
                Toggle(isOn: $settings.soundEnabled) {
                    Label("Enable Sounds", systemImage: "speaker.wave.2.fill")
                }
                .help("Toggle all UI sounds on or off")
                if settings.soundEnabled {
                    HStack {
                        Label("Volume", systemImage: "speaker.wave.3")
                        Spacer()
                        Slider(value: $settings.soundVolume, in: 0...1, step: 0.05)
                            .frame(width: 150)
                        Text("\(Int(settings.soundVolume * 100))%")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                    .help("Sound playback volume")
                    HStack {
                        Label("Key Sound", systemImage: "keyboard")
                        Spacer()
                        Picker("", selection: $settings.soundStyle) {
                            ForEach(SoundManager.SoundStyle.allCases, id: \.rawValue) { style in
                                Text(style.displayName).tag(style.rawValue)
                            }
                        }
                        .frame(width: 100)
                        Button(action: {
                            if let style = SoundManager.SoundStyle(rawValue: settings.soundStyle) {
                                SoundManager.shared.previewStyle(style)
                            }
                        }) {
                            Image(systemName: "play.circle")
                        }
                        .buttonStyle(.plain)
                        .help("Preview selected sound")
                    }
                    .help("Choose the sound played when tapping a key")
                }
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 4)
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
        contentRect: NSRect(x: 0, y: 0, width: 560, height: 480),
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
