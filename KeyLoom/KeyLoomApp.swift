import SwiftUI
import AppKit
import Combine

// MARK: - App
@main
struct KeyLoomApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingWindow: NSWindow?
    var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusBar()
        showFloatingPanel()
        let startMode = UserDefaults.standard.string(forKey: "startMode") ?? "expanded"
        if startMode == "collapsed" {
            openCollapsedPanel()
        }

        // Check accessibility permission
        checkAccessibilityPermission()

        // Show welcome screen on first launch
        let hasSeenWelcome = UserDefaults.standard.object(forKey: "hasSeenWelcome") as? Bool ?? false
        if !hasSeenWelcome {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showWelcome()
            }
        }
    }

    func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let alert = NSAlert()
                alert.messageText = "Accessibility Access Required"
                alert.informativeText = "KeyLoom needs Accessibility access to paste keystrokes into other apps.\n\nPlease enable KeyLoom in System Settings > Privacy & Security > Accessibility."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Later")
                alert.icon = NSImage(systemSymbolName: "hand.raised.fill", accessibilityDescription: nil)
                if alert.runModal() == .alertFirstButtonReturn {
                    self.openAccessibilitySettings()
                }
            }
        }
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        if let img = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "KeyLoom") {
            img.isTemplate = true
            button.image = img
        } else {
            button.title = "⌨"
        }

        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Open Keyboard", action: #selector(togglePanel), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettingsFromMenu), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let guideItem = NSMenuItem(title: "Guide", action: #selector(showGuide), keyEquivalent: "")
        guideItem.target = self
        menu.addItem(guideItem)

        let aboutItem = NSMenuItem(title: "About KeyLoom", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit KeyLoom", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc func openSettingsFromMenu() {
        openSettings()
    }

    @objc func showGuide() {
        showHelp()
    }

    @objc func showAbout() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let alert = NSAlert()
        alert.messageText = "KeyLoom"
        alert.informativeText = "Version \(version) (\(build))\n\nA floating virtual keyboard for macOS.\nType directly into any app with clipboard paste.\n\nDesigned by Fabiconcept (Zayn Favour Ajokubi)\nfavourajokubi@gmail.com\n\n© 2026 Fabiconcept. All rights reserved."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.icon = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)
        alert.runModal()
    }

    @objc func forceQuit() {
        NSApp.terminate(nil)
    }

    @objc func quitApp() {
        let alert = NSAlert()
        alert.messageText = "Quit KeyLoom?"
        alert.informativeText = "Are you sure you want to quit KeyLoom?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")
        alert.icon = NSImage(systemSymbolName: "keyboard", accessibilityDescription: nil)
        if alert.runModal() == .alertFirstButtonReturn {
            NSApp.terminate(nil)
        }
    }

    @objc func togglePanel() {
        if let collapsedWin = collapsedWindow, collapsedWin.isVisible {
            closeCollapsedPanel()
        } else if let floatingWin = floatingWindow, floatingWin.isVisible {
            floatingWin.orderOut(nil)
        } else if let floatingWin = floatingWindow {
            floatingWin.orderFront(nil)
        }
    }

    func showFloatingPanel() {
        let settings = KeyboardSettings.shared
        let panelWidth = settings.keyboardWidth + settings.keyboardPaddingHorizontal * 2
        let panelHeight = Self.calculatePanelHeight(settings: settings)
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false
        )
        configurePanel(panel)
        panel.contentView = NSHostingView(rootView: KeyboardView())
        restorePanelPosition(panel, width: panelWidth, height: panelHeight)
        observeLayoutChanges(panel)
        panel.orderFront(nil)
        floatingWindow = panel
        mainWindow = panel
    }

    private func configurePanel(_ panel: FloatingPanel) {
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
    }

    private func restorePanelPosition(_ panel: FloatingPanel, width: CGFloat, height: CGFloat) {
        if let savedFrame = UserDefaults.standard.dictionary(forKey: "expandedPanelFrame") as? [String: CGFloat],
           let x = savedFrame["x"], let y = savedFrame["y"] {
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else if let screen = NSScreen.main {
            let sf = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: sf.midX - width / 2, y: sf.maxY - height - 20))
        }
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification, object: panel, queue: .main
        ) { _ in
            UserDefaults.standard.set(
                ["x": panel.frame.origin.x, "y": panel.frame.origin.y],
                forKey: "expandedPanelFrame"
            )
        }
    }

    private func observeLayoutChanges(_ panel: FloatingPanel) {
        KeyboardSettings.shared.objectWillChange.sink { [weak panel] _ in
            guard let panel = panel else { return }
            DispatchQueue.main.async {
                let s = KeyboardSettings.shared
                let w = s.keyboardWidth + s.keyboardPaddingHorizontal * 2
                let h = Self.calculatePanelHeight(settings: s)
                var frame = panel.frame
                frame.size = NSSize(width: w, height: h)
                panel.setFrame(frame, display: true, animate: false)
            }
        }.store(in: &cancellables)
    }

    static func calculatePanelHeight(settings: KeyboardSettings) -> CGFloat {
        let pillHandleHeight: CGFloat = 34
        let visibleRows = settings.showDecorativeKeys ? 5 : 4
        let keyboardContentHeight = CGFloat(visibleRows) * settings.keySize + CGFloat(visibleRows - 1) * settings.keySpacing
        return pillHandleHeight + keyboardContentHeight + settings.keyboardPaddingVertical
    }
}

// MARK: - Floating Panel
class FloatingPanel: NSPanel { }

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
        styleMask: [.titled, .closable, .resizable],
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

struct AppVersion {
    let major: Int
    let minor: Int
    let patch: Int
    let build: String

    static let current: AppVersion = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let parts = version.split(separator: ".").compactMap { Int($0) }
        return AppVersion(
            major: parts.indices.contains(0) ? parts[0] : 1,
            minor: parts.indices.contains(1) ? parts[1] : 0,
            patch: parts.indices.contains(2) ? parts[2] : 0,
            build: build
        )
    }()

    var short: String { "\(major).\(minor).\(patch)" }
    var display: String { "\(short) (\(build))" }
}
