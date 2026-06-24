import SwiftUI

var collapsedWindow: NSWindow?
var mainWindow: NSWindow?
private var hoverMonitor: Any?
private var hoverWorkItem: DispatchWorkItem?
private var hoverExitWorkItem: DispatchWorkItem?

class CollapsedHoverState: ObservableObject {
    static let shared = CollapsedHoverState()
    @Published var isHovering = false
}

struct CollapsedKeyboardView: View {
    @ObservedObject private var settings = KeyboardSettings.shared
    @ObservedObject private var keyboardState = KeyboardState.shared
    @ObservedObject private var usageTracker = KeyUsageTracker.shared
    @ObservedObject private var hoverState = CollapsedHoverState.shared

    private let sender = KeystrokeSender.shared
    @State private var expandPulse = false

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

    var body: some View {
        let isHovering = hoverState.isHovering
        VStack(spacing: 0) {
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
                Button(action: { isHovering ? closeCollapsedPanel() : openClipboard() }) {
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
                        Image(systemName: isHovering ? "rectangle.expand.vertical" : "clipboard")
                            .font(.system(size: settings.fontSize - 2, weight: isHovering ? .semibold : .medium))
                            .foregroundColor(isHovering ? .indigo : .secondary)
                            .scaleEffect(isHovering && expandPulse ? 1.2 : 1.0)
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
                    .shadow(color: isHovering ? .indigo.opacity(0.5) : .clear, radius: isHovering && expandPulse ? 8 : 4, x: 0, y: 0)
                }
                .buttonStyle(.plain)
                .help(isHovering ? "Expand to full keyboard" : "Open clipboard history")
                .onChange(of: isHovering) { hovering in
                    if hovering {
                        expandPulse = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                expandPulse = false
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .padding(.top, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: settings.panelCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            settings.showPanelBorder ?
                RoundedRectangle(cornerRadius: settings.panelCornerRadius, style: .continuous)
                    .stroke(settings.resolvedBorderColor, lineWidth: settings.panelBorderWidth)
                : nil
        )
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 8)
    }

    var collapsedKeys: [String] {
        settings.effectiveCollapsedKeys()
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
        SoundManager.shared.playKeyPress(keyLabel: key.label)
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
    panel.hasShadow = false
    panel.contentView?.wantsLayer = true
    panel.contentView?.layer?.borderWidth = 0
    panel.contentView?.layer?.borderColor = NSColor.clear.cgColor

    let hostingView = NSHostingView(rootView: CollapsedKeyboardView().tint(.accentColor))
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

    startHoverMonitor(for: panel)
}

func closeCollapsedPanel() {
    stopHoverMonitor()
    CollapsedHoverState.shared.isHovering = false
    collapsedWindow?.orderOut(nil)
    collapsedWindow = nil
    mainWindow?.orderFront(nil)
}

// MARK: - Hover Monitor

private func startHoverMonitor(for panel: NSPanel) {
    stopHoverMonitor()

    hoverMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { event in
        let mouseLocation = NSEvent.mouseLocation
        let panelFrame = panel.frame

        let isInside = panelFrame.contains(mouseLocation)

        if isInside && !CollapsedHoverState.shared.isHovering {
            hoverExitWorkItem?.cancel()
            hoverExitWorkItem = nil
            guard hoverWorkItem == nil else { return event }
            let workItem = DispatchWorkItem {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        CollapsedHoverState.shared.isHovering = true
                    }
                }
            }
            hoverWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
        } else if !isInside && CollapsedHoverState.shared.isHovering {
            hoverWorkItem?.cancel()
            hoverWorkItem = nil
            guard hoverExitWorkItem == nil else { return event }
            let exitWorkItem = DispatchWorkItem {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        CollapsedHoverState.shared.isHovering = false
                    }
                }
            }
            hoverExitWorkItem = exitWorkItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: exitWorkItem)
        } else if !isInside {
            hoverWorkItem?.cancel()
            hoverWorkItem = nil
        }

        return event
    }
}

private func stopHoverMonitor() {
    if let monitor = hoverMonitor {
        NSEvent.removeMonitor(monitor)
        hoverMonitor = nil
    }
    hoverWorkItem?.cancel()
    hoverWorkItem = nil
    hoverExitWorkItem?.cancel()
    hoverExitWorkItem = nil
}
