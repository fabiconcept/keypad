import SwiftUI

var collapsedWindow: NSWindow?
var mainWindow: NSWindow?

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
                Button(action: { openClipboard() }) {
                    ZStack {
                        if settings.neomorphismEnabled {
                            RoundedRectangle(cornerRadius: settings.keyCornerRadius, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.12 * settings.neomorphismIntensity),
                                            Color.clear,
                                            Color.black.opacity(0.08 * settings.neomorphismIntensity)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        Image(systemName: "clipboard")
                            .font(.system(size: settings.fontSize - 2, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: settings.keySize, height: settings.keySize)
                    .background(
                        RoundedRectangle(cornerRadius: settings.keyCornerRadius, style: .continuous)
                            .fill(Color(NSColor.controlColor).opacity(settings.keyOpacity))
                    )
                    .overlay(
                        settings.neomorphismEnabled ?
                            RoundedRectangle(cornerRadius: settings.keyCornerRadius, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.25 * settings.neomorphismIntensity),
                                            Color.black.opacity(0.15 * settings.neomorphismIntensity)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                ) : nil
                    )
                    .shadow(color: settings.showKeyShadow ? .black.opacity(0.45 * settings.neomorphismIntensity) : .clear, radius: 5, x: 0, y: 3)
                    .shadow(color: settings.showKeyShadow && settings.neomorphismEnabled ? .white.opacity(0.35 * settings.neomorphismIntensity) : .clear, radius: 3, x: 0, y: -2)
                }
                .buttonStyle(.plain)
                .help("Open clipboard history")
            }
            .padding(.horizontal, isHovering ? 0 : 8)
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
        hoverWorkItem?.cancel()
        hoverWorkItem = nil
        withAnimation(.easeInOut(duration: 0.15)) {
            isHovering = false
        }
        usageTracker.recordUse(key.label)
        SoundManager.shared.playKeyPress()
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

    if let savedFrame = UserDefaults.standard.dictionary(forKey: "collapsedPanelFrame") as? [String: CGFloat],
       let x = savedFrame["x"], let y = savedFrame["y"] {
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    } else if let screen = NSScreen.main {
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - panelWidth - 20
        let y = screenFrame.maxY - panelHeight - 20
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

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
