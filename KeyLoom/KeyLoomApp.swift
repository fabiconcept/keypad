import SwiftUI
import AppKit

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
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            // Trigger an accessibility API call to make the app appear in System Settings
            let _ = AXUIElementCreateSystemWide()
            
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
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "KeyLoom")
            button.action = #selector(togglePanel)
            button.target = self

            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Show Keyboard", action: #selector(togglePanel), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Show Tips", action: #selector(showTips), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Check Accessibility Access", action: #selector(checkAccessibility), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "About KeyLoom", action: #selector(showAbout), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Force Quit", action: #selector(forceQuit), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit KeyLoom", action: #selector(quitApp), keyEquivalent: "q"))
            button.menu = menu
        }
    }

    @objc func showTips() {
        showHelp()
    }

    @objc func checkAccessibility() {
        checkAccessibilityPermission()
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
        let panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 524, height: 260),
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

        let hostingView = NSHostingView(rootView: KeyboardView())
        panel.contentView = hostingView

        // Restore saved position or use default
        if let savedFrame = UserDefaults.standard.dictionary(forKey: "expandedPanelFrame") as? [String: CGFloat],
           let x = savedFrame["x"], let y = savedFrame["y"] {
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 262
            let y = screenFrame.maxY - 280
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Save position when moved
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { _ in
            let origin = panel.frame.origin
            UserDefaults.standard.set(["x": origin.x, "y": origin.y], forKey: "expandedPanelFrame")
        }

        panel.orderFront(nil)
        floatingWindow = panel
        mainWindow = panel
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
